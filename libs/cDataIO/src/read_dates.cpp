/***********************************************************************************************
 * 
 * Function implementations for read_dates.
 * 
 * AUTHOR: JULIAN MÄRTE (IAP-GmbH Intelligent Analytics Projects), LUCA BRINKMANN (IAP-GmbH Intelligent Analytics Projects), OLEKSANDER DOSKALIUK (IAP-GmbH Intelligent Analytics Projects)
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 * 
 ***********************************************************************************************/

#include "DataIO/read_dates.hpp"

#include <iostream>
#include <fstream>
#include <exception>
#include <sstream>
#include <filesystem>
#include <limits>
#include <utility>
#include <regex>
#include <optional>
#include <algorithm> 


#include "DataIO/helpers.hpp"
#include "DataIO/text_encoding.hpp"

namespace dbt {
	namespace DataIO {

		struct FileMetadata {
			int number_of_records;
			int number_of_columns;
			std::vector<std::string> column_names;
			std::string times_format;
			std::string comment;
			std::string timezone;
		};

		/**
		 * Extract the text after a Timezone declaration.
		 *
		 * INPUT
		 * line  Text that can contain Timezone: followed by a zone name.
		 *
		 * OUTPUT
		 * Trimmed zone name, or an empty string when the keyword is absent.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		std::string try_parse_timezone(const std::string& line) {
			const std::string keyword = "Timezone: ";
			size_t keywordPos = line.find(keyword);

			// Check if the keyword was found
			if (keywordPos != std::string::npos) {
				// Extract the substring after the keyword
				std::string timezone = line.substr(keywordPos + keyword.size());

				// Trim leading and trailing whitespace from the extracted substring
				timezone.erase(timezone.begin(), std::find_if(timezone.begin(), timezone.end(), [](unsigned char ch) {
					return !std::isspace(ch);
				}));
				timezone.erase(std::find_if(timezone.rbegin(), timezone.rend(), [](unsigned char ch) {
					return !std::isspace(ch);
				}).base(), timezone.end());

				return timezone;
			}

			return "";
		}

		/**
		 * Read DATES counts, labels, comments, and time zone.
		 *
		 * INPUT
		 * headerLines  Header lines in file order, including metadata markers.
		 * mandatory_columns  Required leading column labels.
		 * format_name  Expected format name, such as names or dates.
		 * verbose  Select information messages; data warnings can remain active.
		 * output_stream  Destination stream for diagnostics.
		 *
		 * OUTPUT
		 * FileMetadata with counts, column names, format text, comments, and zone; absent zones use UTC.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		FileMetadata process_header_lines_with_timezone(const std::vector<std::string>& headerLines, const std::vector<std::string>& mandatory_columns, const std::string& format_name, bool verbose = true, std::ostream& output_stream = default_output_stream()) {
			if (headerLines.empty()) {
				throw std::invalid_argument("Header lines are empty!");
			}

			std::string times_format = parse_format_line(headerLines[0], format_name, verbose, output_stream);
			std::vector<std::string> column_names;
			std::string comment = "";
			bool found_comment = false;
			std::string default_timezone = "UTC";
			std::string timezone;
			int N = -1;
			int d = -1;
			bool found_timezone = false;

			int it_offset = times_format.empty() ? 0 : 1;

			for (auto it = headerLines.begin() + it_offset; it != headerLines.end(); ++it) {
				const auto& line = *it;

				if (!line.starts_with("#") && !line.starts_with("%") && !line.starts_with("<")) {
					throw std::invalid_argument("A non-escaped line (#, %) was found before a header/type section was completed! Something seems to be wrong with the header section...");
				}

				if (line.starts_with("#")) {
					// Comments before (or without) Timezone were lost; collect them independently.
					const std::string comment_line = get_text_from_metadata_line(line);
					// A mention of Timezone inside user prose is not a metadata declaration.
					const std::string line_timezone = comment_line.starts_with("Timezone: ") ? try_parse_timezone(comment_line) : "";
					if (!line.starts_with("#<?dates") && line_timezone.empty()) {
						// An empty first comment is still a line; keep its separator.
						if (found_comment) comment += "\n";
						comment += comment_line;
						found_comment = true;
					}
					if (!found_timezone) {
						timezone = line_timezone;
						if (!timezone.empty()) {
							found_timezone = true;
						}
					}
				} 
				else if (line.starts_with("%")) {
					// META DATA
					std::string meta_data_line = get_text_from_metadata_line(line);
					if (N < 0) {
						N = std::stoi(meta_data_line);
					}
					else if (d < 0) {
						d = std::stoi(meta_data_line);
					} 
					else {
						// column names
						column_names = parse_column_names(meta_data_line, mandatory_columns);
					}
				}
			}

			if (static_cast<int>(column_names.size()) != d) {
				throw std::invalid_argument(std::to_string(column_names.size()) + " column names are defined but by header definition we have " + std::to_string(d) + " columns of data!");
			}

			if (!found_timezone) {
				if (verbose) output_stream << "No Timezone found, will use UTC!" << std::endl;
				timezone = default_timezone;
			} else {
				if (verbose) output_stream << "Timezone found: " << timezone << std::endl;
			}

			return {N, d, column_names, times_format, comment, timezone};
		}

		/**
		 * Check timestamp field widths and extract fractional numbers.
		 *
		 * INPUT
		 * times  Date/time strings; NA marks a missing timestamp.
		 *
		 * OUTPUT
		 * One fractional numeric value per string; 0 when absent and NaN for NA.
		 * Malformed widths or fractional text throw; this function does not validate calendar dates.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		std::vector<double> validate_times_and_get_millis(const std::vector<std::string>& times) {
			std::vector<double> millis = std::vector<double>(times.size());

			int i = 0;
			for (const std::string& time : times) {
				double millis_for_time = 0.0;
				// A missing timestamp must remain missing when a short row is retained.
				if (time == "NA") { millis[i++] = std::numeric_limits<double>::quiet_NaN(); continue; }
				if (time.size() < 10) {
					throw std::invalid_argument("Date format is too short! Value: " + time);
				}

				std::istringstream iss(time);
				std::string date_or_time_part;
				bool is_date_part = true;

				while (std::getline(iss, date_or_time_part, ' ')) {
					if (is_date_part) {
						if (date_or_time_part.size() != 10) {
							throw std::invalid_argument("Date part is in the wrong format! Value: " + time);
						}
						is_date_part = false;
					} else {
						std::istringstream iss_time_part(date_or_time_part);
						std::string time_part;
						bool is_time_part = true;

						while (std::getline(iss_time_part, time_part, '.')) {
							if (is_time_part) {
								if (time_part.size() != 8) {
									throw std::invalid_argument("Time part is in the wrong format! Value: " + time);
								}
								is_time_part = false;
							} else {
								try {
									millis_for_time = std::stod(time_part);
								} catch (...) {
									throw std::invalid_argument("Milliseconds part is in the wrong format! Value: " + time);
								}
							}
						}
					}
				}
				millis[i++] = millis_for_time;
			}

			return millis;
		}

		/**
		 * Check that timestamp text can be read by std::get_time.
		 *
		 * INPUT
		 * times  Date/time strings; NA entries are skipped.
		 *
		 * OUTPUT
		 * No return value. Throws for a string that fails date or date-time extraction.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		void try_to_parse_times(const std::vector<std::string>& times) {
			for (unsigned int i = 0; i < times.size(); i++) {
				std::string time = times[i];
				if (time == "NA") continue; // Missing timestamps are retained, not parsed as dates.
				std::tm parsed_time = {};
				std::istringstream ss(time);
				// Date-only rows have no time portion; use their matching format on all platforms.
				ss >> std::get_time(&parsed_time, time.size() == 10 ? "%Y-%m-%d" : "%Y-%m-%d %H:%M:%S");

				if (ss.fail()) {
					throw std::invalid_argument("Could not parse time string: " + time);
				}
			}
		}

		/**
		 * Convert text columns to numeric columns.
		 *
		 * INPUT
		 * further_texts  Additional text columns, one column per inner vector.
		 * numerics  Destination column vectors; parsed columns are appended.
		 * verbose  Accepted interface flag; conversion warnings do not depend on it.
		 * output_stream  Destination stream for diagnostics.
		 *
		 * OUTPUT
		 * Appends numeric columns; missing or invalid cells become NaN, with diagnostics for invalid text.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		void convert_further_text_to_numerics(const std::vector<std::vector<std::string>>& further_texts, std::vector<std::vector<double>>& numerics, bool verbose, std::ostream& output_stream) {
			
			numerics.reserve(further_texts.size());

			for (const std::vector<std::string>& column : further_texts) {

				std::vector<double> column_numerics;
				column_numerics.reserve(column.size());
				for (const std::string& str_val : column) {
					// Missing cells caused conversion exceptions. Handle these normal markers directly.
					if (str_val == "NA" || str_val.empty()) {
						column_numerics.push_back(std::numeric_limits<double>::quiet_NaN());
						continue;
					}
					try {
						// Preserve successful prefix parsing; only add a warning for ignored suffixes.
						std::size_t consumed = 0;
						column_numerics.push_back(parse_numeric_cell(str_val, &consumed));
						warn_numeric_suffix(str_val, consumed, output_stream);
					} catch (...) {
						// Keep the existing warning for invalid text and silence for the NaN marker.
						column_numerics.push_back(std::numeric_limits<double>::quiet_NaN());
						if (str_val != "NaN")
							output_stream << "WARNING: Invalid numeric cell \"" << str_val << "\". The reader uses NaN." << std::endl;
					}
				}

				// Transfer each completed column instead of copying it.
				numerics.push_back(std::move(column_numerics));
			}
		}

		/**
		 * Read a DATES file through the shared core.
		 *
		 * INPUT
		 * path  Filesystem path.
		 * verbose  Select information messages; data warnings can remain active.
		 * output_stream  Destination stream for diagnostics.
		 * encoding  Optional source encoding; empty selects BOM detection, otherwise UTF-8.
		 *
		 * OUTPUT
		 * Tuple: labels, keys, DST markers, timestamp strings, numeric columns, comments, time zone.
		 * Numeric data uses one vector per column. Missing keys use MISSING_KEY.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::string>, std::vector<std::string>, std::vector<std::vector<double>>, std::string, std::string> _read_dates(std::string path, bool verbose, std::ostream& output_stream, const std::string& encoding) {
			std::vector<Key> keys;
			std::vector<std::string> dst;
			std::vector<std::string> times;
			std::vector<std::vector<std::string>> further_texts;
			std::vector<std::vector<double>> numerics;
			std::string comment = "";

			std::vector<std::string> MANDATORY_COLUMNS = {"Key", "Time"};
			std::ifstream raw_stream;
			std::string path_csv;
			std::string path_dts;
			std::string FORMAT_NAME = "dates";

			bool has_dst_info = true;


			std::filesystem::path p {path};

			if (!std::filesystem::exists(p.parent_path())) {
				throw std::invalid_argument("ERROR: Path " + p.parent_path().string() + " does not exist!");
			}

			// We check here if a .dts or .csv file exists (if ending was not given), or both. .dts has precedence over .csv.
			try {
				path_dts = addext_checkext(path, "dts");
				if (file_exists(path_dts)) {
					try {
						path_csv = addext_checkext(path, "csv");
						if (file_exists(path_csv) && path_csv != path_dts) {
							if(verbose) output_stream << "WARNING: The file under " + path + " exists with both acceptable file endings (.dts and .csv). Proceeding with .dts file ending" << std::endl;
						}
					}
					catch (...) {
						// Do nothing
					}
				}

				// opening the file is outside of the if to trigger the catch if it can not be loaded
				raw_stream.open(path_dts, std::ios::binary);
				if (!raw_stream) {
					throw std::invalid_argument("ERROR: File " + path + " does not exist!");
				}
			}
			catch (const std::exception& e) {
				if (verbose) output_stream << "Info: Expected the file to have a .dts ending. Will try to load with .csv ending for backwards compatibility" << std::endl;
				try {
					path_csv = addext_checkext(path, "csv");
				}
				catch (const std::exception& e) {
					throw std::invalid_argument("ERROR: Ending of filename does not match the mandatory ending of .dts or .csv");
				}
				if (!file_exists(path_csv)) {
					throw std::invalid_argument("ERROR: File " + path_csv + " does not exist!");
				}
				else {
					raw_stream.open(path_csv, std::ios::binary);
					if (!raw_stream) {
						throw std::invalid_argument("ERROR: File " + path + " does not exist!");
					}
				}
			}

			TextInput stream(std::move(raw_stream), encoding, output_stream);

			auto [headerLines, posAfterHeader] = read_header_lines(stream, output_stream, verbose);

			FileMetadata file_metadata = process_header_lines_with_timezone(headerLines, MANDATORY_COLUMNS, FORMAT_NAME, verbose, output_stream);

			stream.seekg(posAfterHeader);

			auto fileContents = stream.read_remaining();
			// close file stream
			stream.close();

			std::vector<std::string> col_names;

			// Time-only files have just Key and Time; do not index a third column.
			if (file_metadata.column_names.size() > 2 && file_metadata.column_names[2] == "TZ_DST") {
				col_names = file_metadata.column_names;
				has_dst_info = true;
				col_names.erase(col_names.begin() + 2);
			} else {
				has_dst_info = false;
				bool found_dst_col = std::find(file_metadata.column_names.begin(), file_metadata.column_names.end(), "TZ_DST") != file_metadata.column_names.end();
				if (found_dst_col) {
					throw std::invalid_argument("ERROR: Expected the TZ_DST column to appear after the Time column");
				}
				col_names = file_metadata.column_names;
			}

			keys.reserve(file_metadata.number_of_records);
			times.reserve(file_metadata.number_of_records);
			if (has_dst_info) {
				dst.reserve(file_metadata.number_of_records);
			}	

			int metadata_cols = has_dst_info ? 3 : 2;
			int data_cols = file_metadata.number_of_columns - metadata_cols;

			if (data_cols > 0) {
				further_texts.resize(data_cols);
				for (unsigned int i = 0; i < further_texts.size(); i++) {
					further_texts[i].reserve(file_metadata.number_of_records);
				}
			}

			process_file_body(fileContents, keys, times, dst, further_texts, has_dst_info, output_stream);

			if (keys.size() != static_cast<unsigned int>(file_metadata.number_of_records)) {
				// Keep actual rows when N is stale; previously an otherwise readable file failed.
				output_stream << "WARNING: Header declares " << file_metadata.number_of_records << " rows. The reader keeps all " << keys.size() << " actual rows." << std::endl;
			}


			std::vector<double> millis = validate_times_and_get_millis(times);

			try_to_parse_times(times);

			convert_further_text_to_numerics(further_texts, numerics, verbose, output_stream);

			// Transfer owned results; copying here duplicated the complete data.
			return { std::move(col_names), std::move(keys), std::move(dst), std::move(times), std::move(numerics), std::move(file_metadata.comment), std::move(file_metadata.timezone)};
		}

		// INPUT: path, diagnostics, optional input encoding.
		// OUTPUT: decoded fields; malformed encoding throws.
		// SPDX-License-Identifier: AGPL-3.0-only
		// Additional permission: see MATLAB-EXCEPTION.txt.
		std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::string> ,std::vector<std::string>, std::vector<std::vector<double>>, std::string, std::string> read_dates(std::string path, bool verbose, std::ostream& output_stream, const std::string& encoding) {
			return _read_dates(path, verbose, output_stream, encoding);
		}

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
		std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::string> ,std::vector<std::string>, std::vector<std::vector<double>>, std::string, std::string> read_dates(std::string path, bool verbose, std::ostream& output_stream) {
			return(_read_dates(path, verbose, output_stream, ""));
		}

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
		 */
		std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::string>, std::vector<std::string>, std::vector<std::vector<double>>, std::string, std::string> read_dates(std::string path, bool verbose) {
			return(_read_dates(path, verbose, default_output_stream(), ""));
		}

	}
}
