/***********************************************************************************************
 *
 * Function declarations for read_names.
 *
 * AUTHOR: LUCA BRINKMANN (IAP-GmbH Intelligent Analytics Projects)
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 * Reimplemented from the original R function ReadNAMES by Michael Thrun.
 *
 ***********************************************************************************************/


#ifndef __DBT_DATA_IO_READ_NAMES_HPP__
#define __DBT_DATA_IO_READ_NAMES_HPP__


#include <tuple>
#include <vector>
#include "key.hpp"

// Key is a signed 64-bit integer. Valid IDs are in [-2^53, 2^53].
// Readers warn and use MISSING_KEY for invalid IDs. Writers reject invalid IDs.
// LRN/NAMES remove spaces, tabs, commas, and semicolons from header labels with a warning.
// Legacy NAMES reading can omit column counts or names.
// If both are absent, the first data row sets the width.
// These rules apply only to untagged or version 1.0 input. No legacy writer is provided.
#include <string>
#include <iostream>
#include "dataio_exports.hpp"


namespace dbt {
    namespace DataIO {
		/**
         * Read a NAMES file through the shared core.
         *
         * INPUT
         * path  Filesystem path.
         * verbose  Select information messages; data warnings can remain active.
         *
         * OUTPUT
         * Tuple: all column labels, keys, names, additional text columns, comments.
         * The additional text uses one vector per column; missing text is NA.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * @brief Read a NAMES file and return its contents.
         * @param path Path to the input file. The reader accepts .names and .csv extensions.
         * @param verbose Enable information messages and optional diagnostics.
         * Data warnings can occur when verbose is false.
         * @param output_stream Destination for information messages and warnings.
         *
         * @return A tuple with these five elements, in this order:
         * - Column names: std::vector<std::string>, for all file columns.
         * - Keys: std::vector<Key>, with one value per row.
         * - Names: std::vector<std::string>, from the second column.
         * - Other text columns: std::vector<std::vector<std::string>>.
         *   Each inner vector contains one column, with one value per row.
         * - Comment: std::string, from the comment lines.
         *
         * @details
         * The optional format tag starts with #<?names.
         * Comment lines start with #. Header lines start with %.
         * The header gives the row count, column count, and column names.
         *
         * The first column must be Key. The second column contains names.
         * The reader does not require Time as a column name.
         * The column count includes Key and all text columns.
         *
         * Files without a version tag and files with version 1.0 use the legacy rules.
         * These files can omit the column count or column names.
         * If both are absent, the first data row sets the number of columns.
         * Version 2.0 files require the current header.
         * The reader rejects other versions.
         *
         * The reader removes spaces, commas, and semicolons from header labels with a warning.
         * Tabs separate fields. Text values keep spaces, commas, and semicolons.
         * Empty or missing text fields become the text NA.
         * Short rows receive missing fields. Additional fields do not add columns.
         *
         * If a key is missing or outside the permitted range, the reader uses MISSING_KEY.
         * The reader keeps the row and gives a warning.
         * A numeric prefix can supply a key.
         * The reader gives a warning for additional text after that prefix.
         * If the header row count differs from the actual count, the reader keeps the actual rows and gives a warning.
         *
         * @throws std::invalid_argument if the path, header, or format version is not valid.
         * The reader also gives an error if it cannot open the file.
         * Numeric conversion can throw std::out_of_range for header counts.
         *
         * @see read_names.cpp
         */
        MYLIB_API std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::string>, std::vector<std::vector<std::string>>, std::string> read_names(std::string path, bool verbose = true);

        /**
         * Read a NAMES file through the shared core.
         *
         * INPUT
         * path  Filesystem path.
         * verbose  Select information messages; data warnings can remain active.
         * output_stream  Destination stream for diagnostics.
         *
         * OUTPUT
         * Tuple: all column labels, keys, names, additional text columns, comments.
         * The additional text uses one vector per column; missing text is NA.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        MYLIB_API std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::string>, std::vector<std::vector<std::string>>, std::string> read_names(std::string path, bool verbose = true, std::ostream& output_stream = std::cout);
    }
}

#endif