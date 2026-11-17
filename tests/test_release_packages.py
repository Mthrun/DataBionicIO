# OUTPUT
# Assertions that reject incomplete or incorrectly labelled release packages.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Check that invalid package artifacts cannot pass release inspection."""

import importlib.util
from pathlib import Path
import platform
import tempfile
import unittest
import zipfile

from packaging.tags import sys_tags

ROOT = Path(__file__).resolve().parents[1]


def load(name, path):
    """Load a packaging script without starting its command-line entry point."""
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


wheel_builder = load("wheel_builder", "ci/python/build_wheel.py")
julia_builder = load("julia_builder", "ci/julia/package_julia.py")


class ReleaseInspectionTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)

    def wheel(self, *, version="1.0.0", metadata="1.0.0", tag=None, omit=None):
        """Create a wheel-shaped fixture for metadata and completeness inspection."""
        path = self.root / f"pydataio-{version}-{tag or next(sys_tags())}.whl"
        extension = ".pyd" if platform.system() == "Windows" else ".so"
        files = {"pyDataIO/libs/pyDataIO" + extension: b"inspection fixture",
                 f"pydataio-{version}.dist-info/METADATA":
                     f"Name: pyDataIO\nVersion: {metadata}\n".encode()}
        for name in ("LICENSE", "MATLAB-EXCEPTION.txt", "THIRD-PARTY-NOTICES.txt"):
            files[f"pydataio-{version}.dist-info/licenses/{name}"] = b"license fixture"
        with zipfile.ZipFile(path, "w") as bundle:
            for name, data in files.items():
                if omit is None or omit not in name:
                    bundle.writestr(name, data)
        return path

    def test_wheel_inspection_accepts_complete_metadata(self):
        wheel_builder.inspect_wheel(self.wheel(), "1.0.0")

    def test_wheel_rejects_wrong_version_and_python_abi(self):
        for options in ({"version": "0.9.0"}, {"metadata": "0.9.0"},
                        {"tag": "cp999-cp999-" + next(sys_tags()).platform}):
            with self.subTest(options=options), self.assertRaises(ValueError):
                wheel_builder.inspect_wheel(self.wheel(**options), "1.0.0")

    def test_wheel_rejects_missing_native_module_and_license(self):
        for omit in ("pyDataIO/libs/", "MATLAB-EXCEPTION.txt"):
            with self.subTest(omit=omit), self.assertRaises(ValueError):
                wheel_builder.inspect_wheel(self.wheel(omit=omit), "1.0.0")

    def test_julia_rejects_source_only_and_wrong_version_packages(self):
        required = ("Project.toml", "Manifest.toml", "src/DataBionicIO.jl", "test/runtests.jl",
                    "examples/example.jl", "README.md", "LICENSE", "MATLAB-EXCEPTION.txt",
                    "THIRD-PARTY-NOTICES.txt", "LICENSES/CxxWrap-MIT.md",
                    "LICENSES/libcxxwrap-julia-MIT.md")
        for name in required:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.touch()
        project = self.root / "Project.toml"
        project.write_text('name = "DataBionicIO"\nversion = "1.0.0"\n')
        with self.assertRaisesRegex(ValueError, "compiled module"):
            julia_builder.inspect_package(self.root, "1.0.0")
        extension = {"Windows": ".dll", "Darwin": ".dylib", "Linux": ".so"}[platform.system()]
        (self.root / "lib").mkdir()
        (self.root / ("lib/libdatabionicio_julia" + extension)).touch()
        julia_builder.inspect_package(self.root, "1.0.0")
        project.write_text('name = "DataBionicIO"\nversion = "0.9.0"\n')
        with self.assertRaisesRegex(ValueError, "version"):
            julia_builder.inspect_package(self.root, "1.0.0")


if __name__ == "__main__":
    unittest.main()
