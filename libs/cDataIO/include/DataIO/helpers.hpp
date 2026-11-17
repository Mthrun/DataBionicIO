/***********************************************************************************************
 * 
 * Function declarations for helpers.
 * 
 * AUTHOR: JULIAN MÄRTE (IAP-GmbH Intelligent Analytics Projects)
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 * 
 ***********************************************************************************************/


#ifndef __DBT_DATA_IO_AUX_HPP__
#define __DBT_DATA_IO_AUX_HPP__

#include <fstream>
#include <string>
#include <vector>
#include "key.hpp"

namespace dbt {
    namespace DataIO {

        /**
         * Check a path and add the required extension.
         *
         * INPUT
         * path  Filesystem path.
         * ending  Required extension without a dot.
         *
         * OUTPUT
         * Path with the extension; matching extensions and .csv stay unchanged. Invalid characters throw.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Add the required extension if the path has a different extension.
         * A path with the required extension or .csv stays unchanged.
         * The function rejects the characters in its invalidChars definition.
         * @param path Path to the input or output file.
         * @param ending Required extension, without the dot.
         */
        std::string addext_checkext(std::string path, std::string ending);

        /**
         * Check whether a filesystem path exists.
         *
         * INPUT
         * path  Filesystem path.
         *
         * OUTPUT
         * TRUE if the path exists; FALSE otherwise.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Return true if the path exists.
         * @param path Path to the file or directory.
         */
        bool file_exists(std::string path);

        /**
         * Check date and time components.
         *
         * INPUT
         * datetime  Date or timestamp string.
         *
         * OUTPUT
         * Resolution 1 for dates, 2 for seconds, 3 for fractional seconds.
         * Code 4 means the fractional integer exceeds 999; -1 means invalid syntax or ranges.
         * Month-specific day counts and fixed field widths are not validated.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Read date and time components and return a resolution code.
         * @param datetime Date or timestamp text.
         * @return 1 for dates, 2 for seconds, and 3 for fractional seconds.
         * Code 4 means that the integer after the decimal point exceeds 999.
         * Code -1 means that a component or separator fails the parser rules.
         *
         * The parser limits months to 1 through 12 and days to 1 through 31.
         * It does not verify the number of days in a particular month.
         * It does not require fixed field widths.
         */
        int is_valid_datetime(const std::string& datetime);

        /**
         * Split a timestamp and its optional DST suffix.
         *
         * INPUT
         * datetime  Date or timestamp, optionally followed by an alphabetic-starting suffix.
         *
         * OUTPUT
         * Tuple of timestamp text, suffix text, and resolution code.
         * Code 4 is reduced to 3 with three fractional characters; invalid input throws.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Separate timestamp text from an optional DST suffix.
         * @param datetime Date or timestamp text, with an optional suffix after a space.
         * The suffix must start with a letter.
         * @return Timestamp text, suffix text, and the resolution code.
         * An absent suffix gives an empty string.
         * For resolution code 4, the function keeps three fractional characters and returns code 3.
         * @throws std::invalid_argument if is_valid_datetime returns -1.
         */
        std::tuple<std::string, std::string, int> get_datetime_and_dst(const std::string& datetime);

        /**
         * Check component extraction from timestamp text.
         *
         * INPUT
         * datetime  Text to parse.
         *
         * OUTPUT
         * TRUE if stream extraction reads the date, time, and fractional components. Separators and ranges are not validated.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Return true if stream extraction reads the date, time, and fractional components.
         * @param datetime Text for component extraction.
         * This function does not validate separator values, component ranges, or trailing text.
         */
        bool is_ms(std::string datetime);

        /**
         * Check component extraction from timestamp text.
         *
         * INPUT
         * datetime  Text to parse.
         *
         * OUTPUT
         * TRUE if stream extraction reads the date and time components. Separators and ranges are not validated.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Return true if stream extraction reads the date and time components.
         * @param datetime Text for component extraction.
         * This function does not validate separator values, component ranges, or trailing text.
         */
        bool is_s(std::string datetime);

        /**
         * Check component extraction from timestamp text.
         *
         * INPUT
         * datetime  Text to parse.
         *
         * OUTPUT
         * TRUE if stream extraction reads the date components. Separators and ranges are not validated.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Return true if stream extraction reads the date components.
         * @param datetime Text for component extraction.
         * This function does not validate separator values, component ranges, or trailing text.
         */
        bool is_d(std::string datetime);

        /**
         * Add zero time fields to change the time resolution.
         *
         * INPUT
         * datetime  Input date or timestamp text.
         * current_resolution  Input resolution: 1 for date, 2 for seconds, 3 for milliseconds.
         * wanted_resolution  Requested resolution using the same codes.
         *
         * OUTPUT
         * Converted text for supported resolution pairs; other pairs keep the input.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Add zero time fields to increase the time resolution.
         * @param datetime Input time text.
         * @param current_resolution Input resolution: 1 for dates, 2 for seconds, or 3 for milliseconds.
         * @param wanted_resolution Output resolution, greater than current_resolution.
         * @return Text with the additional fields for conversions 1 to 2, 1 to 3, and 2 to 3.
         * Other resolution pairs keep the input text.
         */
        std::string extend_datetime_format(std::string datetime, int current_resolution, int wanted_resolution);

        /**
         * Remove trailing time fields to change the time resolution.
         *
         * INPUT
         * datetime  Input date or timestamp text.
         * current_resolution  Input resolution: 1 for date, 2 for seconds, 3 for milliseconds.
         * wanted_resolution  Requested resolution using the same codes.
         *
         * OUTPUT
         * Converted text for supported resolution pairs; other pairs keep the input.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Remove time fields to decrease the time resolution.
         * @param datetime Input time text.
         * @param current_resolution Input resolution: 1 for dates, 2 for seconds, or 3 for milliseconds.
         * @param wanted_resolution Output resolution, less than current_resolution.
         * @return The first 10 characters for conversion from resolution 2 or 3 to resolution 1.
         * Conversion from resolution 3 to resolution 2 keeps the first 19 characters.
         * Other resolution pairs keep the input text.
         */
        std::string shorten_datetime_format(std::string datetime, int current_resolution, int wanted_resolution);

        /**
         * Extract the filename from a path.
         *
         * INPUT
         * path  Filesystem path.
         *
         * OUTPUT
         * Filename component according to the current platform filesystem rules.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Return the filename component of a path.
         * @param path Input path.
         * The function uses std::filesystem path rules for the current platform.
         */
        std::string get_filename(std::string path);

        /**
         * Open a file for reading.
         *
         * INPUT
         * path  Filesystem path.
         *
         * OUTPUT
         * Open input stream; missing paths or an open failure throw.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Open a file for input.
         * @param path Path to the input file.
         * @return An open input stream.
         * @throws std::invalid_argument if the parent directory or file is absent, or the file cannot open.
         */
        std::ifstream open_read(std::string path);

        /**
         * Format the current local time.
         *
         * INPUT
         * None.
         *
         * OUTPUT
         * String in YYYY-MM-DD hh:mm:ss format.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Return the current local date and time.
         * @return A timestamp in YYYY-MM-DD hh:mm:ss format.
         */
        std::string current_date_str();

        /**
         * Open a file for writing and create missing parent directories.
         *
         * INPUT
         * path  Filesystem path.
         * verbose  Select information messages; data warnings can remain active.
         * output_stream  Destination stream for diagnostics.
         *
         * OUTPUT
         * Output stream with existing contents truncated; filesystem failures throw.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Open a file for output.
         * The function creates missing parent directories and removes existing file contents.
         * @param path Path to the output file.
         * @param verbose Select information messages and overwrite warnings.
         * @param output_stream Destination for these messages.
         * @return An open output stream.
         */
        std::ofstream open_write(std::string path, bool verbose, std::ostream& output_stream);

        /**
         * Close and check an output stream.
         *
         * INPUT
         * stream  Open output stream, modified in place.
         *
         * OUTPUT
         * No return value. Closes stream; a closed stream or failed write/close causes an exception.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Close an output stream.
         * @param stream The output stream.
         * @throws std::invalid_argument if the stream is already closed.
         * @throws std::runtime_error if a write operation or the close operation fails.
         */
        void close_write(std::ofstream& stream);

        /**
         * Check a column label against the accepted character rules.
         *
         * INPUT
         * name  Column label.
         *
         * OUTPUT
         * TRUE for a nonempty permitted label that does not start with a digit; FALSE otherwise.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Return true if the column name satisfies the character rules.
         * The name must not be empty or start with a digit.
         * Letters can be uppercase or lowercase.
         * Other permitted characters are 0123456789_.-=?&$§.
         * @param name Column name.
         */
        bool is_valid_colname(std::string name);

        // Remove spaces, tabs, commas, and semicolons from LRN/NAMES labels with a warning.
        /**
         * Remove separators from an LRN or NAMES column label.
         *
         * INPUT
         * name  Column label.
         * output_stream  Destination stream for diagnostics.
         *
         * OUTPUT
         * Label without spaces, tabs, commas, or semicolons, with warnings for changes.
         * Empty labels and labels with line breaks or NUL throw; other nonstandard labels cause a warning.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        std::string clean_column_name(std::string name, std::ostream& output_stream);

        /**
         * Return true if the string contains \t, \r, or \n.
         * @param s Input string.
         */
        /**
         * Check for tab or line-break characters.
         *
         * INPUT
         * s  Input string.
         *
         * OUTPUT
         * TRUE if s contains a tab, CR, or LF; FALSE otherwise.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        bool contains_break(std::string s);

        /**
         * Remove tab and line-break characters.
         *
         * INPUT
         * s  Input string.
         *
         * OUTPUT
         * String without tab, CR, or LF characters.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Remove \t, \r, and \n from a string.
         * @param s Input string.
         * @return The string without these characters.
         */
        std::string clean_string(std::string s);

        /**
         * Convert letters to lowercase.
         *
         * INPUT
         * s  Input string.
         *
         * OUTPUT
         * String after std::tolower is applied to each character.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Change uppercase letters to lowercase letters.
         * @param s Input string.
         * @return The result of std::tolower for each character.
         */
        std::string to_lower_string(std::string s);

        /**
		 * Check a string suffix.
		 *
		 * INPUT
		 * str  Input string.
		 * suffix  Candidate suffix.
		 *
		 * OUTPUT
		 * TRUE if str ends with suffix; FALSE otherwise.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 *
		 * API NOTES
         * Return true if str ends with suffix.
         * @param str Input string.
         * @param suffix Character sequence at the end of the string.
		 */
		bool ends_with(const std::string& str, const std::string& suffix);

        /**
		 * Read metadata and locate the first data row.
		 *
		 * INPUT
		 * inputFile  Input stream at the start of the file; its position changes.
		 * output_stream  Destination stream for diagnostics.
		 * verbose  Select information messages; data warnings can remain active.
		 *
		 * OUTPUT
		 * Pair of header lines and the position before the first data line.
		 * The stream is after that data line. Reaching EOF before it causes an exception.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 *
		 * API NOTES
         * Read the header lines and locate the first data line.
         * @param inputFile Input stream.
         * @param output_stream Destination for information messages.
         * @param verbose Select information messages.
         * @return Header lines and the stream position at the start of the first data line.
         * Header lines start with %, <, or #.
         * The stream itself is after the first data line.
		 */
		std::pair<std::vector<std::string>, std::streampos> read_header_lines(std::ifstream& inputFile, std::ostream& output_stream, bool verbose);

        /**
		 * Inspect a generation tag for version metadata.
		 *
		 * INPUT
		 * format_line  First metadata line.
		 * format_name  Expected format name, such as names or dates.
		 * verbose  Select information messages; data warnings can remain active.
		 * output_stream  Destination stream for diagnostics.
		 *
		 * OUTPUT
		 * Empty string. Emits information messages; does not select or validate a format version.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 *
		 * API NOTES
         * Read the format tag for version metadata.
         * @param format_line Input line.
         * @param format_name Expected format name, such as lrn or names.
         * @param verbose Select information messages.
         * @param output_stream Destination for information messages.
         * @return An empty string.
         * This helper does not select or validate a format version.
		 */
		std::string parse_format_line(const std::string& format_line, const std::string& format_name, bool verbose, std::ostream& output_stream);

        /**
		 * Parse tab-separated column labels.
		 *
		 * INPUT
		 * columns_line  Metadata line with labels.
		 * mandatory_columns  Required leading column labels.
		 * warning_stream  Diagnostic destination; nullptr selects strict DATES label validation.
		 *
		 * OUTPUT
		 * Column labels in file order; invalid mandatory labels or empty labels throw.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 *
		 * API NOTES
         * Read column names from a line with tab separators.
         * @param columns_line Input line.
         * @param mandatory_columns Required names for the first two columns, when supplied.
         * @param warning_stream Destination for LRN/NAMES warnings.
         * A null pointer selects strict DATES name validation.
         * @return The column names in file order.
		 */
		std::vector<std::string> parse_column_names(const std::string& columns_line, const std::vector<std::string>& mandatory_columns, std::ostream* warning_stream = nullptr);

        /**
		 * Remove a metadata marker and following indentation.
		 *
		 * INPUT
		 * line  Metadata line with its marker as the first character.
		 *
		 * OUTPUT
		 * Remaining text with internal spaces and tabs retained.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 *
		 * API NOTES
         * Remove the first character and subsequent spaces and tabs from a metadata line.
         * @param line Input line, with its metadata marker first.
         * @return The remaining text. Internal spaces and tabs stay unchanged.
		 */
		std::string get_text_from_metadata_line(const std::string& line);

        // Read a key without a 32-bit cast. Enforce the shared exact integer range.
        /**
         * Read a signed key without a 32-bit conversion.
         *
         * INPUT
         * text  String with an integer prefix.
         * consumed  Optional destination for the number of consumed characters.
         *
         * OUTPUT
         * Key in [-2^53, 2^53]; missing digits, overflow, or an out-of-range key throw.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        Key parse_key_cell(const std::string& text, std::size_t* consumed);

        // Preserve representable subnormal values that stod reports as underflow.
        /**
         * Parse a numeric prefix and retain representable subnormal values.
         *
         * INPUT
         * text  String with a floating-point prefix.
         * consumed  Optional destination for the number of consumed characters.
         *
         * OUTPUT
         * Parsed double; invalid text, overflow, or underflow to zero can throw.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        double parse_numeric_cell(const std::string& text, std::size_t* consumed);

        // Report ignored suffixes without discarding a successfully parsed number.
        /**
         * Report ignored text after a numeric prefix.
         *
         * INPUT
         * text  Original cell string.
         * consumed  Number of characters consumed by numeric parsing.
         * output_stream  Destination stream for diagnostics.
         *
         * OUTPUT
         * No return value. Writes a warning only for a non-whitespace suffix.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        void warn_numeric_suffix(const std::string& text, std::size_t consumed, std::ostream& output_stream);

        /**
         * Read keys and text fields from the data section.
         * @param fileContents File data as a character vector.
         * @param keys Destination for keys.
         * @param values Destination for the second column.
         * @param dst Destination for DST markers.
         * @param further_texts Destination for other text columns, with one vector per column.
         * @param has_dst_info Select a DST column after the second column.
         * @param output_stream Destination for data warnings.
         */
        /**
         * Read keys and text columns from a buffered file body.
         *
         * INPUT
         * fileContents  Tab-separated data bytes.
         * keys  Destination key vector.
         * values  Destination vector for the second column.
         * dst  Destination vector for DST markers.
         * further_texts  One destination vector per additional column; width must be set before the call.
         * has_dst_info  Select a DST column after the second field.
         * output_stream  Destination stream for diagnostics.
         *
         * OUTPUT
         * Appends parsed rows to keys, values, dst, and further_texts.
         * Invalid keys use MISSING_KEY; empty cells use NA; short rows are padded.
         * Extra fields are ignored and malformed rows cause warnings.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        void process_file_body(const std::vector<char>& fileContents, std::vector<Key>& keys, std::vector<std::string>& values, std::vector<std::string>& dst, std::vector<std::vector<std::string>>& further_texts, bool has_dst_info, std::ostream& output_stream);
        
        /**
         * Find a nonzero fractional character in fixed-point text.
         *
         * INPUT
         * strValue  Numeric text with an optional decimal point.
         * non_zero  TRUE selects the first nonzero fractional character; FALSE selects the last.
         *
         * OUTPUT
         * One-based position after the decimal point, or 0 if no nonzero fraction exists.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Find the position of a fractional digit in fixed-point numeric text.
         * @param strValue Numeric text with a decimal point.
         * @param non_zero If true, return the position of the first fractional character that is not zero.
         * If false, return the position of the last fractional character that is not zero.
         * Positions start at 1 after the decimal point.
         * @return Zero if there is no decimal point or all fractional characters are zero.
         */
        int decimal_positions(std::string strValue, bool non_zero);

        /**
         * Choose decimal places from the smallest nonzero magnitude per column.
         *
         * INPUT
         * numerics  Nonempty rectangular row table; contents are read only.
         * significant_digits  Requested significant-digit count.
         *
         * OUTPUT
         * One decimal-place count per column, capped by the observed fractional precision.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         *
         * API NOTES
         * Calculate a decimal-place count for each numeric column.
         * The calculation uses the smallest nonzero absolute value in each column.
         * @param numerics Rectangular data with one record per inner vector.
         * The outer vector must not be empty.
         * @param significant_digits Target number of significant digits.
         * @return One decimal-place count per column.
         */
        std::vector<int> signif_per_col(std::vector<std::vector<double>>& numerics, int significant_digits);
    }
}

#endif