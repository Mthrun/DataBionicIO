/***********************************************************************************************
 *
 * Function declarations for write_cls.
 *
 * AUTHOR: LUCA BRINKMANN (IAP-GmbH Intelligent Analytics Projects)
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 * Reimplemented from the original R function WriteCLS by Michael Thrun.
 *
 ***********************************************************************************************/


#ifndef __DBT_DATA_IO_WRITE_CLS_HPP__
#define __DBT_DATA_IO_WRITE_CLS_HPP__

#include <vector>
#include "key.hpp"

// Key is a signed 64-bit integer. Valid IDs are in [-2^53, 2^53].
// Readers warn and use MISSING_KEY for invalid IDs. Writers reject invalid IDs.
// Only format version 2.0 can be written. Other versions are rejected before file output.
#include <string>
#include <iostream>
#include "dataio_exports.hpp"

namespace dbt {
    namespace DataIO {


        inline extern const int CLS_WRITER_CURRENT_MAJOR = 2;
        inline extern const int CLS_WRITER_CURRENT_MINOR = 0;
        
        /**
         * Write a CLS file in format 2.0.
         *
         * INPUT
         * keys  Row keys in [-2^53, 2^53]; an empty writer input selects keys 1:n.
         * cls  One numeric class value per record.
         * nan_replacement  Replacement for missing classes; NaN preserves the missing-value marker.
         * path  Filesystem path.
         * comment  User comment text; newlines separate comment lines.
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
         */
        MYLIB_API void write_cls(std::vector<Key> keys, std::vector<double> cls, double nan_replacement, std::string path, std::string comment = "", bool overwrite = true, bool verbose = true, int version_major = CLS_WRITER_CURRENT_MAJOR, int version_minor = CLS_WRITER_CURRENT_MINOR);


        /**
         * Write a CLS file in format 2.0.
         *
         * INPUT
         * keys  Row keys in [-2^53, 2^53]; an empty writer input selects keys 1:n.
         * cls  One numeric class value per record.
         * nan_replacement  Replacement for missing classes; NaN preserves the missing-value marker.
         * path  Filesystem path.
         * comment  User comment text; newlines separate comment lines.
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
        MYLIB_API void write_cls(std::vector<Key> keys, std::vector<double> cls, double nan_replacement, std::string path, std::string comment = "", bool overwrite = true, bool verbose = true, int version_major = CLS_WRITER_CURRENT_MAJOR, int version_minor = CLS_WRITER_CURRENT_MINOR, std::ostream& output_stream = std::cout);
    }
}

#endif