// OUTPUT
// Rcpp interfaces for the C++ readers and writers.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.

#include "Rcpp.h"

// Initialize the Rcpp module registration.
// INPUT
// None. Rcpp supplies the module initialization context.
// OUTPUT
// Registers the empty DataIOModule; exported functions use Rcpp attributes.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
RCPP_MODULE(DataIOModule) {}

#include "DataIO/read_dates.hpp"
#include "DataIO/write_dates.hpp"
#include "DataIO/read_lrn.hpp"
#include "DataIO/write_lrn.hpp"
#include "DataIO/write_names.hpp"
#include "DataIO/read_names.hpp"
#include "DataIO/write_cls.hpp"
#include "DataIO/read_cls.hpp"
#include "DataIO/helpers.hpp"
#include "DataIO/the_same_key.hpp"



#include <exception>
#include <regex>
#include <vector>
#include <utility>
#include <sstream>
#include <iostream>
#include <cmath>
#include <algorithm>
//#include <set>



// INPUT: an R string with an optional explicit Latin-1 encoding marker.
// OUTPUT: UTF-8 bytes; unmarked bytes are assumed to be UTF-8.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
static std::string utf8_from_r(SEXP value) {
    if (value == NA_STRING) return "NA";
    if (Rf_getCharCE(value) == CE_LATIN1) return Rf_translateCharUTF8(value);
    return std::string(CHAR(value), LENGTH(value));
}
static std::vector<std::string> utf8_from_r(const Rcpp::CharacterVector& values) {
    std::vector<std::string> result; result.reserve(values.size());
    for (R_xlen_t i = 0; i < values.size(); ++i) result.push_back(utf8_from_r(STRING_ELT(values, i)));
    return result;
}
// INPUT: validated core UTF-8. OUTPUT: explicitly marked R UTF-8 strings.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
static Rcpp::String utf8_to_r(const std::string& value) {
    return Rcpp::String(Rf_mkCharLenCE(value.data(), value.size(), CE_UTF8));
}
static Rcpp::CharacterVector utf8_to_r(const std::vector<std::string>& values) {
    Rcpp::CharacterVector result(values.size());
    for (size_t i = 0; i < values.size(); ++i)
        SET_STRING_ELT(result, i, Rf_mkCharLenCE(values[i].data(), values[i].size(), CE_UTF8));
    return result;
}
// INPUT: native diagnostics. OUTPUT: encoding warnings as R conditions; other output is preserved.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
static void text_messages(const std::string& messages) {
    std::istringstream input(messages);
    for (std::string line; std::getline(input, line);) {
        if (line.starts_with("WARNING: Converted input") || line.starts_with("WARNING: Replaced "))
            Rcpp::warning("%s", line.substr(9).c_str());
        else Rcpp::Rcout << line << std::endl;
    }
}

// IntegerVector truncated large keys. Convert from R numeric values only after checks.
// bit64 stores bits in doubles; it must not be treated as an ordinary numeric vector.
/**
 * Validate R keys before conversion to signed 64-bit integers.
 *
 * INPUT
 * input  NULL or an ordinary numeric/integer vector; factors and integer64 are rejected.
 *
 * OUTPUT
 * Key vector in [-2^53, 2^53]; NULL gives an empty vector. Invalid keys raise an R error.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
static std::vector<dbt::DataIO::Key> keys_from_r(SEXP input) {
    if (Rf_isNull(input)) return {};
    if ((TYPEOF(input) != INTSXP && TYPEOF(input) != REALSXP) ||
        Rf_inherits(input, "factor") || Rf_inherits(input, "integer64"))
        Rcpp::stop("Key must be an ordinary numeric or integer vector of whole numbers in +/-2^53.");
    const Rcpp::NumericVector values = Rcpp::as<Rcpp::NumericVector>(input);
    std::vector<dbt::DataIO::Key> keys;
    keys.reserve(values.size());
    for (double value : values) {
        if (!std::isfinite(value) || std::trunc(value) != value ||
            value < -dbt::DataIO::MAX_EXACT_KEY || value > dbt::DataIO::MAX_EXACT_KEY)
            Rcpp::stop("Key must contain finite whole numbers between -2^53 and 2^53.");
        keys.push_back(static_cast<dbt::DataIO::Key>(value));
    }
    return keys;
}

// Use R doubles for all keys. Map the separate missing marker to NA_REAL.
/**
 * Convert core keys to R numeric values.
 *
 * INPUT
 * keys  Core key vector, possibly containing MISSING_KEY.
 *
 * OUTPUT
 * R NumericVector; MISSING_KEY becomes NA_REAL.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
static Rcpp::NumericVector keys_to_r(const std::vector<dbt::DataIO::Key>& keys) {
    Rcpp::NumericVector result(keys.size());
    for (size_t i = 0; i < keys.size(); ++i)
        result[i] = keys[i] == dbt::DataIO::MISSING_KEY ? NA_REAL : static_cast<double>(keys[i]);
    return result;
}

// Compare R numeric vectors through the common core.
// INPUT
// key_a, key_b: ordinary real numeric or logical vectors; NULL is empty.
// OUTPUT
// One bool. Unsupported types or dimensions give false; no input is changed.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
// [[Rcpp::export]]
bool the_same_key(SEXP key_a, SEXP key_b) {
    for (SEXP value : {key_a, key_b}) {
        if (!Rf_isNull(value) &&
            ((TYPEOF(value) != INTSXP && TYPEOF(value) != REALSXP && TYPEOF(value) != LGLSXP)
             || Rf_isObject(value) || !Rf_isNull(Rf_getAttrib(value, R_DimSymbol))))
            return false;
    }
    const auto convert = [](SEXP value) {
        if (Rf_isNull(value)) return std::vector<double>{};
        return Rcpp::as<std::vector<double>>(Rcpp::as<Rcpp::NumericVector>(value));
    };
    return dbt::DataIO::the_same_key(convert(key_a), convert(key_b));
}

/*************************
 *
 *  DATES
 *
 *************************/

// Wrapper for C++ read_dates function in cDataIO library
//' @param path(string) Path to the file to read.
//' @param verbose(bool) Enable information messages. Data warnings can occur when false.
//' @return List object with entries "Key" (numeric vector of exact integers), "Time" (character vector), "Data" (numeric matrix), "Header" (character vector), "Comments" (optional string) and "Timezone" (string)

/**
 * Convert R arguments and call the shared DATES reader.
 *
 * INPUT
 * path  Filesystem path.
 * verbose  Select information messages; data warnings can remain active.
 * encoding  Optional source encoding; empty selects a BOM, otherwise UTF-8.
 * keys  NULL or ordinary numeric/integer keys in [-2^53, 2^53].
 * header  Optional character labels; NULL selects defaults.
 * types  Optional integer type codes; NULL selects defaults.
 * df  R data frame with one record per row.
 * data  R data frame with a Time column or times in its first column.
 * texts_df  Optional data frame of additional text columns.
 *
 * OUTPUT
 * R list with Key, Time, and Timezone; optional Data, Header, DST, and Comments.
 * Data is a row-oriented numeric matrix. Missing keys are NA.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
// [[Rcpp::export]]
Rcpp::List read_dates(std::string path, bool verbose = true, std::string encoding = "") {
    std::tuple<std::vector<std::string>, std::vector<dbt::DataIO::Key>, std::vector<std::string>, std::vector<std::string>, std::vector<std::vector<double>>, std::string, std::string> res = {};
    try {
        std::ostringstream output_stream;
        res = dbt::DataIO::read_dates(path, verbose, output_stream, encoding);
        text_messages(output_stream.str());
    }
    catch (const std::exception& e) {
        Rcpp::stop("Exception occoured when reading " + dbt::DataIO::get_filename(path) + ". " + std::string(e.what()));
    }

    // Reference the owned tuple until R conversion finishes; avoid full-data copies.
    const auto& _col_names = std::get<0>(res);
    const auto& _key = std::get<1>(res);
    const auto& _dst = std::get<2>(res);
    const auto& _times = std::get<3>(res);
    const auto& _numerics = std::get<4>(res);
    const auto& comment = std::get<5>(res);
    const auto& timezone = std::get<6>(res);

    if (dbt::DataIO::DEBUG_READ_DATES) {
        Rcpp::Rcout << "DEBUG: Result of Data on the Rcpp level (10 rows): " << std::endl;
        for (const auto& col : _numerics) {
            for (int i = 0; i < 10 && i < col.size(); i++) {
                Rcpp::Rcout << col[i] << " ";
            }
            Rcpp::Rcout << std::endl;
        }
    }

    Rcpp::CharacterVector col_names;
    Rcpp::NumericVector key;
    Rcpp::CharacterVector times;

    times = utf8_to_r(_times);
	
    col_names = utf8_to_r(_col_names);
    key = keys_to_r(_key);

    Rcpp::List res_list = Rcpp::List::create(Rcpp::Named("Key") = key, Rcpp::Named("Time") = times);

	std::vector<std::string> _further_col_names;

    if (_col_names.size() > 2) {
        _further_col_names = std::vector<std::string>(_col_names.begin() + 2, _col_names.end());

        Rcpp::NumericMatrix numerics(_numerics[0].size(), _further_col_names.size());
        for (unsigned int i = 0; i < _further_col_names.size(); i++) {
            for (unsigned int j = 0; j < _numerics[0].size(); j++) {
                numerics(j, i) = _numerics[i][j];
            }
        }
        if (_numerics.size() != _further_col_names.size()) {
            throw std::invalid_argument("The number of data columns does not match the number of data column names!");
        }
        Rcpp::colnames(numerics) = utf8_to_r(_further_col_names);
        res_list["Data"] = numerics;
        res_list["Header"] = _further_col_names;
    }



    if (!comment.empty()) {
        res_list["Comments"] = utf8_to_r(comment);
    }
    res_list["Timezone"] = utf8_to_r(timezone);
    if (!_dst.empty()) {
        res_list["DST"] = utf8_to_r(_dst);
    }


    return res_list;
}


//' Wrapper for C++ write_dates function in cDataIO library
//' @param path(string) Path of file to write data to
//' @param data(dataframe) A dataframe with either the first columns being dates/datetimes or a column named "Time" with dates/datetimes. Rest should be numeric data
//' @param key(vector) A numeric vector of unique whole numbers in +/-2^53. NULL generates keys
//' @param format(int) Integer value indicating the format of the date/datetime values (see R or C++ documentation)
//' @param comment(string) (Optional) Character vector to write as a comment for the file.
//' @param overwrite(bool) (Optional) Whether or not to write data if the file already exists (potentially overwriting other contents).
//' @param verbose(bool) (Optional) Enable information messages. Data warnings can occur when false.
//' @param version_major(int) (Optional) Version major of the writer
//' @param version_minor(int) (Optional) Version minor of the writer

/**
 * Convert R arguments and call the shared DATES writer.
 *
 * INPUT
 * path  Filesystem path.
 * data  R data frame with a Time column or times in its first column.
 * keys  NULL or ordinary numeric/integer keys in [-2^53, 2^53].
 * format  Time resolution: -1 for automatic, 1 for dates, 2 for seconds, 3 for milliseconds.
 * comment  User comment text; newlines separate comment lines.
 * overwrite  Permit replacement of an existing file when true.
 * verbose  Select information messages; data warnings can remain active.
 * version_major  Major output format version; the supported value is 2.
 * version_minor  Minor output format version; the supported value is 0.
 * header  Optional character labels; NULL selects defaults.
 * types  Optional integer type codes; NULL selects defaults.
 * df  R data frame with one record per row.
 * texts_df  Optional data frame of additional text columns.
 *
 * OUTPUT
 * No C++ return value; R receives NULL. Writes the file through the shared core.
 * Core exceptions are translated to R errors; diagnostics use Rcpp::Rcout.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
// [[Rcpp::export]]
void write_dates(Rcpp::String path, Rcpp::DataFrame data, SEXP keys, int format, Rcpp::String comment = "", bool overwrite = 1, bool verbose = 1, int version_major = 2, int version_minor = 0) {

    std::string _path(path.get_cstring());
    std::string _comment = utf8_from_r(comment.get_sexp());

    Rcpp::CharacterVector names = data.names();
    std::vector<std::string> col_names;
    Rcpp::CharacterVector time_strings;
    Rcpp::CharacterVector dst_strings;

    // Get time column, dst and column names.
    bool time_col = false;
    bool has_dst_info = false;
    int time_col_ind = 0;
    int dst_col_ind = 0;
    for (unsigned int i = 0; i < names.length(); i++) {
        std::string name = utf8_from_r(STRING_ELT(names, i));
        if(name == "Time") {
            time_col = true;
            time_col_ind = i;
        } else if (name == "DST") {
            has_dst_info = true;
            dst_col_ind = i;
        } else {
            col_names.push_back(utf8_from_r(STRING_ELT(names, i)));
        }
    }

    if(time_col) {
        time_strings = data["Time"];
        data.erase(time_col_ind);
    } else {
        try {
            time_strings = data[0];
        } catch (const std::exception& e) {
            Rcpp::stop("Exception occoured when writting " + dbt::DataIO::get_filename(path) + ". Could not parse time column");
        }
        data.erase(0);
        col_names.erase(col_names.begin());
    }

    std::vector<std::string> times;
    times.reserve(time_strings.length());
    times = utf8_from_r(time_strings);

    if (has_dst_info) {
        dst_strings = data["DST"];
        std::vector<std::string> dst;
        dst.reserve(dst_strings.length());
        dst = utf8_from_r(dst_strings);

        if (times.size() != dst.size()) {
            Rcpp::stop("Exception occoured when writting " + dbt::DataIO::get_filename(path) + ". Times and DST have to be the same length");
        }

        // Iterate over the vectors and concatenate each pair of strings
        for (size_t i = 0; i < times.size(); ++i) {
            times[i] += " " + dst[i];
        }

        // dst_col_ind-1 because we already erased the time column        
        data.erase(dst_col_ind - 1);
    }


    // Cast times and keys
    std::vector<dbt::DataIO::Key> key;

    // Check if input for keys was given
    key = keys_from_r(keys); 


    // Parse numeric data
    std::vector<std::vector<double>> numerics;
    numerics.reserve(time_strings.length());
    std::vector<Rcpp::NumericVector> vecs;

    for (unsigned int i = 0; i < col_names.size(); i++) {        
        if (Rcpp::is<Rcpp::NumericVector>(data[i]) || Rcpp::is<Rcpp::IntegerVector>(data[i])) {
            vecs.push_back(Rcpp::as<Rcpp::NumericVector>(data[i]));
        } else {
            Rcpp::stop("Exception occoured when writting " + dbt::DataIO::get_filename(path) + ". Non numeric data in data frame");
        }
    }

    for (unsigned int i = 0; i < times.size(); i++) {
        std::vector<double> row;
        row.reserve(col_names.size());

        for (unsigned int j = 0; j < col_names.size(); j++) {
            row.push_back(static_cast<double>(vecs[j][i]));
        }
        // Transfer the completed row instead of allocating and copying it again.
        numerics.push_back(std::move(row));
    }

    std::ostream& output_stream = Rcpp::Rcout;

    try {
        // Transfer converted data to the writer; retaining a second copy is unnecessary.
        dbt::DataIO::write_dates(std::move(col_names), std::move(key), std::move(times), std::move(numerics), _path, _comment, format, overwrite, verbose, version_major, version_minor, output_stream);
    } catch (const std::exception& e) {
        Rcpp::stop("Exception occoured when writting " + dbt::DataIO::get_filename(path) + ". " + std::string(e.what()));
    }
}



/*************************
 *
 *  LRN
 *
 *************************/

//' Wrapper for C++ read_lrn function in cDataIO library
//' @param path(string) Path to the file to read.
//' @param verbose(bool) Enable information messages. Data warnings can occur when false.
//' @return List object with entries "Key" (numeric vector of exact integers), "Data" (numeric matrix), "Header" (character vector), "DataDefined" (integer vector) and "Comments" (optional string)

/**
 * Convert R arguments and call the shared LRN reader.
 *
 * INPUT
 * path  Filesystem path.
 * verbose  Select information messages; data warnings can remain active.
 * encoding  Optional source encoding; empty selects a BOM, otherwise UTF-8.
 * keys  NULL or ordinary numeric/integer keys in [-2^53, 2^53].
 * header  Optional character labels; NULL selects defaults.
 * types  Optional integer type codes; NULL selects defaults.
 * df  R data frame with one record per row.
 * data  R data frame with a Time column or times in its first column.
 * texts_df  Optional data frame of additional text columns.
 *
 * OUTPUT
 * R list with Key, Data, Header, DataDefined, and optional Comments.
 * Data is a row-oriented numeric matrix. Missing keys are NA.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
// [[Rcpp::export]]
Rcpp::List read_lrn(std::string path, bool verbose = true, std::string encoding = "") {
    std::tuple<std::vector<std::string>, std::vector<dbt::DataIO::Key>, std::vector<std::vector<double>>, std::vector<int>, std::string> res = {};
    try {
        std::ostringstream output_stream;
        res = dbt::DataIO::read_lrn(path, verbose, output_stream, encoding);
        text_messages(output_stream.str());
    }
    catch (const std::exception& e) {
        Rcpp::stop("Exception occoured when reading " + dbt::DataIO::get_filename(path) + ". " + std::string(e.what()));
    }

    // Reference the owned tuple until R conversion finishes; avoid full-data copies.
    const auto& _col_names = std::get<0>(res);
    const auto& _key = std::get<1>(res);
    const auto& _numerics = std::get<2>(res);
    const auto& _types = std::get<3>(res);
    const auto& _comments = std::get<4>(res);


    Rcpp::CharacterVector col_names;
    Rcpp::NumericVector key;
    Rcpp::IntegerVector types(_types.size());

    col_names = utf8_to_r(_col_names);
    types = Rcpp::wrap(_types);
    key = keys_to_r(_key);

    Rcpp::List res_list = Rcpp::List::create(Rcpp::Named("Key") = key);
    
    
    Rcpp::NumericMatrix m_numerics(_numerics.size(), _col_names.size());

    for (unsigned int i = 0; i < _col_names.size(); i++) {
        for (unsigned int j = 0; j < _numerics.size(); j++) {
            m_numerics(j, i) = _numerics[j][i];
        }
    }
    Rcpp::colnames(m_numerics) = utf8_to_r(_col_names);

    res_list["Data"] = m_numerics;
    res_list["Header"] = col_names;
    res_list["DataDefined"] = types;
    if (!_comments.empty()) {
        res_list["Comments"] = _comments;
    }

    return res_list;
}


//' Wrapper for C++ write_lrn function in cDataIO library
//' @param df(Dataframe) A dataframe with numeric data
//' @param header(vector) A character vector with column names. Can be NULL, then column names will be autogenerated
//' @param key(vector) A numeric vector of unique whole numbers in +/-2^53. NULL generates keys
//' @param types(vector) A integer vector with type values for columns (see R documentation). Can be NULL, then types will be autogenerated
//' @param path(string) Path of file to write data to
//' @param comment(string) (Optional) Character vector to write as a comment for the file.
//' @param significant_digits(int) (Optional) Number of significant digits to be used, takes precedence over decimal_digits
//' @param decimal_digits(int) (Optional) Number of digits behind the decimal place to be used
//' @param overwrite(bool) (Optional) Whether or not to write data if the file already exists (potentially overwriting other contents).
//' @param verbose(bool) (Optional) Enable information messages. Data warnings can occur when false.
//' @param version_major(int) (Optional) Version major of the writer
//' @param version_minor(int) (Optional) Version minor of the writer

/**
 * Convert R arguments and call the shared LRN writer.
 *
 * INPUT
 * df  R data frame with one record per row.
 * header  Optional character labels; NULL selects defaults.
 * keys  NULL or ordinary numeric/integer keys in [-2^53, 2^53].
 * types  Optional integer type codes; NULL selects defaults.
 * path  Filesystem path.
 * comment  User comment text; newlines separate comment lines.
 * significant_digits  Positive significant-digit limit, or -1 for no such limit.
 * decimal_digits  Decimal-place limit, or -1 for no limit; significant_digits takes precedence.
 * scientific  Select scientific notation when true.
 * overwrite  Permit replacement of an existing file when true.
 * verbose  Select information messages; data warnings can remain active.
 * version_major  Major output format version; the supported value is 2.
 * version_minor  Minor output format version; the supported value is 0.
 * data  R data frame with a Time column or times in its first column.
 * texts_df  Optional data frame of additional text columns.
 *
 * OUTPUT
 * No C++ return value; R receives NULL. Writes the file through the shared core.
 * Core exceptions are translated to R errors; diagnostics use Rcpp::Rcout.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
// [[Rcpp::export]]
void write_lrn(Rcpp::DataFrame df, Rcpp::Nullable<Rcpp::CharacterVector> header, SEXP keys, Rcpp::Nullable<Rcpp::IntegerVector> types, Rcpp::String path, Rcpp::String comment, int significant_digits, int decimal_digits, bool scientific, bool overwrite = true, bool verbose = true, int version_major = 2, int version_minor = 0) {

    std::string _path(path.get_cstring());
    std::string _comment = utf8_from_r(comment.get_sexp());

    std::vector<dbt::DataIO::Key> key;
    std::vector<int> _types;
    std::vector<std::string> _header;

    if (types.isNotNull()) {
        Rcpp::IntegerVector type_tmp;
        type_tmp = types;
        _types.reserve(type_tmp.length());
        _types = Rcpp::as<std::vector<int>>(type_tmp);
    }

    key = keys_from_r(keys);


    if (header.isNotNull()) {
        Rcpp::CharacterVector header_tmp;
        header_tmp = header;
        _header.reserve(header_tmp.length());
        _header = utf8_from_r(header_tmp);
    }

    unsigned int n = df.nrows();
    std::vector<std::vector<double>> numerics;
    numerics.reserve(n);
    std::vector<Rcpp::NumericVector> vecs;

    for (unsigned int j = 0; j < df.size(); j++) {
        vecs.push_back(df[j]);
    }

    for (unsigned int i = 0; i < n; i++) {
        std::vector<double> row;
        row.reserve(df.size());

        for (unsigned int j = 0; j < df.size(); j++) {
            row.push_back(static_cast<double>(vecs[j][i]));
        }
        // Transfer the completed row instead of allocating and copying it again.
        numerics.push_back(std::move(row));
    }

    std::ostream& output_stream = Rcpp::Rcout;

    try {
        // Transfer converted data to the writer; retaining a second copy is unnecessary.
        dbt::DataIO::write_lrn(std::move(_header), std::move(key), std::move(numerics), std::move(_types), _path, _comment, significant_digits, decimal_digits, scientific, overwrite, verbose, version_major, version_minor, output_stream);
    } catch (const std::exception& e) {
        Rcpp::stop("Exception occoured when writting " + dbt::DataIO::get_filename(path) + ". " + std::string(e.what()));
    }

}


/*************************
 *
 *  NAMES
 *
 *************************/

//' Wrapper for C++ read_names function in cDataIO library
//' @param path(string) Path to the file to read.
//' @param verbose(bool) Enable information messages. Data warnings can occur when false.
//' @return List object with entries "Key" (numeric vector of exact integers), "Names" (character vector), "FurtherTexts" (character matrix), "Header" (character vector) and "Comments" (optional string)

/**
 * Convert R arguments and call the shared NAMES reader.
 *
 * INPUT
 * path  Filesystem path.
 * verbose  Select information messages; data warnings can remain active.
 * encoding  Optional source encoding; empty selects a BOM, otherwise UTF-8.
 * keys  NULL or ordinary numeric/integer keys in [-2^53, 2^53].
 * header  Optional character labels; NULL selects defaults.
 * types  Optional integer type codes; NULL selects defaults.
 * df  R data frame with one record per row.
 * data  R data frame with a Time column or times in its first column.
 * texts_df  Optional data frame of additional text columns.
 *
 * OUTPUT
 * R list with Key and Names; optional FurtherTexts, Header, and Comments.
 * FurtherTexts is a character matrix with records in rows. Missing keys are NA.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
// [[Rcpp::export]]
Rcpp::List read_names(std::string path, bool verbose = true, std::string encoding = "") {
    std::tuple<std::vector<std::string>, std::vector<dbt::DataIO::Key>, std::vector<std::string>, std::vector<std::vector<std::string>>, std::string> res = {};
    try {
        std::ostringstream output_stream;
        res = dbt::DataIO::read_names(path, verbose, output_stream, encoding);
        text_messages(output_stream.str());
    }
    catch (const std::exception& e) {
        Rcpp::stop("Exception occoured when reading " + dbt::DataIO::get_filename(path) + ". " + std::string(e.what()));
    }

    
    // Reference the owned tuple until R conversion finishes; avoid full-data copies.
    const auto& _col_names = std::get<0>(res);
    const auto& _key = std::get<1>(res);
    const auto& _names = std::get<2>(res);
    const auto& _further_texts = std::get<3>(res);
    const auto& comment = std::get<4>(res);


    Rcpp::CharacterVector col_names = utf8_to_r(_col_names);
    Rcpp::CharacterVector names = utf8_to_r(_names);
    // Missing text fields are returned as R NA, not the literal marker "NA".
    for (R_xlen_t i = 0; i < names.size(); ++i)
        if (_names[i] == "NA") names[i] = NA_STRING;
    Rcpp::NumericVector key = keys_to_r(_key);

    Rcpp::List res_list = Rcpp::List::create(Rcpp::Named("Key") = key, Rcpp::Named("Names") = names);

	std::vector<std::string> _further_col_names;

	if (_col_names.size() > 2) {
		_further_col_names = std::vector<std::string>(_col_names.begin() + 2, _col_names.end());

        Rcpp::CharacterMatrix ftexts_m(_further_texts[0].size(), _further_col_names.size());
        for (unsigned int i = 0; i < _further_col_names.size(); i++) {


            for (unsigned int j = 0; j < _further_texts[0].size(); j++) {
                // Preserve missing text as R NA when filling repaired rows.
                if (_further_texts[i][j] == "NA") ftexts_m(j, i) = NA_STRING;
                else SET_STRING_ELT(ftexts_m, j + i * ftexts_m.nrow(),
                    Rf_mkCharLenCE(_further_texts[i][j].data(), _further_texts[i][j].size(), CE_UTF8));
            }
        }
        Rcpp::colnames(ftexts_m) = utf8_to_r(_further_col_names);
        res_list["FurtherTexts"] = ftexts_m;
        res_list["Header"] = utf8_to_r(_further_col_names);
    }
    //res_list["Header"] = Rcpp::wrap(_col_names.begin() + 1, _col_names.end());

    if(!comment.empty()) {
        res_list["Comments"] = utf8_to_r(comment);
    }

    return res_list;

}



//' Wrapper for C++ write_names function in cDataIO library
//' @param names(vector) A character vector with the values for names
//' @param texts_df(dataframe) A dataframe for additional columns. Can be NULL
//' @param key(vector) A numeric vector of unique whole numbers in +/-2^53. NULL generates keys
//' @param header(vector) A character vector with column names. Can be NULL, then column names will be autogenerated
//' @param path(string) Path of file to write data to
//' @param comment(string) (Optional) Character vector to write as a comment for the file.
//' @param overwrite(bool) (Optional) Whether or not to write data if the file already exists (potentially overwriting other contents).
//' @param verbose(bool) (Optional) Enable information messages. Data warnings can occur when false.
//' @param version_major(int) (Optional) Version major of the writer
//' @param version_minor(int) (Optional) Version minor of the writer

/**
 * Convert R arguments and call the shared NAMES writer.
 *
 * INPUT
 * names  One name string per record.
 * texts_df  Optional data frame of additional text columns.
 * header  Optional character labels; NULL selects defaults.
 * keys  NULL or ordinary numeric/integer keys in [-2^53, 2^53].
 * path  Filesystem path.
 * comment  User comment text; newlines separate comment lines.
 * overwrite  Permit replacement of an existing file when true.
 * verbose  Select information messages; data warnings can remain active.
 * version_major  Major output format version; the supported value is 2.
 * version_minor  Minor output format version; the supported value is 0.
 * replacement  Optional nonempty field replacement; default one underscore.
 * types  Optional integer type codes; NULL selects defaults.
 * df  R data frame with one record per row.
 * data  R data frame with a Time column or times in its first column.
 *
 * OUTPUT
 * No C++ return value; R receives NULL. Writes the file through the shared core.
 * Core exceptions are translated to R errors; diagnostics use Rcpp::Rcout.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
// [[Rcpp::export]]
void write_names(Rcpp::CharacterVector names, Rcpp::Nullable<Rcpp::DataFrame> texts_df, Rcpp::Nullable<Rcpp::CharacterVector> header, SEXP keys, Rcpp::String path, Rcpp::String comment, bool overwrite = true, bool verbose = true, int version_major = 2, int version_minor = 0, Rcpp::String replacement = "_") {

    std::string _path(path.get_cstring());
    std::string _comment = utf8_from_r(comment.get_sexp());

    std::vector<dbt::DataIO::Key> key;
    std::vector<std::string> _header;
    std::vector<std::string> _names;
    std::vector<std::vector<std::string>> futher_texts;


    key = keys_from_r(keys);


    if (header.isNotNull()) {
        Rcpp::CharacterVector header_tmp;
        header_tmp = header;
        _header.reserve(header_tmp.length());
        _header = utf8_from_r(header_tmp);
    }

    _names = utf8_from_r(names);

    if (texts_df.isNotNull()) {
        Rcpp::DataFrame texts_df_tmp;
        texts_df_tmp = texts_df;
        unsigned int n = texts_df_tmp.nrows();
        futher_texts.reserve(n);
        std::vector<Rcpp::CharacterVector> vecs;

        for (unsigned int i = 0; i < texts_df_tmp.size(); i++) {
            vecs.push_back(texts_df_tmp[i]);
        }

        for (unsigned int i = 0; i < n; i++) {
            std::vector<std::string> row;
            row.reserve(texts_df_tmp.size());

            for (unsigned int j = 0; j < texts_df_tmp.size(); j++) {
                row.push_back(utf8_from_r(STRING_ELT(vecs[j], i)));
            }
            // Transfer the completed row instead of allocating and copying it again.
            futher_texts.push_back(std::move(row));
        }
    }

    std::ostringstream output_stream;

    try {
        // Transfer converted data to the writer; retaining a second copy is unnecessary.
        dbt::DataIO::write_names(std::move(_names), std::move(_header), std::move(key), std::move(futher_texts), _path, _comment, overwrite, verbose, version_major, version_minor, output_stream, utf8_from_r(replacement.get_sexp()));
        text_messages(output_stream.str());
    }
    catch (const std::exception& e) {
        Rcpp::stop("Exception occoured when writting " + dbt::DataIO::get_filename(path) + ". " + std::string(e.what()));
    }

}

/*************************
 *
 *  CLS
 *
 *************************/

//' Wrapper for C++ write_cls function in cDataIO library
//' @param cls(vector) A integer vector with the values for cls, can contain NaN values
//' @param key(vector) A numeric vector of unique whole numbers in +/-2^53. NULL generates keys
//' @param nan_replacement(double) A value for NaN replacement in cls. Should be a integer or NaN. (Double just allowed for the NaN case).
//' @param path(string) Path of file to write data to
//' @param comment(string) (Optional) Character vector to write as a comment for the file.
//' @param overwrite(bool) (Optional) Whether or not to write data if the file already exists (potentially overwriting other contents).
//' @param verbose(bool) (Optional) Enable information messages. Data warnings can occur when false.
//' @param version_major(int) (Optional) Version major of the writer
//' @param version_minor(int) (Optional) Version minor of the writer

/**
 * Convert R arguments and call the shared CLS writer.
 *
 * INPUT
 * cls  One numeric class value per record.
 * keys  NULL or ordinary numeric/integer keys in [-2^53, 2^53].
 * nan_replacement  Replacement for missing classes; NaN preserves the missing-value marker.
 * path  Filesystem path.
 * comment  User comment text; newlines separate comment lines.
 * overwrite  Permit replacement of an existing file when true.
 * verbose  Select information messages; data warnings can remain active.
 * version_major  Major output format version; the supported value is 2.
 * version_minor  Minor output format version; the supported value is 0.
 * header  Optional character labels; NULL selects defaults.
 * types  Optional integer type codes; NULL selects defaults.
 * df  R data frame with one record per row.
 * data  R data frame with a Time column or times in its first column.
 * texts_df  Optional data frame of additional text columns.
 *
 * OUTPUT
 * No C++ return value; R receives NULL. Writes the file through the shared core.
 * Core exceptions are translated to R errors; diagnostics use Rcpp::Rcout.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
// [[Rcpp::export]]
void write_cls(Rcpp::NumericVector cls, SEXP keys, double nan_replacement, Rcpp::String path, Rcpp::String comment, bool overwrite = true, bool verbose = true, int version_major = 2, int version_minor = 0) {
    std::string _path(path.get_cstring());
    std::string _comment = utf8_from_r(comment.get_sexp());

    std::vector<dbt::DataIO::Key> key;

    // cls is here given as numeric vector and then kept as double, because integer vectors cannot keep NaN values. The values are later coerced into integer values. Similiar for nan_replacement, instead of a null
    // value it will get a NaN value if not used (because in Rcpp ints are not nullable, which leads to incorrect behaviour)
    std::vector<double> _cls;

    key = keys_from_r(keys);

    _cls = Rcpp::as<std::vector<double>>(cls);

    std::ostream& output_stream = Rcpp::Rcout;

    try {
        // Transfer converted data to the writer; retaining a second copy is unnecessary.
        dbt::DataIO::write_cls(std::move(key), std::move(_cls), nan_replacement, path, _comment, overwrite, verbose, version_major, version_minor, output_stream);
    }
    catch (const std::exception& e) {
        Rcpp::stop("Exception occoured when writting " + dbt::DataIO::get_filename(path) + ". " + std::string(e.what()));
    }

}



// Wrapper for C++ read_cls function in cDataIO library
//' @param path(string) Path to the file to read.
//' @param verbose(bool) Enable information messages. Data warnings can occur when false.
//' @return List object with entries "Key" (numeric vector of exact integers), "Cls" (integer vector), "UniqueClasses" (integer vector) and "Comments" (optional string)

/**
 * Convert R arguments and call the shared CLS reader.
 *
 * INPUT
 * path  Filesystem path.
 * verbose  Select information messages; data warnings can remain active.
 * encoding  Optional source encoding; empty selects a BOM, otherwise UTF-8.
 * keys  NULL or ordinary numeric/integer keys in [-2^53, 2^53].
 * header  Optional character labels; NULL selects defaults.
 * types  Optional integer type codes; NULL selects defaults.
 * df  R data frame with one record per row.
 * data  R data frame with a Time column or times in its first column.
 * texts_df  Optional data frame of additional text columns.
 *
 * OUTPUT
 * R list with Key, Cls, UniqueClasses, and optional Comments. Missing keys are NA.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
// [[Rcpp::export]]
Rcpp::List read_cls(std::string path, bool verbose = true, std::string encoding = "") {
    std::tuple<std::vector<dbt::DataIO::Key>, std::vector<double>, std::vector<double>, std::string> res = {};
    try {
        std::ostringstream output_stream;
        res = dbt::DataIO::read_cls(path, verbose, output_stream, encoding);
        text_messages(output_stream.str());
    }
    catch (const std::exception& e) {
        Rcpp::stop("Exception occoured when reading " + dbt::DataIO::get_filename(path) + ". " + std::string(e.what()));
    }

    // Reference the owned tuple until R conversion finishes; avoid full-data copies.
    const auto& _key = std::get<0>(res);
    const auto& _cls = std::get<1>(res);
    const auto& _unique_classes = std::get<2>(res);
    const auto& comment = std::get<3>(res);

    Rcpp::NumericVector key;
    Rcpp::NumericVector cls;
    Rcpp::NumericVector unique_classes;

    key = keys_to_r(_key);
    cls = Rcpp::wrap(_cls);
    unique_classes = Rcpp::wrap(_unique_classes);

    Rcpp::List res_list = Rcpp::List::create(Rcpp::Named("Key") = key, Rcpp::Named("Cls") = cls, Rcpp::Named("UniqueClasses") = unique_classes);

    if (!comment.empty()) {
        res_list["Comments"] = utf8_to_r(comment);
    }

    return res_list;
}

