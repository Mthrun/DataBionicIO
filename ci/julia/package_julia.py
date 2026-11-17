# INPUT
# A built Julia package, its Julia interpreter, and output paths.
# OUTPUT
# A tested ZIP archive, its checksum, build record, and installation logs.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Package Julia binaries and test the extracted archive without a compiler path."""

import argparse
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import tomllib
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from release_common import (ROOT, build_path, clean_test_environment, run,
                            source_info, write_checksum, write_json)


def inspect_package(package, version):
    """Reject incomplete packages and package metadata from a different version."""
    for name in ("Project.toml", "Manifest.toml", "src/DataBionicIO.jl", "test/runtests.jl",
                 "examples/example.jl", "README.md", "LICENSE", "MATLAB-EXCEPTION.txt",
                 "THIRD-PARTY-NOTICES.txt", "LICENSES/CxxWrap-MIT.md",
                 "LICENSES/libcxxwrap-julia-MIT.md"):
        if not (package / name).is_file():
            raise ValueError("Missing Julia package file: " + name)
    project = tomllib.loads((package / "Project.toml").read_text())
    if project.get("name") != "DataBionicIO" or project.get("version") != version:
        raise ValueError("The Julia package name or version is incorrect")
    extension = {"Windows": ".dll", "Darwin": ".dylib", "Linux": ".so"}[platform.system()]
    native = list((package / "lib").glob("libdatabionicio_julia" + extension))
    if len(native) != 1:
        raise ValueError("Expected the compiled module for this operating system")
    return native[0]


def main():
    """Create and test a relocatable package before publishing it to the output folder."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", type=build_path, required=True)
    parser.add_argument("--julia", default="julia")
    parser.add_argument("--work", type=build_path, default=ROOT / "build/ci/julia-release")
    parser.add_argument("--output", type=build_path, default=ROOT / "build/ci/packages")
    parser.add_argument("--macos-target", default="13.0")
    parser.add_argument("--reuse-depot", action="store_true",
                        help="Use cached dependencies for a local test instead of a fresh depot")
    args = parser.parse_args()
    if args.work.exists():
        raise ValueError("Select a new work directory")
    julia = Path(shutil.which(args.julia) or args.julia).absolute()
    info = source_info()
    native = inspect_package(args.package, info["version"])
    manifest = tomllib.loads((args.package / "Manifest.toml").read_text())
    julia_version = subprocess.check_output(
        [julia, "--startup-file=no", "-e", "print(VERSION)"], text=True).strip()
    if manifest.get("julia_version") != julia_version:
        raise ValueError("Use the Julia version recorded in the package manifest")
    info.update(julia=julia_version,
                dependencies={name: manifest["deps"][name][0]["version"]
                              for name in ("CxxWrap", "libcxxwrap_julia_jll")})
    machine = platform.machine().lower()
    arch = {"amd64": "x64", "x86_64": "x64", "aarch64": "arm64", "arm64": "arm64"}[machine]
    system = {"Windows": "windows", "Darwin": "macos", "Linux": "linux"}[platform.system()]
    args.work.mkdir(parents=True)
    logs = args.work / "logs"
    if system == "macos":
        run(["otool", "-l", native], logs / "native-load-commands.log")
        lines = (logs / "native-load-commands.log").read_text().splitlines()
        minimum = [line.split()[1] for line in lines if line.strip().startswith("minos ")]
        if minimum != [args.macos_target]:
            raise ValueError("The native macOS deployment target differs from the archive label")
        info["macos_deployment_target"] = args.macos_target
        system += args.macos_target
    elif system == "linux":
        info["build_libc"] = " ".join(platform.libc_ver())
        system += "-glibc" + platform.libc_ver()[1]
    name = f"DataBionicIO-{info['version']}-Julia-{julia_version}-{system}-{arch}.zip"
    info.update(artifact=name, fresh_test_depot=not args.reuse_depot)
    staged = args.work / "staging/DataBionicIO"
    shutil.copytree(args.package, staged)
    write_json(staged / "build-info.json", info)
    (staged / "INSTALL.txt").write_text(
        "DataBionicIO " + info["version"] + " for Julia " + julia_version + "\n\n"
        "Use the operating system and processor type in the archive filename.\n"
        "Use the Julia version shown above.\n"
        "The archive contains the compiled library and a dependency manifest.\n"
        "A C++ compiler is not necessary.\n"
        "An Internet connection is necessary to install the Julia dependencies.\n\n"
        "1. Extract this archive.\n"
        "2. Open a terminal in the extracted DataBionicIO folder.\n"
        "3. Install the dependencies:\n"
        "   julia --project=. -e 'using Pkg; Pkg.instantiate()'\n"
        "4. Start the package tests:\n"
        "   julia --project=. test/runtests.jl\n"
        "5. Start Julia with this project:\n"
        "   julia --project=.\n"
        "6. Load the package:\n"
        "   using DataBionicIO\n\n"
        "On Windows, use double quotation marks around the Julia expression in step 3.\n"
        "For another Julia version or system, build the package from source.\n",
        encoding="utf-8")
    candidate = args.work / name
    with zipfile.ZipFile(candidate, "w", zipfile.ZIP_DEFLATED) as bundle:
        for path in sorted(staged.rglob("*")):
            if path.is_file():
                bundle.write(path, path.relative_to(staged.parent).as_posix())
    extracted = args.work / "installation-test"
    with zipfile.ZipFile(candidate) as bundle:
        if bundle.testzip() is not None:
            raise ValueError("The Julia archive integrity test failed")
        bundle.extractall(extracted)
    installed = extracted / "DataBionicIO"
    inspect_package(installed, info["version"])
    env = clean_test_environment(julia)
    env["JULIA_LOAD_PATH"] = "@" + os.pathsep + "@stdlib"
    env["JULIA_PKG_PRECOMPILE_AUTO"] = "0"
    if not args.reuse_depot:
        env["JULIA_DEPOT_PATH"] = str(args.work / "test-depot")
        env.pop("JULIA_PKG_OFFLINE", None)
    command = [julia, "--startup-file=no", "--compiled-modules=no", "--project=" + str(installed)]
    run(command + ["-e", "using Pkg; Pkg.instantiate(; allow_autoprecomp=false)"],
        logs / "instantiate.log", cwd=extracted, env=env)
    probe = ('using DataBionicIO; '
             '@assert realpath(pathof(DataBionicIO)) == realpath(ARGS[1]); '
             '@assert string(pkgversion(DataBionicIO)) == ARGS[2]')
    run(command + ["-e", probe, installed / "src/DataBionicIO.jl", info["version"]],
        logs / "installed-origin.log", cwd=extracted, env=env)
    for script in ("test/runtests.jl", "examples/example.jl"):
        run(command + [installed / script], logs / (Path(script).stem + ".log"),
            cwd=extracted, env=env)
    info.update(status="PASS", installation_tests=["origin", "package-tests", "example"])
    args.output.mkdir(parents=True, exist_ok=True)
    target = args.output / name
    if target.exists():
        raise ValueError("The output artifact already exists")
    shutil.copy2(candidate, target)
    write_checksum(target)
    write_json(target.with_name(target.name + ".build.json"), info)
    print(target)


if __name__ == "__main__":
    main()
