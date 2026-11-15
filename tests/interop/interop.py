# INPUT
# Command arguments: mode, exchange directory, Python package parent.
# Mode is generate, verify, verify-r-python, or verify-julia (Julia files only).
# OUTPUT
# Four Python output files, or checks of files from R, Python, and MATLAB.
# Full verification writes python-verified.txt. Failed checks raise errors.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Write or check shared file-exchange cases through the public Python API."""
from datetime import datetime, timezone
from pathlib import Path
import sys

if len(sys.argv) != 4 or sys.argv[1] not in ("generate", "verify", "verify-r-python", "verify-julia"):
    raise SystemExit("Supply generate, verify, verify-r-python, or verify-julia; exchange directory; Python package parent")
mode, directory, package = sys.argv[1:]
out = Path(directory).resolve(strict=True)
sys.path.insert(0, str(Path(package).resolve(strict=True)))
import numpy as np
import pyDataIO as io

key = [-2**53, 2**31, 2**53]
values = [[1.25, 10.0], [np.nan, -2.5], [3.75, 30.0]]
classes = [2, np.nan, 1]
names = ["1.0.4", None, "M\u00fcnchen"]
texts = [["A1", "B1"], [None, "B2"], ["A3", None]]
times = ["2024-10-27 00:30:00.125", "2024-06-15 13:45:10.250", "2024-10-27 01:30:00.999"]
comment = "language exchange"
marker = out / "python-verified.txt"
marker.unlink(missing_ok=True)

if mode == "generate":
    options = dict(Key=key, OutDirectory=out, Comments=comment, Verbose=False)
    io.WriteLRN("python", values, Header=["X", "Y"], **options)
    io.WriteCls("python", classes, **options)
    io.WriteNames("python", names, FurtherTexts=texts,
                  Header=["Names", "Extra1", "Extra2"], **options)
    io.WriteDates("python", {"Time": times, "X": [v[0] for v in values],
                            "Y": [v[1] for v in values]}, tz="UTC", Format=3, **options)
else:
    writers = ("julia",) if mode == "verify-julia" else (("r", "python", "matlab") if mode == "verify" else ("r", "python"))
    for writer in writers:
        for extension, reader in (("lrn", io.ReadLRN), ("cls", io.ReadCls),
                                  ("names", io.ReadNames), ("dts", io.ReadDates)):
            actual = reader(f"{writer}.{extension}", out, False)
            assert actual["Key"] == key and actual["Comments"] == comment
            if extension in ("lrn", "dts"):
                np.testing.assert_equal(actual["Data"], values)
                assert actual["Header"] == ["X", "Y"]
            if extension == "cls":
                np.testing.assert_equal(actual["Cls"], classes)
            if extension == "names":
                assert actual["Names"] == names and actual["FurtherTexts"] == texts
                assert actual["Header"] == ["Extra1", "Extra2"]
                assert actual["FileHeader"] == ["Key", "Names", "Extra1", "Extra2"]
            if extension == "dts":
                assert actual["Times"] == times and actual["Timezone"] == "UTC"
                expected = [datetime.fromisoformat(t).replace(tzinfo=timezone.utc)
                            if t is not None else None for t in times]
                assert actual["Time"] == expected
            print(f"PASS {writer} -> Python: {extension}")
    if mode == "verify":
        marker.write_text("PASS: Python verified all four formats from r, python, matlab.\n")
