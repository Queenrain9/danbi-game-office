"""Conservative fidelity-v1 construction and static checks. No Godot execution.

This is a structural verifier, not a GDScript compiler or a gameplay reviewer.
Unknown construction/check forms fail closed. The independent gate still reviews
source meaning before recording VERIFIED in the database.
"""
import argparse
import copy
from decimal import Decimal, InvalidOperation
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

STAGES = ('skeleton', 'geometry', 'state', 'input', 'presentation', 'integration')
PATTERNS = {
    'absolute_control_v1': {'types': ['Control', 'Label', 'Panel', 'ColorRect', 'TextureRect', 'Button', 'ProgressBar'], 'mouse_filter': 2},
    'button_tap_v1': {'types': ['Button'], 'mouse_filter': 0, 'signal': 'pressed'},
    'modal_scrim_v1': {'types': ['Control', 'ColorRect', 'Panel'], 'mouse_filter': 0},
    'explicit_script_v1': {'types': ['Control', 'Button', 'Panel', 'ColorRect', 'TextureRect', 'Label', 'ProgressBar'], 'mouse_filter': 0, 'script_required': True},
}
CHECKS = {'file', 'node', 'symbol', 'geometry', 'connection', 'resources'}
NAME = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')

STUDIO_REFERENCE_SIZES = {
    'portrait': {'width': 540, 'height': 960},
    'landscape': {'width': 960, 'height': 540},
}

# Wireframe component types are semantic, not Godot class names. The Compiler
# must use this registry instead of inventing a mapping per game. A component
# that receives a non-Button gesture keeps its canonical Godot type and is
# promoted to explicit_script_v1.
SOURCE_COMPONENT_TYPES = {}


def _component_types(names, godot_type, default_pattern='absolute_control_v1', extra_patterns=()):
    patterns = tuple(dict.fromkeys((default_pattern,) + tuple(extra_patterns)))
    for name in names.split():
        SOURCE_COMPONENT_TYPES[name] = {
            'godot_type': godot_type,
            'default_pattern': default_pattern,
            'allowed_patterns': patterns,
        }


_component_types('button', 'Button', 'button_tap_v1', ('explicit_script_v1',))
_component_types('hold_button hold_control toggle', 'Button', 'explicit_script_v1', ('button_tap_v1',))
_component_types(
    'label status counter metric grade headline large_number stat timer rating '
    'result_stamp legend text report cue',
    'Label', 'absolute_control_v1', ('explicit_script_v1',)
)
_component_types('meter progress', 'ProgressBar', 'absolute_control_v1', ('explicit_script_v1',))
_component_types(
    'panel card goal_card request_card risk_card rule_card text_card modal popover '
    'header context summary resource_row banner overlay_banner',
    'Panel', 'absolute_control_v1', ('explicit_script_v1', 'modal_scrim_v1')
)
_component_types('overlay world_overlay', 'ColorRect', 'modal_scrim_v1', ('absolute_control_v1', 'explicit_script_v1'))
_component_types(
    'preview portrait diagram grid_preview comparison animation object world_view',
    'TextureRect', 'absolute_control_v1', ('explicit_script_v1',)
)
_component_types(
    'canvas card_list cards chip chip_group chips cue_strip list list_buttons grid grid_buttons timeline '
    'metric_grid tags tray part_tray tool_tray horizontal_strip stack resource route_cards '
    'goal_overlays reach_overlay world',
    'Control', 'absolute_control_v1', ('explicit_script_v1',)
)
_component_types(
    'arc_control crank cuttable drag_handle drag_tool draggable draggable_entities '
    'draggable_list draggable_objects draggable_token draggable_tool drop_slot drop_target '
    'drop_zone dropzone editable_path fader geometry graph grinder hit_layer hit_targets '
    'hotspots indicator interactive_layer interactive_object interactive_part latch manipulable '
    'manipulation_zone map mask_canvas node_graph part_tray path polygon_surface rail rope rotary '
    'route_selector scripted_sim slider spline_playfield tool vertical_handle vertical_slider '
    'vertical_swipe_control viewport wipe world_entities world_entity world_object world_targets',
    'Control', 'explicit_script_v1', ('absolute_control_v1',)
)


def source_component_spec(source_type):
    spec = SOURCE_COMPONENT_TYPES.get(str(source_type or '').strip())
    if not spec:
        raise ValueError('Unsupported Wireframe component type: ' + str(source_type))
    return dict(spec)


def canonical_reference_size(pack):
    """Resolve the deterministic construction canvas for a Wireframe Pack.

    Explicit source data wins. Older percent-based packs may omit a pixel canvas;
    in that case the studio mobile convention supplies one from orientation.
    """
    if not isinstance(pack, dict):
        raise ValueError('Wireframe Pack object required')
    explicit = pack.get('reference_size')
    if explicit is None and isinstance(pack.get('developer_handoff'), dict):
        explicit = pack['developer_handoff'].get('reference_size')
    if explicit is not None:
        if not isinstance(explicit, dict) or set(('width', 'height')) - set(explicit):
            raise ValueError('Explicit reference_size requires width and height')
        width, height = explicit.get('width'), explicit.get('height')
        if isinstance(width, bool) or isinstance(height, bool) or not isinstance(width, (int, float)) or not isinstance(height, (int, float)) or width <= 0 or height <= 0:
            raise ValueError('Explicit reference_size must contain positive numeric width/height')
        return {'width': width, 'height': height}
    orientation = str(pack.get('orientation') or '').strip().lower()
    if orientation in STUDIO_REFERENCE_SIZES:
        return dict(STUDIO_REFERENCE_SIZES[orientation])
    raise ValueError('No explicit reference_size and no supported portrait/landscape orientation')



def digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':'), allow_nan=False).encode()).hexdigest()


def seal(blueprint):
    b = copy.deepcopy(blueprint)
    b['hash_algorithm'] = 'sha256-canonical-json-v1'
    b['source_hash'] = digest(b['source'])
    b.pop('blueprint_hash', None)
    b['blueprint_hash'] = digest(b)
    return b


def geometry(box, size):
    def number(value):
        if isinstance(value, bool):
            raise ValueError('Boolean coordinate')
        try:
            n = Decimal(str(value))
        except InvalidOperation as exc:
            raise ValueError('Non-numeric coordinate') from exc
        if not n.is_finite():
            raise ValueError('Non-finite coordinate')
        return n
    b = {k: number(box[k]) for k in ('x', 'y', 'w', 'h')}
    s = {k: number(size[k]) for k in ('width', 'height')}
    if min(s.values()) <= 0 or b['w'] <= 0 or b['h'] <= 0 or min(b['x'], b['y']) < 0 or b['x']+b['w'] > 100 or b['y']+b['h'] > 100:
        raise ValueError('Box outside screen or empty geometry')
    return {k: float(v*s['width' if k in ('x', 'w') else 'height']/100) for k, v in b.items()}


def resource_path(value):
    if not isinstance(value, str) or not value.startswith('res://'):
        raise ValueError('Expected res:// path')
    tail = value[6:]
    parts = tail.split('/')
    if not tail or any(p in ('', '.', '..') for p in parts) or any(c in value for c in ('\\', '\n', '\r', '"')):
        raise ValueError('Unsafe resource path')
    return tail


def resolve_source(b, pointer):
    if not isinstance(pointer, str) or not pointer.startswith('/source/'):
        raise ValueError('Explicit RFC6901 pointer under /source required (arrays are zero based)')
    cur = b
    for part in pointer.split('/')[1:]:
        part = part.replace('~1', '/').replace('~0', '~')
        if isinstance(cur, list):
            if not re.fullmatch(r'0|[1-9][0-9]*', part):
                raise ValueError('Invalid array index')
            cur = cur[int(part)]
        else:
            cur = cur[part]
    if cur is None:
        raise ValueError('Source reference resolves to null')
    return cur


def is_static(t):
    return t.get('verification_scope', 'static' if t.get('kind') == 'static' else 'manual_playtest') == 'static'


def all_nodes(b):
    bindings = b.get('bindings') or {}
    return bindings.get('nodes', []) + bindings.get('components', [])


def expected_nodes(b):
    nodes = {n['node_path']: dict(n) for n in all_nodes(b)}
    size = b['bindings']['reference_size']
    full = {'x': 0, 'y': 0, 'w': size['width'], 'h': size['height']}
    for path, n in sorted(nodes.items(), key=lambda v: v[0].count('/')):
        parent = nodes.get(path.rsplit('/', 1)[0])
        pr = parent['_rect'] if parent else full
        rect = geometry(n['source_box'], size) if n.get('source_box') else dict(pr)
        n['_rect'] = rect
        n['_props'] = {'layout_mode': 0, 'anchor_left': 0.0, 'anchor_top': 0.0, 'anchor_right': 0.0, 'anchor_bottom': 0.0,
                       'offset_left': rect['x']-pr['x'], 'offset_top': rect['y']-pr['y'],
                       'offset_right': rect['x']-pr['x']+rect['w'], 'offset_bottom': rect['y']-pr['y']+rect['h']}
        if n.get('full_rect'):
            n['_props'].update(layout_mode=1, anchor_right=1.0, anchor_bottom=1.0, offset_left=0.0, offset_top=0.0, offset_right=0.0, offset_bottom=0.0)
        pattern = PATTERNS.get(n.get('construction_pattern', 'absolute_control_v1'), {})
        n['_props']['mouse_filter'] = pattern.get('mouse_filter', 2)
        for key, value in n.get('properties', {}).items():
            if key in n['_props']:
                raise ValueError('Layout/input properties cannot override canonical pattern')
            n['_props'][key] = value
    return nodes


def gdvalue(v):
    if v is True: return 'true'
    if v is False: return 'false'
    if isinstance(v, str): return json.dumps(v, ensure_ascii=False)
    if isinstance(v, (int, float)) and not isinstance(v, bool): return format(v, '.12g')
    raise ValueError('Only explicit scalar properties supported')


def construct(b):
    report = validate(b)
    if report['errors']:
        raise ValueError(json.dumps(report['errors'], ensure_ascii=False))
    nodes = expected_nodes(b)
    root = next(p for p in nodes if p.count('/') == 2)
    scripts = sorted({n['script_path'] for n in nodes.values() if n.get('script_path')})
    ids = {s: str(i+1) for i, s in enumerate(scripts)}
    lines = [f'[gd_scene load_steps={len(scripts)+1} format=3]', '']
    for s in scripts:
        lines.extend([f'[ext_resource type="Script" path="{s}" id="{ids[s]}"]', ''])
    for p, n in sorted(nodes.items(), key=lambda v: (v[0].count('/'), v[0])):
        parent = p.rsplit('/', 1)[0]
        attr = '' if p == root else f' parent="{parent[len(root)+1:] or "."}"'
        lines.append(f'[node name="{p.rsplit("/",1)[1]}" type="{n["godot_type"]}"{attr}]')
        lines.extend(f'{k} = {gdvalue(v)}' for k, v in n['_props'].items())
        if n.get('script_path'): lines.append(f'script = ExtResource("{ids[n["script_path"]]}")')
        lines.append('')
    for c in b['bindings'].get('connections', []):
        src, dst = c['from'][len(root)+1:] or '.', c['to'][len(root)+1:] or '.'
        lines.append(f'[connection signal="{c["signal"]}" from="{src}" to="{dst}" method="{c["method"]}"]')
    return '\n'.join(lines)+'\n'


def parse_scene(text):
    """Read declarative nodes only; instances/inheritance need a future resolver."""
    nodes, resources, connections = {}, {}, []
    root, current = None, None
    for line in text.splitlines():
        line = line.strip()
        if line.startswith('['):
            current = None
            attrs = dict(re.findall(r'(\w+)="([^"\n]*)"', line))
            if line.startswith('[ext_resource '): resources[attrs['id']] = attrs.get('path')
            elif line.startswith('[node '):
                if 'instance=' in line or 'type' not in attrs: raise ValueError('Instanced/inherited nodes need explicit static resolver')
                if root is None:
                    root = '/root/'+attrs['name']; path = root
                else:
                    parent = attrs.get('parent')
                    if parent is None: raise ValueError('Multiple roots')
                    path = root+'/'+('' if parent == '.' else parent+'/')+attrs['name']
                if path in nodes: raise ValueError('Duplicate node path')
                current = {'type': attrs['type'], 'props': {}, 'script': None}; nodes[path] = current
            elif line.startswith('[connection '):
                connections.append(attrs)
        elif current and ' = ' in line:
            key, value = line.split(' = ', 1)
            if key == 'script':
                match = re.fullmatch(r'ExtResource\("([^"\n]+)"\)', value)
                current['script'] = resources.get(match[1]) if match else None
            else:
                try: current['props'][key] = json.loads(value)
                except ValueError: current['props'][key] = value
    return nodes, connections, root


def script_symbols(text):
    # Preserve line positions while removing comments and string literals, including
    # multiline strings. A comment or quoted example cannot define a symbol.
    token = r'"""[\s\S]*?"""|\x27\x27\x27[\s\S]*?\x27\x27\x27|"(?:\\.|[^"\\])*"|\x27(?:\\.|[^\x27\\])*\x27|#[^\n]*'
    clean = re.sub(token, lambda m: '\n'*m[0].count('\n'), text)
    return set(re.findall(r'^\s*(?:@\w+(?:\([^\n]*\))?\s+)*(?:static\s+)?(func|var|const|signal|enum)\s+(\w+)', clean, re.M))


def validate(b, project=None, claims=None, commit=None):
    errors = []
    def error(code, path, message): errors.append({'code': code, 'path': str(path), 'message': message})
    bindings = b.get('bindings') or {}
    reqs = b.get('requirements', [])
    ids = [r.get('id') for r in reqs]
    if not ids or any(not isinstance(i, str) or not i for i in ids) or len(set(ids)) != len(ids): error('REQUIREMENT_IDS', 'requirements', 'Nonempty unique IDs required')
    if b.get('schema_version') != 'fidelity-v1': error('SCHEMA', '', 'Expected fidelity-v1')
    if b.get('hash_algorithm') != 'sha256-canonical-json-v1': error('HASH_ALGORITHM', '', 'Explicit canonical hash algorithm required; do not silently rehash approved legacy data')
    else:
        try:
            if seal(b).get('blueprint_hash') != b.get('blueprint_hash') or digest(b.get('source')) != b.get('source_hash'): error('HASH', '', 'Blueprint/source content hash mismatch')
        except (ValueError, KeyError, TypeError): error('HASH', '', 'Invalid JSON/hash input')
    source = b.get('source', {})
    try:
        expected_size = canonical_reference_size(source.get('pack', {}))
        if bindings.get('reference_size') != expected_size:
            error('REFERENCE_SIZE', 'bindings.reference_size', 'Blueprint reference_size must match explicit source size or studio orientation fallback')
    except (ValueError, TypeError) as exc:
        error('REFERENCE_SIZE', 'bindings.reference_size', str(exc))
    if source.get('requirements') != reqs or source.get('pack', {}).get('screens') != b.get('screens'): error('SOURCE_DRIFT', '', 'Frozen source requirements/screens differ')
    if source.get('pack', {}).get('id') != b.get('wireframe_pack_id') or source.get('pack', {}).get('design_id') != source.get('design', {}).get('id'): error('SOURCE_IDENTITY', '', 'Pack/design identity mismatch')
    for r in reqs:
        pointer = bindings.get('sources', {}).get(r.get('id'), r.get('source_ref'))
        try: resolve_source(b, pointer)
        except (KeyError, IndexError, ValueError, TypeError): error('SOURCE_REF', r.get('id'), 'Unresolved RFC6901 source reference')
    if bindings.get('coordinate_space') != 'screen_percent': error('GEOMETRY', '', 'Only explicit screen_percent supported')
    if bindings.get('stretch_mode') != 'canvas_items': error('GEOMETRY', '', 'Foundation supports canvas_items')
    try: resource_path(bindings.get('scene_path'))
    except ValueError as exc: error('PATH', 'scene_path', str(exc))
    ns = all_nodes(b); paths = [n.get('node_path') for n in ns]
    if len(set(paths)) != len(paths): error('NODE_DUPLICATE', '', 'Node paths must be unique')
    nodes = {n.get('node_path'): n for n in ns}
    roots = [p for p in paths if isinstance(p,str) and p.count('/')==2]
    if len(roots)!=1: error('NODE_PATH', '', 'Exactly one explicit /root/SceneRoot required')
    for n in ns:
        path = n.get('node_path')
        if not isinstance(path,str) or not path.startswith('/root/') or any(not NAME.fullmatch(x) for x in path.split('/')[2:]): error('NODE_PATH', path, 'Explicit identifier-only path required'); continue
        if path not in roots and path.rsplit('/',1)[0] not in nodes: error('NODE_PATH', path, 'Missing declared parent')
        if not n.get('full_rect') and not n.get('source_box'): error('GEOMETRY', path, 'Explicit full_rect or source_box required')
        if n.get('source_box'):
            try:
                rect=geometry(n['source_box'], bindings['reference_size'])
                if n.get('reference_px_rect') and any(abs(rect[k]-n['reference_px_rect'][k])>2 for k in rect): error('GEOMETRY',path,'Reference rect conflicts with source')
            except (KeyError, ValueError, TypeError): error('GEOMETRY',path,'Invalid source geometry')
        pattern=PATTERNS.get(n.get('construction_pattern','absolute_control_v1'))
        if not pattern or n.get('godot_type') not in pattern['types']: error('PATTERN',path,'Unsupported pattern/type; containers cannot reinterpret absolute geometry')
        if pattern and pattern.get('script_required') and not n.get('script_path'): error('PATTERN',path,'Explicit behavior script required')
        if n.get('script_path'):
            try: resource_path(n['script_path'])
            except ValueError as exc: error('PATH',path,str(exc))
        reusable=n.get('reusable_component')
        if reusable:
            spec=bindings.get('reusable_components',{}).get(reusable,{})
            if not spec or spec.get('script_path')!=n.get('script_path') or spec.get('godot_type')!=n.get('godot_type'): error('REUSABLE',path,'Reusable name must resolve to attached script and compatible type')
        for key in ('state_binding','enabled_when'):
            if n.get(key) and not n.get(key+'_ref'): error('STATE_BINDING',path,'Explicit file/symbol binding required for '+key)
    source_components={(s['id'],c['id']):c for s in b.get('screens',[]) for c in s.get('components',[])}
    source_states={(s['id'],v.get('id') if isinstance(v,dict) else v) for s in b.get('screens',[]) for v in s.get('states',[])}
    bound_states={(v.get('screen_id'),v.get('id')) for v in bindings.get('states',[])}
    if source_states != bound_states or len(bindings.get('states',[])) != len(bound_states):
        error('STATE_COVERAGE','','Every screen state needs one concrete binding')
    source_variants={(s['id'],v.get('id') if isinstance(v,dict) else v) for s in b.get('screens',[]) for v in s.get('state_variants',s.get('variants',[]))}
    bound_variants={(v.get('screen_id'),v.get('id')) for v in bindings.get('variants',[])}
    if source_variants != bound_variants or len(bindings.get('variants',[])) != len(bound_variants):
        error('VARIANT_COVERAGE','','Every source variant needs one concrete binding')
    source_transitions=[(s['id'],v.get('from'),v.get('to'),v.get('trigger')) for s in b.get('screens',[]) for v in s.get('transitions',[])]
    bound_transitions=[(v.get('screen_id'),v.get('from'),v.get('to'),v.get('trigger')) for v in bindings.get('transitions',[])]
    if sorted(map(str,source_transitions)) != sorted(map(str,bound_transitions)):
        error('TRANSITION_COVERAGE','','Transition screen/from/to/trigger must preserve source exactly')
    component_keys=[(n.get('screen_id'),n.get('component_id')) for n in bindings.get('components',[])]
    if set(component_keys)!=set(source_components) or len(set(component_keys))!=len(component_keys): error('COMPONENT_COVERAGE','','Exact wireframe component mapping required')
    for n in bindings.get('components',[]):
        src=source_components.get((n.get('screen_id'),n.get('component_id')), {})
        if src.get('box')!=n.get('source_box'): error('GEOMETRY',n.get('node_path'),'Component box differs from source')
        try:
            spec=source_component_spec(src.get('type'))
            if n.get('godot_type')!=spec['godot_type']:
                error('COMPONENT_TYPE',n.get('node_path'),'Godot type must follow SOURCE_COMPONENT_TYPES registry for '+str(src.get('type')))
            if n.get('construction_pattern','absolute_control_v1') not in spec['allowed_patterns']:
                error('COMPONENT_PATTERN',n.get('node_path'),'Construction pattern is not allowed for source component type '+str(src.get('type')))
        except ValueError as exc:
            error('COMPONENT_TYPE',n.get('node_path'),str(exc))
    for name, spec in bindings.get('reusable_components', {}).items():
        if not any(n.get('reusable_component') == name and n.get('script_path') == spec.get('script_path') for n in ns):
            error('REUSABLE', name, 'Declared reusable component has no compatible use site')
    conns=bindings.get('connections',[])
    for c in conns:
        if c.get('from') not in nodes or c.get('to') not in nodes or not NAME.fullmatch(c.get('method','')) or not NAME.fullmatch(c.get('signal','')): error('CONNECTION','','Invalid node/signal/method binding')
    source_interactions={(s['id'],i):v for s in b.get('screens',[]) for i,v in enumerate(s.get('interactions',[]))}
    ints=bindings.get('interactions',[])
    keys=[(v.get('screen_id'),v.get('interaction_index')) for v in ints]
    if len(set(keys))!=len(keys) or set(keys)!=set(source_interactions): error('INTERACTION_COVERAGE','','Exact source interaction mapping required')
    for v in ints:
        src=source_interactions.get((v.get('screen_id'),v.get('interaction_index')), {})
        primary_path=v.get('target_node')
        target_paths=[primary_path] if primary_path else []
        target_paths.extend(v.get('related_nodes',[]) if isinstance(v.get('related_nodes'),list) else [])
        if v.get('source_target') != src.get('target'):
            error('INPUT_TARGET',primary_path,'source_target must preserve the Wireframe interaction target text exactly')
        primary_component=nodes.get(primary_path,{})
        if len(target_paths)==1 and primary_component and v.get('source_target') not in (primary_component.get('component_id'), primary_component.get('label')):
            if not v.get('target_selector'):
                error('INPUT_TARGET',primary_path,'Semantic sub-target needs explicit target_selector when source target is not the component itself')
        if v.get('input')!=src.get('trigger',src.get('input')):
            error('INPUT_MODALITY',primary_path,'Gesture differs from source')
        if not target_paths:
            error('INPUT_TARGET',primary_path,'Interaction needs at least one explicit component target')
            continue
        target_nodes=[]
        for path in target_paths:
            target=nodes.get(path,{})
            if not target or 'component_id' not in target or target.get('screen_id')!=v.get('screen_id'):
                error('INPUT_TARGET',path,'Gesture target must resolve to an explicit component on the same screen')
            else:
                target_nodes.append((path,target))
        if not v.get('action_symbol') or not v.get('action_script'):
            error('ACTION',primary_path,'Explicit game action symbol/script required')
        if v.get('input')=='tap':
            for path,target in target_nodes:
                if target.get('construction_pattern')=='button_tap_v1':
                    if not any(c.get('from')==path and c.get('signal')=='pressed' and c.get('method')==v.get('action_symbol') and nodes.get(c.get('to'),{}).get('script_path')==v.get('action_script') for c in conns):
                        error('CONNECTION',path,'Button tap requires pressed bound to the exact action owner')
                elif target.get('construction_pattern')=='explicit_script_v1':
                    if not v.get('input_handler') or target.get('script_path') is None:
                        error('INPUT_MODALITY',path,'Non-Button tap requires explicit_script_v1 with a reviewed input_handler')
                else:
                    error('INPUT_MODALITY',path,'Tap target must use button_tap_v1 or explicit_script_v1')
        else:
            primary=nodes.get(primary_path,{})
            if primary.get('construction_pattern')!='explicit_script_v1' or not v.get('input_handler') or primary.get('script_path') is None:
                error('INPUT_MODALITY',primary_path,'Non-tap gesture requires explicit_script_v1 on the primary target with a reviewed input_handler')
    impl=bindings.get('implementations',{})
    if set(impl)!=set(ids): error('IMPLEMENTATION_COVERAGE','','Every requirement needs explicit implementation references')
    refs=[]
    for rid, rr in impl.items():
        if not isinstance(rr,list) or not rr: error('IMPLEMENTATION_COVERAGE',rid,'Nonempty reference array required'); continue
        refs.extend(rr)
    refs.extend(bindings.get('symbols',[]))
    for n in ns:
        refs.extend(n[k] for k in ('state_binding_ref','enabled_when_ref') if isinstance(n.get(k),dict))
    for key in ('states','variants','transitions'):
        for entry in bindings.get(key,[]):
            ref = entry.get('implementation_ref')
            if not isinstance(ref,dict) or not ref.get('file') or not (ref.get('node_path') or ref.get('symbol')):
                error('BINDING_REF',key,'Every state/variant/transition needs a concrete implementation location')
            else: refs.append(ref)
    for rule_id, entry in bindings.get('rules',{}).items():
        ref = entry.get('implementation_ref') if isinstance(entry,dict) else None
        if not isinstance(ref,dict) or not ref.get('file') or not (ref.get('node_path') or ref.get('symbol')):
            error('BINDING_REF',rule_id,'Every rule needs a concrete implementation location')
        else: refs.append(ref)
    for v in ints:
        if v.get('action_script'): refs.append({'file':v['action_script'],'symbol':v.get('action_symbol'),'kind':'func'})
        if v.get('input_handler') and nodes.get(v.get('target_node'),{}).get('script_path'):
            refs.append({'file':nodes.get(v.get('target_node'),{}).get('script_path'),'symbol':v['input_handler'],'kind':'func'})
    for ref in refs:
        try: resource_path(ref.get('file'))
        except ValueError as exc: error('PATH',ref.get('file'),str(exc))
        if not ref.get('symbol') and not ref.get('node_path'): error('IMPLEMENTATION_REF',ref.get('file'),'Node or symbol required')
    tests=bindings.get('tests',[]); tids=[t.get('id') for t in tests]
    if not tids or any(not t for t in tids) or len(set(tids))!=len(tids): error('TEST_IDS','','Unique test IDs required')
    for rid in ids:
        if not any(is_static(t) and rid in t.get('requirement_ids',[]) for t in tests): error('STATIC_COVERAGE',rid,'Static implementation test required; manual playtests are additional')
        locations = impl.get(rid,[])
        if isinstance(locations,list) and locations and not any(
            is_static(t) and rid in t.get('requirement_ids',[]) and any(
                check.get('file') == ref.get('file') and
                (not ref.get('node_path') or check.get('node_path') == ref['node_path'] or check.get('kind') in ('file','resources')) and
                (not ref.get('symbol') or check.get('symbol') == ref['symbol'] or check.get('kind') in ('file','resources'))
                for ref in locations for check in t.get('checks',[])) for t in tests):
            error('TEST_TRACE',rid,'Static test must inspect a declared implementation location')
    for t in tests:
        if any(r not in ids for r in t.get('requirement_ids',[])): error('TEST_REQUIREMENT',t.get('id'),'Unknown requirement')
        if t.get('kind') == 'runtime' and is_static(t):
            error('TEST_SCOPE',t.get('id'),'Runtime test cannot be recorded as static; add a separate structural test')
        if is_static(t):
            if not t.get('checks') or any(c.get('kind') not in CHECKS for c in t['checks']): error('TEST_CHECK',t.get('id'),'Nonempty deterministic checks required; unknown checks cannot pass')
            if t.get('stage') not in STAGES: error('TEST_STAGE',t.get('id'),'Explicit known construction stage required')
    for stage in STAGES:
        if not any(is_static(t) and t.get('stage') == stage for t in tests):
            error('STAGE_COVERAGE',stage,'Every DB construction stage needs a concrete static test')
    if claims is not None:
        cids=[c.get('requirement_id') for c in claims]
        if set(cids)!=set(ids) or len(cids)!=len(ids): error('CLAIM_COVERAGE','','Exact unique claims required')
        for c in claims:
            if c.get('blueprint_hash')!=b.get('blueprint_hash') or (commit and c.get('commit')!=commit) or not re.fullmatch('[0-9a-f]{40}',c.get('commit','')): error('CLAIM_STALE',c.get('requirement_id'),'Claim hash/commit mismatch')
            if c.get('status')!='IMPLEMENTED' or c.get('implementation_refs')!=impl.get(c.get('requirement_id')): error('CLAIM_TRACE',c.get('requirement_id'),'Claims must match approved implementation references exactly')
    if project is not None:
        validate_project(b,Path(project),refs,error)
    return {'verification_scope':'static','runtime_qa_performed':False,'manual_playtest_required':True,
            'status':'failed' if errors else 'passed','errors':errors,
            'manual_test_ids':[t.get('id') for t in tests if not is_static(t)],
            'blueprint_hash':b.get('blueprint_hash'),'commit':commit,
            'results':[{'test_id':t.get('id'),'status':'failed' if errors else 'passed'} for t in tests if is_static(t)],
            'limitation':'Structural checks only; independent code/source review must verify game-specific semantics. Not runtime QA.'}


def validate_project(b, project, refs, error):
    bindings=b['bindings']; cache={}
    def read(res):
        try:
            relative=resource_path(res); p=(project/relative).resolve()
            if not p.is_relative_to(project.resolve()): raise ValueError('Resource escaped project')
            if res not in cache:
                if p.suffix.lower() in ('.gd','.tscn','.tres','.godot','.json','.cfg','.txt'):
                    cache[res]=p.read_text()
                else:
                    p.read_bytes()  # Existence/readability for binary assets; never decode as text.
                    cache[res]=''
            return cache[res]
        except (ValueError,OSError,UnicodeError) as exc: error('MISSING_FILE',res,str(exc)); return ''
    def symbol(ref):
        text=read(ref.get('file')); name=ref.get('symbol'); kind=ref.get('kind')
        if not any(n==name and (not kind or k==kind) for k,n in script_symbols(text)): error('SYMBOL',ref.get('file'),str(name)+' is not declared')
    scene=read(bindings.get('scene_path'))
    try: actual,connections,root=parse_scene(scene)
    except (ValueError,KeyError) as exc: error('SCENE',bindings.get('scene_path'),str(exc)); actual={};connections=[];root=''
    try: expected=expected_nodes(b)
    except (ValueError,KeyError,TypeError) as exc: error('GEOMETRY','',str(exc)); expected={}
    for path,n in expected.items():
        a=actual.get(path)
        if not a: error('NODE_PATH',path,'Declared node missing'); continue
        if a['type']!=n['godot_type']: error('NODE_TYPE',path,'Godot type differs')
        if a['script']!=n.get('script_path'): error('SCRIPT_BINDING',path,'Attached script differs')
        for k,v in n['_props'].items():
            av=a['props'].get(k)
            same=abs(av-v)<0.000001 if isinstance(av,(int,float)) and isinstance(v,(int,float)) else av==v
            if not same: error('GEOMETRY' if k.startswith(('anchor','offset','layout')) else 'PROPERTY',path,k+' differs from canonical construction')
        if n.get('script_path'): read(n['script_path'])
    for path in set(actual)-set(expected):
        error('UNDECLARED_NODE',path,'Scene contains a node absent from approved blueprint')
    for c in bindings.get('connections',[]):
        relative=lambda p: p[len(root)+1:] or '.'
        wanted={'from':relative(c['from']),'to':relative(c['to']),'signal':c['signal'],'method':c['method']}
        if wanted not in connections: error('CONNECTION',c['from'],'Missing declared signal connection')
        dst=expected.get(c['to'],{}).get('script_path')
        if dst: symbol({'file':dst,'symbol':c['method'],'kind':'func'})
        else: error('SYMBOL',c['to'],'Signal receiver has no script')
        src=expected.get(c['from'],{})
        if not (src.get('godot_type')=='Button' and c['signal']=='pressed'):
            if src.get('script_path'): symbol({'file':src['script_path'],'symbol':c['signal'],'kind':'signal'})
            else: error('SYMBOL',c['from'],'Unknown signal')
    for ref in refs:
        read(ref.get('file'))
        if ref.get('symbol'): symbol(ref)
        if ref.get('node_path'):
            try: rn,_,_=parse_scene(read(ref['file']))
            except (KeyError,ValueError): rn={}
            if ref['node_path'] not in rn: error('NODE_PATH',ref['node_path'],'Implementation node missing from referenced scene')
    for t in bindings.get('tests',[]):
        if not is_static(t): continue
        for check in t.get('checks',[]):
            kind=check.get('kind')
            if kind=='file': read(check.get('file'))
            elif kind=='symbol': symbol({'file':check.get('file'),'symbol':check.get('symbol'),'kind':check.get('symbol_kind')})
            elif kind in ('node','geometry'):
                if check.get('node_path') not in expected or check.get('node_path') not in actual: error('NODE_PATH',check.get('node_path'),'Test target unresolved')
            elif kind=='connection' and check.get('binding') not in bindings.get('connections',[]): error('CONNECTION',t['id'],'Test connection unresolved')
            elif kind=='resources':
                text=read(check.get('file'))
                for res in re.findall(r'["\x27](res://[^"\x27\n]+)["\x27]',text): read(res)
    try: config=(project/'project.godot').read_text()
    except OSError: config='';error('MISSING_FILE','project.godot','Missing Godot project')
    main=re.search(r'^run/main_scene="([^"]+)"',config,re.M)
    if not main or main[1]!=bindings.get('scene_path'): error('MAIN_SCENE','project.godot','Main scene differs from blueprint')
    for key,value in [('window/size/viewport_width',bindings.get('reference_size',{}).get('width')),('window/size/viewport_height',bindings.get('reference_size',{}).get('height')),('window/stretch/mode',bindings.get('stretch_mode'))]:
        match=re.search(r'^'+re.escape(key)+r'=(.+)$',config,re.M)
        if not match or match[1].strip()!=gdvalue(value): error('PROJECT_CONFIG','project.godot',key+' differs')
    for p in project.rglob('*'):
        if p.suffix not in ('.tscn','.tres','.gd','.godot') or '.godot' in p.relative_to(project).parts or not p.is_file(): continue
        if not p.resolve().is_relative_to(project.resolve()): error('RESOURCE_PATH',p,'Symlink escapes project');continue
        text=p.read_text()
        for res in re.findall(r'["\x27](res://[^"\x27\n]+)["\x27]',text):
            try:
                target=(project/resource_path(res)).resolve()
                if not target.is_relative_to(project.resolve()) or not target.is_file(): error('RESOURCE_PATH',p.relative_to(project),'Missing resource '+res)
            except ValueError as exc: error('RESOURCE_PATH',p.relative_to(project),str(exc))


def verify_commit(project, commit):
    """Verify a real immutable Git object and byte equality, not a SHA-shaped string."""
    if not re.fullmatch(r'[0-9a-f]{40}',commit or ''): raise ValueError('Full commit SHA required')
    project=Path(project).resolve()
    def git(*args): return subprocess.check_output(['git','-C',str(project),*args],stderr=subprocess.PIPE).decode().strip()
    if git('rev-parse',commit+'^{commit}')!=commit: raise ValueError('Commit not found')
    repo=Path(git('rev-parse','--show-toplevel')); rel=project.relative_to(repo).as_posix()
    if git('status','--porcelain','--untracked-files=all','--',str(project)): raise ValueError('Project has uncommitted files')
    if git('diff',commit,'--',str(project)): raise ValueError('Project differs from reviewed commit')
    if not subprocess.check_output(['git','-C',str(repo),'ls-tree','-r',commit,'--',rel+'/project.godot'],stderr=subprocess.PIPE).strip():
        raise ValueError('project.godot absent at commit')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command',choices=['validate','construct','seal','registry'])
    parser.add_argument('--blueprint');parser.add_argument('--project');parser.add_argument('--claims');parser.add_argument('--commit');parser.add_argument('--output')
    args=parser.parse_args()
    if args.command=='registry': result=json.dumps(PATTERNS,indent=2)
    else:
        b=json.loads(Path(args.blueprint).read_text())
        if args.command=='seal': result=json.dumps(seal(b),ensure_ascii=False,indent=2)
        elif args.command=='construct': result=construct(b)
        else:
            if args.project: verify_commit(args.project,args.commit)
            report=validate(b,args.project,json.loads(Path(args.claims).read_text()) if args.claims else None,args.commit)
            result=json.dumps(report,ensure_ascii=False,indent=2)
            if report['errors']:
                if args.output: Path(args.output).write_text(result+'\n')
                else: print(result)
                return 1
    if args.output:
        target=Path(args.output)
        if args.command in ('construct','seal') and target.exists(): raise ValueError('Refusing overwrite; compare generated candidate then replace explicitly')
        target.write_text(result+'\n')
    else: print(result)
    return 0

if __name__=='__main__':
    try: sys.exit(main())
    except (ValueError,KeyError,TypeError,OSError,subprocess.CalledProcessError) as exc:
        print(json.dumps({'status':'blocked','error':str(exc)}),file=sys.stderr);sys.exit(2)
