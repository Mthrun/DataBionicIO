# Build and publish the documentation

The documentation source is in `docs/` in the DataBionicIO repository.
Sphinx converts the Markdown pages to HTML.
MyST supplies Markdown support.
The theme is `sphinx_rtd_theme`.

## Local build

Use Python 3.12 and a shell in the repository directory.
Make an isolated environment:

```sh
python3 -m venv build/docs-env
build/docs-env/bin/python -m pip install -r docs/requirements.txt
build/docs-env/bin/python -m sphinx -n -W --keep-going -b html docs build/docs/html
```

On Windows, use `build\docs-env\Scripts\python.exe` as the Python executable for the environment.
Open `build/docs/html/index.html` in a browser.
The output includes navigation, search, source pages, and tutorial downloads.

R, MATLAB, Julia, and the compiled DataBionicIO package are not necessary for the documentation build.
The tutorial programs have their applicable runtime requirements.
Their source files supply the displayed code through Sphinx `literalinclude` directives.

## Input and output files

Commit documentation source, example programs, fixed inputs, and the build configuration.
Keep generated HTML and isolated environments in `build/`.
Do not commit them.
Keep the common API in `API.md`.
The reference page includes that source directly.

## Read the Docs setup

To connect the repository, do these steps:

1. Push the approved source to the GitHub repository.
2. Log in to [Read the Docs](https://app.readthedocs.org/dashboard/).
3. Select **Add project**.
4. Select `Mthrun/DataBionicIO`.
5. Complete the repository setup.
6. Select the repository configuration file `.readthedocs.yaml`.
7. After the first build starts, open the build log.
8. After the build completes without errors, open the documentation.

Access to the selected GitHub project is necessary for the repository connection.
The configuration installs the specified versions of the documentation packages.
It then runs Sphinx.
Warnings cause a build failure.
Refer to the [Read the Docs setup instructions](https://docs.readthedocs.com/platform/stable/intro/add-project.html).

## Subsequent updates

A Git commit records the change locally.
A push transfers it to GitHub.
With the Git integration configured, Read the Docs then builds the changed version.
An SVN commit does not update GitHub or Read the Docs.

`latest` usually uses the repository's default branch.
It does not identify a published package release.
For documentation of a fixed release, use a release tag.
Keep that version active in the Read the Docs version settings.
Refer to the [version settings](https://docs.readthedocs.com/platform/stable/versions.html).
