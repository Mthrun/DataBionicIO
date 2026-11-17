/***********************************************************************************************
 * 
 * Function declarations for write_lrn.
 * 
 * AUTHOR: JULIAN MÄRTE (IAP-GmbH Intelligent Analytics Projects)
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 * Reimplemented from the original R function WriteLRN by Michael Thrun.
 * 
 ***********************************************************************************************/


#ifndef __DBT_DATA_IO_WRITE_LRN_HPP__
#define __DBT_DATA_IO_WRITE_LRN_HPP__

#include <vector>
#include "key.hpp"

// Key is a signed 64-bit integer. Valid IDs are in [-2^53, 2^53].
// Readers warn and use MISSING_KEY for invalid IDs. Writers reject invalid IDs.
// LRN/NAMES remove spaces, tabs, commas, and semicolons from header labels with a warning.
// Only format version 2.0 can be written. Other versions are rejected before file output.
#include <string>
#include <iostream>
#include "dataio_exports.hpp"


namespace dbt {
    namespace DataIO {

        inline extern const int LRN_WRITER_CURRENT_MAJOR = 2;
        inline extern const int LRN_WRITER_CURRENT_MINOR = 0;

        /**
         * Write a LRN file in format 2.0.
         *
         * INPUT
         * column_names  Column labels in file order; empty writer input selects default labels.
         * keys  Row keys in [-2^53, 2^53]; an empty writer input selects keys 1:n.
         * numerics  Numeric table with one record per inner vector.
         * types  Column type codes; empty input selects data type 1 and key type 9.
         * path  Filesystem path.
         * comment  User comment text; newlines separate comment lines.
         * significant_digits  Positive significant-digit limit, or -1 for no such limit.
         * decimal_digits  Decimal-place limit, or -1 for no limit; significant_digits takes precedence.
         * scientific  Select scientific notation when true.
         * overwrite  Permit replacement of an existing file when true.
         * verbose  Select information messages; data warnings can remain active.
         * version_major  Major output format version; the supported value is 2.
         * version_minor  Minor output format version; the supported value is 0.
         *
         * OUTPUT
         * No return value. Creates or replaces the output file according to overwrite.
         * Validation and I/O failures throw; diagnostics use output_stream or std::cout.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * @brief Write numeric rows to an LRN file in format 2.0.
         * @param column_names Column labels. An empty vector selects automatic labels.
         * The vector can contain the data labels or all labels, with Key first.
         * @param keys Unique keys in the permitted range.
         * An empty vector selects keys from 1 to the row count and causes a warning.
         * @param numerics Numeric data. Each inner vector contains one row.
         * @param types Column type codes. Type 9 identifies the key column.
         * An empty vector selects type 1 for each data column and type 9 for Key.
         * The vector can contain the data types or all types, with 9 first.
         * @param path Path to the output file.
         * The writer adds .lrn if the path has neither an .lrn nor a .csv extension.
         * @param comment Text for comment lines at the start of the file.
         * @param significant_digits Number of significant digits. A positive value selects this precision.
         * @param decimal_digits Number of decimal places. Zero rounds to whole numbers.
         * A negative value selects no decimal-place limit.
         * A positive significant_digits value takes precedence over decimal_digits.
         * @param scientific Select scientific notation.
         * @param overwrite If true, the writer can replace an existing file. The default is true.
         * @param verbose Enable information messages and optional diagnostics.
         * Data warnings can occur when verbose is false.
         * @param version_major Major format version. The permitted value is 2.
         * @param version_minor Minor format version. The permitted value is 0.
         * @param output_stream Destination for information messages and warnings.
         *
         * @details
         * The file contains a format tag, optional comments, a header, and numeric rows.
         * The header gives the row count, column count, type codes, and column names.
         * The column count includes Key.
         * The writer keeps NaN as a missing-value marker.
         *
         * The writer removes spaces, tabs, commas, and semicolons from header labels with a warning.
         * Empty labels, line breaks, and NUL characters cause an error.
         * The writer keeps other nonstandard labels with a warning.
         *
         * For a row with an incorrect width, the writer gives a warning.
         * It adds NaN values to a short row and removes additional fields from a long row.
         * The writer validates supplied keys before it opens the output file.
         *
         * @throws std::invalid_argument for empty data, invalid keys, an incorrect type vector, or an unsupported format version.
         * The writer also gives an error for an existing file when overwrite is false.
         * File-system errors can prevent creation of the output file.
         */
        MYLIB_API void write_lrn(std::vector<std::string> column_names, std::vector<Key> keys, std::vector<std::vector<double>> numerics, std::vector<int> types, std::string path, std::string comment = "", int significant_digits = -1, int decimal_digits = -1, bool scientific=false, bool overwrite = true, bool verbose = true, int version_major = LRN_WRITER_CURRENT_MAJOR, int version_minor = LRN_WRITER_CURRENT_MINOR);

        /**
         * Write a LRN file in format 2.0.
         *
         * INPUT
         * column_names  Column labels in file order; empty writer input selects default labels.
         * keys  Row keys in [-2^53, 2^53]; an empty writer input selects keys 1:n.
         * numerics  Numeric table with one record per inner vector.
         * types  Column type codes; empty input selects data type 1 and key type 9.
         * path  Filesystem path.
         * comment  User comment text; newlines separate comment lines.
         * significant_digits  Positive significant-digit limit, or -1 for no such limit.
         * decimal_digits  Decimal-place limit, or -1 for no limit; significant_digits takes precedence.
         * scientific  Select scientific notation when true.
         * overwrite  Permit replacement of an existing file when true.
         * verbose  Select information messages; data warnings can remain active.
         * version_major  Major output format version; the supported value is 2.
         * version_minor  Minor output format version; the supported value is 0.
         * output_stream  Destination stream for diagnostics.
         *
         * OUTPUT
         * No return value. Creates or replaces the output file according to overwrite.
         * Validation and I/O failures throw; diagnostics use output_stream or std::cout.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        MYLIB_API void write_lrn(std::vector<std::string> column_names, std::vector<Key> keys, std::vector<std::vector<double>> numerics, std::vector<int> types, std::string path, std::string comment = "", int significant_digits = -1, int decimal_digits = -1, bool scientific=false, bool overwrite = true, bool verbose = true, int version_major = LRN_WRITER_CURRENT_MAJOR, int version_minor = LRN_WRITER_CURRENT_MINOR, std::ostream& output_stream = std::cout);
    }
}

#endif