# OUTPUT
# Documentation findings and a process status for the selected source files.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Screen Markdown prose and Python docstrings for selected documentation rules.

This program does not check the complete ASD-STE100 dictionary or prove conformity.
It does not change files. Code blocks, inline code and Python statements stay out
of the prose checks. Sentence classification and word counts are approximate.
"""
import argparse
import ast
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_FILES = (
    "README.md", "API.md", "libs/pyDataIO/README.md", "libs/matlabDataIO/README.md",
    "libs/qslegacy/README.txt", "libs/pyDataIO/py/common.py", "tests/README.md", "tests/legacy/README.md",
    "tests/qslegacy/README.md", "libs/pyDataIO/py/extension.py",
    "libs/juliaDataIO/README.md",
    "examples/excel/README.md",
)
LINK = re.compile(r"\[([^\]]+)\]\((<[^>]+>|[^\s)]+)(?:\s+\"[^\"]*\")?\)")
INSTRUCTION = re.compile(
    r"^(?:Use|Do|Set|Open|Close|Run|Start|Install|Remove|Keep|Supply|Select|Add|"
    r"Make sure|Prepare|Read|Write|Reject|Replace|Return)\b"
)
SPELLING = re.compile(r"\b(?:wheather|preceeded|aswell|occoured|writting)\b|\ban (?:legacy|previous)\b", re.I)


def markdown_blocks(text):
    """Yield prose blocks with their source line numbers, outside code fences."""
    pending, first, fence = [], 0, None
    for number, line in enumerate(text.splitlines(), 1):
        stripped = line.strip()
        marker = re.match(r"^(`{3,}|~{3,})", stripped)
        if fence:
            if marker and marker[1][0] == fence[0] and len(marker[1]) >= len(fence):
                fence = None
            continue
        if marker:
            if pending:
                yield first, " ".join(pending)
                pending = []
            fence = marker[1]
            continue
        boundary = not stripped or stripped.startswith("#") or stripped.isupper()
        table = stripped.startswith("|")
        item = re.match(r"^(?:[-*+] |\d+\. )", stripped)
        if boundary or table or item:
            if pending:
                yield first, " ".join(pending)
                pending = []
            if table:
                # Pipes inside code spans are not table separators.
                protected = re.sub(r"`+[^`]*`+", lambda m: m[0].replace("|", "PIPE"), stripped)
                for cell in protected.strip("|").split("|"):
                    if cell.strip() and not re.fullmatch(r"[\s:-]+", cell):
                        yield number, cell.strip()
            elif item:
                first, pending = number, [stripped[item.end():]]
            continue
        if not pending:
            first = number
        pending.append(stripped)
    if pending:
        yield first, " ".join(pending)


def docstrings(text):
    tree = ast.parse(text)
    for node in ast.walk(tree):
        if isinstance(node, (ast.Module, ast.ClassDef, ast.FunctionDef, ast.AsyncFunctionDef)):
            value = ast.get_docstring(node, clean=False)
            if value is not None:
                start = node.body[0].lineno
                for offset, block in markdown_blocks(value):
                    yield start + offset - 1, block


def prose(text):
    text = LINK.sub(lambda m: m[1], text)
    text = re.sub(r"`+[^`]*`+", "CODE", text)
    text = re.sub(r'https?://\S+', 'URL', text)
    text = re.sub(r'"[^"\n]*"', 'QUOTE', text)
    return text.replace("**", "").strip()


def screen(path):
    text = path.read_text(encoding="utf-8")
    blocks = list(docstrings(text) if path.suffix == ".py" else markdown_blocks(text))
    findings = []
    for line, block in blocks:
        if path.suffix != ".py":
            # Links in inline code are examples, not navigation.
            links = re.sub(r"`+[^`]*`+", "CODE", block)
            for match in LINK.finditer(links):
                target = match[2].strip("<>")
                parts = urlsplit(target)
                if parts.scheme or parts.netloc or not parts.path:
                    continue
                if not (path.parent / unquote(parts.path)).exists():
                    findings.append((line, "link", "Local link target does not exist: " + target))
        clean = prose(block)
        if ";" in clean:
            findings.append((line, "8.1", "Use separate sentences instead of a semicolon in prose."))
        for match in SPELLING.finditer(clean):
            findings.append((line, "spelling", "Review: " + match[0]))
        if re.search(r"\b(?:should|checks|checking)\b|^Check\b", clean):
            findings.append((line, "vocabulary", "Review the verb against the dictionary and its context."))
        sentences = re.split(r"(?<=[.!?])\s+(?=[A-Z0-9])", clean)
        for sentence in sentences:
            # Parentheses and quoted text have special word-count rules in STE.
            counted = re.sub(r"\([^()]*\)", "PAREN", sentence)
            count = len(re.findall(r"\S+", counted))
            limit = 20 if INSTRUCTION.match(sentence) else 25
            if count > limit:
                findings.append((line, "length", f"Review sentence length: approximately {count} words, limit {limit}."))
    return findings


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="*", type=Path,
                        help="Markdown, plain text or Python files. Defaults to public READMEs and Python API docstrings.")
    args = parser.parse_args(argv)
    paths = args.files or [ROOT / name for name in DEFAULT_FILES]
    count = 0
    for path in paths:
        try:
            findings = screen(path)
        except (OSError, SyntaxError, UnicodeError) as error:
            findings = [(1, "input", str(error))]
        for line, rule, message in findings:
            print(f"{path}:{line}: {rule}: {message}")
        count += len(findings)
    print(f"Documentation screen: {len(paths)} files, {count} findings.")
    print("This screen does not establish ASD-STE100 conformity.")
    return 1 if count else 0


if __name__ == "__main__":
    sys.exit(main())
