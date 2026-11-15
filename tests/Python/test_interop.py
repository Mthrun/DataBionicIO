# OUTPUT
# Test results reported through assertions, errors, or the process exit status.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Test both directions and compare file bytes against a freshly built R package.

python tests/Python/test_interop.py <Python package parent> <R test library>
"""
from datetime import date, datetime, timezone
from pathlib import Path
import re
import subprocess
import sys
import tempfile

if len(sys.argv) != 3:
    raise SystemExit(__doc__)
sys.path.insert(0, str(Path(sys.argv[1]).resolve()))
r_library = str(Path(sys.argv[2]).resolve())
import numpy as np
import pandas as pd
import pyDataIO as io

script = Path(__file__).with_name("interop.R")
with tempfile.TemporaryDirectory(prefix="dataio-interop-") as temporary:
    out = Path(temporary)
    def r(mode):
        subprocess.run(["Rscript", "--vanilla", str(script), mode, str(out), r_library], check=True)
    def read(fn, name):
        return fn("r-" + name, out, False)
    r("generate")
    key = [1, 2**31, 2**53]
    values = [[1.25, 10.0], [float("nan"), -2.5], [3.75, 30.0]]
    times = ["2024-01-01 12:30:00.125", "2024-06-15 13:45:10.250", "2024-12-31 23:59:59.999"]
    texts = [["A1", "B1"], [None, "B2"], ["A3", None]]
    names = ["1.0.4", None, "Sample A"]
    instants = [datetime(2024, 10, 27, 0, 30, tzinfo=timezone.utc),
                datetime(2024, 10, 27, 1, 30, tzinfo=timezone.utc),
                datetime(1995, 7, 1, 12, tzinfo=timezone.utc)]
    dates = [date(2024, 1, i) for i in (1, 2, 3)]
    for kind, fn in [("lrn", io.ReadLRN), ("cls", io.ReadCls), ("names", io.ReadNames), ("dts", io.ReadDates)]:
        result = read(fn, "basic." + kind)
        assert result["Key"] == key
        assert result["Comments"] == "audit"
        if kind in ("lrn", "dts"):
            np.testing.assert_equal(result["Data"], values)
            assert result["Header"] == ["X", "Y"]
        if kind == "cls":
            np.testing.assert_equal(result["Cls"], [2, np.nan, 1])
        if kind == "names":
            assert result["Names"] == names and result["FurtherTexts"] == texts
        if kind == "dts":
            assert result["Times"] == times and result["Timezone"] == "UTC"
        print("PASS R -> Python:", kind)
    assert read(io.ReadDates, "date-only.dts")["Time"] == dates
    actual_instants = [value.astimezone(timezone.utc) for value in read(io.ReadDates, "dst.dts")["Time"]]
    assert actual_instants == instants
    print("PASS R -> Python: date-only and both autumn folds plus historical DST")

    common = dict(Key=key, OutDirectory=out, Verbose=False)
    io.WriteLRN("py-basic", values, Header=["X", "Y"], Comments="audit", **common)
    io.WriteCls("py-basic", [2, np.nan, 1], Comments="audit", **common)
    io.WriteNames("py-basic", names, FurtherTexts=texts, Header=["Names", "Extra1", "Extra2"], Comments="audit", **common)
    io.WriteDates("py-basic", pd.DataFrame({"Time": times, "X": [v[0] for v in values], "Y": [v[1] for v in values]}), tz="UTC", Format=3, Comments="audit", **common)
    io.WriteDates("py-date-only", dates, **common)
    io.WriteDates("py-dst", {"Time": instants, "X": [1, 2, 3]}, tz="Europe/Berlin", **common)
    io.WriteLRN("py-header", values, Header=["ID", "X", "Y"], **common)
    io.WriteNames("py-header", names, FurtherTexts=texts, Header=["ID", "Names", "Extra1", "Extra2"], **common)
    io.WriteLRN("py-digits", values, Header=["X", "Y"], DecimalDigits=0, **common)
    r("verify")
    for expected in sorted(out.glob("r-*")):
        actual = out / ("py-" + expected.name[2:])
        def normalized(path):
            return re.sub(rb'created_at="[^"]*"', b'created_at="TIME"', path.read_bytes())
        assert normalized(actual) == normalized(expected), expected.name
        print("PASS identical format bytes:", expected.name[2:])
print("R/Python interoperability passed for all four formats and nine file pairs.")
