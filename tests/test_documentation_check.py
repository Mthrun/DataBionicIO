# OUTPUT
# Test results reported through assertions, errors, or the process exit status.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Test that the prose screen keeps executable text separate from prose."""
from pathlib import Path
import tempfile
import unittest

from check_documentation import screen


class DocumentationScreen(unittest.TestCase):
    def run_screen(self, content, suffix=".md"):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / ("sample" + suffix)
            path.write_text(content)
            return screen(path)

    def test_code_and_api_names_are_not_prose(self):
        text = "Use `checkFilename()` and `x; y`.\n\n```cpp\nCheck(x);\n[example](absent.md)\n```\n"
        self.assertEqual(self.run_screen(text), [])

    def test_prose_semicolon_and_dead_link(self):
        result = self.run_screen("Read the file; keep the rows. See [help](absent.md).\n")
        self.assertEqual({x[1] for x in result}, {"8.1", "link"})

    def test_wrapped_sentences_are_counted_together(self):
        result = self.run_screen("The reader " + "word " * 12 + "\n" + "word " * 13 + ".\n")
        self.assertIn("length", [x[1] for x in result])

    def test_python_only_docstrings(self):
        text = '"""Read the file. Keep the rows."""\nmessage = "a; b"\nx = 1; y = 2\n'
        self.assertEqual(self.run_screen(text, ".py"), [])
        text += '\ndef read():\n    """Read the file; keep the rows."""\n    return 1\n'
        self.assertIn("8.1", [x[1] for x in self.run_screen(text, ".py")])

    def test_table_inline_code_and_external_links(self):
        text = "| Item | Result |\n| --- | --- |\n| `a|b;` | See [reference](https://example.org). |\n"
        self.assertEqual(self.run_screen(text), [])

    def test_known_grammar_error(self):
        self.assertIn("spelling", [x[1] for x in self.run_screen("Read an legacy file.\n")])


if __name__ == "__main__":
    unittest.main()
