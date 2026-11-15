# INPUT
# The build/ci package, MATLAB reports, and optional language-exchange reports.
# OUTPUT
# A ZIP package and its SHA-256 file, after all required reports indicate success.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Create a MATLAB package from a successful CI build."""
import csv
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import zipfile


def package_matlab(build, require_interop=False):
    # INPUT
    # build  CI output directory with package and matlab subdirectories.
    # require_interop  Require successful R, Python, and MATLAB exchange checks.
    # OUTPUT
    # Path to a new ZIP. Missing files or unsuccessful reports raise an error.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    reports = build / "matlab"
    package = build / "package" / "DataBionicIO"
    with (reports / "summary.tsv").open(newline="") as stream:
        results = list(csv.DictReader(stream, delimiter="\t"))
    stages = {row["stage"]: row["result"] for row in results}
    required = {"build", "modern", "legacy"}
    if require_interop:
        required.add("interop")
    if len(stages) != len(results) or not required <= stages.keys() or any(
            result != "PASS" for result in stages.values()):
        raise ValueError("The required MATLAB tests did not all pass")
    info = json.loads((reports / "build.json").read_text())
    if not re.fullmatch(r"[0-9a-f]{40}", info["commit"]):
        raise ValueError("A full source commit is required for a CI package")
    if os.getenv("GITHUB_SHA", info["commit"]) != info["commit"]:
        raise ValueError("The package source commit does not match this job")
    if not re.fullmatch(r"R20\d{2}[ab]", info["release"]):
        raise ValueError("Invalid MATLAB release")
    extensions = {"win64": "mexw64", "glnxa64": "mexa64", "maca64": "mexmaca64"}
    if extensions.get(info["architecture"]) != info["mex_extension"]:
        raise ValueError("Unexpected MEX architecture or extension")
    mex = package / "bin" / ("dataio_mex." + info["mex_extension"])
    if not mex.is_file() or not mex.stat().st_size:
        raise ValueError("The package MEX file is missing or empty")
    for name in ("setupDataIO.m", "README.md", "LICENSE", "LICENSING.md",
                 "MATLAB-EXCEPTION.txt", "COMMERCIAL-LICENSE.txt", "NOTICE.txt",
                 "THIRD-PARTY-NOTICES.txt", "LICENSES/pybind11-BSD-3-Clause.txt"):
        if not (package / name).is_file():
            raise ValueError("Missing package file: " + name)
    if require_interop:
        for language in ("r", "python"):
            report = build / "interop" / (language + "-verified.txt")
            if not report.is_file() or not report.read_text().startswith("PASS:"):
                raise ValueError("Missing successful exchange report: " + language)
    shutil.copyfile(reports / "build.json", package / "build-info.json")
    shutil.copyfile(reports / "summary.tsv", package / "validation.tsv")
    if require_interop:
        for language in ("r", "python"):
            shutil.copyfile(build / "interop" / (language + "-verified.txt"),
                            package / (language + "-verified.txt"))
    output = build / "packages"
    output.mkdir(exist_ok=True)
    name = "DataBionicIO-{release}-{architecture}-{commit}.zip".format(
        **dict(info, commit=info["commit"][:12]))
    archive = output / name
    files = sorted(p for p in package.rglob("*") if p.is_file())
    with zipfile.ZipFile(archive, "x", zipfile.ZIP_DEFLATED) as bundle:
        for path in files:
            bundle.write(path, path.relative_to(package.parent).as_posix())
    with zipfile.ZipFile(archive) as bundle:
        if bundle.testzip() is not None:
            raise ValueError("The ZIP integrity check failed")
        for path in files:
            if bundle.read(path.relative_to(package.parent).as_posix()) != path.read_bytes():
                raise ValueError("The ZIP bytes differ from the tested package: " + str(path))
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix(".zip.sha256").write_text(digest + "  " + name + "\n")
    return archive


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[2]
    print(package_matlab(root / "build" / "ci", bool(os.getenv("DATAIO_INTEROP_DIR"))))
