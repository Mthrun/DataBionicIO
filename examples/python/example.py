# OUTPUT
# Example file operations and printed results from the Python interface.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Run after building/installing pyDataIO. All files live in a temporary folder."""
from datetime import datetime, timezone
from tempfile import TemporaryDirectory
import pyDataIO as io

with TemporaryDirectory(prefix="dataio-example-") as directory:
    common = dict(Key=[10, 20], OutDirectory=directory, Verbose=False)
    io.WriteLRN("measurements", {"A": [1.5, 2.5], "B": [3.0, 4.0]}, **common)
    io.WriteCLS("classes", [1, 2], **common)
    io.WriteNAMES("samples", ["Sample A", "Sample B"],
                  FurtherTexts={"Group": ["control", "treated"]}, **common)
    io.WriteDates("times", {"Time": [datetime(2024, 1, 1, tzinfo=timezone.utc),
                                     datetime(2024, 1, 2, tzinfo=timezone.utc)],
                            "Value": [10.5, 20.5]}, **common)
    for reader, filename in [(io.read_lrn, "measurements"), (io.read_cls, "classes"),
                             (io.read_names, "samples"), (io.read_dates, "times")]:
        print(reader(filename, directory, Verbose=False))
