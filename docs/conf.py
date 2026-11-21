# OUTPUT
# Sphinx settings for the DataBionicIO user documentation.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
project = "DataBionicIO"
release = re.search(r"^Version: (.+)$", (ROOT / "DESCRIPTION").read_text(), re.M)[1]
version = release
language = "en"
extensions = ["myst_parser"]
myst_enable_extensions = ["colon_fence", "substitution"]
myst_substitutions = {"version": release}
myst_heading_anchors = 3
exclude_patterns = ["README.md"]
html_theme = "sphinx_rtd_theme"
html_title = f"DataBionicIO {release} documentation"
html_static_path = ["_static"]
html_css_files = ["custom.css"]
html_theme_options = {"navigation_depth": 3, "collapse_navigation": False}
html_show_sourcelink = True
html_show_copyright = False
html_context = {
    "display_github": True,
    "github_user": "Mthrun",
    "github_repo": "DataBionicIO",
    "github_version": "main",
    "conf_py_path": "/docs/",
}
nitpicky = True
