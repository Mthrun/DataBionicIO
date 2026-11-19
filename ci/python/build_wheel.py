# INPUT
# The source checkout, a Python interpreter with build dependencies, and output paths.
# OUTPUT
# A wheel, its checksum, and a build record after installation tests pass.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Build a platform wheel and test the installed artifact outside the source tree."""

import argparse
from email.parser import BytesParser
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import venv
import zipfile

from packaging.tags import sys_tags
from packaging.utils import parse_wheel_filename

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from release_common import (ROOT, build_path, clean_test_environment, run,
                            source_info, write_checksum, write_json)


def inspect_wheel(path, version):
    """Reject a wrong version, incompatible tags, or a wheel without its native module."""
    name, wheel_version, _, tags = parse_wheel_filename(path.name)
    if name != "databionicio" or str(wheel_version) != version or not tags.intersection(sys_tags()):
        raise ValueError("The wheel identity or compatibility tags do not match this build")
    with zipfile.ZipFile(path) as bundle:
        if bundle.testzip() is not None:
            raise ValueError("The wheel integrity test failed")
        names = bundle.namelist()
        metadata = [n for n in names if n.endswith(".dist-info/METADATA")]
        if len(metadata) != 1:
            raise ValueError("Expected exactly one wheel metadata file")
        fields = BytesParser().parsebytes(bundle.read(metadata[0]))
        if fields["Version"] != version:
            raise ValueError("The wheel metadata version is incorrect")
        native = [n for n in names if n.startswith("DataBionicIO/libs/") and n.endswith((".so", ".pyd"))]
        if len(native) != 1:
            raise ValueError("Expected one compiled Python module in the wheel")
        for required in ("LICENSE", "MATLAB-EXCEPTION.txt", "THIRD-PARTY-NOTICES.txt"):
            if not any(n.endswith("/" + required) for n in names):
                raise ValueError("Missing wheel license file: " + required)


def main():
    """Build, repair, install, and test one wheel before placing it in the output folder."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", type=build_path, default=ROOT / "build/ci/python-release")
    parser.add_argument("--output", type=build_path, default=ROOT / "build/ci/packages")
    parser.add_argument("--cmake", default="cmake")
    parser.add_argument("--pybind11-dir")
    parser.add_argument("--macos-target", default="13.0")
    parser.add_argument("--manylinux", default="manylinux_2_28_x86_64")
    parser.add_argument("--r-library", type=Path)
    args = parser.parse_args()
    if args.build.exists():
        raise ValueError("Select a new build directory")
    info = source_info()
    args.build.mkdir(parents=True)
    logs = args.build / "logs"
    pybind = args.pybind11_dir or subprocess.check_output(
        [sys.executable, "-m", "pybind11", "--cmakedir"], text=True).strip()
    command = [args.cmake, "-S", ROOT, "-B", args.build / "cmake", "-DCMAKE_BUILD_TYPE=Release",
               "-DBUILD_RPACKAGE=OFF", "-DBUILD_PYPACKAGE=ON", "-DBUILD_PYTHON_TESTS=OFF",
               "-DBUILD_MATLABPACKAGE=OFF", "-DBUILD_JULIAPACKAGE=OFF",
               "-DPython_EXECUTABLE=" + sys.executable, "-Dpybind11_DIR=" + pybind]
    if platform.system() == "Darwin":
        command.append("-DCMAKE_OSX_DEPLOYMENT_TARGET=" + args.macos_target)
        info["macos_deployment_target"] = args.macos_target
    run(command, logs / "configure.log")
    run([args.cmake, "--build", args.build / "cmake", "--config", "Release", "--parallel", "2",
         "--target", "PyPackageBuild"], logs / "build.log")
    wheels = list((args.build / "cmake/libs/pyDataIO/dist").glob("*.whl"))
    if len(wheels) != 1:
        raise ValueError("Expected one newly built wheel")
    repaired = args.build / "repaired"
    repaired.mkdir()
    if platform.system() == "Linux":
        run([sys.executable, "-m", "auditwheel", "repair", "--plat", args.manylinux,
             "--wheel-dir", repaired, wheels[0]], logs / "auditwheel.log")
    elif platform.system() == "Darwin":
        run([sys.executable, "-m", "delocate.cmd.delocate_wheel", "--require-archs", platform.machine(),
             "-w", repaired, wheels[0]], logs / "delocate.log",
            env=dict(os.environ, MACOSX_DEPLOYMENT_TARGET=args.macos_target))
    else:
        shutil.copy2(wheels[0], repaired)
    wheels = list(repaired.glob("*.whl"))
    if len(wheels) != 1:
        raise ValueError("Expected one repaired wheel")
    wheel = wheels[0]
    inspect_wheel(wheel, info["version"])

    # Dependencies come from the build interpreter; the project package must come from this wheel.
    environment = args.build / "test-venv"
    venv.EnvBuilder(with_pip=True, system_site_packages=True).create(environment)
    python = environment / ("Scripts/python.exe" if os.name == "nt" else "bin/python")
    test_env = clean_test_environment(python)
    run([python, "-m", "pip", "install", "--no-index", "--no-deps", "--ignore-installed", wheel],
        logs / "install.log", cwd=args.build, env=test_env)
    probe = ("import importlib.metadata,json,pathlib,sys,DataBionicIO; "
             "p=pathlib.Path(DataBionicIO.__file__).resolve(); "
             "assert p.is_relative_to(pathlib.Path(sys.prefix).resolve()),p; "
             "assert importlib.metadata.version('DataBionicIO')==sys.argv[1]; "
             "print(json.dumps(str(p.parent.parent)))")
    run([python, "-c", probe, info["version"]], logs / "installed-origin.log", cwd=args.build, env=test_env)
    site = Path(json.loads((logs / "installed-origin.log").read_text().strip()))
    extensions = list((site / "DataBionicIO/libs").glob("*.pyd" if os.name == "nt" else "*.so"))
    if len(extensions) != 1:
        raise ValueError("The installed native module is missing or ambiguous")
    for test, argument in (("test_key64.py", extensions[0]), ("test_wrappers.py", site),
                           ("test_same_key.py", site), ("test_common_api.py", site)):
        run([python, ROOT / "tests/Python" / test, argument], logs / (test + ".log"),
            cwd=args.build, env=test_env)
    if args.r_library:
        # Rscript is needed only for this optional comparison, not for normal wheel use.
        interop_env = dict(test_env, PATH=os.environ["PATH"])
        run([python, ROOT / "tests/Python/test_interop.py", site, args.r_library.resolve()],
            logs / "interop.log", cwd=args.build, env=interop_env)
    info.update(python=platform.python_version(), artifact=wheel.name, status="PASS",
                installation_tests=["native-keys", "wrappers", "same-key", "common-api"])
    if args.r_library:
        info["installation_tests"].append("r-interop")
    args.output.mkdir(parents=True, exist_ok=True)
    target = args.output / wheel.name
    if target.exists():
        raise ValueError("The output artifact already exists")
    shutil.copy2(wheel, target)
    write_checksum(target)
    write_json(target.with_name(target.name + ".build.json"), info)
    print(target)


if __name__ == "__main__":
    main()
