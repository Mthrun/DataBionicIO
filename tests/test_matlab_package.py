# INPUT
# None. Temporary package files and reports supply the test cases.
# OUTPUT
# Assertions check archive contents, checksums, and rejection of invalid reports.
# No MATLAB binary is executed by these archive tests.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Check the conditions that permit MATLAB package creation."""
import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "ci" / "matlab"))
from package_matlab import package_matlab


def prepare(build, architecture="win64", extension="mexw64"):
    # INPUT
    # build  Empty temporary directory for one archive test.
    # architecture, extension  MATLAB architecture and MEX file extension.
    # OUTPUT
    # Minimal synthetic package and success reports. Returns the package path.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    package = build / "package" / "DataBionicIO"
    (package / "bin").mkdir(parents=True)
    (package / "bin" / ("dataio_mex." + extension)).write_bytes(b"archive test only")
    for name in ("LICENSE", "LICENSING.md", "MATLAB-EXCEPTION.txt", "COMMERCIAL-LICENSE.txt",
                 "NOTICE.txt", "THIRD-PARTY-NOTICES.txt", "LICENSES/pybind11-BSD-3-Clause.txt"):
        target = package / name
        target.parent.mkdir(exist_ok=True)
        target.write_bytes((ROOT / name).read_bytes())
    for name in ("setupDataIO.m", "README.md"):
        (package / name).write_bytes((ROOT / "libs" / "matlabDataIO" / name).read_bytes())
    reports = build / "matlab"
    reports.mkdir()
    (reports / "summary.tsv").write_text("stage\tresult\nbuild\tPASS\nmodern\tPASS\nlegacy\tPASS\n")
    (reports / "build.json").write_text(json.dumps({"release": "R2024b",
        "architecture": architecture, "mex_extension": extension,
        "commit": os.getenv("GITHUB_SHA", "a" * 40)}))
    return package


def reject(build, interop=False):
    # INPUT
    # build  Temporary CI directory containing an invalid package or reports.
    # interop  Require language-exchange reports when true.
    # OUTPUT
    # An assertion fails if an invalid build can produce a package.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    try:
        package_matlab(build, interop)
    except (ValueError, FileNotFoundError):
        assert not list(build.glob("packages/*.zip"))
    else:
        raise AssertionError("An invalid build produced a package")


for architecture, extension in (("win64", "mexw64"), ("glnxa64", "mexa64"),
                                 ("maca64", "mexmaca64")):
    with tempfile.TemporaryDirectory() as temporary:
        build = Path(temporary)
        package = prepare(build, architecture, extension)
        archive = package_matlab(build)
        with zipfile.ZipFile(archive) as bundle:
            assert bundle.read("DataBionicIO/LICENSE") == (ROOT / "LICENSE").read_bytes()
            assert bundle.read("DataBionicIO/bin/dataio_mex." + extension) == b"archive test only"
            assert "DataBionicIO/build-info.json" in bundle.namelist()
            assert "DataBionicIO/validation.tsv" in bundle.namelist()
        assert archive.with_suffix(".zip.sha256").read_text().split()[0] == hashlib.sha256(archive.read_bytes()).hexdigest()

for failure in ("failed-test", "missing-test", "missing-license", "missing-mex", "wrong-architecture", "missing-interop"):
    with tempfile.TemporaryDirectory() as temporary:
        build = Path(temporary)
        package = prepare(build)
        summary = build / "matlab" / "summary.tsv"
        if failure == "failed-test":
            summary.write_text(summary.read_text().replace("modern\tPASS", "modern\tFAIL"))
        elif failure == "missing-test":
            summary.write_text(summary.read_text().replace("legacy\tPASS\n", ""))
        elif failure == "missing-license":
            (package / "MATLAB-EXCEPTION.txt").unlink()
        elif failure == "missing-mex":
            (package / "bin" / "dataio_mex.mexw64").unlink()
        elif failure == "wrong-architecture":
            path = build / "matlab" / "build.json"
            info = json.loads(path.read_text())
            info["architecture"] = "maca64"
            path.write_text(json.dumps(info))
        reject(build, failure == "missing-interop")

with tempfile.TemporaryDirectory() as temporary:
    build = Path(temporary)
    prepare(build)
    summary = build / "matlab" / "summary.tsv"
    summary.write_text(summary.read_text() + "interop\tPASS\n")
    reject(build, True)
    (build / "interop").mkdir()
    (build / "interop" / "r-verified.txt").write_text("PASS: R checks\n")
    reject(build, True)
    (build / "interop" / "python-verified.txt").write_text("PASS: Python checks\n")
    assert package_matlab(build, True).is_file()

print("MATLAB package archive checks passed for three platforms and rejection cases.")
