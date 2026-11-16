# INPUT
# The built package directory and fixed comparison cases.
# OUTPUT
# Assertions check the public Boolean comparison; no files are written.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

import sys
sys.path.insert(0, sys.argv[1])
import numpy as np
import pandas as pd
from pyDataIO import TheSameKey, the_same_key

cases = [
    ([], [], True), (None, [], True), ([], [1], False),
    ([1, 2, 3], [1.0, 2.0, 3.0], True),
    ([1, 2, 3], [1, 3, 2], False), ([1, 2], [1, 2, 3], False),
    ([1, 1], [1, 1], True), ([1.5, -0.0], [1.5, 0.0], True),
    ([1], [np.nextafter(1.0, 2.0)], False),
    ([-2**53, 2**53], [-2**53, 2**53], True),
    ([1, None], [1, None], False), ([pd.NA], [pd.NA], False),
    ([float("nan")], [float("nan")], False),
    ([float("inf"), -float("inf")], [float("inf"), -float("inf")], True),
    ([True, False], [1, 0], True),
    (["1"], [1], False), ("12", "12", False), (1, 1, False),
    ([[1, 2], [3, 4]], [[1, 2], [3, 4]], False),
    ([2**53 + 1], [2**53], False),
    ([np.int64(2**53 + 1)], [float(2**53 + 1)], False),
    ([10**400], [10**400], False),
    (pd.Series([1, 2], dtype="Int64"), [1, 2], True),
]
for left, right, expected in cases:
    assert TheSameKey(left, right) is expected, (left, right, expected)
    assert the_same_key(left, right) is expected
key = np.array([3, 1, 2], dtype=np.int64)
before = key.copy()
assert TheSameKey(key, key) is True
assert np.array_equal(key, before)
print(f"{len(cases) + 1} TheSameKey cases passed through both public names.")
