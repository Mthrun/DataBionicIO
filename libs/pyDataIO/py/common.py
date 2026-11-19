# INPUT
# File names, row-oriented data, and format-specific metadata.
# OUTPUT
# The common DataBionicIO interface. Readers return fields in a fixed order.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Common reader and writer names, arguments, and result fields for four languages.

Optional directories use the current working directory. Writers return None.
See the project API.md for argument order, defaults, and result fields.
"""
from . import extension as _impl


def ReadLRN(FileName, InDirectory=None, Verbose=True):
    # INPUT
    # FileName, InDirectory, Verbose. See the function documentation and API.md.
    # OUTPUT
    # Key, Data, Header, DataDefined, Comments in this fixed order.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Return Key, Data, Header, DataDefined, and Comments, in that order."""
    value = _impl.ReadLRN(FileName, InDirectory, Verbose)
    return {name: value[name] for name in ("Key", "Data", "Header", "DataDefined", "Comments")}


def ReadCLS(FileName, InDirectory=None, Verbose=True):
    # INPUT
    # FileName, InDirectory, Verbose. See the function documentation and API.md.
    # OUTPUT
    # Key, Cls, UniqueClasses, Comments in this fixed order.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Return Key, Cls, UniqueClasses, and Comments, in that order."""
    value = _impl.ReadCls(FileName, InDirectory, Verbose)
    return {name: value[name] for name in ("Key", "Cls", "UniqueClasses", "Comments")}


def ReadNAMES(FileName, InDirectory=None, Verbose=True):
    # INPUT
    # FileName, InDirectory, Verbose. See the function documentation and API.md.
    # OUTPUT
    # Key, Names, FurtherTexts, Header, Comments in this fixed order.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Return Key, Names, FurtherTexts, Header, and Comments, in that order."""
    value = _impl.ReadNames(FileName, InDirectory, Verbose)
    return {name: value[name] for name in ("Key", "Names", "FurtherTexts", "Header", "Comments")}


def ReadDates(FileName, InDirectory=None, Verbose=True):
    # INPUT
    # FileName, InDirectory, Verbose. See the function documentation and API.md.
    # OUTPUT
    # Key, Time, Data, Header, Comments, Timezone, DST in this fixed order.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Return Key, Time, Data, Header, Comments, Timezone, and DST, in that order."""
    value = _impl.ReadDates(FileName, InDirectory, Verbose)
    return {name: value[name] for name in ("Key", "Time", "Data", "Header", "Comments", "Timezone", "DST")}


def WriteLRN(FileName, Data, Header=None, Key=None, DataDefined=None,
             OutDirectory=None, Comments=None, SignificantDigits=None,
             DecimalDigits=None, Scientific=False, Overwrite=True, Verbose=True):
    # INPUT
    # FileName, Data, Header, Key, DataDefined, OutDirectory, Comments, SignificantDigits, DecimalDigits, Scientific, Overwrite, Verbose. See the function documentation and API.md.
    # OUTPUT
    # A format 2.0 file. No return value.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Write numeric rows with optional labels, keys, types, comments, and precision."""
    return _impl.WriteLRN(FileName, Data, Header, Key, DataDefined, OutDirectory,
                          Comments, SignificantDigits, DecimalDigits, Scientific,
                          Overwrite, Verbose)


def WriteCLS(FileName, Cls, OutDirectory=None, Key=None, Comment=None,
             Int4NaN=None, Overwrite=True, Verbose=True):
    # INPUT
    # FileName, Cls, OutDirectory, Key, Comment, Int4NaN, Overwrite, Verbose. See the function documentation and API.md.
    # OUTPUT
    # A format 2.0 file. No return value.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Write class values. OutDirectory precedes Key, as in the R interface."""
    return _impl.WriteCls(FileName, Cls, Key, OutDirectory, Comment, Int4NaN,
                          Overwrite, Verbose)


def WriteNAMES(FileName, Names, Key=None, FurtherTexts=None, Header=None,
               OutDirectory=None, Comments="", Overwrite=True, Verbose=True):
    # INPUT
    # FileName, Names, Key, FurtherTexts, Header, OutDirectory, Comments, Overwrite, Verbose. See the function documentation and API.md.
    # OUTPUT
    # A format 2.0 file. No return value.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Write names and optional additional text, with one record per row."""
    return _impl.WriteNames(FileName, Names, Key, FurtherTexts, Header,
                            OutDirectory, Comments, Overwrite, Verbose)


def WriteDates(FileName, TSdata, Key=None, OutDirectory=None, Comments=None,
               tz=None, Format=None, Overwrite=True, Verbose=True):
    # INPUT
    # FileName, TSdata, Key, OutDirectory, Comments, tz, Format, Overwrite, Verbose. See the function documentation and API.md.
    # OUTPUT
    # A format 2.0 file. No return value.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    """Write time series in tz. Zoned input keeps its instant during conversion."""
    return _impl.WriteDates(FileName, TSdata, Key, OutDirectory, Comments,
                            tz, Format, Overwrite, Verbose)
