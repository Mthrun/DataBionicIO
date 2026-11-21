/***********************************************************************************************
 *
 * Function declarations for read_cls.
 *
 * AUTHOR: LUCA BRINKMANN (IAP-GmbH Intelligent Analytics Projects)
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 * Reimplemented from the original R function ReadCLS by Michael Thrun.
 *
 ***********************************************************************************************/


#ifndef __DBT_DATA_IO_READ_CLS_HPP__
#define __DBT_DATA_IO_READ_CLS_HPP__


#include <tuple>
#include <vector>
#include "key.hpp"

// Key is a signed 64-bit integer. Valid IDs are in [-2^53, 2^53].
// Readers warn and use MISSING_KEY for invalid IDs. Writers reject invalid IDs.
// Legacy CLS reading also accepts space separators and an omitted row count.
// Class colour metadata is ignored.
// These rules apply only to untagged or version 1.0 input. No legacy writer is provided.
#include <string>
#include <iostream>
#include "dataio_exports.hpp"
#include "output_stream.hpp"

namespace dbt {
    namespace DataIO {



        /**
         * Read a CLS file through the shared core.
         *
         * INPUT
         * path  Filesystem path.
         * verbose  Select information messages; data warnings can remain active.
         *
         * OUTPUT
         * Tuple: keys, class values, unique classes, comments.
         * Invalid keys use MISSING_KEY; invalid class cells use NaN.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        MYLIB_API std::tuple<std::vector<Key>, std::vector<double>, std::vector<double>, std::string> read_cls(std::string path, bool verbose = true);

        /**
         * Read a CLS file through the shared core.
         *
         * INPUT
         * path  Filesystem path.
         * verbose  Select information messages; data warnings can remain active.
         * output_stream  Destination stream for diagnostics.
         *
         * OUTPUT
         * Tuple: keys, class values, unique classes, comments.
         * Invalid keys use MISSING_KEY; invalid class cells use NaN.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        MYLIB_API std::tuple<std::vector<Key>, std::vector<double>, std::vector<double>, std::string> read_cls(std::string path, bool verbose = true, std::ostream& output_stream = default_output_stream());

        // INPUT: existing reader arguments plus optional explicit encoding.
        // OUTPUT: the same fields as above, decoded as UTF-8.
        // SPDX-License-Identifier: AGPL-3.0-only
        // Additional permission: see MATLAB-EXCEPTION.txt.
        MYLIB_API std::tuple<std::vector<Key>, std::vector<double>, std::vector<double>, std::string> read_cls(std::string path, bool verbose, std::ostream& output_stream, const std::string& encoding);
    }
}

#endif