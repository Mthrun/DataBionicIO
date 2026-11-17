/***********************************************************************************************
 * 
 * Function declarations for read_lrn.
 * 
 * AUTHOR: JULIAN MÄRTE (IAP-GmbH Intelligent Analytics Projects), LUCA BRINKMANN (IAP-GmbH Intelligent Analytics Projects)
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 * Reimplemented from the original R function ReadLRN by Michael Thrun.
 * 
 ***********************************************************************************************/


#ifndef __DBT_DATA_IO_READ_LRN_HPP__
#define __DBT_DATA_IO_READ_LRN_HPP__


#include <tuple>
#include <vector>
#include "key.hpp"

// Key is a signed 64-bit integer. Valid IDs are in [-2^53, 2^53].
// Readers warn and use MISSING_KEY for invalid IDs. Writers reject invalid IDs.
// LRN/NAMES remove spaces, tabs, commas, and semicolons from header labels with a warning.
// Legacy LRN reading also accepts old key names and positions.
// Without a key column, it warns and generates keys 1:n.
// These rules apply only to untagged or version 1.0 input. No legacy writer is provided.
#include <string>
#include <iostream>
#include "dataio_exports.hpp"

namespace dbt {
    namespace DataIO {
        // Incremental LRN parser. Method contracts describe its state changes.
        struct MYLIB_API LRN_Reader {
            int N = -1;
            int d = -1;
            std::vector<std::string> column_names;
            std::vector<std::vector<double>> numerics;
            std::vector<Key> keys;
            std::vector<int> types;
            std::string comment = "";
            bool has_header = false;
            bool has_types = false;
            bool has_keys = false;
            bool has_nan = false;
            int row = 0;
            // Remove with the legacy reader module. Zero keeps the current key position.
            int legacy_key_column = 0;
            int version_major = 1;
            int version_minor = 0;
            bool first_line = true;
            std::ostream* output_stream = &std::cout;

            /**
             * Consume one line in the incremental LRN reader.
             *
             * INPUT
             * line  File line without its line terminator.
             * verbose  Select information messages.
             * this  Reader state, including its diagnostic stream.
             *
             * OUTPUT
             * Updates metadata or appends a data row. Invalid metadata throws; recoverable row errors cause warnings.
             * SPDX-License-Identifier: AGPL-3.0-only
             * Additional permission: see MATLAB-EXCEPTION.txt.
             */
            void readNextLine(const std::string& line, bool verbose = true);
            /**
             * Compare the consumed and declared row counts.
             *
             * INPUT
             * this  Reader state containing row and N.
             *
             * OUTPUT
             * TRUE exactly when row equals N; this does not check the input stream for EOF.
             * SPDX-License-Identifier: AGPL-3.0-only
             * Additional permission: see MATLAB-EXCEPTION.txt.
             */
            bool isFinished();
            /**
             * Copy the accumulated LRN result.
             *
             * INPUT
             * this  Reader state after zero or more readNextLine calls.
             *
             * OUTPUT
             * Tuple: data-column labels, keys, numeric rows, type codes including Key, comments.
             * Invalid keys use MISSING_KEY; invalid numeric cells use NaN. Actual rows are retained.
             * A mismatch between the declared and actual row count causes a warning.
             * SPDX-License-Identifier: AGPL-3.0-only
             * Additional permission: see MATLAB-EXCEPTION.txt.
             */
            std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::vector<double>>, std::vector<int>, std::string> getLRN();
        };

        /**
         * Read a LRN file through the shared core.
         *
         * INPUT
         * path  Filesystem path.
         * verbose  Select information messages; data warnings can remain active.
         *
         * OUTPUT
         * Tuple: data-column labels, keys, numeric rows, type codes including Key, comments.
         * Invalid keys use MISSING_KEY; invalid numeric cells use NaN. Actual rows are retained.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        MYLIB_API std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::vector<double>>, std::vector<int>, std::string> read_lrn(std::string path, bool verbose = true);

        /**
         * Read a LRN file through the shared core.
         *
         * INPUT
         * path  Filesystem path.
         * verbose  Select information messages; data warnings can remain active.
         * output_stream  Destination stream for diagnostics.
         *
         * OUTPUT
         * Tuple: data-column labels, keys, numeric rows, type codes including Key, comments.
         * Invalid keys use MISSING_KEY; invalid numeric cells use NaN. Actual rows are retained.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        MYLIB_API std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::vector<double>>, std::vector<int>, std::string> read_lrn(std::string path, bool verbose = true, std::ostream& output_stream = std::cout);
    }
}

#endif