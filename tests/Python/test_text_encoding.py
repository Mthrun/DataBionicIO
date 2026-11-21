# OUTPUT
# Regression checks for encoding, optional arguments, replacement, and failure protection.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
import pathlib
import tempfile
import warnings
import numpy as np
import DataBionicIO as io


def fails(operation):
    try:
        operation()
    except (ValueError, TypeError, RuntimeError, UnicodeError):
        return
    raise AssertionError("Expected rejection")


def run(directory):
    root = pathlib.Path(directory)
    root.mkdir(parents=True, exist_ok=True)
    readers = {"lrn": io.ReadLRN, "cls": io.ReadCLS, "names": io.ReadNAMES, "dts": io.ReadDates}
    comment = "Grüße € e\u0301"
    io.WriteLRN("sample.lrn", [[1.25]], Header=["Value"], Key=[17], OutDirectory=root, Comments=comment, Verbose=False)
    io.WriteCLS("sample.cls", [2], Key=[17], OutDirectory=root, Comment=comment, Verbose=False)
    io.WriteNAMES("sample.names", ["Grüße €"], Key=[17], OutDirectory=root, Comments=comment, Verbose=False)
    io.WriteDates("sample.dts", ["2026-11-20"], Key=[17], OutDirectory=root, Comments=comment, Verbose=False)
    for ext, read in readers.items():
        original = (root / ("sample." + ext)).read_bytes()
        assert not original.startswith(b"\xef\xbb\xbf")
        original.decode("utf-8")
        for enc in ["utf-8-sig", "utf-16", "utf-32", "utf-16-be", "utf-32-be", "cp1252", "latin1"]:
            text = original.decode("utf-8")
            # Single-byte fixtures deliberately use representable text.
            if enc in ["cp1252", "latin1"]:
                text = text.replace(" e\u0301", "")
            if enc == "latin1":
                text = text.replace(" €", "")
            data = text.encode(enc)
            if enc == "utf-16-be": data = b"\xfe\xff" + data
            if enc == "utf-32-be": data = b"\0\0\xfe\xff" + data
            path = root / (enc + "." + ext)
            path.write_bytes(data)
            option = {"Encoding": {"cp1252": "Windows-1252", "latin1": "ISO-8859-1"}[enc]} if enc in ["cp1252", "latin1"] else {}
            with warnings.catch_warnings(record=True) as seen:
                warnings.simplefilter("always")
                result = read(path.name, root, False, **option)
            assert list(result["Key"]) == [17]
            assert len(seen) == (enc != "utf-8-sig"), (ext, enc, seen)
            assert path.read_bytes() == data
            if enc not in ["cp1252", "latin1", "utf-8-sig"]:
                fails(lambda: read(path.name, root, False, Encoding="UTF-8"))
        for bad in [b"\xff", b"\xc0\xaf", b"\xed\xa0\x80", b"\xf4\x90\x80\x80", b"\xe2\x82"]:
            path = root / ("invalid." + ext)
            path.write_bytes(original + b"\n# " + bad)
            fails(lambda: read(path.name, root, False))
        for bom, codec, suffix in [
                (b"\xff\xfe", "utf-16-le", b"\x00\xd8"),
                (b"\xff\xfe", "utf-16-le", b"\x00\xdc"),
                (b"\xfe\xff", "utf-16-be", b"\xd8\x00\x00\x41"),
                (b"\xff\xfe", "utf-16-le", b"\x00"),
                (b"\xff\xfe\x00\x00", "utf-32-le", b"\x00\x00\x11\x00"),
                (b"\x00\x00\xfe\xff", "utf-32-be", b"\x00\x00\xd8\x00"),
                (b"\xff\xfe\x00\x00", "utf-32-le", b"\x00")]:
            path = root / ("malformed." + ext)
            path.write_bytes(bom + original.decode("utf-8").encode(codec) + suffix)
            fails(lambda: read(path.name, root, False))
        path = root / ("undefined." + ext)
        path.write_bytes(original + b"\x81")
        fails(lambda: read(path.name, root, False, Encoding="Windows-1252"))
        fails(lambda: read("sample." + ext, root, False, Encodin="UTF-8"))
    names = ["Sample\tA", "A\r\nB", "N\0Z", " café ", "e\u0301", "é", "🙂\ufeffX", r"literal\t", "literal<TAB>"]
    texts = np.array([["X\nY"]] * len(names), dtype=object)
    saved = texts.copy()
    for replacement in ["_", "[sep]", "🙂"]:
        with warnings.catch_warnings(record=True) as seen:
            warnings.simplefilter("always")
            io.WriteNAMES("replace.names", names, Key=list(range(1, len(names) + 1)), FurtherTexts=texts,
                          Header=["Names", "Description"], OutDirectory=root, Verbose=False, TextReplacement=replacement)
        assert len(seen) == 1, seen
        assert str(seen[0].message) == f'Replaced 13 forbidden text characters in 12 fields with "{replacement}".'
        result = io.ReadNAMES("replace.names", root, False)
        assert result["Names"] == [s.translate({ord(c): replacement for c in "\t\r\n\0"}) for s in names]
        assert np.array_equal(texts, saved)
    path = root / "replace.names"
    original = path.read_bytes()
    for replacement in ["", "\t", "\0", "\n", "\r", "\ud800"]:
        fails(lambda: io.WriteNAMES(path.name, ["A\tB"], Key=[1], OutDirectory=root, TextReplacement=replacement))
        assert path.read_bytes() == original
    fails(lambda: io.WriteNAMES(path.name, ["\ud800"], Key=[1], OutDirectory=root))
    assert path.read_bytes() == original
    # A valid multibyte sequence split at the 64 KiB input-buffer boundary.
    path = root / "boundary.names"
    prefix = b'#<?names version="2.0"?>\n% 1\n% 2\n% Key\tNames\n1\t'
    for offset in range(4):
        name = "x" * (65535 - len(prefix) - offset) + "🙂"
        path.write_bytes(prefix + name.encode() + b"\n")
        assert io.ReadNAMES(path.name, root, False)["Names"] == [name]
    print("Python encoding and text policy checks passed for all four formats.")


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        run(sys.argv[1])
    else:
        with tempfile.TemporaryDirectory() as directory:
            run(directory)
