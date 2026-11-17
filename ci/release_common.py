# INPUT
# Build paths, source files, and commands for release-package validation.
# OUTPUT
# Build logs, source identifiers, checksums, and isolated test environments.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Shared operations for the Python and Julia package builders."""

import hashlib
import json
import os
from pathlib import Path
import platform
import re
import subprocess


ROOT = Path(__file__).resolve().parents[1]


def build_path(value):
    """Resolve an output path and require it to be below ROOT/build."""
    path = Path(value).resolve()
    if not path.is_relative_to(ROOT / "build") or path == ROOT / "build":
        raise ValueError("Use an output directory below the repository build folder")
    return path


def run(command, log, *, cwd=None, env=None):
    """Run a command, retain its output, and stop on any nonzero exit status."""
    log = Path(log)
    log.parent.mkdir(parents=True, exist_ok=True)
    print(log.stem, flush=True)
    with log.open("w", encoding="utf-8") as stream:
        result = subprocess.run([str(x) for x in command], cwd=cwd, env=env,
                                stdout=stream, stderr=subprocess.STDOUT)
    if result.returncode:
        print("\n".join(log.read_text(encoding="utf-8", errors="replace").splitlines()[-60:]))
        raise subprocess.CalledProcessError(result.returncode, command)


def source_info():
    """Record the version and source bytes; report a commit only for a clean checkout."""
    version = re.search(r"project\(DataBionicIO VERSION ([0-9]+\.[0-9]+\.[0-9]+)\)",
                        (ROOT / "CMakeLists.txt").read_text())[1]
    files = []
    for directory in ("libs", "cmake", "ci", "tests", ".github"):
        files.extend(p for p in (ROOT / directory).rglob("*") if p.is_file()
                     and not any(part in (".svn", ".git", "__pycache__") for part in p.parts)
                     and p.suffix not in (".pyc", ".o", ".so", ".dylib", ".dll"))
    files.extend(ROOT / name for name in (
        "CMakeLists.txt", "README.md", "LICENSE", "LICENSING.md", "MATLAB-EXCEPTION.txt",
        "COMMERCIAL-LICENSE.txt", "NOTICE.txt", "THIRD-PARTY-NOTICES.txt"))
    files.extend(p for p in (ROOT / "LICENSES").rglob("*") if p.is_file())
    digest = hashlib.sha256()
    for path in sorted(files):
        digest.update(path.relative_to(ROOT).as_posix().encode() + b"\0")
        digest.update(hashlib.sha256(path.read_bytes()).digest())
    head = subprocess.run(["git", "rev-parse", "--verify", "HEAD"], cwd=ROOT,
                          capture_output=True, text=True)
    status = subprocess.run(["git", "status", "--porcelain", "--untracked-files=all"],
                            cwd=ROOT, capture_output=True, text=True)
    commit = head.stdout.strip() if head.returncode == status.returncode == 0 and not status.stdout else None
    requested = os.environ.get("GITHUB_SHA")
    if requested and (not re.fullmatch(r"[0-9a-f]{40}", requested) or requested != commit):
        details = "\n".join(part.strip() for part in
                            (head.stderr, status.stderr, status.stdout) if part.strip())
        raise ValueError("The CI source must be a clean checkout of GITHUB_SHA"
                         + ("\n" + details if details else ""))
    return {"version": version, "commit": commit, "source_inputs_sha256": digest.hexdigest(),
            "system": platform.system(), "architecture": platform.machine(),
            "run": os.environ.get("GITHUB_RUN_ID")}


def clean_test_environment(executable):
    """Remove build-path overrides and compiler directories from native loading tests."""
    env = dict(os.environ)
    for name in ("PYTHONPATH", "PYTHONHOME", "LD_LIBRARY_PATH", "DYLD_LIBRARY_PATH",
                 "DYLD_FALLBACK_LIBRARY_PATH", "LIBRARY_PATH"):
        env.pop(name, None)
    if os.name == "nt":
        # os.environ exposes uppercase keys on Windows; a plain dict is case-sensitive.
        windows = Path(env["SYSTEMROOT"])
        paths = [Path(executable).parent, windows / "System32", windows]
    else:
        paths = [Path(executable).parent, Path("/usr/bin"), Path("/bin")]
    env["PATH"] = os.pathsep.join(str(p) for p in paths)
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    return env


def write_json(path, value):
    """Write UTF-8 JSON with a final newline."""
    Path(path).write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_checksum(path):
    """Write a SHA-256 sidecar for the exact final artifact bytes."""
    path = Path(path)
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    path.with_name(path.name + ".sha256").write_text(digest + "  " + path.name + "\n", encoding="utf-8")
