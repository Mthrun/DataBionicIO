# Build the DataBionicIO documentation

Use Python 3.12 from the repository directory:

```sh
python3 -m venv build/docs-env
build/docs-env/bin/python -m pip install -r docs/requirements.txt
build/docs-env/bin/python -m sphinx -n -W --keep-going -b html docs build/docs/html
```

On Windows, use `build\docs-env\Scripts\python.exe` for the environment's Python executable.
Open `build/docs/html/index.html` in a browser.

The [documentation procedure](reference/documentation.md) gives the publication steps.
The [tutorial index](tutorials/index.md) gives the examples and data sources.
Generated HTML stays in `build/`.
