"""Publish pinned canonical Godot builds without changing gameplay or DB gate state."""
import argparse
import json
import re
import shutil
import subprocess
import tarfile
import tempfile
import urllib.request
from pathlib import Path

REPO = 'Queenrain9/danbi-game-office'
SYNC_URL = 'https://hmblaasagxyntyfrfztg.supabase.co/functions/v1/danbi-game-office-sync?view=playtest_showcase&limit=100'
ROOT = Path(__file__).resolve().parents[2]


def collect_targets(payload):
    targets = {}
    for group, required in [('showcases', 'ready'), ('ready_builds', 'playtest_ready')]:
        for row in payload.get(group, []):
            if row.get('status') != required:
                continue
            if (row.get('repo_full_name') or REPO) != REPO:
                continue
            path = row.get('project_path', '')
            commit = row.get('final_commit') or row.get('last_commit') or ''
            if not re.fullmatch(r'builds/[a-z0-9]+(?:-[a-z0-9]+)*', path):
                continue
            if not re.fullmatch(r'[a-f0-9]{40}', commit):
                continue
            targets[(path, commit)] = {
                'slug': path.split('/')[1], 'project_path': path,
                'source_commit': commit, 'title': row.get('title', path),
            }
    return list(targets.values())


def load_targets(root, payload_path=None):
    if payload_path:
        return collect_targets(json.loads(Path(payload_path).read_text(encoding='utf-8')))
    payload = {'showcases': [], 'ready_builds': []}
    # A committed ready showcase also makes the export reproducible during sync outages.
    for path in sorted((root / 'projects').glob('*/playtest/showcase.json')):
        row = json.loads(path.read_text(encoding='utf-8'))
        payload['showcases'].append(row)
    try:
        with urllib.request.urlopen(SYNC_URL, timeout=30) as response:
            live = json.load(response)
        payload['showcases'].extend(live.get('showcases', []))
        payload['ready_builds'].extend(live.get('ready_builds', []))
    except (OSError, ValueError) as error:
        print(f'Sync unavailable; using committed ready showcases: {error}', flush=True)
    return collect_targets(payload)


def run_godot(godot, project, args):
    result = subprocess.run([godot, '--headless', '--path', str(project), *args],
                            capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=180)
    log = result.stdout + result.stderr
    print(log, flush=True)
    # Godot can return zero even after a GDScript parse failure.
    if result.returncode or re.search(r'SCRIPT ERROR:|Parse Error:|Failed to load script|Error exporting project', log):
        raise RuntimeError('Godot import/export failed; see workflow log')


def export_target(target, root, output, godot):
    destination = output / target['slug'] / target['source_commit']
    destination.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='danbi-web-') as temporary:
        temporary = Path(temporary)
        archive = temporary / 'source.tar'
        subprocess.run(['git', 'archive', '--format=tar', '-o', str(archive),
                        target['source_commit'], target['project_path']], cwd=root, check=True)
        with tarfile.open(archive) as contents:
            contents.extractall(temporary, filter='data')
        project = temporary / target['project_path']
        if not (project / 'project.godot').is_file():
            raise RuntimeError('Canonical project.godot missing at source commit')
        preset = (root / 'tools/web/export_presets.cfg').read_text(encoding='utf-8')
        (project / 'export_presets.cfg').write_text(preset, encoding='utf-8')
        # Web-only override in the temporary export copy. Canonical files are untouched.
        (project / 'override.cfg').write_text('[rendering]\nrenderer/rendering_method="gl_compatibility"\nrenderer/rendering_method.web="gl_compatibility"\n', encoding='utf-8')
        run_godot(godot, project, ['--editor', '--import'])
        run_godot(godot, project, ['--export-release', 'Web', str(destination / 'index.html')])
    for suffix in ('html', 'js', 'wasm', 'pck'):
        file = destination / ('index.' + suffix)
        if not file.is_file() or not file.stat().st_size:
            raise RuntimeError(f'Missing export artifact: {file.name}')
    return {**target, 'status': 'exported',
            'url': f"play/{target['slug']}/{target['source_commit']}/index.html"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default='godot')
    parser.add_argument('--payload', help='Offline sync payload for reproducible verification')
    parser.add_argument('--output', default=str(ROOT / 'play'))
    args = parser.parse_args()
    output = Path(args.output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    entries = []
    for target in load_targets(ROOT, args.payload):
        try:
            entry = export_target(target, ROOT, output, args.godot)
        except (OSError, RuntimeError, subprocess.SubprocessError) as error:
            destination = output / target['slug'] / target['source_commit']
            if destination.exists():
                shutil.rmtree(destination)
            entry = {**target, 'status': 'failed', 'error': str(error)}
            print(f"::warning::{target['slug']}: {error}", flush=True)
        entries.append(entry)
    manifest = {'schema_version': 'godot-web-v1', 'godot_version': '4.7.2', 'exports': entries}
    (output / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    # Stable per-game entry point; the showroom uses the pinned source URL instead.
    for entry in entries:
        if entry['status'] == 'exported':
            url = entry['source_commit'] + '/index.html'
            (output / entry['slug'] / 'index.html').write_text(
                '<!doctype html><meta charset="utf-8"><title>Godot Web player</title>'
                f'<meta http-equiv="refresh" content="0;url={url}"><a href="{url}">Play</a>', encoding='utf-8')
    print(f"Web exports: {sum(x['status'] == 'exported' for x in entries)}/{len(entries)}", flush=True)


if __name__ == '__main__':
    main()
