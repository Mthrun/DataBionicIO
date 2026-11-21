/***********************************************************************************************
 * 
 * Function declarations for write_dates.
 * 
 * AUTHOR: JULIAN MÄRTE (IAP-GmbH Intelligent Analytics Projects)
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 * 
 ***********************************************************************************************/


#ifndef __DBT_DATA_IO_WRITE_DATES_HPP__
#define __DBT_DATA_IO_WRITE_DATES_HPP__

#include <vector>
#include "key.hpp"

// Key is a signed 64-bit integer. Valid IDs are in [-2^53, 2^53].
// Readers warn and use MISSING_KEY for invalid IDs. Writers reject invalid IDs.
#include <string>
#include <iostream>
#include "dataio_exports.hpp"
#include "output_stream.hpp"

namespace dbt {
    namespace DataIO {

        inline extern const int DATES_WRITER_CURRENT_MAJOR = 2;
        inline extern const int DATES_WRITER_CURRENT_MINOR = 0;

            /**
         * Write a DATES file in format 2.0.
         *
         * INPUT
         * column_names  Column labels in file order; empty writer input selects default labels.
         * keys  Row keys in [-2^53, 2^53]; an empty writer input selects keys 1:n.
         * times  Date or timestamp strings, optionally followed by alphabetic DST markers.
         * numerics  Numeric table with one record per inner vector.
         * path  Filesystem path.
         * comment  User comment text; newlines separate comment lines.
         * format  Time resolution: -1 for automatic, 1 for dates, 2 for seconds, 3 for milliseconds.
         * overwrite  Permit replacement of an existing file when true.
         * verbose  Select information messages; data warnings can remain active.
         * version_major  Major output format version; the supported value is 2.
         * version_minor  Minor output format version; the supported value is 0.
         *
         * OUTPUT
         * No return value. Creates or replaces the output file according to overwrite.
         * Validation and I/O failures throw; diagnostics use output_stream or the build-specific console.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
             * write_dates(column_names, keys, times, numericals, path);
             * 
             * FUNCTION TO WRITE DATES FORMAT TO A FILE.
             * A file is in "dates format" if it has an optional first row declared as
             * <?dates version="M.m" created_at="YYYY-MM-DD hh:mm:ss"?>
             * and an optional comment block with lines preceeded by "#". Lines that are preceeded by "#" are ignored.
             * 
             * The header section starts the document and it is a block of lines preceeded by "%".
             * The header has to be of the format
             * %    N
             * %    d
             * % Key    Time    Col1    Col2    Col3    ...
             * 
             * where N defines the number of rows, d defines the number of columns (including Key and Time).
             * The first two columns are ALWAYS named Key and Time, containing a unique identifier for each
             * row in the Key column (has to be integral) and a (non-unique) time string in the second column.
             * The time string has to be of the format
             *      YYYY-MM-DD hh:mm:ss ms
             * where hh:mm:ss and ms are optional but if ms is used hh:mm:ss has to be given aswell, i.e.
             * the valid formats are
             *      YYYY-MM-DD
             *      YYYY-MM-DD hh:mm:ss
             *      YYYY-MM-DD hh:mm:ss ms
             * 
             * where ms is a three-digit number and counts the milliseconds.
             * 
             * CAUGHT INPUT ERRORS:
             *      * Extensions: Checks if the ending of the given file is .dts. If not we add ".dts" to the given file (no matter if it exists afterwards).
             *      * Permissions: Creating the directory where the file should be created,
             *              Creating the file itself might not work due to lack of permissions.
             *              In these cases we throw an error.
             *      * Double close of filestream: Internal error; if this ever shows up something is
             *              wrong with the code.
             *      * Overwrite: If overwrite is set to false and the file exists we throw
             *              an existing file error.
             *      * Key: The keys variable can either be an empty array (in which case we just
             *              set it to 1,...,N) or a custom vector of unique values. However if it has non-zero length
             *              not equal to N we throw an error.
             *      * Non-rectangular: If a row does not have d entries we throw an error.
             *      * Time format: If times contains a timestamp which does not match the time format
             *              we throw an error.
             *      * Version: If the version given in the format does not match any given writer version.
             *      * Column name format: Column names can only contain alpha numerical characters aswell as "-" and "_", " " 
             *              and are not allowed to start with a digit.
             * 
             * 
             * INPUT:   column_names:           List of column names to write
             *          keys:                   Key values to write
             *          times:                  Timestamps to write (have to match format)
             *          numerics:               Matrix of numeric values
             *          path:                   Path to the file to read.
             *          comment:                Comment string to write at the beginning of the file
             *          format:                 A integer value indicating the wanted format of the datetimes. 1: YYYY-MM-DD, 2: YYYY-MM-DD hh:mm:ss, 3: YYYY-MM-DD hh:mm:ss.ms or -1 per default, in this case the format is the maximal time resolution in the data
             *          overwrite:              Whether or not overwrite existing files
             *          verbose:                Whether or not warnings and comments should be printed
             *          version_major:          first number of the version
             *          version_minor:          second number of the version
             *
         */
        MYLIB_API void write_dates(std::vector<std::string> column_names, std::vector<Key> keys, std::vector<std::string> times, std::vector<std::vector<double>> numerics, std::string path, std::string comment = "", int format = -1, bool overwrite = true, bool verbose = true, int version_major = DATES_WRITER_CURRENT_MAJOR, int version_minor = DATES_WRITER_CURRENT_MINOR);

        /**
         * Write a DATES file in format 2.0.
         *
         * INPUT
         * column_names  Column labels in file order; empty writer input selects default labels.
         * keys  Row keys in [-2^53, 2^53]; an empty writer input selects keys 1:n.
         * times  Date or timestamp strings, optionally followed by alphabetic DST markers.
         * numerics  Numeric table with one record per inner vector.
         * path  Filesystem path.
         * comment  User comment text; newlines separate comment lines.
         * format  Time resolution: -1 for automatic, 1 for dates, 2 for seconds, 3 for milliseconds.
         * overwrite  Permit replacement of an existing file when true.
         * verbose  Select information messages; data warnings can remain active.
         * version_major  Major output format version; the supported value is 2.
         * version_minor  Minor output format version; the supported value is 0.
         * output_stream  Destination stream for diagnostics.
         *
         * OUTPUT
         * No return value. Creates or replaces the output file according to overwrite.
         * Validation and I/O failures throw; diagnostics use output_stream or the build-specific console.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        MYLIB_API void write_dates(std::vector<std::string> column_names, std::vector<Key> keys, std::vector<std::string> times, std::vector<std::vector<double>> numerics, std::string path, std::string comment = "", int format = -1, bool overwrite = true, bool verbose = true, int version_major = DATES_WRITER_CURRENT_MAJOR, int version_minor = DATES_WRITER_CURRENT_MINOR, std::ostream& output_stream = default_output_stream());
    }
}

#endif