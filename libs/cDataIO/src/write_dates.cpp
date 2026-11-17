/***********************************************************************************************
 * 
 * Function implementations for write_dates.
 * 
 * AUTHOR: JULIAN MÄRTE (IAP-GmbH Intelligent Analytics Projects), LUCA BRINKMANN (IAP-GmbH Intelligent Analytics Projects)
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 * 
 ***********************************************************************************************/


#include "DataIO/write_dates.hpp"

#include <algorithm>

// IO
#include <filesystem>
#include <iostream>
#include <fstream>
#include <sstream>
#include <utility>
#include <limits>
#include <iomanip>
#include <unordered_set>

#include "DataIO/helpers.hpp"

namespace dbt {
	namespace DataIO {

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
		 * Validation and I/O failures throw; diagnostics use output_stream or std::cout.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		void _write_dates(std::vector<std::string> column_names, std::vector<Key> keys, std::vector<std::string> times, std::vector<std::vector<double>> numerics, std::string path, std::string comment, int format, bool overwrite, bool verbose, int version_major, int version_minor, std::ostream& output_stream) {
			path = addext_checkext(path, "dts");


			if (!overwrite && file_exists(path)) {
	        	throw std::invalid_argument("The file " + path + " already exists! Consider to set overwrite=true if you want the contents to be overwritten!");
			}
			
			// Mismatched time/data lengths previously caused out-of-bounds access; retain all rows.
			const size_t rows = std::max(times.size(), numerics.size());
			if (times.size() != numerics.size()) {
				output_stream << "WARNING: DATES time/data lengths differ; missing cells filled with NA/NaN." << std::endl;
				times.resize(rows, "NA");
				numerics.resize(rows);
			}
			// Header names define the numeric width; never emit undeclared numeric fields.
			for (size_t i = 0; i < numerics.size(); ++i) {
				if (numerics[i].size() != column_names.size()) {
					output_stream << "WARNING: DATES row " << i + 1 << " has the wrong width; padding with NaN or ignoring extra fields." << std::endl;
					numerics[i].resize(column_names.size(), std::numeric_limits<double>::quiet_NaN());
				}
			}

			// Here time checks
			if (times.size() == 0) {
				throw std::invalid_argument("times vector is empty!");
			}

			std::vector<int> time_resolution;
			std::vector<std::string> dst_info;

			time_resolution.reserve(times.size());

			int maximal_time_resolution = 0;

			bool dst_info_needed = false;

			for (unsigned int i = 0; i < times.size(); i++) {

				std::string time_string = times[i];
				// A padded timestamp must stay missing, not enter the datetime parser.
				if (time_string == "NA") { dst_info.push_back("NA"); time_resolution.push_back(0); continue; }


				std::tuple <std::string, std::string, int> time_information = get_datetime_and_dst(time_string);
				
				// Get date/datetime
				times[i] = std::get<0>(time_information);

				// Get dst information if given
				std::string dst = std::get<1>(time_information);
				if (!dst_info_needed && dst != "") dst_info_needed = true;
				dst_info.push_back(dst);

				// Get time resolution
				int resolution = std::get<2>(time_information);
				time_resolution.push_back(resolution);
				maximal_time_resolution = std::max(resolution, maximal_time_resolution);

				/**
				if (!is_valid_datetime(time_string)) {
					throw std::invalid_argument("Timestamp " + time_string + " is not of the necessary format!");
				}

				std::pair<std::string, std::string> get_datetime_and_dst(const std::string & datetime)

				// Find the maximal resolution of time present in the time column
				if (is_ms(time_string)) {
					maximal_time_resolution = std::max(3, maximal_time_resolution);
					time_resolution.push_back(3);
				}
				else if (is_s(time_string)) {
					maximal_time_resolution = std::max(2, maximal_time_resolution);
					time_resolution.push_back(2);
				}
				else if (is_d(time_string)) {
					maximal_time_resolution = std::max(1, maximal_time_resolution);
					time_resolution.push_back(1);
				}
				else {
					// Should never happen since correct date format is checked before
					throw std::invalid_argument("Could not parse dates/datetimes. Please check format of time vector");
				}
				**/
			}

			if (maximal_time_resolution == 1 || format == 1) dst_info_needed = false;

			if (format < -1 || format > 3) {
				if (verbose) output_stream << "WARNING: format argument is not one of the following values: -1, 1, 2, 3. Proceeding without reformatting!" << std::endl;
			}
			// Format times as needed and add keys if any where given
			for (unsigned int i = 0; i < times.size(); i++) {

				std::string time_val = times[i];
				if (time_val == "NA") continue;

				if (format != -1) {
					if (time_resolution[i] > format) {
						time_val = shorten_datetime_format(time_val, time_resolution[i], format);
					}
					else if (time_resolution[i] < format) {
						time_val = extend_datetime_format(time_val, time_resolution[i], format);
					}
				}
				else {
					time_val = extend_datetime_format(time_val, time_resolution[i], maximal_time_resolution);
				}
				times[i] = time_val;
			}

			
			int N = numerics.size();
			if (N == 0) {
				throw std::invalid_argument("Tried to write dates file with zero rows!");
			}

			int d = 0;
			if (dst_info_needed) {
				d = numerics[0].size() + 3;
			} else {
				d = numerics[0].size() + 2;
			}
			

			if (static_cast<int>(keys.size()) != N) {
				if (keys.size() == 0) {
					for (int i = 0; i < N; i++)
						keys.push_back(i+1);
					if (verbose) output_stream << "WARNING: Auto-generating key 1:N now as no key column was given!" << std::endl;
				} else {
					throw std::invalid_argument("Keys do not have the same length as the table but also are not empty!");
				}
			}

			// Larger IDs can lose precision in R/MATLAB; reject them before writing.
			if (std::any_of(keys.begin(), keys.end(), [](Key key) { return key < -MAX_EXACT_KEY || key > MAX_EXACT_KEY; }))
				throw std::invalid_argument("Key must be between -9007199254740992 and 9007199254740992 (2^53).");

			std::unordered_set<Key> keys_unique(keys.begin(), keys.end());

			if(keys.size() != keys_unique.size()) {
				throw std::invalid_argument("Not all Keys are unique!");
			}

			std::stringstream buffer;

			if (version_major == 2) {
				if (version_minor == 0) {

					// write header
					// version first:
					buffer << "#<?dates version=\"" << version_major << "." << version_minor << "\" created_at=\"" + current_date_str() + "\"?>" << std::endl;
					
					// multi-line comment:
					auto ss = std::stringstream(comment);

				    for (std::string line; std::getline(ss, line, '\n');)
						buffer << "# " << line << std::endl;

					// HEADER
					// dimensions
					buffer << "% \t" << N << std::endl;
					buffer << "% \t" << d << std::endl;

					// column names
					if (dst_info_needed) {
						buffer << "% Key\tTime\tTZ_DST";
					} else {
						buffer << "% Key\tTime";
					}
					for (auto col_name : column_names) {
						if (is_valid_colname(col_name)) {
							buffer << "\t" << col_name;
						} else {
							throw std::invalid_argument("Column name " + col_name + " starts with a digit or contains letters not alpha-numerical and not '_'!");
						}
					}
					buffer << std::endl;

					bool has_nans = false;

					// BODY
					for (int i = 0; i < N; i++) {
						const std::vector<double>& row = numerics[i];
						if ((!dst_info_needed && static_cast<int>(row.size()) != d - 2) || (dst_info_needed && static_cast<int>(row.size()) != d - 3)) {
							throw std::invalid_argument("Row " + std::to_string(i) + " has not the same number of columns as described; " + std::to_string(d) + " should be given but row has " + std::to_string(row.size()) + " columns!");
						}

						if (dst_info_needed) {
							buffer << keys[i] << "\t" << times[i] << "\t" << dst_info[i];
						} else {
							buffer << keys[i] << "\t" << times[i];
						}

						for (auto val : row) {
							if (val != val) {
								if (!has_nans) {
									if (verbose)
										output_stream << "WARNING: Numeric data contains NaNs!" << std::endl;
									has_nans = true;
								}
								buffer << "\t" << "NaN";
							} else {
								// Fixed precision 6 rounded small values to zero; retain enough digits for a double round trip.
								buffer << "\t" << std::defaultfloat << std::setprecision(std::numeric_limits<double>::max_digits10) << val;
							}
						}
						if (i != N - 1)
							buffer << std::endl;
					}
				} else {
	        		throw std::invalid_argument("There is no writer for version " + std::to_string(version_major) + "." + std::to_string(version_minor) + "!");
				}
			} else {
				throw std::invalid_argument("There is no writer for version " + std::to_string(version_major) + "." + std::to_string(version_minor) + "!");
			}

			std::ofstream of_stream = open_write(path, verbose, output_stream);
			of_stream << buffer.rdbuf();
			close_write(of_stream);
		}

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
		 * Validation and I/O failures throw; diagnostics use output_stream or std::cout.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		void write_dates(std::vector<std::string> column_names, std::vector<Key> keys, std::vector<std::string> times, std::vector<std::vector<double>> numerics, std::string path, std::string comment, int format, bool overwrite, bool verbose, int version_major, int version_minor, std::ostream& output_stream) {
			// Avoid a second deep copy: these owned arguments are no longer used here.
			_write_dates(std::move(column_names), std::move(keys), std::move(times), std::move(numerics), path, comment, format, overwrite, verbose, version_major, version_minor, output_stream);
		}

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
		 * Validation and I/O failures throw; diagnostics use output_stream or std::cout.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		void write_dates(std::vector<std::string> column_names, std::vector<Key> keys, std::vector<std::string> times, std::vector<std::vector<double>> numerics, std::string path, std::string comment, int format, bool overwrite, bool verbose, int version_major, int version_minor) {
			// Avoid a second deep copy: these owned arguments are no longer used here.
			_write_dates(std::move(column_names), std::move(keys), std::move(times), std::move(numerics), path, comment, format, overwrite, verbose, version_major, version_minor, std::cout);
		}

	}
}
