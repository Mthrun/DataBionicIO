# OUTPUT
# Test results reported through assertions, errors, or the process exit status.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Run with the path to the built native pyDataIO module as the first argument."""
import importlib.util
from pathlib import Path
import sys
import tempfile

import numpy as np

spec = importlib.util.spec_from_file_location("pyDataIO", sys.argv[1])
io = importlib.util.module_from_spec(spec)
spec.loader.exec_module(io)

keys = [1, 2147483647, 2147483648, -2147483648, 1234567890123,
        2**53 - 1, 2**53, -2**53]
with tempfile.TemporaryDirectory(prefix="dataio-key64-") as directory:
    for kind in ("lrn", "cls", "names", "dts"):
        path = Path(directory) / ("keys." + kind)

        def write(values):
            n = len(values)
            if kind == "lrn":
                io._write_lrn(["Value"], values, [[1.23456]] * n, [],
                              str(path), "", 4, -1, False, True, False, 2, 0)
            elif kind == "cls":
                io._write_cls(values, [1.] * n, float("nan"), str(path), "", True, False, 2, 0)
            elif kind == "names":
                io._write_names(["sample"] * n, ["Names"], values, [],
                                str(path), "", True, False, 2, 0)
            else:
                io._write_dates(["Value"], values, ["2024-01-01"] * n, [[1.23456]] * n,
                                str(path), "", 1, True, False, 2, 0)

        def read_keys():
            reader = getattr(io, "_read_" + ("dates" if kind == "dts" else kind))
            result = reader(str(path), False)
            return result[0 if kind == "cls" else 1]

        for values in (keys, np.array(keys, dtype=np.int64)):
            write(values)
            assert read_keys() == keys
        original = path.read_bytes()
        for invalid in ([2**53 + 1], [-2**53 - 1], [2**63], [1.5], [2**31, 2**31]):
            try:
                write(invalid)
            except (ValueError, TypeError, OverflowError):
                pass
            else:
                raise AssertionError("Invalid keys were accepted")
            assert path.read_bytes() == original

        text = original.decode().replace("\n2147483648\t", "\n2147483648oops\t")
        text = text.replace("\n1234567890123\t", "\n9007199254740993\t")
        path.write_bytes(text.encode('utf-8'))
        expected = keys.copy()
        expected[4] = -(2**63)  # Missing-key marker in the native interface.
        assert read_keys() == expected

print("Python native 64-bit key tests passed for all four formats.")
