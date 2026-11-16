# INPUT
# Fixed pilot cases and synthetic observations for fault-injection checks.
# OUTPUT
# Comparator and request-integrity test results. MATLAB is not executed.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
"""Check that the MATLAB pilot detects corrupted observations and file effects."""
from copy import deepcopy
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "ci/matlab"))
from fixture_pilot import load, prepare, save, sha, verify
from fixture_compare import compare_case, table

BUNDLE = load(ROOT / "tests/fixtures/matlab_pilot_v1/cases.json")


class FixturePilot(unittest.TestCase):
    def corruption(self, prefix, field, mutate):
        # INPUT: read-case prefix, checked field, and corruption function.
        # OUTPUT: assertion that the unchanged case passes and corruption fails.
        # SPDX-License-Identifier: AGPL-3.0-only
        # Additional permission: see MATLAB-EXCEPTION.txt.
        case = next(c for c in BUNDLE["cases"] if c["request"]["operation"] == "read"
                    and c["request"]["id"].startswith(prefix))
        actual = deepcopy(case["expected"])
        actual.update(working_directory_unchanged=True, diagnostics=["test warning"])
        self.assertEqual(compare_case(case["request"], actual, case["expected"])["status"], "PASS")
        mutate(actual)
        result = compare_case(case["request"], actual, case["expected"])
        self.assertEqual(result["status"], "FAIL")
        self.assertIn(field, [e["field"] for e in result["errors"]])

    def test_numeric_bit(self):
        self.corruption("BASE-LRN/", "data", lambda a: a["data"][0].__setitem__(0, "0000000000000000"))

    def test_key_order(self):
        self.corruption("KEY-VALID/KEY-VALID/keys_valid/lrn", "keys", lambda a: a["keys"].reverse())

    def test_original_trailing_space(self):
        self.corruption("TEXT-BOUNDARY/TEXT-B02/", "names", lambda a: a["names"].__setitem__(1, "A"))

    def test_millisecond(self):
        self.corruption("TIME-INVALID/TIME-I04/", "times", lambda a: a["times"].__setitem__(0, "2024-01-01 00:00:00.001"))

    def test_diagnostic(self):
        self.corruption("KEY-READ-BAD/KEY-READ-BAD/keys_invalid_text/lrn", "diagnostic",
                        lambda a: a.update(diagnostics=[], stdout=""))

    def test_working_directory(self):
        self.corruption("BASE-CLS/", "working_directory", lambda a: a.update(working_directory_unchanged=False))

    def test_protected_target(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "protected.lrn"
            path.write_bytes(b"changed")
            request = dict(id="protected", operation="write", format="lrn", path=str(path))
            actual = dict(ok=False, working_directory_unchanged=True, error="invalid key")
            result = compare_case(request, actual, {"ok": False}, b"original")
            self.assertIn("file_effect", [e["field"] for e in result["errors"]])

    def test_declared_rows(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "wrong.cls"
            path.write_text('#<?cls version="2.0"?>\n% 2\n1\t1\n', encoding="utf-8")
            with self.assertRaises(AssertionError):
                table(path)

    def test_portable_requests_and_original_bytes(self):
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "pilot"
            prepare(ROOT, output)
            state = load(output / "state.json")
            requests = load(output / "requests.json")
            self.assertEqual(len(requests), 48)
            self.assertEqual(len({q["id"].split('/')[0] for q in requests}), 34)
            self.assertEqual(len(state["bundle"]["input_sha256"]), 128)
            for name, digest in BUNDLE["input_sha256"].items():
                self.assertEqual(sha(ROOT / name), digest)
            for q in requests:
                if q["operation"] in ("write", "legacy"):
                    self.assertEqual(Path(q["path"]).parent, output.resolve() / "outputs")
                elif q["operation"] == "read":
                    self.assertTrue(Path(q["path"]).is_file())
            save(output / "observed.json", [{"id": q["id"]} for q in reversed(requests)])
            with self.assertRaisesRegex(ValueError, "reordered"):
                verify(ROOT, output)

    def test_request_tampering(self):
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "pilot"
            prepare(ROOT, output)
            with (output / "requests.json").open("a") as stream:
                stream.write(" ")
            with self.assertRaisesRegex(ValueError, "request bytes changed"):
                verify(ROOT, output)


if __name__ == "__main__":
    unittest.main()
