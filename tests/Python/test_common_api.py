# INPUT
# The built or installed DataBionicIO package; optional build import path.
# OUTPUT
# Assertions for the shared API contract and Chicago DST round trips.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
import inspect
import csv
from datetime import datetime, timezone
from pathlib import Path
import sys
import tempfile

if len(sys.argv) > 1:
    sys.path.insert(0, sys.argv[1])
import DataBionicIO as io

with (Path(__file__).resolve().parents[1] / 'common_api.tsv').open() as stream:
    contract = {row['Function']: {'inputs': row['Inputs'].split(','),
                                  'outputs': row['Outputs'].split(',')}
                for row in csv.DictReader(stream, delimiter='\t')}
for name, spec in contract.items():
    assert list(inspect.signature(getattr(io, name)).parameters) == spec['inputs'], name

with tempfile.TemporaryDirectory() as directory:
    key = [11, 22]
    io.WriteLRN('matrix', [[7, 1.5], [8, 2.5]], ['Unused', 'Value'], key,
                [0, 1], directory, 'LRN', None, None, False, False, False)
    io.WriteCLS('classes', [2, 3], directory, key, 'CLS', None, False, False)
    io.WriteNAMES('names', ['A', 'B'], key, [['x'], ['y']], ['Group'], directory, 'NAMES', False, False)
    instants = [datetime(2026, 1, 15, 18, tzinfo=timezone.utc),
                datetime(2026, 7, 15, 17, tzinfo=timezone.utc),
                datetime(2026, 11, 1, 6, 30, tzinfo=timezone.utc),
                datetime(2026, 11, 1, 7, 30, tzinfo=timezone.utc)]
    io.WriteDates('times', {'Time': instants, 'Value': [1, 2, 3, 4]}, [1, 2, 3, 4],
                  directory, 'DTS', 'America/Chicago', 2, False, False)
    for reader, file in [('ReadLRN', 'matrix'), ('ReadCLS', 'classes'),
                          ('ReadNAMES', 'names'), ('ReadDates', 'times')]:
        value = getattr(io, reader)(file, directory, False)
        assert list(value) == contract[reader]['outputs'], (reader, list(value))
    value = io.ReadLRN('matrix', directory, False)
    assert value['Data'] == [[7, 1.5], [8, 2.5]] and value['DataDefined'] == [9, 0, 1]
    value = io.ReadDates('times', directory, False)
    assert value['Timezone'] == 'America/Chicago'
    assert value['DST'] == ['CST', 'CDT', 'CDT', 'CST']
    assert [t.timestamp() for t in value['Time']] == [t.timestamp() for t in instants]
    # No optional text/data columns or comments: every output slot still exists.
    io.WriteNAMES('empty', ['A', 'B'], Key=key, OutDirectory=directory, Verbose=False)
    value = io.ReadNAMES('empty', directory, False)
    assert list(value) == contract['ReadNAMES']['outputs']
    assert value['FurtherTexts'] == [[], []] and value['Header'] == [] and value['Comments'] == ''
    io.WriteDates('only-time', instants[:1], Key=[1], OutDirectory=directory, Verbose=False)
    value = io.ReadDates('only-time', directory, False)
    assert list(value) == contract['ReadDates']['outputs']
    assert value['Data'] == [[]] and value['Header'] == [] and value['Comments'] == ''
print('Common Python API, positional arguments, fixed fields, and Chicago DST passed.')
