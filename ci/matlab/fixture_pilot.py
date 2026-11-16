# INPUT
# prepare or verify; source root and a new pilot output directory.
# OUTPUT
# Portable MATLAB requests, observations, comparisons, and integrity reports.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
"""Prepare and verify the fixed MATLAB adapter pilot without a Research checkout."""
import argparse
import base64
from collections import Counter
import csv
import hashlib
import json
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tests" / "interop"))
from fixture_compare import bits, compare_case, padded


def load(path):
    # INPUT: path to a UTF-8 JSON file.
    # OUTPUT: decoded JSON value.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    return json.loads(path.read_text(encoding="utf-8"))


def save(path, value):
    # INPUT: output path and JSON-compatible value.
    # OUTPUT: UTF-8 JSON file; nonfinite JSON numbers cause an error.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False) + "\n", encoding="utf-8")


def sha(path):
    # INPUT: existing file path.
    # OUTPUT: SHA-256 hexadecimal digest of the file bytes.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    return hashlib.sha256(path.read_bytes()).hexdigest()


def contained(root, relative):
    # INPUT: root directory and relative file path.
    # OUTPUT: resolved path inside root; paths outside root cause an error.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    path = (root / relative).resolve()
    path.relative_to(root.resolve())
    return path


def directory_entries(root, directories):
    # INPUT: source root and relative input-directory names.
    # OUTPUT: sorted relative entries in each directory, including empty folders.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    return {name: sorted(p.relative_to(root / name).as_posix() for p in (root / name).rglob("*"))
            for name in directories}


def prepare(root, output):
    # INPUT: source root and an output directory that does not exist.
    # OUTPUT: requests.json and state.json; fixed inputs are checked and not changed.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    root, output = root.resolve(), output.resolve()
    manifest = root / "tests/fixtures/matlab_pilot_v1/cases.json"
    bundle = load(manifest)
    if bundle["schema"] != 1:
        raise ValueError("Unsupported MATLAB fixture schema")
    selection = manifest.with_name("selection.tsv")
    if sha(selection) != bundle["selection_sha256"]:
        raise ValueError("Case selection differs from the prepared bundle")
    for name, digest in bundle["input_sha256"].items():
        if sha(contained(root, name)) != digest:
            raise ValueError("Fixed input differs: " + name)
    output.mkdir(parents=True, exist_ok=False)
    (output / "outputs").mkdir()
    requests = []
    output_paths = set()
    for case in bundle["cases"]:
        request = dict(case["request"])
        operation = request["operation"]
        if operation == "read":
            if request["path"] not in bundle["input_sha256"]:
                raise ValueError("Read path is not a fixed input")
            request["path"] = str(contained(root, request["path"]))
        elif operation in ("write", "legacy"):
            path = contained(output, request["path"])
            if path.parent != output / "outputs" or path in output_paths:
                raise ValueError("Output path is not unique or outside outputs")
            output_paths.add(path)
            if case["initial_base64"] is not None:
                path.write_bytes(base64.b64decode(case["initial_base64"], validate=True))
            request["path"] = str(path)
        elif operation != "helper":
            raise ValueError("Unknown request operation")
        requests.append(request)
    if len({q["id"] for q in requests}) != len(requests):
        raise ValueError("Duplicate request identifiers")
    save(output / "requests.json", requests)
    source_hashes = {p.relative_to(root).as_posix(): sha(p)
                     for name in ("libs/cDataIO", "libs/matlabDataIO", "tests/interop", "ci/matlab")
                     for p in (root / name).rglob("*")
                     if p.is_file() and "__pycache__" not in p.parts}
    source_hashes[manifest.relative_to(root).as_posix()] = sha(manifest)
    source_hashes[selection.relative_to(root).as_posix()] = sha(selection)
    save(output / "state.json", dict(root=str(root), bundle=bundle,
         requests_sha256=sha(output / "requests.json"), source_sha256=source_hashes,
         directory_entries=directory_entries(root, bundle["fixture_directories"])))
    print(f"Prepared {len(requests)} MATLAB calls in {len(Counter(q['id'].split('/')[0] for q in requests))} families.")


def verify(root, output):
    # INPUT: source root and prepared directory with observed.json from MATLAB.
    # OUTPUT: report.json; returns the report and raises on incomplete observations.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    root, output = root.resolve(), output.resolve()
    state = load(output / "state.json")
    if state["root"] != str(root) or sha(output / "requests.json") != state["requests_sha256"]:
        raise ValueError("Prepared root or request bytes changed")
    bundle = state["bundle"]
    requests, observations = load(output / "requests.json"), load(output / "observed.json")
    ids = [q["id"] for q in requests]
    if not isinstance(observations, list) or [a["id"] for a in observations] != ids:
        raise ValueError("Missing, extra, duplicate, or reordered observations")
    if [c["request"]["id"] for c in bundle["cases"]] != ids:
        raise ValueError("Expected-value identifiers differ")
    results = []
    for case, request, actual in zip(bundle["cases"], requests, observations):
        before = None if case["initial_base64"] is None else base64.b64decode(case["initial_base64"], validate=True)
        results.append(compare_case(request, actual, case["expected"], before))
        results[-1]["purpose"] = case["purpose"]
    join = {q["format"]: a for q, a in zip(requests, observations)
            if q["operation"] == "read" and q["id"].startswith("JOIN-ORDER/")}
    join_ok = False
    if all(f in join and join[f]["ok"] for f in ("lrn", "cls", "names")):
        expected = bundle["join_expected"]
        keys = join["lrn"]["keys"]
        classes = dict(zip(join["cls"]["keys"], join["cls"]["classes"]))
        names = dict(zip(join["names"]["keys"], join["names"]["names"]))
        join_ok = ([classes.get(k) for k in keys] == [bits(x) for x in expected["classes"]]
                   and [names.get(k) for k in keys] == padded(expected["names"]))
    results.append(dict(binding="MATLAB", id="JOIN-ORDER/observed-key-join",
                        status="PASS" if join_ok else "FAIL",
                        errors=[] if join_ok else ["Observed key relation differs"]))
    changed = [p for p, h in dict(state["source_sha256"], **bundle["input_sha256"]).items()
               if not (root / p).is_file() or sha(root / p) != h]
    inputs_unchanged = (not changed and state["directory_entries"] ==
                        directory_entries(root, bundle["fixture_directories"]))
    counts = dict(Counter(r["status"] for r in results))
    success = inputs_unchanged and not counts.get("FAIL")
    report = dict(status="PASS" if success else "FAIL", scope="MATLAB_FIXTURE_PILOT_NOT_MAIN_STUDY",
                  counts=counts, requests=len(requests), families=len({q["id"].split('/')[0] for q in requests}),
                  fixed_inputs_unchanged=inputs_unchanged, changed_files=changed,
                  manifest_sha256=state["source_sha256"]["tests/fixtures/matlab_pilot_v1/cases.json"],
                  input_sha256=bundle["input_sha256"], source_sha256=state["source_sha256"], results=results)
    build_info = output.parent / "matlab/build.json"
    if build_info.is_file():
        report["build"] = load(build_info)
    save(output / "report.json", report)
    with (output / "results.tsv").open("w", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream, delimiter="\t")
        writer.writerow(("case", "purpose", "result", "differences"))
        for result in results:
            writer.writerow((result["id"], result.get("purpose", "Check relations after key alignment."),
                             result["status"], json.dumps(result["errors"], ensure_ascii=False)))
    print(json.dumps({k: report[k] for k in ("status", "counts", "requests", "families", "fixed_inputs_unchanged")}))
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("prepare", "verify"))
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--output", type=Path, default=ROOT / "build/ci/fixture-pilot")
    args = parser.parse_args()
    if args.mode == "prepare":
        prepare(args.root, args.output)
        if os.getenv("GITHUB_ENV"):
            with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as stream:
                stream.write("DATAIO_FIXTURE_DIR=" + str(args.output.resolve()) + "\n")
    else:
        report = verify(args.root, args.output)
        summary = args.output.parent / "matlab/summary.tsv"
        with summary.open("a", encoding="utf-8") as stream:
            stream.write("fixtures\t" + report["status"] + "\n")
        if report["status"] != "PASS":
            raise SystemExit("MATLAB fixture pilot failed; see report.json")
