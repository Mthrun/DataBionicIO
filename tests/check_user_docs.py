# INPUT
# Optional path to the built Sphinx HTML directory.
# OUTPUT
# Input hash checks and a report of broken local HTML links or anchors.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Verify the fixed tutorial inputs and local navigation in built documentation."""

from html.parser import HTMLParser
import hashlib
import json
from pathlib import Path
import sys
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]


class Page(HTMLParser):
    def __init__(self, path):
        super().__init__()
        self.ids = set()
        self.links = []
        self.feed(path.read_text(encoding="utf-8"))

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if attrs.get("id"):
            self.ids.add(attrs["id"])
        for name in ("href", "src"):
            if attrs.get(name):
                self.links.append(attrs[name])


def main():
    directory = Path(sys.argv[1] if len(sys.argv) > 1 else ROOT / "build/docs/html").resolve()
    inputs = ROOT / "examples/tutorials/data"
    records = json.loads((inputs / "manifest.json").read_text())["files"]
    for record in records:
        data = (inputs / record["file"]).read_bytes()
        assert len(data) == record["bytes"], record["file"]
        assert hashlib.sha256(data).hexdigest() == record["sha256"], record["file"]
    pages = {p.resolve(): Page(p) for p in directory.rglob("*.html")}
    assert directory / "index.html" in pages, "HTML build is missing"
    errors = []
    for path, page in pages.items():
        for link in page.links:
            parts = urlsplit(link)
            if parts.scheme or parts.netloc:
                continue
            target = (path.parent / unquote(parts.path)).resolve() if parts.path else path
            if target.is_dir():
                target = target / "index.html"
            if not target.is_relative_to(directory) or not target.exists():
                errors.append(f"{path.relative_to(directory)}: missing {link}")
            elif parts.fragment and target in pages:
                fragment = unquote(parts.fragment)
                if fragment not in pages[target].ids:
                    errors.append(f"{path.relative_to(directory)}: missing anchor {link}")
    for error in errors:
        print(error)
    print(f"User documentation: {len(records)} input hashes, {len(pages)} HTML pages, {len(errors)} broken local links.")
    return bool(errors)


if __name__ == "__main__":
    sys.exit(main())
