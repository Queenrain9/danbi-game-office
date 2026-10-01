import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location('web_export', Path(__file__).parents[1] / 'tools/web/export.py')
web = importlib.util.module_from_spec(spec)
spec.loader.exec_module(web)


class WebExportTests(unittest.TestCase):
    def row(self, **kwargs):
        return dict(project_path='builds/clockwork-pet-dentist',
                    repo_full_name='Queenrain9/danbi-game-office',
                    final_commit='a' * 40, status='ready', **kwargs)

    def test_ready_showcase_and_ready_build_share_canonical_target(self):
        row = self.row()
        build = dict(id='fixture', slug='clockwork-pet-dentist-showroom-test',
                     project_path=row['project_path'], last_commit=row['final_commit'],
                     status='playtest_ready')
        targets = web.collect_targets({'showcases': [row], 'ready_builds': [build]})
        self.assertEqual(len(targets), 1)
        self.assertEqual(targets[0]['slug'], 'clockwork-pet-dentist')
        self.assertEqual(targets[0]['source_commit'], 'a' * 40)

    def test_preparing_and_failed_builds_are_not_exported(self):
        row = self.row()
        row['status'] = 'preparing'
        self.assertEqual(web.collect_targets({'showcases': [row]}), [])
        row['status'] = 'fidelity_pending'
        self.assertEqual(web.collect_targets({'ready_builds': [row]}), [])

    def test_foreign_repo_invalid_paths_and_unpinned_refs_are_rejected(self):
        for field, value in [('repo_full_name', 'other/repo'),
                             ('project_path', 'builds/../index.html'),
                             ('project_path', 'projects/a/build/godot'),
                             ('final_commit', 'main')]:
            with self.subTest(field=field):
                row = self.row()
                row[field] = value
                self.assertEqual(web.collect_targets({'showcases': [row]}), [])

    def test_multiple_source_commits_are_not_collapsed_by_slug(self):
        a, b = self.row(), self.row()
        b['final_commit'] = 'b' * 40
        self.assertEqual(len(web.collect_targets({'showcases': [a, b]})), 2)


if __name__ == '__main__':
    unittest.main()
