# INPUT
# The built or installed DataBionicIO package; optional build import path.
# OUTPUT
# Assertions for the shared API contract and Chicago DST round trips.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
import inspect
import csv
import os
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
    defaults = {'InDirectory': None, 'OutDirectory': None, 'Verbose': True,
                'Overwrite': True, 'Scientific': False, 'Key': None,
                'Header': None, 'DataDefined': None, 'FurtherTexts': None,
                'SignificantDigits': None, 'DecimalDigits': None, 'Int4NaN': None,
                'Comment': None, 'Comments': '' if name == 'WriteNAMES' else None,
                'tz': None, 'Format': None}
    for argument, parameter in inspect.signature(getattr(io, name)).parameters.items():
        expected = defaults.get(argument, inspect.Parameter.empty)
        assert parameter.default == expected, (name, argument, parameter.default)

# Import before changing directory: defaults must follow each call, not import time.
import pyDataIO as legacy
previous = os.getcwd()
with tempfile.TemporaryDirectory() as directory:
    try:
        for folder in ('first', 'second'):
            working = Path(directory) / folder
            working.mkdir()
            os.chdir(working)
            for api, cls_name, names_name in ((io, 'WriteCLS', 'WriteNAMES'),
                                               (legacy, 'WriteCls', 'WriteNames')):
                prefix = 'common' if api is io else 'compat'
                cases = [
                    ('WriteLRN', 'ReadLRN', 'lrn', [[1.0], [2.0]], [[3.25], [4.5]], 'Data', [[3.25], [4.5]]),
                    (cls_name, 'ReadCLS' if api is io else 'ReadCls', 'cls', [1, 2], [3, 4], 'Cls', [3, 4]),
                    (names_name, 'ReadNAMES' if api is io else 'ReadNames', 'names', ['A', 'B'], ['C', 'D'], 'Names', ['C', 'D']),
                    ('WriteDates', 'ReadDates', 'dts', {'Time': ['2026-01-01', '2026-01-02'], 'Value': [1, 2]},
                     {'Time': ['2026-01-01', '2026-01-02'], 'Value': [3.25, 4.5]}, 'Data', [[3.25], [4.5]])]
                for writer_name, reader_name, extension, first, second, field, expected in cases:
                    writer, reader = getattr(api, writer_name), getattr(api, reader_name)
                    writer(prefix, first)
                    writer(prefix, second)
                    path = working / (prefix + '.' + extension)
                    assert path.is_file()
                    value = reader(prefix)
                    assert value[field] == expected, (folder, writer_name, value)
                    assert value['Key'] == [1, 2] and value['Comments'] == ''
                    if extension == 'dts':
                        assert value['Timezone'] == 'UTC'
                    original = path.read_bytes()
                    try:
                        writer(prefix, first, Overwrite=False)
                    except ValueError:
                        pass
                    else:
                        raise AssertionError((writer_name, 'Overwrite=False replaced a file'))
                    assert path.read_bytes() == original
    finally:
        os.chdir(previous)

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
print('Common Python API, defaults, current paths, overwrite protection, and Chicago DST passed.')
