# INPUT
# Fixed K3 cases, synthetic environments, and deliberate evidence corruption.
# OUTPUT
# Regression results for environment, source, package, transfer, and data checks.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
"""Test the exchange validator without executing a native package."""
from contextlib import redirect_stdout
from copy import deepcopy
import io
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tests/interop'))
import run_k3

REFERENCE = dict(ImageOS='ubuntu24', RUNNER_OS='Linux', RUNNER_ARCH='X64',
                 ImageVersion='image-a', os='Linux-kernel-a', python='Python 3.12.10',
                 machine='x86_64', TZ='UTC', locale='C.UTF-8',
                 timezone_hashes={'tzdata.zi': 'unchanged'},
                 python_packages={'numpy': '2.3.5', 'pandas': '2.2.3', 'tzdata': '2025.2'})


class EnvironmentChecks(unittest.TestCase):
    def test_identical_environments(self):
        self.assertEqual(run_k3.compare_environments(REFERENCE, deepcopy(REFERENCE)), ([], {}))

    def test_runner_changes_are_recorded(self):
        current = dict(REFERENCE, ImageVersion='image-b', os='Linux-kernel-b')
        errors, differences = run_k3.compare_environments(REFERENCE, current)
        self.assertEqual(errors, [])
        self.assertEqual(differences, {
            'ImageVersion': {'reference': 'image-a', 'current': 'image-b'},
            'os': {'reference': 'Linux-kernel-a', 'current': 'Linux-kernel-b'}})

    def test_required_environment_changes_fail(self):
        for key in ('ImageOS', 'RUNNER_OS', 'RUNNER_ARCH', 'python', 'machine',
                    'TZ', 'locale', 'timezone_hashes'):
            with self.subTest(field=key):
                current = deepcopy(REFERENCE)
                current[key] = 'changed'
                self.assertIn(key, run_k3.compare_environments(REFERENCE, current)[0])

    def test_missing_required_evidence_fails(self):
        for key in ('ImageOS', 'RUNNER_OS', 'RUNNER_ARCH', 'python', 'machine',
                    'TZ', 'locale', 'timezone_hashes'):
            with self.subTest(field=key):
                incomplete = deepcopy(REFERENCE)
                del incomplete[key]
                self.assertIn(key, run_k3.compare_environments(incomplete, incomplete)[0])

    def test_package_changes_and_missing_versions_fail(self):
        for package in ('numpy', 'pandas', 'tzdata'):
            with self.subTest(package=package):
                current = deepcopy(REFERENCE)
                current['python_packages'][package] = 'changed'
                self.assertIn(package, run_k3.compare_environments(REFERENCE, current)[0])
                del current['python_packages'][package]
                self.assertIn(package, run_k3.compare_environments(current, current)[0])

    def test_empty_system_timezone_manifest_is_supported(self):
        # Windows uses the required tzdata package instead of a system tzdata.zi file.
        reference = dict(REFERENCE, timezone_hashes={})
        self.assertEqual(run_k3.compare_environments(reference, reference), ([], {}))


class CrossChecks(unittest.TestCase):
    def run_cross(self, corruption=None):
        # INPUT
        # corruption  Optional source, package, transfer, data, or timezone fault.
        # OUTPUT
        # Exit code, eight comparison records, and the environment check record.
        # SPDX-License-Identifier: AGPL-3.0-only
        # Additional permission: see MATLAB-EXCEPTION.txt.
        bundle = run_k3.load(run_k3.BUNDLE)
        comparisons = [c for c in bundle['comparisons']
                       if c['kind'] == 'cross_os_read' and c['destination_os'] == 'Linux']
        actions = {a['id']: a for a in bundle['writer_actions']}
        profiles = {p['id']: p for p in bundle['profiles']}
        source = dict(commit='synthetic-test', files={'source': 'original'})
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            incoming = base/'incoming'
            package = base/'package.bin'
            package.write_bytes(b'original package')
            run_k3.save(incoming/'Linux/package-hashes.json',
                        [dict(path=str(package), sha256=run_k3.sha(package))])
            for system in ('Linux', 'Windows', 'macOS'):
                entries = []
                for c in comparisons:
                    if c['origin_os'] != system:
                        continue
                    action = actions[c['writer_action']]
                    path = incoming/system/'files'/action['artifact_relative_path']
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(c['id'].encode())
                    entries.append(dict(action=action, sha256=run_k3.sha(path), writer_status='PASS'))
                    if corruption == 'transfer' and c == comparisons[0]:
                        path.write_bytes(b'changed file')
                run_k3.save(incoming/system/'source.json', source)
                run_k3.save(incoming/system/'transfer.json',
                            dict(source=source, environment=REFERENCE, files=entries))
            if corruption == 'package':
                package.write_bytes(b'changed package')
            current = dict(deepcopy(REFERENCE), ImageVersion='image-b', os='Linux-kernel-b')
            if corruption == 'timezone':
                current['timezone_hashes'] = {'tzdata.zi': 'changed'}
            observed = {}
            for c in comparisons:
                record = deepcopy(profiles[c['profile']]['expected']['Python'])
                record.update(id=c['id'], working_directory_unchanged=True)
                if corruption == 'data' and c['format'] == 'lrn':
                    record['data'][0][0] = format(int(record['data'][0][0], 16) ^ 1, '016x')
                observed[c['id']] = record
            actual_source = {'source': 'changed'} if corruption == 'source' else source['files']
            args = SimpleNamespace(os='Linux', incoming=incoming, output=base/'result')
            with patch.object(run_k3, 'environment', return_value=current), \
                 patch.object(run_k3, 'source_hashes', return_value=actual_source), \
                 patch.object(run_k3, 'observe', return_value=0), \
                 patch.object(run_k3, 'observations', return_value=observed), \
                 redirect_stdout(io.StringIO()):
                status = run_k3.cross(args, bundle)
            return (status, run_k3.load(args.output/'results.json'),
                    run_k3.load(args.output/'environment-check.json'))

    def test_runner_changes_reach_the_saved_results(self):
        status, rows, check = self.run_cross()
        self.assertEqual(status, 0)
        self.assertEqual(len(rows), 8)
        self.assertTrue(all(row['status'] == 'PASS' for row in rows))
        self.assertEqual(check['errors'], [])
        self.assertEqual(set(check['runner_differences']), {'ImageVersion', 'os'})
        self.assertTrue(all(row['runner_differences'] == check['runner_differences'] for row in rows))

    def test_corrupted_evidence_still_fails_with_runner_changes(self):
        for fault in ('source', 'package', 'transfer', 'data', 'timezone'):
            with self.subTest(fault=fault):
                status, rows, check = self.run_cross(fault)
                self.assertEqual(status, 1)
                self.assertTrue(any(row['status'] == 'FAIL' for row in rows))
                errors = [error for row in rows for error in row['errors']]
                if fault == 'data':
                    self.assertIn('data', [error['field'] for error in errors])
                else:
                    self.assertIn('configuration_or_transfer', [error['field'] for error in errors])
                self.assertEqual(set(check['runner_differences']), {'ImageVersion', 'os'})


if __name__ == '__main__':
    unittest.main()
