# OUTPUT
# Python readers and writers for LRN, CLS, NAMES, and DATES.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Python adapters for the shared DataIO C++ readers and writers.

Tables use records in rows. Dictionaries contain named columns. Missing keys
and text are None. Missing numeric cells are NaN. See ../README.md for the API.
"""
from collections.abc import Mapping
from datetime import date, datetime, timezone
from numbers import Real
from zoneinfo import ZoneInfo
import os
import re
import warnings

import numpy as np
import pandas as pd

from .libs.pyDataIO import (
    _read_dates, _write_dates, _read_lrn, _write_lrn,
    _read_names, _write_names, _read_cls, _write_cls,
    LRN_Reader as LRN_Reader_cpp, ostream_redirect,
)

_MISSING_KEY = -(2**63)
_MAX_KEY = 2**53


def _path(filename, directory):
    # Defaults must follow chdir(), not the directory at module import time.
    # Resolve a file path for the current call.
    #
    # INPUT
    # filename  File name or path-like object.
    # directory  Directory path; None uses the current working directory at call time.
    #
    # OUTPUT
    # Joined path. An absolute file name takes precedence over the directory.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    return os.path.join(os.getcwd() if directory is None else os.fspath(directory),
                        os.fspath(filename))


def _call(function, *args):
    # Forward native diagnostics to Python's stdout, including redirected logs.
    # Call a native function with redirected diagnostics.
    #
    # INPUT
    # function  Native callable.
    # args  Positional arguments for the callable.
    #
    # OUTPUT
    # The native return value; C++ diagnostics are forwarded to Python stdout.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    with ostream_redirect():
        return function(*args)


def _bool(value, name):
    # Validate a Boolean option.
    #
    # INPUT
    # value  Candidate value.
    # name  Option name used in errors.
    #
    # OUTPUT
    # Python bool; types other than bool or numpy.bool_ raise TypeError.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    if not isinstance(value, (bool, np.bool_)):
        raise TypeError(name + " must be a boolean")
    return bool(value)


def _missing(value):
    # Check a scalar for a missing-value marker.
    #
    # INPUT
    # value  Scalar value supported by pandas.isna.
    #
    # OUTPUT
    # True for None, pandas.NA, or another missing scalar; False otherwise.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    return value is None or value is pd.NA or bool(pd.isna(value))


def _vector(value, name):
    # Convert one-dimensional values to a list.
    #
    # INPUT
    # value  Vector-like input, or None.
    # name  Argument name used in errors.
    #
    # OUTPUT
    # List of values; None gives an empty list. Strings and non-vectors raise an error.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    if value is None:
        return []
    if isinstance(value, (str, bytes)):
        raise TypeError(name + " must be a vector, not a string")
    if isinstance(value, np.ndarray) and value.ndim == 1 and value.dtype.kind == "M":
        value = pd.Series(value)
    array = np.asarray(value, dtype=object)
    if array.ndim != 1:
        raise ValueError(name + " must be one-dimensional")
    return array.tolist()


def _empty(value):
    # Check whether a value is absent or has zero length.
    #
    # INPUT
    # value  Candidate object.
    #
    # OUTPUT
    # True for None or an object of length zero; False otherwise.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    return value is None or (hasattr(value, "__len__") and len(value) == 0)


def _keys(value, rows):
    # Use object values until validation: a float array could round large IDs.
    # Validate writer keys without a floating-point intermediate.
    #
    # INPUT
    # value  Optional vector of whole numbers.
    # rows  Required record count for nonempty keys.
    #
    # OUTPUT
    # Unique Python integer keys in [-2^53, 2^53], or an empty list to request generated keys.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    values = _vector(value, "Key")
    result = []
    for key in values:
        if (isinstance(key, (bool, np.bool_)) or not isinstance(key, Real)
                or abs(key) > _MAX_KEY or not np.isfinite(key) or key != int(key)):
            raise ValueError("Key must contain finite whole numbers between -2^53 and 2^53")
        result.append(int(key))
    if result and len(result) != rows:
        raise ValueError("Key must contain one value per row")
    if len(set(result)) != len(result):
        raise ValueError("Key values must be unique")
    return result


def _read_keys(keys):
    # Convert the core missing-key marker.
    #
    # INPUT
    # keys  Core integer key sequence.
    #
    # OUTPUT
    # List of keys with None in place of the reserved missing-key value.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    return [None if key == _MISSING_KEY else key for key in keys]


def _table(value, name, rows=None):
    # Convert supported table input without changing it.
    #
    # INPUT
    # value  DataFrame, mapping of columns, rectangular array, vector, or None.
    # name  Argument name used in errors.
    # rows  Row count for an absent table; None uses zero rows.
    #
    # OUTPUT
    # Pair of a two-dimensional object array and a list of column labels.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Return an object matrix and column names. Keep the input unchanged."""
    if value is None or (_empty(value) and not isinstance(value, pd.DataFrame)
                         and not (isinstance(value, np.ndarray) and value.ndim == 2)):
        return np.empty((0 if rows is None else rows, 0), dtype=object), []
    if isinstance(value, pd.DataFrame):
        return value.to_numpy(dtype=object, copy=True), list(value.columns)
    if isinstance(value, Mapping):
        columns = [_vector(column, name) for column in value.values()]
        if len({len(column) for column in columns}) > 1:
            raise ValueError(name + " columns must have equal lengths")
        # Transpose even a single column; zip alone would silently truncate rows.
        return np.asarray(columns, dtype=object).T, list(value)
    if isinstance(value, np.ndarray) and value.ndim == 1 and value.dtype.kind == "M":
        # NumPy converts datetime64[ns] to integer nanoseconds with dtype=object.
        value = pd.Series(value)
    array = np.asarray(value, dtype=object)
    if array.ndim == 1:
        array = array.reshape(-1, 1)
    if array.ndim != 2:
        raise ValueError(name + " must be a rectangular table or a vector")
    return array.copy(), []


def _take_key(array, names, key):
    # Separate an embedded Key column.
    #
    # INPUT
    # array  Two-dimensional data array.
    # names  Column labels, or an empty list.
    # key  Explicit keys, or an empty value to use the embedded column.
    #
    # OUTPUT
    # Tuple of data without Key, remaining labels, and selected keys. Duplicate Key labels raise an error.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    if names.count("Key") > 1:
        raise ValueError("Only one Key column is allowed")
    if "Key" in names:
        index = names.index("Key")
        if _empty(key):
            key = array[:, index].tolist()
        # An explicit Key overrides the embedded key; it never becomes data.
        array = np.delete(array, index, axis=1)
        names = names[:index] + names[index + 1:]
    return array, names, key


def _numbers(array):
    # Convert numeric tables in NumPy rather than calling Python per cell.
    # Pandas nullable scalars need a missing-value replacement first.
    # Convert a numeric table to Python rows.
    #
    # INPUT
    # array  Numeric or convertible rectangular array, possibly with pandas missing scalars.
    #
    # OUTPUT
    # Nested lists of floats; missing numeric cells become NaN.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    try:
        return np.asarray(array, dtype=float).tolist()
    except (TypeError, ValueError):
        return np.asarray(np.where(pd.isna(array), np.nan, array), dtype=float).tolist()


def _text(value):
    # Validate and encode one text cell.
    #
    # INPUT
    # value  String or missing scalar.
    #
    # OUTPUT
    # String, or NA for missing input. Nontext values, tabs, line breaks, and NUL raise an error.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    if _missing(value):
        return "NA"
    if not isinstance(value, str):
        raise TypeError("Names and FurtherTexts must contain strings or missing values")
    if any(char in value for char in "\t\r\n\0"):
        raise ValueError("Text cells cannot contain tabs, line breaks or NUL")
    return value


def _header(value, fallback):
    # Default DataFrame columns are integers; DATES requires valid text labels.
    # Select explicit labels or labels from a table.
    #
    # INPUT
    # value  Optional vector of explicit labels.
    # fallback  Labels used when value is empty; nontext labels become C1, C2, ... .
    #
    # OUTPUT
    # List of string labels. Explicit nontext labels raise TypeError.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    labels = [label if isinstance(label, str) else "C" + str(i + 1)
              for i, label in enumerate(fallback)] if _empty(value) else _vector(value, "Header")
    if any(not isinstance(label, str) for label in labels):
        raise TypeError("Header must contain strings")
    return labels


def _comment(value):
    # Validate a comment value.
    #
    # INPUT
    # value  String or None.
    #
    # OUTPUT
    # String; None becomes empty text. Other types raise TypeError.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    if value is None:
        return ""
    if not isinstance(value, str):
        raise TypeError("Comments must be a string")
    return value


def _integer(value, name, minimum=0):
    # Validate a bounded integer option.
    #
    # INPUT
    # value  Candidate real scalar, excluding Boolean values.
    # name  Option name used in errors.
    # minimum  Inclusive lower bound, default 0.
    #
    # OUTPUT
    # Python int from minimum through 2^31-1; other values raise ValueError.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    if (isinstance(value, (bool, np.bool_)) or not isinstance(value, Real)
            or not minimum <= value <= 2**31 - 1
            or not np.isfinite(value) or value != int(value)):
        raise ValueError(name + " must be an integer between " + str(minimum) + " and 2^31-1")
    return int(value)


def _comments(result, comment):
    # Store both supported comment field names.
    #
    # INPUT
    # result  Result dictionary to update.
    # comment  Comment text.
    #
    # OUTPUT
    # The same dictionary with Comment and Comments set to comment.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    result.update(Comment=comment, Comments=comment)
    return result


def _lrn_result(raw):
    # Convert the native LRN tuple to the public dictionary.
    #
    # INPUT
    # raw  Tuple of labels, keys, numeric rows, type codes, and comments.
    #
    # OUTPUT
    # Dictionary with Header, Key, Data, Types, DataDefined, Comment, and Comments.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    header, key, data, types, comment = raw
    return _comments(dict(Header=header, Key=_read_keys(key), Data=data,
                          Types=types, DataDefined=types), comment)


def _frame(data, header, keys, *, dtype=None, **metadata):
    # Build a DataFrame with exact nullable keys.
    #
    # INPUT
    # data  Record rows.
    # header  Data column labels.
    # keys  Integer keys or None for missing keys.
    # dtype  Data column type; None uses pandas type inference.
    # metadata  Keyword metadata stored in frame.attrs.
    #
    # OUTPUT
    # DataFrame with Key first, using pandas Int64, followed by the data columns.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    frame = pd.DataFrame(data, columns=header, dtype=dtype)
    # Nullable integers preserve exact IDs even when another row has no key.
    frame.insert(0, "Key", pd.array(keys, dtype="Int64"), allow_duplicates=True)
    frame.attrs.update(metadata)
    return frame


def ReadLRN(FileName, Directory=None, Verbose=True):
    # Read a LRN file into named fields.
    #
    # INPUT
    # FileName  File name, including an optional format extension.
    # Directory  Input directory; None uses the current working directory at call time.
    # Verbose  Boolean flag for native information messages; warnings remain active.
    #
    # OUTPUT
    # Dictionary with Header, Key, Data, Types, DataDefined, Comment, and Comments.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Read LRN into a dictionary with row-oriented Data and exact integer Key."""
    return _lrn_result(_call(_read_lrn, _path(FileName, Directory), _bool(Verbose, "Verbose")))


def read_lrn(FileName, Directory=None, Verbose=True):
    # Read a LRN file into a DataFrame.
    #
    # INPUT
    # FileName  File name, including an optional format extension.
    # Directory  Input directory; None uses the current working directory at call time.
    # Verbose  Boolean flag for native information messages; warnings remain active.
    #
    # OUTPUT
    # DataFrame with Key first and format-specific columns. Comments and other metadata are in frame.attrs.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Read a DataFrame. The function stores column types and comments in frame.attrs."""
    result = ReadLRN(FileName, Directory, Verbose)
    return _frame(result["Data"], result["Header"], result["Key"],
                  DataDefined=result["DataDefined"], Comments=result["Comments"])


def WriteLRN(FileName, Data, Header=None, Key=None, DataDefined=None,
             OutDirectory=None, Comments="", SignificantDigits=None,
             DecimalDigits=None, Scientific=False, Overwrite=False, Verbose=True):
    # Write a LRN file through the shared C++ core.
    #
    # INPUT
    # FileName  File name, including an optional format extension.
    # Data  Numeric table with records in rows, or a mapping of columns.
    # Header  Optional text labels; accepted widths depend on the format.
    # Key  Optional unique whole-number keys in [-2^53, 2^53]; empty input selects 1:n.
    # DataDefined  Optional integer column type codes.
    # OutDirectory  Output directory; None uses the current working directory at call time.
    # Comments  Comment string; None becomes an empty string.
    # SignificantDigits  Optional positive integer significant-digit limit.
    # DecimalDigits  Optional non-negative integer decimal-place limit.
    # Scientific  Boolean switch for scientific notation.
    # Overwrite  Boolean permission to replace an existing file; default False.
    # Verbose  Boolean flag for native information messages; warnings remain active.
    #
    # OUTPUT
    # Returns None. Writes format 2.0; validation or I/O failures raise exceptions.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Write a numeric table. Lists and arrays contain rows. Dictionaries contain columns.

    Header contains one name per data column, with an optional first key label.
    The writer changes that key label to Key.
    The writer rejects incorrect dimensions before it opens the output file.
    """
    array, names = _table(Data, "Data")
    array, names, Key = _take_key(array, names, Key)
    rows, width = array.shape
    if rows == 0 or width == 0:
        raise ValueError("Data must have at least one row and one numeric column")
    labels = _header(Header, names)
    if labels and len(labels) not in (width, width + 1):
        raise ValueError("Header must have one name per data column, optionally preceded by the key name")
    if len(labels) == width + 1:
        labels[0] = "Key"
    types = [_integer(value, "DataDefined") for value in _vector(DataDefined, "DataDefined")]
    significant = -1 if SignificantDigits is None else _integer(SignificantDigits, "SignificantDigits", 1)
    decimal = -1 if DecimalDigits is None else _integer(DecimalDigits, "DecimalDigits")
    _call(_write_lrn, labels, _keys(Key, rows), _numbers(array), types,
          _path(FileName, OutDirectory), _comment(Comments), significant, decimal,
          _bool(Scientific, "Scientific"), _bool(Overwrite, "Overwrite"), _bool(Verbose, "Verbose"), 2, 0)


def ReadCls(FileName, Directory=None, Verbose=True):
    # Read a CLS file into named fields.
    #
    # INPUT
    # FileName  File name, including an optional format extension.
    # Directory  Input directory; None uses the current working directory at call time.
    # Verbose  Boolean flag for native information messages; warnings remain active.
    #
    # OUTPUT
    # Dictionary with Key, Cls, UniqueClasses, Comment, and Comments.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Read class labels, exact keys, unique classes and comments."""
    key, cls, unique, comment = _call(_read_cls, _path(FileName, Directory), _bool(Verbose, "Verbose"))
    return _comments(dict(Key=_read_keys(key), Cls=cls, UniqueClasses=unique), comment)


def read_cls(FileName, Directory=None, Verbose=True):
    # Read a CLS file into a DataFrame.
    #
    # INPUT
    # FileName  File name, including an optional format extension.
    # Directory  Input directory; None uses the current working directory at call time.
    # Verbose  Boolean flag for native information messages; warnings remain active.
    #
    # OUTPUT
    # DataFrame with Key first and format-specific columns. Comments and other metadata are in frame.attrs.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Read a DataFrame with Key and Cls columns."""
    result = ReadCls(FileName, Directory, Verbose)
    return _frame([[value] for value in result["Cls"]], ["Cls"], result["Key"],
                  UniqueClasses=result["UniqueClasses"], Comments=result["Comments"])


def WriteCls(FileName, Cls, Key=None, OutDirectory=None, Comments="",
             Int4NaN=float("nan"), Overwrite=False, Verbose=True):
    # Write a CLS file through the shared C++ core.
    #
    # INPUT
    # FileName  File name, including an optional format extension.
    # Cls  Class vector, one-column table, or two-column table containing keys and classes.
    # Key  Optional unique whole-number keys in [-2^53, 2^53]; empty input selects 1:n.
    # OutDirectory  Output directory; None uses the current working directory at call time.
    # Comments  Comment string; None becomes an empty string.
    # Int4NaN  Replacement for missing class values; None or NaN retains missing values.
    # Overwrite  Boolean permission to replace an existing file; default False.
    # Verbose  Boolean flag for native information messages; warnings remain active.
    #
    # OUTPUT
    # Returns None. Writes format 2.0; validation or I/O failures raise exceptions.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Write a class vector, one-column table, or two-column Key/Cls table.

    An explicit Key argument replaces keys from the input table.
    The writer replaces NaN with Int4NaN before it validates class values.
    Class values must be finite whole numbers in the range of the C++ int type.
    Other values become NaN with a warning. The writer does not round fractions.
    """
    array, names = _table(Cls, "Cls")
    had_key = "Key" in names
    array, names, Key = _take_key(array, names, Key)
    if array.shape[1] == 2 and not had_key:
        if _empty(Key):
            Key = array[:, 0].tolist()
        array = array[:, 1:]
    if array.shape[1] != 1:
        raise ValueError("Cls must have one class column or two columns containing Key and Cls")
    values = [row[0] for row in _numbers(array)]
    replacement = float("nan") if Int4NaN is None else float(Int4NaN)
    _call(_write_cls, _keys(Key, len(values)), values, replacement,
          _path(FileName, OutDirectory), _comment(Comments),
          _bool(Overwrite, "Overwrite"), _bool(Verbose, "Verbose"), 2, 0)


def ReadNames(FileName, Directory=None, Verbose=True):
    # Read a NAMES file into named fields.
    #
    # INPUT
    # FileName  File name, including an optional format extension.
    # Directory  Input directory; None uses the current working directory at call time.
    # Verbose  Boolean flag for native information messages; warnings remain active.
    #
    # OUTPUT
    # Dictionary with Header, FileHeader, Key, Names, row-oriented FurtherTexts, Comment, and Comments.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Read names and row-oriented FurtherTexts. FileHeader retains all labels.

    Header contains the additional text labels. Missing text is None.
    """
    header, key, names, columns, comment = _call(_read_names, _path(FileName, Directory), _bool(Verbose, "Verbose"))
    text = lambda value: None if value == "NA" else value
    rows = [[text(column[i]) for column in columns] for i in range(len(key))]
    return _comments(dict(Header=header[2:], FileHeader=header, Key=_read_keys(key),
                          Names=[text(value) for value in names], FurtherTexts=rows), comment)


def read_names(FileName, Directory=None, Verbose=True):
    # Read a NAMES file into a DataFrame.
    #
    # INPUT
    # FileName  File name, including an optional format extension.
    # Directory  Input directory; None uses the current working directory at call time.
    # Verbose  Boolean flag for native information messages; warnings remain active.
    #
    # OUTPUT
    # DataFrame with Key first and format-specific columns. Comments and other metadata are in frame.attrs.
    # Text columns use object dtype and None for missing values.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Read Key, the names column and each additional text column into a DataFrame."""
    result = ReadNames(FileName, Directory, Verbose)
    data = [[name] + row for name, row in zip(result["Names"], result["FurtherTexts"])]
    return _frame(data, result["FileHeader"][1:], result["Key"],
                  dtype=object, Comments=result["Comments"])


def WriteNames(FileName, Names, Key=None, FurtherTexts=None, Header=None,
               OutDirectory=None, Comments="", Overwrite=False, Verbose=True):
    # Write a NAMES file through the shared C++ core.
    #
    # INPUT
    # FileName  File name, including an optional format extension.
    # Names  Vector of names; missing values are stored as NA.
    # Key  Optional unique whole-number keys in [-2^53, 2^53]; empty input selects 1:n.
    # FurtherTexts  Additional text table with records in rows, or a mapping of columns.
    # Header  Optional text labels; accepted widths depend on the format.
    # OutDirectory  Output directory; None uses the current working directory at call time.
    # Comments  Comment string; None becomes an empty string.
    # Overwrite  Boolean permission to replace an existing file; default False.
    # Verbose  Boolean flag for native information messages; warnings remain active.
    #
    # OUTPUT
    # Returns None. Writes format 2.0; validation or I/O failures raise exceptions.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Write names plus a table of additional texts (records in rows).

    Header can label FurtherTexts, Names and FurtherTexts, or all columns with Key first.
    The writer changes a custom first key label to Key.
    """
    names = [_text(value) for value in _vector(Names, "Names")]
    array, labels = _table(FurtherTexts, "FurtherTexts", rows=len(names))
    if len(array) != len(names):
        raise ValueError("Names and FurtherTexts must have the same number of rows")
    header = _header(Header, labels)
    width = array.shape[1]
    if header and len(header) not in (width, width + 1, width + 2):
        raise ValueError("Header does not match Names and FurtherTexts")
    if len(header) == width + 2:
        header[0] = "Key"
    text = [[_text(value) for value in row] for row in array]
    _call(_write_names, names, header, _keys(Key, len(names)), text,
          _path(FileName, OutDirectory), _comment(Comments),
          _bool(Overwrite, "Overwrite"), _bool(Verbose, "Verbose"), 2, 0)


def _local_time(value, zone, marker=None):
    # Resolve a local timestamp to an instant.
    #
    # INPUT
    # value  Naive datetime.
    # zone  Target time-zone object.
    # marker  Optional DST abbreviation selecting one candidate.
    #
    # OUTPUT
    # Aware datetime. An ambiguous unmarked time uses the later instant; invalid matches raise ValueError.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Use the actual UTC offsets for both occurrences of a local time.

    Reject a local time that does not exist."""
    candidates = {}
    for fold in (0, 1):
        candidate = value.replace(tzinfo=zone, fold=fold)
        utc = candidate.astimezone(timezone.utc)
        if utc.astimezone(zone).replace(tzinfo=None) == value:
            candidates[utc] = candidate
    matching = [candidate for candidate in candidates.values()
                if marker is None or candidate.tzname() == marker]
    if not matching or (marker is not None and len(matching) != 1):
        raise ValueError("Timestamp and DST marker do not identify a valid instant")
    # R selects the later occurrence when an ambiguous wall time has no marker.
    return max(matching, key=lambda candidate: candidate.astimezone(timezone.utc))


def _read_times(times, dst, zone):
    # Convert DATES text and DST metadata.
    #
    # INPUT
    # times  Timestamp strings; NA marks a missing time.
    # dst  DST abbreviation sequence, or an empty sequence.
    # zone  IANA time-zone name.
    #
    # OUTPUT
    # Date objects for date-only input, otherwise aware datetimes. Invalid times become None with a warning.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    zone = ZoneInfo(zone)
    date_only = all(value == "NA" or len(value) == 10 for value in times)
    result = []
    invalid = False
    for i, value in enumerate(times):
        if value == "NA":
            result.append(None)
            continue
        try:
            result.append(date.fromisoformat(value) if date_only else
                          _local_time(datetime.fromisoformat(value), zone, dst[i] if dst else None))
        except ValueError:
            result.append(None)
            invalid = True
    if invalid:
        warnings.warn("The timestamp or DST information is not valid. The reader returns None for the affected times.", RuntimeWarning, stacklevel=3)
    return result


def ReadDates(FileName, Directory=None, Verbose=True):
    # Read a DATES file into named fields.
    #
    # INPUT
    # FileName  File name, including an optional format extension.
    # Directory  Input directory; None uses the current working directory at call time.
    # Verbose  Boolean flag for native information messages; warnings remain active.
    #
    # OUTPUT
    # Dictionary with Header, FileHeader, Key, Time, Times, Data, DST, Timezone, Comment, and Comments.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Read DATES. Time contains date objects or datetime objects with a time zone.

    Times contains the timestamp strings from the file.

    Data contains numeric rows. Header labels the numeric columns.
    DST and FileHeader contain the file metadata.
    When daylight saving time ends, the DST abbreviation identifies the occurrence of a repeated local time.
    """
    header, key, dst, times, data, comment, zone = _call(
        _read_dates, _path(FileName, Directory), _bool(Verbose, "Verbose"))
    rows = [[column[i] for column in data] for i in range(len(key))]
    return _comments(dict(Header=header[2:], FileHeader=header, Key=_read_keys(key),
                          Time=_read_times(times, dst, zone), Times=times, Data=rows,
                          DST=dst, Timezone=zone), comment)


def read_dates(file_name, directory=None, Verbose=True):
    # Read a DATES file into a DataFrame.
    #
    # INPUT
    # file_name  File name, including an optional format extension.
    # directory  Directory path; None uses the current working directory at call time.
    # Verbose  Boolean flag for native information messages; warnings remain active.
    #
    # OUTPUT
    # DataFrame with Key first and format-specific columns. Comments and other metadata are in frame.attrs.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Read a DataFrame with Key, Time and the numeric data columns."""
    result = ReadDates(file_name, directory, Verbose)
    frame = _frame(result["Data"], result["Header"], result["Key"],
                   Comments=result["Comments"], Timezone=result["Timezone"], DST=result["DST"])
    frame.insert(1, "Time", result["Time"], allow_duplicates=True)
    return frame


def _write_times(values, tz, markers=None, format_value=-1):
    # Prepare timestamp strings and their time zone.
    #
    # INPUT
    # values  Dates, datetimes, NumPy timestamps, or supported timestamp strings.
    # tz  Optional IANA time-zone name; absent values use the input zone or UTC.
    # markers  Optional DST abbreviation per value.
    # format_value  -1 for automatic resolution, 1 for dates, 2 for seconds, or 3 for milliseconds.
    #
    # OUTPUT
    # Tuple of timestamp strings and zone name. Invalid times or unrepresentable DST markers raise an error.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    parsed, explicit = [], []
    for value in values:
        if _missing(value):
            raise ValueError("Times cannot contain missing values")
        marker = None
        if isinstance(value, str):
            match = re.fullmatch(r"(.+ \d{2}:\d{2}:\d{2}(?:\.\d+)?) ([A-Za-z]+)", value)
            if match:
                value, marker = match.groups()
            value = value.replace("/", "-")
            if not re.fullmatch(r"\d{4}-\d{2}-\d{2}(?:[ T]\d{2}:\d{2}:\d{2}(?:\.\d{1,9})?(?:Z|[+-]\d{2}:\d{2})?)?", value):
                raise ValueError("Time strings must use YYYY-MM-DD with optional time and milliseconds")
            if len(value) == 10:
                value = date.fromisoformat(value)
            else:
                value = pd.Timestamp(value)
        elif isinstance(value, np.datetime64):
            value = pd.Timestamp(value)
        if not isinstance(value, (date, datetime)) or _missing(value):
            raise TypeError("Time must contain dates, datetimes or timestamp strings")
        parsed.append(value)
        explicit.append(marker)
    if markers is not None:
        if len(markers) != len(parsed):
            raise ValueError("DST must have one marker per timestamp")
        for i, marker in enumerate(markers):
            if not isinstance(marker, str):
                raise TypeError("DST markers must be strings")
            if explicit[i] and marker != explicit[i]:
                raise ValueError("Conflicting DST markers")
            explicit[i] = marker or None
    if tz is None or tz == "":
        aware = next((value for value in parsed if isinstance(value, datetime) and value.tzinfo is not None), None)
        info = aware.tzinfo if aware is not None else None
        tz = getattr(info, "key", None) or getattr(info, "zone", None) or "UTC"
    if not isinstance(tz, str):
        raise TypeError("tz must be an IANA timezone name")
    zone = ZoneInfo(tz)
    local = []
    for value, marker in zip(parsed, explicit):
        if isinstance(value, datetime):
            # Round on the UTC timeline so a carry across seconds/DST is correct.
            if value.tzinfo is None:
                value = _local_time(value, zone, marker)
            else:
                value = value.astimezone(zone)
                if marker and value.tzname() != marker:
                    raise ValueError("DST marker does not match timezone")
            if format_value != 1:
                stamp = pd.Timestamp(value).tz_convert("UTC")
                # Formats 1/2 shorten timestamps; rounding must not advance them.
                stamp = stamp.floor("s") if format_value == 2 else stamp.round("ms")
                value = stamp.tz_convert(zone).to_pydatetime()
        elif marker:
            raise ValueError("A date-only value cannot have a DST marker")
        local.append(value)
    if format_value == 1:
        return [(value.date() if isinstance(value, datetime) else value).isoformat()
                for value in local], tz
    needs_marker = any(explicit) or any(
        isinstance(value, datetime) and (bool(value.dst()) or
            value.replace(fold=0).utcoffset() != value.replace(fold=1).utcoffset()) for value in local)
    strings = []
    for value in local:
        if isinstance(value, datetime):
            text = value.replace(tzinfo=None).isoformat(sep=" ", timespec="milliseconds" if value.microsecond else "seconds")
            if needs_marker:
                marker = value.tzname()
                if not marker or not re.fullmatch(r"[A-Za-z]+", marker):
                    raise ValueError("The DATES parser cannot store this timezone abbreviation; use tz='UTC'")
                text += " " + marker
        else:
            text = value.isoformat()
            if needs_marker:
                raise ValueError("Date-only values cannot be mixed with DST-marked timestamps")
        strings.append(text)
    return strings, tz


def WriteDates(FileName, TSdata, Key=None, OutDirectory=None, Comments="", tz=None,
               Format=-1, Overwrite=False, Verbose=True):
    # Write a DATES file through the shared C++ core.
    #
    # INPUT
    # FileName  File name, including an optional format extension.
    # TSdata  Time series; tables use rows, but nested lists contain columns with times first.
    # Key  Optional unique whole-number keys in [-2^53, 2^53]; empty input selects 1:n.
    # OutDirectory  Output directory; None uses the current working directory at call time.
    # Comments  Comment string; None becomes an empty string.
    # tz  Optional IANA time-zone name; absent values use the input zone or UTC.
    # Format  -1 or None selects automatic resolution; 1 selects dates, 2 seconds, 3 milliseconds.
    # Overwrite  Boolean permission to replace an existing file; default False.
    # Verbose  Boolean flag for native information messages; warnings remain active.
    #
    # OUTPUT
    # Returns None. Writes format 2.0; validation or I/O failures raise exceptions.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Write time series. Keep the input unchanged.

    DataFrames and dictionaries use a Time column or their first column after Key.
    Arrays contain rows, with time first. A nested list retains the original API:
    [times, column1, column2, ...]. A flat vector writes time-only records.
    Datetime values with a time zone keep their instants and DST markers.
    The maximum precision is one millisecond.
    """
    if isinstance(TSdata, list) and TSdata and not np.isscalar(TSdata[0]) and not isinstance(TSdata[0], (date, datetime)):
        columns = [_vector(column, "TSdata") for column in TSdata]
        if len({len(column) for column in columns}) != 1:
            raise ValueError("TSdata columns must have equal lengths")
        array = np.asarray(columns, dtype=object).T
        names = []
    else:
        array, names = _table(TSdata, "TSdata")
    array, names, Key = _take_key(array, names, Key)
    if array.shape[1] == 0:
        raise ValueError("TSdata must contain a time column")
    if names.count("Time") > 1 or names.count("DST") > 1:
        raise ValueError("Time and DST column names must be unique")
    time_index = names.index("Time") if "Time" in names else 0
    dst_index = names.index("DST") if "DST" in names else None
    if dst_index == time_index:
        raise ValueError("The first column cannot be DST")
    markers = array[:, dst_index].tolist() if dst_index is not None else None
    data_indices = [i for i in range(array.shape[1]) if i not in (time_index, dst_index)]
    labels = [names[i] for i in data_indices] if names else ["C" + str(i + 1) for i in range(len(data_indices))]
    labels = _header(None, labels)
    format_value = -1 if Format is None else _integer(Format, "Format", -1)
    if format_value not in (-1, 1, 2, 3):
        raise ValueError("Format must be -1, 1, 2 or 3")
    strings, zone = _write_times(array[:, time_index].tolist(), tz, markers, format_value)
    _call(_write_dates, labels, _keys(Key, len(array)), strings,
          _numbers(array[:, data_indices]), _path(FileName, OutDirectory),
          "Timezone: " + zone + "\n" + _comment(Comments), format_value,
          _bool(Overwrite, "Overwrite"), _bool(Verbose, "Verbose"), 2, 0)


# R spellings are aliases; existing Python names remain available.
ReadCLS, WriteCLS = ReadCls, WriteCls
ReadNAMES, WriteNAMES = ReadNames, WriteNames


class LRN_reader:
    """Incremental LRN reader backed by the same C++ reader as ReadLRN."""

    def __init__(self):
        # Create an incremental native LRN reader.
        #
        # INPUT
        # self  Current LRN_reader instance.
        #
        # OUTPUT
        # No return value; initializes self._lrn.
        # SPDX-License-Identifier: AGPL-3.0-only
        # Additional permission: see MATLAB-EXCEPTION.txt.
        self._lrn = LRN_Reader_cpp()

    def read_next_line(self, line, verbose=True):
        # Match the file reader's CRLF and blank-line handling.
        # Feed one text line to the incremental reader.
        #
        # INPUT
        # self  Current LRN_reader instance.
        # line  Text line with optional CR/LF ending.
        # verbose  Boolean native information-message flag.
        #
        # OUTPUT
        # Returns None; updates reader state. Empty lines and whitespace-only lines without tabs are skipped.
        # SPDX-License-Identifier: AGPL-3.0-only
        # Additional permission: see MATLAB-EXCEPTION.txt.
        line = line.rstrip("\r\n")
        if not line or ("\t" not in line and line.isspace()):
            return
        _call(self._lrn.readNextLine, line, _bool(verbose, "verbose"))

    def get_lrn(self, as_data_frame=False):
        # Retrieve the accumulated LRN data.
        #
        # INPUT
        # self  Current LRN_reader instance.
        # as_data_frame  True requests a DataFrame; False requests a dictionary.
        #
        # OUTPUT
        # LRN result in the selected representation; a row-count mismatch can cause a native warning.
        # SPDX-License-Identifier: AGPL-3.0-only
        # Additional permission: see MATLAB-EXCEPTION.txt.
        result = _lrn_result(_call(self._lrn.getLRN))
        if as_data_frame:
            return _frame(result["Data"], result["Header"], result["Key"],
                          DataDefined=result["DataDefined"], Comments=result["Comments"])
        return result

    def is_finished(self):
        # Check whether the declared LRN row count has been reached.
        #
        # INPUT
        # self  Current LRN_reader instance.
        #
        # OUTPUT
        # True if a header exists and the stored row count is at least the declared count.
        # SPDX-License-Identifier: AGPL-3.0-only
        # Additional permission: see MATLAB-EXCEPTION.txt.
        return self._lrn.has_header and self._lrn.row >= self._lrn.N

    @property
    def keys(self):
        # Get the accumulated keys.
        #
        # INPUT
        # self  Current LRN_reader instance.
        #
        # OUTPUT
        # List of keys; missing keys are None.
        # SPDX-License-Identifier: AGPL-3.0-only
        # Additional permission: see MATLAB-EXCEPTION.txt.
        return _read_keys(self._lrn.keys)

    @property
    def has_nan(self):
        # Check accumulated numeric cells.
        #
        # INPUT
        # self  Current LRN_reader instance.
        #
        # OUTPUT
        # True if any numeric cell is NaN; False otherwise.
        # SPDX-License-Identifier: AGPL-3.0-only
        # Additional permission: see MATLAB-EXCEPTION.txt.
        return any(np.isnan(value) for row in self._lrn.numerics for value in row)

    def __getattr__(self, name):
        # Expose selected native reader attributes.
        #
        # INPUT
        # self  Current LRN_reader instance.
        # name  One of the explicitly supported reader-state field names.
        #
        # OUTPUT
        # The corresponding native field; other names raise AttributeError.
        # SPDX-License-Identifier: AGPL-3.0-only
        # Additional permission: see MATLAB-EXCEPTION.txt.
        if name in {"N", "d", "column_names", "numerics", "types", "comment",
                    "has_header", "has_types", "has_keys", "row", "version_major",
                    "version_minor", "first_line"}:
            return getattr(self._lrn, name)
        raise AttributeError(name)
