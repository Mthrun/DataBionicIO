# INPUT
# The common API table and language wrapper source declarations.
# OUTPUT
# Assertions for package names, argument spelling/order, and MATLAB output slots.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
import ast
import csv
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
python = ast.parse((root / 'libs/pyDataIO/py/common.py').read_text())
python_args = {node.name: [arg.arg for arg in node.args.args]
               for node in python.body if isinstance(node, ast.FunctionDef)}
julia = (root / 'libs/juliaDataIO/src/common.jl').read_text()
with (root / 'tests/common_api.tsv').open() as stream:
    for row in csv.DictReader(stream, delimiter='\t'):
        name = row['Function']
        expected = row['Inputs'].split(',')
        assert python_args[name] == expected, name
        signature = re.search(r'function ' + name + r'\((.*?)\)\n', julia, re.S)[1]
        actual = [arg.split('=')[0].strip() for arg in signature.replace(';', ',').split(',')]
        assert actual == expected, (name, actual)
        matlab = (root / f'libs/matlabDataIO/modern/+DataBionicIO/{name}.m').read_text().splitlines()[0]
        assert re.search(r'\((.*)\)', matlab)[1].replace(' ', '') == row['Inputs'], name
        if row['Outputs']:
            assert re.search(r'\[(.*?)\]', matlab)[1].replace(' ', '') == row['Outputs'], name
assert (root / 'libs/RDataIO/DESCRIPTION').read_text().startswith('Package: DataBionicIO\n')
assert 'name = "DataBionicIO"' in (root / 'libs/juliaDataIO/Project.toml').read_text()
assert 'set(PACKAGE_NAME DataBionicIO)' in (root / 'libs/pyDataIO/CMakeLists.txt').read_text()
print('Package identities and all eight common source declarations passed.')
