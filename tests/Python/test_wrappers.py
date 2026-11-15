# OUTPUT
# Test results reported through assertions, errors, or the process exit status.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

"""Regression tests for the public Python API; use a freshly built package.

python tests/Python/test_wrappers.py /path/to/build/libs/pyDataIO
"""
from contextlib import redirect_stdout
from datetime import date, datetime, timezone
from io import StringIO
from pathlib import Path
from zoneinfo import ZoneInfo
import os
import sys
import tempfile
import unittest
import warnings

if len(sys.argv) > 1 and not sys.argv[1].startswith("-"):
    sys.path.insert(0, str(Path(sys.argv.pop(1)).resolve()))
import numpy as np
import pandas as pd
import pyDataIO as io


class Wrappers(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dataio-python-")
        self.directory = Path(self.temp.name)
        self.keys = [1, 2**31, 2**53]
        self.values = [[1.25, 10], [np.nan, -2.5], [3.75, 30]]
        self.times = ["2024-01-01 12:30:00.125", "2024-06-15 13:45:10.250", "2024-12-31 23:59:59.999"]

    def tearDown(self):
        self.temp.cleanup()

    def write(self, function, name, *args, **kwargs):
        return function(name, *args, OutDirectory=self.directory, Verbose=False, **kwargs)

    def read(self, function, name):
        return function(name, self.directory, False)

    def numeric(self, actual, expected):
        np.testing.assert_equal(np.asarray(actual, dtype=float), np.asarray(expected, dtype=float))

    def test_lrn_containers_and_headers(self):
        inputs = [self.values, tuple(map(tuple, self.values)), np.asarray(self.values),
                  {"X": [row[0] for row in self.values], "Y": [row[1] for row in self.values]},
                  pd.DataFrame(self.values, columns=["X", "Y"], index=[7, 9, 20])]
        for i, data in enumerate(inputs):
            with self.subTest(type=type(data)):
                self.write(io.WriteLRN, str(i), data, Header=np.array(["ID", "X", "Y"]), Key=self.keys,
                           DataDefined=pd.Series([1, 3]), Comments="first\nsecond")
                result = self.read(io.ReadLRN, str(i))
                self.numeric(result["Data"], self.values)
                self.assertEqual(result["Key"], self.keys)
                self.assertEqual(result["Header"], ["X", "Y"])
                self.assertEqual(result["DataDefined"], [9, 1, 3])
                self.assertEqual(result["Types"], result["DataDefined"])
                self.assertEqual(result["Comments"], "first\nsecond")
                frame = self.read(io.read_lrn, str(i))
                self.assertEqual(list(frame.columns), ["Key", "X", "Y"])
                self.numeric(frame.iloc[:, 1:], self.values)
                self.assertEqual(frame.attrs["DataDefined"], [9, 1, 3])

    def test_one_column_dicts(self):
        self.write(io.WriteLRN, "a", {"X": [1, 2, 3]}, Key=self.keys)
        self.numeric(self.read(io.ReadLRN, "a")["Data"], [[1], [2], [3]])
        self.write(io.WriteNames, "a", ["A", "B", "C"], Key=self.keys, FurtherTexts={"Extra": ["x", "y", "z"]})
        self.assertEqual(self.read(io.ReadNames, "a")["FurtherTexts"], [["x"], ["y"], ["z"]])
        self.write(io.WriteDates, "a", {"Time": self.times, "X": [1, 2, 3]}, Key=self.keys)
        self.numeric(self.read(io.ReadDates, "a")["Data"], [[1], [2], [3]])

    def test_explicit_keys_override_embedded_without_extra_data(self):
        for i, supplied in enumerate((None, [3.0, 4.0, 5.0])):
            frame = pd.DataFrame({"Key": self.keys, "X": [1, 2, 3]}, index=[2, 4, 6])
            original = frame.copy(deep=True)
            self.write(io.WriteLRN, "lrn"+str(i), frame, Key=supplied)
            result = self.read(io.ReadLRN, "lrn"+str(i))
            self.assertEqual(result["Key"], self.keys if supplied is None else supplied)
            self.assertEqual(result["Header"], ["X"])
            pd.testing.assert_frame_equal(frame, original)
            frame["Time"] = self.times
            original = frame.copy(deep=True)
            self.write(io.WriteDates, "dts"+str(i), frame, Key=supplied)
            result = self.read(io.ReadDates, "dts"+str(i))
            self.assertEqual(result["Header"], ["X"])
            self.assertEqual(result["Key"], self.keys if supplied is None else supplied)
            self.numeric(result["Data"], [[1], [2], [3]])
            pd.testing.assert_frame_equal(frame, original)

    def test_header_validation_and_file_preservation(self):
        self.write(io.WriteLRN, "a", self.values, Header=["X", "Y"], Key=self.keys)
        path = self.directory / "a.lrn"
        original = path.read_bytes()
        for header in (["X"], ["Key", "A", "B", "C"], ["X\nX", "Y"]):
            with self.subTest(header=header), self.assertRaises((ValueError, TypeError)):
                self.write(io.WriteLRN, "a", self.values, Header=header, Key=self.keys, Overwrite=True)
            self.assertEqual(path.read_bytes(), original)
        header = ["ID", "X", "Y"]
        self.write(io.WriteLRN, "b", self.values, Header=header, Key=self.keys)
        self.assertEqual(header, ["ID", "X", "Y"])

    def test_key_validation_in_every_writer(self):
        calls = [(io.WriteLRN, "lrn", [[1], [2], [3]]),
                 (io.WriteCls, "cls", [1, 2, 3]),
                 (io.WriteNames, "names", ["a", "b", "c"]),
                 (io.WriteDates, "dts", {"Time": self.times, "X": [1, 2, 3]})]
        bad_keys = [[1, 1, 2], [1, None, 3], [1, np.nan, 3], [1, 2.5, 3],
                    [1, 2**53 + 1, 3], [1, 2**100, 3], [1, True, 3], ["1", "2", "3"], [1, 2]]
        for fn, suffix, data in calls:
            self.write(fn, "a", data, Key=self.keys)
            path = self.directory / ("a." + suffix)
            original = path.read_bytes()
            for keys in bad_keys:
                with self.subTest(format=suffix, keys=keys), self.assertRaises((TypeError, ValueError)):
                    self.write(fn, "a", data, Key=keys, Overwrite=True)
                self.assertEqual(path.read_bytes(), original)

    def test_missing_keys_and_text(self):
        for suffix, lines, reader, frame_reader in [
            ("lrn", ['#<?lrn version="2.0"?>', '% 2', '% 2', '% 9\t1', '% Key\tX', 'bad\t2', str(2**53)+'\t3'], io.ReadLRN, io.read_lrn),
            ("cls", ['#<?cls version="2.0"?>', '% 2', 'bad\t2', str(2**53)+'\t3'], io.ReadCls, io.read_cls),
            ("names", ['#<?names version="2.0"?>', '% 2', '% 3', '% Key\tNames\tExtra', 'bad\tNA\t', str(2**53)+'\tB\tNA'], io.ReadNames, io.read_names),
            ("dts", ['#<?dates version="2.0" format="1"?>', '# Timezone: UTC', '% 2', '% 3', '% Key\tTime\tX', 'bad\t2024-01-01\t2', str(2**53)+'\t2024-01-02\t3'], io.ReadDates, io.read_dates),
        ]:
            with self.subTest(format=suffix):
                (self.directory / ("bad."+suffix)).write_text("\n".join(lines))
                result = self.read(reader, "bad")
                self.assertEqual(result["Key"], [None, 2**53])
                frame = self.read(frame_reader, "bad")
                self.assertEqual(str(frame.iloc[:, 0].dtype), "Int64")
                self.assertTrue(pd.isna(frame.iloc[0, 0]))
                self.assertEqual(frame.iloc[1, 0], 2**53)
        result = self.read(io.ReadNames, "bad")
        self.assertEqual(result["Names"], [None, "B"])
        self.assertEqual(result["FurtherTexts"], [[None], [None]])

    def test_names_round_trip_and_frame(self):
        names = ["1.0.4", None, "Sample A"]
        texts = [["a,b;c", "x"], [None, "y"], ["end", None]]
        for i, more in enumerate([texts, np.array(texts, dtype=object),
                                   {"First": [r[0] for r in texts], "Second": [r[1] for r in texts]},
                                   pd.DataFrame(texts, columns=["First", "Second"]) ]):
            self.write(io.WriteNAMES, str(i), names, Key=self.keys, FurtherTexts=more,
                       Header=["ID", "Version", "First", "Second"])
            result = self.read(io.ReadNAMES, str(i))
            self.assertEqual(result["Names"], names)
            self.assertEqual(result["FurtherTexts"], texts)
            self.assertEqual(result["Header"], ["First", "Second"])
            self.assertEqual(result["FileHeader"], ["Key", "Version", "First", "Second"])
            frame = self.read(io.read_names, str(i))
            self.assertEqual(list(frame.columns), result["FileHeader"])
            self.assertEqual(frame.iloc[:, 2:].values.tolist(), texts)
        self.write(io.WriteNames, "copy", result["Names"], Key=result["Key"],
                   FurtherTexts=result["FurtherTexts"], Header=result["FileHeader"])
        self.assertEqual(self.read(io.ReadNames, "copy")["FurtherTexts"], texts)

    def test_names_without_extra_columns(self):
        self.write(io.WriteNames, "a", ["a", "b"], Key=[1, 2])
        result = self.read(io.ReadNames, "a")
        self.assertEqual(result["FurtherTexts"], [[], []])
        self.assertEqual(self.read(io.read_names, "a").shape, (2, 2))

    def test_text_delimiters_and_unequal_lengths_rejected(self):
        for value in ("tab\there", "new\nline", "carriage\rreturn", "null\0byte", 12):
            with self.subTest(value=value), self.assertRaises((TypeError, ValueError)):
                self.write(io.WriteNames, "a", [value], Key=[1])
        for fn, data in [(io.WriteLRN, {"A": [1, 2], "B": [3]}),
                         (io.WriteDates, {"Time": self.times, "X": [1, 2]})]:
            with self.assertRaises(ValueError):
                self.write(fn, "a", data)
        with self.assertRaises(ValueError):
            self.write(io.WriteNames, "a", ["a", "b"], FurtherTexts={"x": ["z"]})
        self.assertEqual(list(self.directory.iterdir()), [])

    def test_cls_input_forms_and_nan(self):
        for i, value in enumerate(([2, np.nan, 1], np.array([2, np.nan, 1]),
                                   [[1, 2], [2**31, np.nan], [2**53, 1]],
                                   pd.DataFrame({"Key": self.keys, "Cls": [2, np.nan, 1]}))):
            self.write(io.WriteCLS, str(i), value, Key=self.keys)
            result = self.read(io.ReadCLS, str(i))
            self.numeric(result["Cls"], [2, np.nan, 1])
            self.assertEqual(result["Key"], self.keys)
            frame = self.read(io.read_cls, str(i))
            self.assertEqual(list(frame.columns), ["Key", "Cls"])
            self.numeric(frame["Cls"], [2, np.nan, 1])
        self.write(io.WriteCls, "replace", [np.nan, 1], Key=[1, 2], Int4NaN=-7)
        self.numeric(self.read(io.ReadCls, "replace")["Cls"], [-7, 1])

    def test_extra_cls_columns_are_not_discarded(self):
        with self.assertRaises(ValueError):
            self.write(io.WriteCls, "a", pd.DataFrame({"Key": [1], "Cls": [2], "Extra": [3]}))
        self.assertFalse((self.directory / "a.cls").exists())

    def test_dates_containers_and_no_input_mutation(self):
        data = [[self.times[i]] + self.values[i] for i in range(3)]
        for i, value in enumerate([
            {"Time": self.times, "X": [row[0] for row in self.values], "Y": [row[1] for row in self.values]},
            pd.DataFrame(data, columns=["Time", "X", "Y"], index=[4, 8, 12]),
            np.array(data, dtype=object),
            [list(self.times), [row[0] for row in self.values], [row[1] for row in self.values]],
        ]):
            self.write(io.WriteDates, str(i), value, Key=self.keys, Comments="audit", Format=3)
            result = self.read(io.ReadDates, str(i))
            self.numeric(result["Data"], self.values)
            self.assertEqual(result["Times"], self.times)
            self.assertEqual(result["Timezone"], "UTC")
            self.assertEqual(result["Comments"], "audit")
            self.assertEqual(len(result["Header"]), 2)
            self.assertEqual(result["Time"][0].microsecond, 125000)
            frame = self.read(io.read_dates, str(i))
            self.assertEqual(frame.shape, (3, 4))
            self.numeric(frame.iloc[:, 2:], self.values)
        self.assertIsInstance(data[0][0], str)

    def test_time_only_and_numpy_dates(self):
        dates = [date(2024, 1, 1), date(2024, 1, 2)]
        for i, data in enumerate([dates, [dates], {"Time": dates}, pd.DataFrame({"Time": dates}),
                                   np.array(dates, dtype="datetime64[ns]"),
                                   {"Time": np.array(dates, dtype="datetime64[ns]")} ]):
            self.write(io.WriteDates, str(i), data, Key=[1, 2], Format=1)
            result = self.read(io.ReadDates, str(i))
            self.assertEqual(result["Time"], dates)
            self.assertEqual(result["Data"], [[], []])
            self.assertEqual(self.read(io.read_dates, str(i)).shape, (2, 2))

    def test_timezone_folds_and_historical_dst(self):
        instants = [datetime(2024, 10, 27, 0, 30, tzinfo=timezone.utc),
                    datetime(2024, 10, 27, 1, 30, tzinfo=timezone.utc),
                    datetime(1995, 7, 1, 12, tzinfo=timezone.utc)]
        for i, zone in enumerate(["Europe/Berlin", "UTC"]):
            frame = pd.DataFrame({"Time": instants, "X": [1, 2, 3]}, index=[2, 9, 20])
            original = frame.copy(deep=True)
            self.write(io.WriteDates, str(i), frame, Key=self.keys, tz=zone)
            result = self.read(io.ReadDates, str(i))
            self.assertEqual([v.astimezone(timezone.utc) for v in result["Time"]], instants)
            self.assertEqual(result["Timezone"], zone)
            pd.testing.assert_frame_equal(frame, original)
        result = self.read(io.ReadDates, "0")
        self.assertEqual(result["DST"], ["CEST", "CET", "CEST"])
        self.write(io.WriteDates, "again", {"Time": result["Time"]}, Key=self.keys)
        again = self.read(io.ReadDates, "again")
        self.assertEqual([v.timestamp() for v in again["Time"]], [v.timestamp() for v in instants])

    def test_millisecond_rounding_carries(self):
        values = [datetime(2024, 12, 31, 23, 59, 59, 999600), datetime(2025, 1, 1, 0, 0, 1, 123600)]
        original = values.copy()
        self.write(io.WriteDates, "a", values, Key=[1, 2], Format=3)
        self.assertEqual(self.read(io.ReadDates, "a")["Times"], ["2025-01-01 00:00:00.000", "2025-01-01 00:00:01.124"])
        self.assertEqual(values, original)

    def test_shorter_time_formats_do_not_round_into_next_day(self):
        value = datetime(2024, 12, 31, 23, 59, 59, 999600)
        for fmt, expected in [(1, "2024-12-31"), (2, "2024-12-31 23:59:59")]:
            self.write(io.WriteDates, str(fmt), [value], Key=[1], Format=fmt)
            self.assertEqual(self.read(io.ReadDates, str(fmt))["Times"], [expected])

    def test_fixed_offset_strings_preserve_the_instant(self):
        self.write(io.WriteDates, "a", ["2024-01-01T03:00:00+02:00"], Key=[1])
        self.assertEqual(self.read(io.ReadDates, "a")["Time"],
                         [datetime(2024, 1, 1, 1, tzinfo=timezone.utc)])

    def test_explicit_dst_column(self):
        self.write(io.WriteDates, "a", {"Time": ["2024-10-27 02:30:00"]*2,
                   "DST": ["CEST", "CET"], "X": [1, 2]}, Key=[1, 2], tz="Europe/Berlin")
        result = self.read(io.ReadDates, "a")
        self.assertEqual(result["Time"][1].timestamp()-result["Time"][0].timestamp(), 3600)
        self.numeric(result["Data"], [[1], [2]])

    def test_invalid_times_and_options(self):
        for values in ([None], [pd.NaT], ["2024-02-30"], ["2024-03-31 02:30:00"], ["today"], ["2024"]):
            with self.subTest(values=values), self.assertRaises((TypeError, ValueError)):
                self.write(io.WriteDates, "a", {"Time": values}, tz="Europe/Berlin")
        for digits in (0, -1, 1.5, True, 2**100):
            with self.subTest(digits=digits), self.assertRaises((TypeError, ValueError)):
                self.write(io.WriteLRN, "a", [[1]], SignificantDigits=digits)
        for fmt in (0, 4, 1.5, True):
            with self.subTest(fmt=fmt), self.assertRaises((TypeError, ValueError)):
                self.write(io.WriteDates, "a", self.times, Format=fmt)
        self.assertEqual(list(self.directory.iterdir()), [])

    def test_date_only_does_not_need_numeric_dst_abbreviations(self):
        instant = datetime(2024, 12, 1, tzinfo=timezone.utc)
        self.write(io.WriteDates, "a", [instant], Key=[1], tz="Australia/Lord_Howe", Format=1)
        self.assertEqual(self.read(io.ReadDates, "a")["Time"], [date(2024, 12, 1)])

    def test_invalid_dst_file_keeps_rows(self):
        self.write(io.WriteDates, "a", {"Time": ["2024-10-27 02:30:00 CEST", "2024-10-27 02:30:00 CET"]},
                   Key=[1, 2], tz="Europe/Berlin")
        path = self.directory / "a.dts"
        path.write_text(path.read_text().replace("CEST", "INVALID"))
        with warnings.catch_warnings(record=True) as caught:
            warnings.simplefilter("always")
            result = self.read(io.ReadDates, "a")
        self.assertIsNone(result["Time"][0])
        self.assertIsNotNone(result["Time"][1])
        self.assertEqual(result["Key"], [1, 2])
        self.assertEqual(len(caught), 1)
        self.assertIs(caught[0].category, RuntimeWarning)
        self.assertIn("DST information is not valid", str(caught[0].message))
        self.assertIn("returns None", str(caught[0].message))

    def test_empty_declared_text_table_is_rejected(self):
        with self.assertRaises(ValueError):
            self.write(io.WriteNames, "a", ["one"], FurtherTexts=np.empty((0, 2), dtype=str))

    def test_nullable_numeric_frames(self):
        frame = pd.DataFrame({"X": pd.array([1, None, 3], dtype="Int64")})
        self.write(io.WriteLRN, "a", frame, Key=self.keys)
        self.numeric(self.read(io.ReadLRN, "a")["Data"], [[1], [np.nan], [3]])

    def test_default_dataframe_column_labels(self):
        self.write(io.WriteLRN, "a", pd.DataFrame([[1, 2], [3, 4]]), Key=[1, 2])
        self.numeric(self.read(io.ReadLRN, "a")["Data"], [[1, 2], [3, 4]])
        self.write(io.WriteDates, "a", pd.DataFrame([[self.times[0], 1], [self.times[1], 2]]), Key=[1, 2])
        self.numeric(self.read(io.ReadDates, "a")["Data"], [[1], [2]])

    def test_rectangular_shapes_and_numeric_extremes(self):
        for rows in (1, 2, 5):
            for columns in (1, 2, 4):
                values = np.arange(rows*columns, dtype=float).reshape(rows, columns)
                values.flat[0] = np.nan
                names = ["X"+str(i) for i in range(columns)]
                self.write(io.WriteLRN, f"{rows}-{columns}", dict(zip(names, values.T)), Key=list(range(rows)))
                self.numeric(self.read(io.ReadLRN, f"{rows}-{columns}")["Data"], values)
        values = [[np.inf, -np.inf, 1e-310]]
        self.write(io.WriteLRN, "extreme", values, Key=[1])
        self.numeric(self.read(io.ReadLRN, "extreme")["Data"], values)
        with self.assertRaises((TypeError, ValueError)):
            self.write(io.WriteLRN, "complex", np.array([[1+2j]]), Key=[1])

    def test_precision_settings(self):
        for i, (options, expected) in enumerate([({"DecimalDigits": 0}, 1.0),
                                                ({"DecimalDigits": 2}, 1.23),
                                                ({"SignificantDigits": 3}, 1.23),
                                                ({"SignificantDigits": 3, "Scientific": True}, 1.23)]):
            self.write(io.WriteLRN, str(i), [[1.23456]], Key=[1], **options)
            self.numeric(self.read(io.ReadLRN, str(i))["Data"], [[expected]])

    def test_current_directory_is_resolved_at_call(self):
        previous = os.getcwd()
        try:
            os.chdir(self.directory)
            io.WriteLRN("cwd", [[1]], Key=[1], Verbose=False)
            self.assertEqual(io.ReadLRN("cwd", Verbose=False)["Data"], [[1]])
            self.assertTrue((self.directory / "cwd.lrn").is_file())
        finally:
            os.chdir(previous)

    def test_overwrite_protection_and_verbose_false(self):
        self.write(io.WriteCls, "a", [1, 2], Key=[1, 2])
        original = (self.directory / "a.cls").read_bytes()
        with self.assertRaises(ValueError):
            self.write(io.WriteCls, "a", [3, 4], Key=[1, 2])
        self.assertEqual((self.directory / "a.cls").read_bytes(), original)
        buffer = StringIO()
        with redirect_stdout(buffer):
            self.read(io.read_cls, "a")
        self.assertEqual(buffer.getvalue(), "")

    def test_streaming_crlf_matches_file(self):
        self.write(io.WriteLRN, "a", self.values, Key=self.keys, Header=["X", "Y"])
        reader = io.LRN_reader()
        reader.read_next_line("\r\n", False)
        self.assertFalse(reader.is_finished())
        for line in (self.directory / "a.lrn").read_text().splitlines():
            reader.read_next_line(line + "\r\n", False)
        self.assertTrue(reader.is_finished())
        self.assertTrue(reader.has_nan)
        self.assertEqual(reader.keys, self.keys)
        self.numeric(reader.get_lrn()["Data"], self.values)
        pd.testing.assert_frame_equal(reader.get_lrn(True), self.read(io.read_lrn, "a"))

    def test_legacy_samples_and_moved_key(self):
        sample_root = Path(__file__).resolve().parents[1] / "legacy/samples"
        samples = list(sample_root.rglob("*.*"))
        self.assertEqual(len(samples), 9)
        for path in samples:
            reader = {".lrn": io.ReadLRN, ".cls": io.ReadCls, ".names": io.ReadNames}[path.suffix]
            result = reader(path.name, path.parent, False)
            self.assertGreater(len(result["Key"]), 0)
        text = "% 2\n% 3\n% 1\t9\t1\n% Left\tID\tRight\n10\t2147483648\t30\n20\t42\t31"
        (self.directory / "moved.lrn").write_text(text)
        result = self.read(io.ReadLRN, "moved")
        self.assertEqual(result["Key"], [2**31, 42])
        self.numeric(result["Data"], [[10, 30], [20, 31]])


if __name__ == "__main__":
    unittest.main(verbosity=2)
