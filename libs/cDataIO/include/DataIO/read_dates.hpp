/***********************************************************************************************
 * 
 * Function declarations for read_dates.
 * 
 * AUTHOR: JULIAN MÄRTE
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 * 
 ***********************************************************************************************/


#ifndef __DBT_DATA_IO_READ_DATES_HPP__
#define __DBT_DATA_IO_READ_DATES_HPP__


#include <tuple>
#include <vector>
#include "key.hpp"

// Key is a signed 64-bit integer. Valid IDs are in [-2^53, 2^53].
// Readers warn and use MISSING_KEY for invalid IDs. Writers reject invalid IDs.
#include <string>
#include <iostream>
#include "dataio_exports.hpp"

namespace dbt {
    namespace DataIO {
        const bool DEBUG_READ_DATES = false;
		/**
         * Read a DATES file through the shared core.
         *
         * INPUT
         * path  Filesystem path.
         * verbose  Select information messages; data warnings can remain active.
         *
         * OUTPUT
         * Tuple: labels, keys, DST markers, timestamp strings, numeric columns, comments, time zone.
         * Numeric data uses one vector per column. Missing keys use MISSING_KEY.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * @brief Read a DATES file and return its contents.
         * @param path Path to the input file. The reader accepts .dts and .csv files.
         * @param verbose Enable information messages and optional diagnostics.
         * Data warnings can occur when verbose is false.
         * @param output_stream Destination for information messages and warnings.
         *
         * @return A tuple with these seven elements, in this order:
         * - Column names: std::vector<std::string>, without the optional TZ_DST column name.
         * - Keys: std::vector<Key>, with one value per data row.
         * - DST markers: std::vector<std::string>, with one value per row if TZ_DST exists.
         *   Without TZ_DST, this vector is empty.
         * - Times: std::vector<std::string>, with one date or timestamp per row.
         * - Numeric columns: std::vector<std::vector<double>>.
         *   Each inner vector contains one column, with one value per row.
         * - Comment: std::string, without the format tag or the time zone declaration.
         * - Time zone: std::string. The default is UTC.
         *
         * @details
         * The optional format tag and comments are before the header.
         * The header gives the row count, column count, and column names.
         * The first two columns must be Key and Time.
         * The optional TZ_DST column must follow Time.
         * The column count includes Key, Time, TZ_DST, and all numeric columns.
         *
         * Dates use YYYY-MM-DD.
         * Timestamps use YYYY-MM-DD hh:mm:ss or YYYY-MM-DD hh:mm:ss.ms.
         * The core returns time text without time zone conversion.
         * A missing time field becomes the text NA.
         *
         * If a key is missing or outside the permitted range, the reader uses MISSING_KEY.
         * The reader keeps the row and gives a warning.
         * A numeric prefix can supply a key or numeric value.
         * The reader gives a warning for additional text after that prefix.
         *
         * Empty numeric fields and the markers NA and NaN become NaN values.
         * Other numeric fields that the reader cannot convert become NaN values with a warning.
         * If the header row count differs from the actual count, the reader keeps the actual rows and gives a warning.
         * Short rows receive missing values. Additional fields do not add columns.
         *
         * @throws std::invalid_argument if the reader cannot open the file or the header or time text is not valid.
         * Header errors include incorrect column names, inconsistent column counts, and an incorrect TZ_DST position.
         * Numeric conversion can also throw std::out_of_range for header counts.
         *
         * @see helpers.hpp
         * @see read_dates.cpp
         */
        MYLIB_API std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::string>, std::vector<std::string>, std::vector<std::vector<double>>, std::string, std::string> read_dates(std::string path, bool verbose = true);

        /**
         * Read a DATES file through the shared core.
         *
         * INPUT
         * path  Filesystem path.
         * verbose  Select information messages; data warnings can remain active.
         * output_stream  Destination stream for diagnostics.
         *
         * OUTPUT
         * Tuple: labels, keys, DST markers, timestamp strings, numeric columns, comments, time zone.
         * Numeric data uses one vector per column. Missing keys use MISSING_KEY.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        MYLIB_API std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::string>, std::vector<std::string>, std::vector<std::vector<double>>, std::string, std::string> read_dates(std::string path, bool verbose = true, std::ostream& output_stream = std::cout);
    }
}

#endif
