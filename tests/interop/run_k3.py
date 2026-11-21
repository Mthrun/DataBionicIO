# INPUT
# Phase, operating system, output directory, and native package paths. See --help.
# OUTPUT
# Requests, native observations, file hashes, and the fixed 240-comparison report.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
"""Run the fixed K3 selection with the existing public-API adapters."""
import argparse
from collections import Counter
from copy import deepcopy
from datetime import datetime, timezone
import hashlib
import importlib.metadata
import json
import locale
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import tomllib
from zoneinfo import TZPATH

from fixture_compare import compare_case, sha

ROOT = Path(__file__).resolve().parents[2]
BUNDLE = ROOT / 'tests/fixtures/k3_240.json'
BINDINGS = ('R', 'Python', 'MATLAB', 'Julia')
ADAPTERS = dict(R='fixture_adapter.R', Python='fixture_adapter.py',
                MATLAB='runDataIOFixture.m', Julia='fixture_adapter.jl')


def load(path):
    # INPUT
    # path  JSON file.
    # OUTPUT
    # Decoded value.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    return json.loads(Path(path).read_text(encoding='utf-8'))


def save(path, value):
    # INPUT
    # path, value  Output file and JSON-compatible value.
    # OUTPUT
    # UTF-8 JSON file with parent directories.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False)+'\n', encoding='utf-8')


def julia_literal(value):
    # INPUT
    # value  JSON-compatible request data.
    # OUTPUT
    # Julia literal with string interpolation escaped.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    if value is None:
        return 'nothing'
    if isinstance(value, bool):
        return str(value).lower()
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False).replace('$', '\\$')
    if isinstance(value, list):
        return 'Any['+','.join(map(julia_literal, value))+']'
    if isinstance(value, dict):
        return 'Dict{String,Any}('+','.join(julia_literal(k)+'=>'+julia_literal(v) for k, v in value.items())+')'
    return str(value)


def source_hashes():
    # INPUT
    # ROOT  Source checkout.
    # OUTPUT
    # Hashes of build definitions, bindings, adapters, and fixed inputs.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    files = [ROOT/'CMakeLists.txt']
    for name in ('libs', 'tests', 'ci', 'cmake', '.github/workflows'):
        files.extend(p for p in (ROOT/name).rglob('*') if p.is_file()
                     and not set(p.parts).intersection({'.git', '.svn', '__pycache__'}))
    return {p.relative_to(ROOT).as_posix(): sha(p) for p in sorted(files)}


def environment():
    # INPUT
    # Current process and runner environment.
    # OUTPUT
    # Exact Python, OS image, locale, and time-zone database information.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    result = {key: os.getenv(key, '') for key in
              ('GITHUB_SHA', 'GITHUB_RUN_ID', 'GITHUB_RUN_ATTEMPT', 'ImageOS', 'ImageVersion',
               'RUNNER_OS', 'RUNNER_ARCH', 'CC', 'CXX', 'TZ')}
    result.update(python=sys.version, executable=sys.executable, os=platform.platform(),
                  machine=platform.machine(), locale=locale.setlocale(locale.LC_ALL),
                  timezone_paths=list(TZPATH))
    result['python_packages'] = {p.metadata['Name']: p.version for p in importlib.metadata.distributions()}
    result['timezone_hashes'] = {str(Path(d)/'tzdata.zi'): sha(Path(d)/'tzdata.zi')
                                 for d in TZPATH if (Path(d)/'tzdata.zi').is_file()}
    return result


def compare_environments(reference, current):
    # INPUT
    # reference, current  Recorded local and destination environments.
    # OUTPUT
    # Required-environment errors and documented runner image/platform differences.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    required = ('ImageOS', 'RUNNER_OS', 'RUNNER_ARCH', 'python', 'machine',
                'TZ', 'locale', 'timezone_hashes')
    errors = [key for key in required if key not in reference or key not in current
              or reference[key] != current[key]]
    for package in ('numpy', 'pandas', 'tzdata'):
        before = reference.get('python_packages', {}).get(package)
        after = current.get('python_packages', {}).get(package)
        if before is None or after is None or before != after:
            errors.append(package)
    differences = {key: dict(reference=reference.get(key), current=current.get(key))
                   for key in ('ImageVersion', 'os') if reference.get(key) != current.get(key)}
    return errors, differences


def run_command(argv, stem, timeout=900, env=None):
    # INPUT
    # argv, stem, timeout, env  Command, log prefix, time limit, and optional environment.
    # OUTPUT
    # Process log and exact command record. Returns the process exit code.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    stem = Path(stem)
    stem.parent.mkdir(parents=True, exist_ok=True)
    record = dict(argv=argv, started_utc=datetime.now(timezone.utc).isoformat())
    with stem.with_suffix('.log').open('w', encoding='utf-8') as stream:
        try:
            record['returncode'] = subprocess.run(argv, stdout=stream, stderr=subprocess.STDOUT,
                                                   timeout=timeout, cwd=ROOT, env=env, check=False).returncode
        except (OSError, subprocess.TimeoutExpired) as exc:
            record.update(returncode=-1, error=str(exc))
    save(stem.with_suffix('.command.json'), record)
    return record['returncode']


def request_file(out, binding, phase):
    # INPUT
    # out, binding, phase  Run directory and adapter group.
    # OUTPUT
    # JSON request path.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    return out/binding/(phase+'.json')


def prepare(args, bundle):
    # INPUT
    # args, bundle  Platform selection, empty run directory, and fixed selection.
    # OUTPUT
    # 24 writer requests, 64 local reader requests, and source/environment records.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    out = args.output
    out.mkdir(parents=True, exist_ok=False)
    for entry in bundle['inputs']:
        if sha(ROOT/entry['path']) != entry['sha256']:
            raise ValueError('Input hash differs: '+entry['path'])
    if len(bundle['comparisons']) != 240 or len(bundle['writer_actions']) != 72:
        raise ValueError('The K3 selection must contain 240 comparisons and 72 writes')
    profiles = {p['id']: p for p in bundle['profiles']}
    actions = {a['id']: a for a in bundle['writer_actions']}
    for binding in BINDINGS:
        writes, reads = [], []
        for action in actions.values():
            if action['os'] == args.os and action['binding'] == binding:
                p = profiles[action['profile']]
                path = out/'files'/action['artifact_relative_path']
                path.parent.mkdir(parents=True, exist_ok=True)
                writes.append(dict(deepcopy(p['payload']), id=action['id'], operation='write',
                                   format=p['format'], path=str(path)))
        for c in bundle['comparisons']:
            if c['kind'] == 'default_exchange' and c['origin_os'] == args.os and c['reader'] == binding:
                path = out/'files'/actions[c['writer_action']]['artifact_relative_path']
                reads.append(dict(id=c['id'], operation='read', format=c['format'], path=str(path)))
        if len(writes) != 6 or len(reads) != 16:
            raise ValueError('Unexpected local request count')
        save(request_file(out, binding, 'writes'), writes)
        save(request_file(out, binding, 'reads'), reads)
        if binding == 'MATLAB':
            save(out/'MATLAB/requests.json', writes+reads)
    save(out/'selection.json', bundle)
    save(out/'environment.json', environment())
    save(out/'source.json', dict(commit=os.getenv('GITHUB_SHA', ''), files=source_hashes(),
                                  bundle_sha256=sha(BUNDLE), git_worktree_status='not queried; full file hashes recorded'))
    print('Prepared 24 writes and 72 counted local comparisons for '+args.os)


def observe(args, binding, phase):
    # INPUT
    # args, binding, phase  Runtime paths and a prepared native adapter group.
    # OUTPUT
    # Native observations, diagnostics, and process logs.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    req = request_file(args.output, binding, phase)
    suffix = '.toml' if binding == 'Julia' else '.json'
    result = req.with_name(phase+'-observed'+suffix)
    if result.exists():
        raise FileExistsError(result)
    adapter = str(ROOT/'tests/interop'/ADAPTERS[binding])
    if binding == 'Python':
        argv = [sys.executable, adapter, str(req), str(result), str(args.python_package.resolve(strict=True))]
    elif binding == 'R':
        argv = [args.rscript, '--vanilla', adapter, str(req), str(result), str(args.r_library.resolve(strict=True))]
    else:
        jl = req.with_suffix('.jl')
        jl.write_text('requests = '+julia_literal(load(req))+'\n', encoding='utf-8')
        argv = [args.julia, '--startup-file=no', '--project='+str(args.julia_project.resolve(strict=True)),
                adapter, str(jl), str(result)]
    env = os.environ.copy()
    if binding == 'Julia' and env.get('K3_JULIA_BIN'):
        env['PATH'] = env['K3_JULIA_BIN']+os.pathsep+env['PATH']
    return run_command(argv, req.with_name(phase+'-process'), env=env)


def observations(out, binding, phase):
    # INPUT
    # out, binding, phase  Run directory and request group.
    # OUTPUT
    # Observations indexed by request ID. Missing files give an empty mapping.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    path = out/binding/('observed.json' if binding == 'MATLAB' else
                         phase+'-observed'+('.toml' if binding == 'Julia' else '.json'))
    if not path.is_file():
        return {}
    data = tomllib.loads(path.read_text())['results'] if path.suffix == '.toml' else load(path)
    if isinstance(data, dict):
        data = [data]
    if len({row['id'] for row in data}) != len(data):
        raise ValueError('Duplicate observation ID: '+str(path))
    req = out/binding/('requests.json' if binding == 'MATLAB' else phase+'.json')
    if {row['id'] for row in data} != {row['id'] for row in load(req)}:
        raise ValueError('Observation IDs differ from requests: '+str(path))
    return {row['id']: row for row in data}


def checked(q, actual, expected, binding):
    # INPUT
    # q, actual, expected, binding  Request, observations, fixed oracle, and binding.
    # OUTPUT
    # An existing-comparator result or an explicit missing-observation result.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    if q['id'] not in actual:
        return dict(id=q['id'], status='MISSING', errors=[dict(field='observation', observed='absent')])
    return compare_case(q, actual[q['id']], expected, binding=binding)


def evaluate(args, bundle):
    # INPUT
    # args, bundle  Complete local observations and fixed comparison selection.
    # OUTPUT
    # 72 local comparisons, 24 separate writer records, and transfer hashes.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    out = args.output
    profiles = {p['id']: p for p in bundle['profiles']}
    actions = {a['id']: a for a in bundle['writer_actions']}
    writers, readers, requests = {}, {}, {}
    for binding in BINDINGS:
        writes = observations(out, binding, 'writes')
        readers[binding] = observations(out, binding, 'reads')
        for q in load(request_file(out, binding, 'writes')):
            p = profiles[actions[q['id']]['profile']]
            writers[q['id']] = checked(q, writes, dict(ok=True, file=p['expected']['Python']), binding)
        requests.update({q['id']: q for q in load(request_file(out, binding, 'reads'))})
    source = load(out/'source.json')
    changed = source['files'] != source_hashes()
    results = []
    for c in bundle['comparisons']:
        if c['kind'] == 'cross_os_read' or c['origin_os'] != args.os:
            continue
        p, action = profiles[c['profile']], actions[c['writer_action']]
        writer = writers[c['writer_action']]
        if c['kind'] == 'numeric_writer':
            result = deepcopy(writer)
        else:
            q = requests[c['id']]
            result = checked(q, readers[c['reader']], p['expected'][c['reader']], c['reader'])
            if writer['status'] != 'PASS':
                result['errors'].append(dict(field='writer', observed=writer))
                result['status'] = 'FAIL' if writer['status'] == 'FAIL' else 'MISSING'
        result.update(id=c['id'], comparison_id=c['id'], kind=c['kind'], profile=c['profile'],
                      reason='; '.join(e['field'] for e in result['errors']),
                      source_identity=dict(commit=source['commit'], manifest='source.json', sha256=sha(out/'source.json')),
                      configuration_id=args.os, writer_options=p['writer_options'],
                      input_sha256={x['path']: x['sha256'] for x in bundle['inputs']},
                      oracle_sha256={x['name']: x['sha256'] for x in bundle['oracles']},
                      adapter_sha256={b:sha(ROOT/'tests/interop'/v) for b,v in ADAPTERS.items()},
                      raw_evidence_path=c['reader'] if c['kind']=='default_exchange' else action['binding'],
                      observed_vs_expected=result['errors'])
        file = out/'files'/action['artifact_relative_path']
        result['output_sha256'] = sha(file) if file.exists() else None
        if changed:
            result['status'] = 'FAIL'
            result['errors'].append(dict(field='source', observed='changed during run'))
        results.append(result)
    if len(results) != 72:
        raise ValueError('Expected 72 local comparisons')
    save(out/'writers.json', list(writers.values()))
    save(out/'results.json', results)
    transfer = []
    for action in actions.values():
        if action['os'] == args.os and action['binding'] == 'Python' and action['profile'].startswith('DEFAULT-'):
            file = out/'files'/action['artifact_relative_path']
            transfer.append(dict(action=action, sha256=sha(file) if file.exists() else None,
                                 writer_status=writers[action['id']]['status']))
    save(out/'transfer.json', dict(os=args.os, source=source, environment=load(out/'environment.json'), files=transfer))
    print(dict(Counter(x['status'] for x in results)))
    return int(any(x['status'] != 'PASS' for x in results))


def cross(args, bundle):
    # INPUT
    # args, bundle  Downloaded original outputs, target package, and fixed selection.
    # OUTPUT
    # Eight Python reads with source/destination hashes and configuration checks.
    # Runner image/platform differences are recorded separately from required equality.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    out = args.output
    out.mkdir(parents=True, exist_ok=False)
    profiles = {p['id']: p for p in bundle['profiles']}
    local = args.incoming/args.os
    target = load(local/'transfer.json')
    current = environment()
    config_errors, runner_differences = compare_environments(target['environment'], current)
    if source_hashes() != target['source']['files']:
        config_errors.append('source_files')
    original_packages = load(local/'package-hashes.json')
    if not original_packages:
        config_errors.append('empty package manifest')
    for entry in original_packages:
        path = ROOT/entry['path']
        if not path.is_file() or sha(path) != entry['sha256']:
            config_errors.append('package:'+entry['path'])
    save(out/'environment-check.json', dict(errors=config_errors, runner_differences=runner_differences))
    requests, transfer = [], {}
    for c in bundle['comparisons']:
        if c['kind'] != 'cross_os_read' or c['destination_os'] != args.os:
            continue
        origin = args.incoming/c['origin_os']
        manifest = load(origin/'transfer.json')
        entry = next(x for x in manifest['files'] if x['action']['id']==c['writer_action'])
        src = origin/'files'/entry['action']['artifact_relative_path']
        dst = out/'received'/entry['action']['artifact_relative_path']
        dst.parent.mkdir(parents=True, exist_ok=True)
        errors = []
        if manifest['source']['files'] != target['source']['files']:
            errors.append('origin source differs from target source')
        before = sha(src) if src.exists() else None
        if entry['writer_status'] != 'PASS' or before is None or before != entry['sha256']:
            errors.append('origin file or writer evidence')
        if src.exists():
            shutil.copyfile(src,dst)
        after = sha(dst) if dst.exists() else None
        if before != after:
            errors.append('transfer hash')
        transfer[c['id']] = dict(original_sha256=entry['sha256'], downloaded_sha256=before,
                                 destination_sha256=after, errors=errors,
                                 origin_source_sha256=sha(origin/'source.json'))
        requests.append(dict(id=c['id'], format=c['format'], operation='read', path=str(dst)))
    save(request_file(out,'Python','cross'), requests)
    observe(args,'Python','cross')
    actual = observations(out,'Python','cross')
    results=[]
    for q in requests:
        c=next(x for x in bundle['comparisons'] if x['id']==q['id'])
        p=profiles[c['profile']]
        result=checked(q,actual,p['expected']['Python'],'Python')
        result.update(comparison_id=c['id'], kind='cross_os_read', configuration_id=args.os,
                      transfer=transfer[q['id']],
                      runner_differences=runner_differences,
                      source_identity=dict(commit=target['source']['commit'], sha256=sha(local/'source.json')),
                      writer_options=p['writer_options'], output_sha256=transfer[q['id']]['destination_sha256'],
                      input_sha256=transfer[q['id']]['original_sha256'],
                      oracle_sha256={x['name']:x['sha256'] for x in bundle['oracles']},
                      adapter_sha256=sha(ROOT/'tests/interop/fixture_adapter.py'), raw_evidence_path='Python')
        errors=config_errors+transfer[q['id']]['errors']
        if errors:
            result['status']='FAIL'
            result['errors'].append(dict(field='configuration_or_transfer',observed=errors))
        result['reason']='; '.join(e['field'] for e in result['errors'])
        result['observed_vs_expected']=result['errors']
        results.append(result)
    if len(results)!=8:
        raise ValueError('Expected eight directed cross-OS reads')
    save(out/'environment.json',current)
    save(out/'results.json',results)
    print(dict(Counter(x['status'] for x in results)))
    return int(any(x['status']!='PASS' for x in results))


def merge(args, bundle):
    # INPUT
    # args, bundle  Downloaded reports and the fixed 240 IDs.
    # OUTPUT
    # One complete report with explicit missing rows and no duplicate counts.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    observations_by_id={}
    paths = list(args.incoming.glob('K3-local-*/results.json'))+list(args.incoming.glob('K3-cross-*/results.json'))
    for path in sorted(paths):
        for row in load(path):
            ident=row['comparison_id']
            if ident in observations_by_id:
                raise ValueError('Duplicate comparison: '+ident)
            observations_by_id[ident]=dict(row,report_path=str(path.relative_to(args.incoming)))
    expected={c['id'] for c in bundle['comparisons']}
    if set(observations_by_id)-expected:
        raise ValueError('Unexpected comparison IDs')
    rows=[observations_by_id.get(c['id'],dict(comparison_id=c['id'],kind=c['kind'],status='MISSING',
                                             reason='No main-study result artifact')) for c in bundle['comparisons']]
    supplements = []
    for system in ('Windows','Linux','macOS'):
        root=args.incoming/('K3-local-'+system)
        supplements.append(dict(os=system, evidence_files=[p.relative_to(args.incoming).as_posix()
                                for p in sorted(root.rglob('*')) if p.is_file()
                                and ('regressions' in p.parts or 'regressions' in p.name)],
                                status='SEPARATE_REVIEW_REQUIRED', counted_in_240=False))
    report=dict(counts=dict(Counter(x['status'] for x in rows)), comparisons=rows, expected_count=240,
                complete=len(rows)==240 and all(x['status'] in ('PASS','FAIL') for x in rows),
                bundle_sha256=sha(BUNDLE), targeted_regressions=supplements,
                excel_imports=dict(status='NOT_RUN', count=4, counted_in_240=False,
                                   reason='Excel imports require separate application evidence'))
    save(args.output/'report.json',report)
    (args.output/'results.tsv').write_text('comparison_id\tstatus\treason\n'+''.join(
        x['comparison_id']+'\t'+x['status']+'\t'+x.get('reason','').replace('\n',' ')+'\n' for x in rows))
    print(report['counts'])
    return int(any(x['status']!='PASS' for x in rows))


def main():
    # INPUT
    # Command-line arguments.
    # OUTPUT
    # Phase artifacts and a nonzero exit code for failed or missing comparisons.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('phase',choices=('prepare','writes','reads','evaluate','cross','merge'))
    parser.add_argument('--os',choices=('Windows','Linux','macOS'))
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--incoming',type=Path)
    parser.add_argument('--python-package',type=Path)
    parser.add_argument('--r-library',type=Path)
    parser.add_argument('--julia-project',type=Path)
    parser.add_argument('--rscript',default='Rscript')
    parser.add_argument('--julia',default='julia')
    args=parser.parse_args()
    args.output=args.output.resolve()
    bundle=load(BUNDLE)
    if args.phase=='prepare':
        prepare(args,bundle); return 0
    if args.phase in ('writes','reads'):
        statuses=[]
        for binding in ('R','Python','Julia'):
            try:
                statuses.append(observe(args,binding,args.phase))
            except (OSError, ValueError) as exc:
                save(args.output/binding/(args.phase+'-unavailable.json'),dict(error=str(exc)))
                statuses.append(1)
        return int(any(x!=0 for x in statuses))
    return {'evaluate':evaluate,'cross':cross,'merge':merge}[args.phase](args,bundle)


if __name__=='__main__':
    sys.exit(main())
