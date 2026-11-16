# INPUT
# Fixed requests, expected values, native observations, and written files.
# OUTPUT
# Per-case comparison results. No package API is executed.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

from copy import deepcopy
from datetime import datetime
import hashlib
import math
from pathlib import Path
import struct
from zoneinfo import ZoneInfo

def sha(path):
    # INPUT
    # path  Existing file.
    # OUTPUT
    # SHA-256 hexadecimal digest.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def bits(x):
    # INPUT
    # x  Numeric value, decimal string, or missing marker.
    # OUTPUT
    # Binary64 hexadecimal bits, or the token NaN.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    value = float('nan') if x is None or x == 'NA' else float(x)
    return 'NaN' if math.isnan(value) else struct.pack('>d', value).hex()

def hexrows(rows):
    # INPUT
    # rows  Numeric records.
    # OUTPUT
    # Binary64 hexadecimal values with the same row structure.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    return [[bits(x) for x in row] for row in rows]

def text(x):
    # INPUT
    # x  Scalar text or a missing value.
    # OUTPUT
    # Text with missing values represented by NA.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    return 'NA' if x is None or x == '' else str(x)

def padded(rows):
    # INPUT
    # rows  Character rows.
    # OUTPUT
    # Rows padded to equal width with trailing spaces.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    width = max(map(len, rows), default=0)
    return [x.ljust(width) for x in rows]

def table(path):
    # INPUT
    # path  Fixed-format v2 data file.
    # OUTPUT
    # Independently scanned rows, labels, types, and time-zone metadata.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Independent fixed-v2 fixture scanner; no repair or production parser calls."""
    lines = Path(path).read_text(encoding='utf-8').splitlines()
    meta = [x[1:].lstrip(' ') for x in lines if x.startswith('%')]
    data = [x.split('\t') for x in lines if x and not x.startswith(('#','%'))]
    fmt = Path(path).suffix[1:]
    out = dict(rows=data)
    if fmt != 'cls':
        out['labels'] = meta[3 if fmt == 'lrn' else 2].split('\t')
    if fmt == 'lrn':
        out['types'] = list(map(int,meta[2].split('\t')))
    if fmt == 'dts':
        out['zone'] = next(x.split(':',1)[1].strip() for x in lines if x.startswith('# Timezone:'))
    assert int(meta[0])==len(data), 'Declared row count differs'
    if fmt != 'cls':
        assert int(meta[1])==len(out['labels']), 'Declared column count differs'
        assert all(len(row)==len(out['labels']) for row in data), 'Nonrectangular file rows'
    else: assert all(len(row)==2 for row in data), 'CLS rows must have two fields'
    return out

def payload(fmt, t):
    # INPUT
    # fmt, t  File format and independently scanned table.
    # OUTPUT
    # Named fields with record rows and exact text cells.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    r = t['rows']; p = dict(keys=[x[0] for x in r])
    if fmt == 'lrn':
        p.update(data=[x[1:] for x in r],header=t['labels'][1:],types=t['types'])
    elif fmt == 'cls':
        p['classes'] = [x[1] for x in r]
    elif fmt == 'names':
        p.update(names=[x[1] for x in r],further_texts=[x[2:] for x in r],header=t.get('labels',['Key','Names'])[1:])
    else:
        has_dst = 'TZ_DST' in t['labels']; offset = 3 if has_dst else 2
        p.update(times=[x[1] for x in r],data=[x[offset:] for x in r],header=t['labels'][offset:],
                 timezone=t['zone'],dst=[x[2] for x in r] if has_dst else [])
    return p

def expectation(fmt, p, binding):
    # INPUT
    # fmt, p, binding  Format, fixed values, and binding name.
    # OUTPUT
    # Expected normalized fields under the specified binding contract.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    e = dict(ok=True, keys=[text(x) for x in p['keys']])
    if fmt in ('lrn','dts'):
        e.update(data=hexrows(p['data']),shape=[len(p['data']),len(p['header'])],header=p['header'])
    if fmt == 'lrn':
        e['types'] = p.get('types',[9]+[1]*len(p['header']))
        if binding == 'MATLAB':
            keep = [i for i,t in enumerate(e['types'][1:]) if t != 0]
            e['data'] = [[r[i] for i in keep] for r in e['data']]
            e['header'] = [e['header'][i] for i in keep]
            e['types'] = [e['types'][i+1] for i in keep]; e['shape'][1] = len(keep)
    elif fmt == 'cls':
        e['classes'] = [bits(x) for x in p['classes']]
    elif fmt == 'names':
        e.update(names=[text(x) for x in p['names']], further_texts=[[text(x) for x in row] for row in p['further_texts']])
        if 'header' in p:
            e['header'] = p['header'][1:]
            if binding in ('Python','Julia'): e['file_header'] = ['Key']+p['header']
            if binding == 'MATLAB': e['header'] = ['Key']+p['header']
        if binding == 'MATLAB': e['names'] = padded(e['names'])
    elif fmt == 'dts':
        e['timezone'] = p.get('timezone','UTC')
        if binding != 'R':
            e['times'] = [text(x) for x in p['times']]; e['dst'] = p.get('dst',[])
        if binding in ('R','Python'):
            if all(len(t)==10 for t in p['times'] if t not in (None,'NA')):
                e['dates'] = [text(x) for x in p['times']]
            elif 'epoch_ms' in p:
                e['epoch_ms'] = [text(x) for x in p['epoch_ms']]
            else:
                times = []
                for i,t in enumerate(p['times']):
                    if t in (None,'NA'): times.append('NA'); continue
                    dt = datetime.fromisoformat(t).replace(tzinfo=ZoneInfo(e['timezone']))
                    dst = p.get('dst',[])
                    if dst and dt.tzname() != dst[i]: dt = dt.replace(fold=1)
                    times.append(str(round(dt.timestamp()*1000)))
                e['epoch_ms'] = times
    if binding == 'MATLAB' and 'header' in e: e['header'] = padded(e['header'])
    if 'comment' in p: e['comment'] = p['comment']
    return e

def compare_case(q, a, expected, before=None, binding="MATLAB"):
    # INPUT
    # q, a, expected, before, binding  Request, observation, fixed expectations, original bytes, and binding.
    # OUTPUT
    # PASS or FAIL with field-level differences and optional output hash.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    e=deepcopy(expected);errors=[];details={}
    def check(want,got):
        # INPUT
        # want, got  Expected and observed fields.
        # OUTPUT
        # Appends differences to the enclosing case error list.
        # SPDX-License-Identifier: AGPL-3.0-only
        # Additional permission: see MATLAB-EXCEPTION.txt.
        for k,v in want.items():
            if k in ('diagnostic','file','file_cells','file_labels','numeric_zero_sign'):continue
            actual=got.get(k,'<absent>')
            if k=='comment' and isinstance(actual,str) and actual.endswith('\n'):actual=actual[:-1]
            if k=='data' and want.get('numeric_zero_sign')=='characterize':
                details['zero_bits_observed']=actual
                normal=lambda rows:[[('0000000000000000' if x=='8000000000000000' else x) for x in r] for r in rows]
                if isinstance(actual,list):actual=normal(actual);v=normal(v)
            if v!=actual:errors.append(dict(field=k,expected=v,observed=actual))
    check(e,a)
    if not a.get('working_directory_unchanged',False):errors.append(dict(field='working_directory',expected='unchanged',observed='changed_or_not_recorded'))
    diagnostic=e.get('diagnostic','none_required')
    if diagnostic.startswith('required'):
        diagnostic_text='\n'.join(a.get('diagnostics',[]))+'\n'+a.get('error','')
        diagnostic_text+='\n'+'\n'.join(line for line in a.get('stdout','').splitlines() if line.startswith('WARNING:'))
        if not diagnostic_text.strip():errors.append(dict(field='diagnostic',expected=diagnostic,observed='none'))
    if q['operation'] in ('write','legacy'):
        path=Path(q['path'])
        if not e['ok']:
            after=path.read_bytes() if path.exists() else None
            if before!=after:errors.append(dict(field='file_effect',expected='unchanged_or_absent',observed='changed'))
        elif a['ok'] and path.exists():
            try:
                t=table(path);observed=expectation(q['format'],payload(q['format'],t),'Python')
                # Comment extraction is scoped to the fixed multiline user text.
                if 'comment' in e.get('file',{}):
                    raw=path.read_text(encoding='utf-8'); lines=[]
                    for line in raw.splitlines():
                        if line.startswith('#\tClass'):break
                        if not line.startswith('#') or line.startswith('#<?') or line.startswith('# Timezone:'):continue
                        line=line[1:]; lines.append(line[1:] if line.startswith(' ') else line)
                    observed['comment']='\n'.join(lines)
                check(e.get('file',{}),observed)
                if 'file_cells' in e and t['rows']!=e['file_cells']:errors.append(dict(field='file_cells',expected=e['file_cells'],observed=t['rows']))
                if 'file_labels' in e and t.get('labels')!=e['file_labels']:errors.append(dict(field='file_labels',expected=e['file_labels'],observed=t.get('labels')))
                details['output_sha256']=sha(path)
            except Exception as exc:errors.append(dict(field='independent_file_check',observed=str(exc)))
        elif e['ok'] and not path.exists():errors.append(dict(field='file',expected='created',observed='absent'))
    return dict(binding=binding,id=q['id'],status='FAIL' if errors else 'PASS',errors=errors,**details)
