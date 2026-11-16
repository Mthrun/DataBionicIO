# INPUT
# Arguments: JSON request file, JSON result file, Python package parent.
# OUTPUT
# Native public-API observations and diagnostics; requested files are written.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Observe fixed cases. Expected values and pass/fail decisions live in the study."""
import contextlib
import io as streams
import json
import math
import os
from pathlib import Path
import struct
import sys
import warnings
from datetime import datetime
from zoneinfo import ZoneInfo

sys.path.insert(0, str(Path(sys.argv[3]).resolve(strict=True)))
import pyDataIO as io
import numpy as np


def number(x):
    return float('nan') if x is None else float(x)


def bits(x):
    return 'NaN' if math.isnan(float(x)) else struct.pack('>d', float(x)).hex()


def text(x):
    return 'NA' if x is None else str(x)


def input_data(q):
    if 'data_bits' in q:
        return [[float('nan') if x == 'NaN' else struct.unpack('>d', bytes.fromhex(x))[0]
                 for x in row] for row in q['data_bits']]
    return [[number(x) for x in row] for row in q['data']]


def observe(q):
    if q['operation'] == 'helper':
        a, b = [list(map(number, q[k])) for k in ('a', 'other')]
        before = (a.copy(), b.copy())
        value = io.TheSameKey(a, b)
        return dict(value=value, immutable=all(np.array_equal(x, y, equal_nan=True)
                    for x, y in zip((a, b), before)), native_type=type(value).__name__)
    path = Path(q['path'])
    fmt = q['format']
    verbose = q.get('verbose', False)
    if q['operation'] == 'write':
        common = dict(Key=list(map(number, q['keys'])), OutDirectory=path.parent,
                      Verbose=verbose, Overwrite=q.get('overwrite', True),
                      Comments=q.get('comment', ''))
        opts = q.get('options', {})
        if fmt == 'lrn':
            io.WriteLRN(path.name, input_data(q),
                        Header=q['header'], **common, **opts)
        elif fmt == 'cls':
            opts = dict(opts)
            if 'NaNReplacement' in opts:
                opts['Int4NaN'] = opts.pop('NaNReplacement')
            io.WriteCls(path.name, list(map(number, q['classes'])), **common, **opts)
        elif fmt == 'names':
            io.WriteNames(path.name, q['names'], FurtherTexts=q['further_texts'],
                          Header=q['header'], **common)
        elif fmt == 'dts':
            data = {'Time': q['times']}
            if 'native_epoch_ms' in q:
                data['Time'] = [datetime.fromtimestamp(x/1000,ZoneInfo(q['timezone'])) for x in q['native_epoch_ms']]
            data.update({h: [row[j] for row in input_data(q)]
                         for j, h in enumerate(q['header'])})
            io.WriteDates(path.name, data, tz=q.get('timezone', 'UTC'),
                          Format=q.get('time_format', 3), **common)
        else:
            raise ValueError(fmt)
        return {}
    reader = {'lrn': io.ReadLRN, 'cls': io.ReadCls, 'names': io.ReadNames,
              'dts': io.ReadDates}[fmt]
    a = reader(path.name, path.parent, verbose)
    out = dict(keys=['NA' if x is None or math.isnan(float(x)) else str(int(x)) for x in a['Key']],
               comment=a['Comments'])
    if fmt in ('lrn', 'dts'):
        out.update(data=[[bits(x) for x in row] for row in a['Data']],
                   shape=list(np.shape(a['Data'])), header=list(a['Header']))
    if fmt == 'lrn':
        out['types'] = list(a['DataDefined'])
    if fmt == 'cls':
        out['classes'] = list(map(bits, a['Cls']))
    if fmt == 'names':
        out.update(names=list(map(text, a['Names'])),
                   further_texts=[[text(x) for x in row] for row in a['FurtherTexts']],
                   header=list(a['Header']), file_header=list(a['FileHeader']))
    if fmt == 'dts':
        out.update(times=list(map(text, a['Times'])), timezone=a['Timezone'],
                   file_header=list(a['FileHeader']),
                   dst=list(map(text, a.get('DST') or [])),
                   native_time_type=type(a['Time'][0]).__name__)
        if any(x is not None and not hasattr(x, 'timestamp') for x in a['Time']):
            out['dates'] = ['NA' if x is None else x.isoformat() for x in a['Time']]
        else:
            out['epoch_ms'] = ['NA' if x is None else str(round(x.timestamp()*1000)) for x in a['Time']]
    return out


results = []
for q in json.loads(Path(sys.argv[1]).read_text(encoding='utf-8')):
    captured = streams.StringIO()
    before_directory = os.getcwd()
    with warnings.catch_warnings(record=True) as diagnostics, contextlib.redirect_stdout(captured):
        warnings.simplefilter('always')
        try:
            result = dict(id=q['id'], ok=True, **observe(q))
        except Exception as error:
            result = dict(id=q['id'], ok=False, error=str(error), error_type=type(error).__name__)
    result.update(diagnostics=[str(x.message) for x in diagnostics], stdout=captured.getvalue(),
                  working_directory_unchanged=os.getcwd() == before_directory)
    results.append(result)
Path(sys.argv[2]).write_text(json.dumps(results, ensure_ascii=False, indent=2, allow_nan=False)+'\n', encoding='utf-8')
