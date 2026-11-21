/***********************************************************************************************
 * 
 * Function implementations for helpers.
 * 
 * AUTHOR: JULIAN MÄRTE (IAP-GmbH Intelligent Analytics Projects), LUCA BRINKMANN (IAP-GmbH Intelligent Analytics Projects), OLEKSANDER DOSKALIUK (IAP-GmbH Intelligent Analytics Projects)
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 * 
 ***********************************************************************************************/


#include "DataIO/helpers.hpp"

#include <iostream>
#include <exception>
#include <sstream>
#include <filesystem>
#include <limits>
#include <algorithm>
#include <regex>
#include <utility>
#include <cstdlib>
#include <cmath>
#include <stdexcept>


namespace dbt {
	namespace DataIO { //get_text_from_metadata_line

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
		 */
		std::string addext_checkext(std::string path, std::string ending) {
			const std::string invalidChars = R"(*?"<>)";

			if (std::any_of(path.begin(), path.end(), [&](char c) {
				return invalidChars.find(c) != std::string::npos;
				})) {
				throw std::invalid_argument("The path contains a character that is not permitted: " + path + ". Remove characters from this set: " + invalidChars + ".");
			}

			size_t last_dot_pos = path.find_last_of('.');

			// If no dot is found in the filename, append the ending
			if (last_dot_pos == std::string::npos) {
				return path + "." + ending;
			}
			else {
				std::string file_extension = path.substr(last_dot_pos + 1);
				// If ending after dot is correct use input path, else add the necessary ending
				if (file_extension == ending || file_extension == "csv") {
					return path;
				}
				else {
					return path + "." + ending;
				}
			}
		}

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
		 */
		bool file_exists(std::string path) {
			return std::filesystem::exists(path);
		}


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
		 */
		int is_valid_datetime(const std::string& datetime) {
			// Function that checks if the timestamp is one of the following formats
			// YYYY-MM-DD
			// or
			// YYYY-MM-DD hh:mm:ss
			// or
			// YYYY-MM-DD hh:mm:ss.ms
			// NOTE: Regex does not word with winbuild of R installation. Will compile but will have unexpected behaviour. 
			//std::basic_regex pattern("^(\\d{4}-(0[1-9]|1[0-2])-([0-2][0-9]|3[0-1])( (0[0-9]|1[0-9]|2[0-3]):(0[0-9]|[1-5][0-9]):(0[0-9]|[1-5][0-9])(\\.\\d{1,3})?)?$)");
			//return std::regex_match(time, pattern);

			//bool truncate_millis = false;

			std::istringstream iss(datetime);
			char dash1, dash2, colon1, colon2, dot;
			int year, month, day, hour = 0, minute = 0, second = 0, milliseconds = 0;

			// Attempt to parse the date part of the datetime string
			if (!(iss >> year >> dash1 >> month >> dash2 >> day)) {
				return -1; // Parsing failed
			}

			// Validate parsed components of the date part
			if (dash1 != '-' || dash2 != '-') {
				return -1;
			}
			if (year < 1000 || month < 1 || month > 12 || day < 1 || day > 31) {
				return -1;
			}

			if (iss.eof()) {
				return 1;
			}
			// Check if there's more to parse (optional time component)
			else if (!iss.eof() && iss.peek() == ' ') {
				// Attempt to parse the time part of the datetime string
				if (!(iss >> hour >> colon1 >> minute >> colon2 >> second)) {
					return -1;
				}

				if (colon1 != ':' || colon2 != ':') {
					return -1;
				}
				//if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59 || milliseconds < 0 || milliseconds > 999) {
				//	return -1;
				//}

				if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59) {
					return -1;
				}
			}

			if (iss.eof()) {
				return 2;
			}

			// Check if there's more to parse (optional millisecond component)
			else if (!iss.eof() && iss.peek() == '.') {
				if (!(iss >> dot >> milliseconds)) {
					return -1;
				}

				if (dot != '.') {
					return -1;
				}
				if (milliseconds < 0) {
					return -1;
				}
				else if (milliseconds > 999) {
					//truncate_millis = true;
					return 4;
				}
			}

			/**
			// Check for optional time zone information
			if (!iss.eof()) {
				// Extract the remaining part as time zone
				std::string remaining;
				std::getline(iss, remaining);

				// Trim leading spaces of the remaining string
				remaining.erase(0, remaining.find_first_not_of(" \t"));

				// Time zones should be non-empty and only consist of letters, spaces, or signs
				if (!remaining.empty()) {
					for (char c : remaining) {
						if (!std::isalpha(c) && !std::isspace(c) && c != '/' && c != '+' && c != '-') {
							return false; // Invalid characters in timezone
						}
					}
				}
			}
			return true;
			**/


			if (iss.eof()) {
				return 3;
			} else {
				return -1;
			}
		}


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
		 */
		std::tuple<std::string, std::string, int> get_datetime_and_dst(const std::string& datetime) {
			size_t lastSpacePos = datetime.rfind(' ');
			int time_resolution = -1;
			if (lastSpacePos != std::string::npos) {
				std::string dst = datetime.substr(lastSpacePos + 1);

				// Check if the potential dst starts with a letter (indicating a valid timezone)
				if (!dst.empty() && std::isalpha(dst[0])) {
					// Get the datetime without dst
					std::string datetime_without_dst = datetime.substr(0, lastSpacePos);
					time_resolution = dbt::DataIO::is_valid_datetime(datetime_without_dst);
					if (time_resolution == -1) {
						throw std::invalid_argument("Timestamp " + datetime + " is not of the necessary format!");
					} else if(time_resolution == 4) {
						size_t dotPosition = datetime.find_last_of('.');
						//if (dotPosition != std::string::npos) {
							// Truncate milliseconds to three entries
						datetime_without_dst = datetime_without_dst.substr(0, dotPosition + 4);
							//+ datetime.substr(dotPosition + 1, 3);
						//}
						time_resolution = 3;
					}
					return { datetime_without_dst, dst, time_resolution };
				}
			}

			time_resolution = dbt::DataIO::is_valid_datetime(datetime);
			if (time_resolution == -1) {
				throw std::invalid_argument("Timestamp " + datetime + " is not of the necessary format!");
			} else if (time_resolution == 4) {
				size_t dotPosition = datetime.find_last_of('.');
				//if (dotPosition != std::string::npos) {
					// Truncate milliseconds to three entries
				std::string datetime_truncated = datetime.substr(0, dotPosition + 4);
				time_resolution = 3;
				return { datetime_truncated, "" , time_resolution };
			}
			// If no valid timezone is found, return the original datetime and an empty string
			return { datetime, "" , time_resolution };
		}


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
		 */
		bool is_ms(std::string datetime) {
			// REGEX THAT CHECKS WHETHER A TIMESTAMP IS OF THE FORMAT
			// YYYY-MM-DD hh:mm:ss.ms
			//std::basic_regex pattern("^(\\d{4})-(\\d{2})-(\\d{2})\\s(\\d{2}):(\\d{2}):(\\d{2})\\.\\d{3}$");
			//return std::regex_match(datetime, pattern);

			std::istringstream iss(datetime);
			char dash1, dash2, space1, colon1, colon2;
			int year, month, day, hour, minute, second;
			char dot;
			int milliseconds;

			// Attempt to parse the date-time string
			if (!(iss >> year >> dash1 >> month >> dash2 >> day >> space1 >> hour >> colon1 >> minute >> colon2 >> second >> dot >> milliseconds)) {
				return false; // Parsing failed
			}
			return true;

		}

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
		 */
		bool is_s(std::string datetime) {
			// REGEX THAT CHECKS WHETHER A TIMESTAMP IS OF THE FORMAT
			// YYYY-MM-DD hh:mm:ss
			//std::basic_regex pattern("^(\\d{4})-(\\d{2})-(\\d{2})\\s(\\d{2}):(\\d{2}):(\\d{2})$");
			//return std::regex_match(datetime, pattern);

			std::istringstream iss(datetime);
			char dash1, dash2, space1, colon1, colon2;
			int year, month, day, hour, minute, second;

			// Attempt to parse the date-time string
			if (!(iss >> year >> dash1 >> month >> dash2 >> day >> space1 >> hour >> colon1 >> minute >> colon2 >> second)) {
				return false; // Parsing failed
			}
			return true;
		}

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
		 */
		bool is_d(std::string datetime) {
			// REGEX THAT CHECKS WHETHER A TIMESTAMP IS OF THE FORMAT
			// YYYY-MM-DD
			//std::basic_regex pattern("^(\\d{4})-(\\d{2})-(\\d{2})$");
			//return std::regex_match(datetime, pattern);

			std::istringstream iss(datetime);
			char dash1, dash2;
			int year, month, day;

			// Attempt to parse the date-time string
			if (!(iss >> year >> dash1 >> month >> dash2 >> day)) {
				return false; // Parsing failed
			}
			return true;
		}

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
		 */
		std::string extend_datetime_format(std::string datetime, int current_resolution, int wanted_resolution) {
			// EXTENDS A GIVEN TIME RESOLUTION TO A TARGET RESOLUTION
			// resolutions:
			// 1: YYYY-MM-DD, 2: YYYY-MM-DD hh:mm:ss, 3: YYYY-MM-DD hh:mm:ss.ms

			if (current_resolution == 1 && wanted_resolution == 2) {
				return(datetime + " 00:00:00");
			}
			if (current_resolution == 1 && wanted_resolution == 3) {
				return(datetime + " 00:00:00.000");
			}
			if (current_resolution == 2 && wanted_resolution == 3) {
				return(datetime + ".000");
			}
			return(datetime);
		}

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
		 */
		std::string shorten_datetime_format(std::string datetime, int current_resolution, int wanted_resolution) {
			// SHORTENS A GIVEN TIME RESOLUTION TO A TARGET RESOLUTION
			// resolutions:
			// 1: YYYY-MM-DD, 2: YYYY-MM-DD hh:mm:ss, 3: YYYY-MM-DD hh:mm:ss.ms

			if ((current_resolution == 3 || current_resolution == 2) && wanted_resolution == 1) {
				return(datetime.substr(0, 10));
			}
			if (current_resolution == 3 && wanted_resolution == 2) {
				return(datetime.substr(0, 19));
			}
			return(datetime);
		}

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
		 */
		std::string get_filename(std::string path) {
			std::filesystem::path p = path;
			std::filesystem::path filename = p.filename();
			return(filename.string());
		}

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
		 */
		std::ifstream open_read(std::string path) {
	    	std::filesystem::path p {path};

			if (!std::filesystem::exists(p.parent_path())) {
				throw std::invalid_argument("ERROR: Path " + p.parent_path().string() + " does not exist!");
			}

	    	if (!file_exists(path)) {
	    		throw std::invalid_argument("ERROR: File " + path + " does not exist under given path!");
	    	}

			std::ifstream res(path, std::ios::binary);

		    if (res.is_open()) {
		       	return res;
		    }

	        throw std::invalid_argument("ERROR: File " + path + " could not be read! Check if you have permissions for the requested file.");
		}

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
		 */
		std::string current_date_str() {
		    std::time_t now = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());

		    char buf[100] = {0};
		    std::strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", std::localtime(&now));
		    return buf;
		}

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
		 */
		std::ofstream open_write(std::string path, bool verbose, std::ostream& output_stream) {
	    	std::filesystem::path p {path};
	    	if (!std::filesystem::exists(p.parent_path())) {
	    		if (!std::filesystem::create_directories(p.parent_path())) {
	    			throw std::invalid_argument("ERROR: Directory " + p.parent_path().string() + " could not be created! Check if you have permissions for the requested folder.");
				} else {
					if (verbose) output_stream << "INFO: Created new subdirectory/subdirectories in given path " + p.string() << std::endl;
				}
	    	}

	    	bool existed = std::filesystem::exists(p);

			std::ofstream res(path, std::ofstream::trunc);

		    if (res.is_open()) {
		    	if (existed) {
		    		if (verbose)
						output_stream << "WARNING: Overwriting contents of file " + p.string() + " now!" << std::endl;
		    	}
		       	return res;
		    }

	        throw std::invalid_argument("ERROR: File " + path + " could not be created! Check if you have permissions for the requested folder.");
		}

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
		 */
		void close_write(std::ofstream& stream) {
			if (stream.is_open()) {
		        // Writes and close/flush could fail silently; close first, then report failure.
		        const bool write_failed = !stream;
		        stream.close();
		        if (write_failed || !stream)
		            throw std::runtime_error("ERROR: Writing or closing the output file failed; the file may be incomplete.");
		    } else {
		        throw std::invalid_argument("ERROR: Attempted a double close on a file output stream.");
		    }
		}

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
         */
        bool is_valid_colname(std::string name) {
			// Empty names and signed UTF-8 bytes need safe character checks.
			if (name.empty() || std::isdigit(static_cast<unsigned char>(name[0]))) return false;
        	std::transform(name.begin(), name.end(), name.begin(), [](unsigned char c) { return std::tolower(c); });
        	return name.find_first_not_of("abcdefghijklmnopqrstuvwxyz0123456789_.-=?&$§") == std::string::npos;
        }

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
		std::string clean_column_name(std::string name, std::ostream& output_stream) {
			// Rejecting spaces stopped valid data output. Remove header separators and warn.
			// Apply this only to labels; Names and FurtherTexts remain text values.
			if (name.find_first_of("\r\n") != std::string::npos || name.find('\0') != std::string::npos)
				throw std::invalid_argument("Header names must not contain line breaks or NUL characters.");
			if (name.find_first_of(" \t,;") != std::string::npos) {
				name.erase(std::remove_if(name.begin(), name.end(), [](char c) {
					return c == ' ' || c == '\t' || c == ',' || c == ';';
				}), name.end());
				output_stream << "WARNING: Removed spaces, tabs, commas, or semicolons from a Header label. Using \"" << name << "\"." << std::endl;
			}
			if (name.empty())
				throw std::invalid_argument("Header names must not be empty after removing separators.");
			if (!is_valid_colname(name))
				output_stream << "WARNING: Column name \"" << name << "\" does not follow the naming rules. Keeping it unchanged." << std::endl;
			return name;
		}

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
		bool contains_break(const std::string s) {
			for (char c : s) {
				if (c == '\t' || c == '\n' || c == '\r') {
					return true;
				}
			}
			return false;
		}

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
		 */
		std::string clean_string(std::string s) {
			// Replace line breaks, tabs, and spaces with underscores. Leading whitespaces will be removed, rest is replaced with _.
			
			s.erase(std::remove(s.begin(), s.end(), '\t'), s.end());
			s.erase(std::remove(s.begin(), s.end(), '\r'), s.end());
			s.erase(std::remove(s.begin(), s.end(), '\n'), s.end());

			return s;
			
		}

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
		 */
		std::string to_lower_string(std::string s) {
			std::string res = s;
			std::transform(res.begin(), res.end(), res.begin(), [](unsigned char c) {
				return std::tolower(c);
				});
			return res;
		}


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
		 */
		bool ends_with(const std::string& str, const std::string& suffix) {
			if (str.size() < suffix.size()) {
				return false;
			}
			return str.compare(str.size() - suffix.size(), suffix.size(), suffix) == 0;
		}

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
		 */
		std::pair<std::vector<std::string>, std::streampos> read_header_lines(std::istream& inputFile, std::ostream& output_stream, bool verbose) {
			std::string line;
			std::vector<std::string> headerLines;
			std::streampos posAfterHeader;
			bool missingSymbol = false;

			while (true) {
				std::streampos prevPos = inputFile.tellg();
				if (!std::getline(inputFile, line)) {
					throw std::runtime_error("Failed to read a line");
				}
				// Tab-only records after a header are missing data rows, not blank separators.
				if (std::all_of(line.begin(), line.end(), isspace) &&
					(headerLines.empty() || line.find('\t') == std::string::npos)) continue;
				if (line.empty() || (line[0] != '#' && line[0] != '%' && line[0] != '<')) {
					if (headerLines.empty()) {
						if (verbose && !missingSymbol) output_stream << "WARNING: Could not find header/type symbols \"#\" or \"%\" at document beginning. Lines of document will be ignored until one of these symbols are found at the beginning of a line" << std::endl;
						missingSymbol = true;
						continue;
					} else {
						// We've reached the end of the header, break the loop
						posAfterHeader = prevPos;
						break;
					}

				}
				// handle CRLF
				if (line.ends_with('\r')) {
					headerLines.push_back(line.substr(0, line.size() - 1));
				} else {
					headerLines.push_back(line);
				}
			}

			return {headerLines, posAfterHeader};
		}

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
		 */
		std::string parse_format_line(const std::string& format_line, const std::string& format_name, bool verbose, std::ostream& output_stream) {
			//int version_major = 1;
			//int version_minor = 0;
			bool has_version = false;

			if (format_line.starts_with("#<?" + format_name)) {
				std::size_t start = format_line.find("version=\"");
				if (start != std::string::npos) {
					start += 9; // length of "version=\""
					std::size_t end = format_line.find("\"", start);
					std::size_t dot = format_line.find(".", start);
					if (dot != std::string::npos && dot < end) {
						//version_major = std::stoi(format_line.substr(start, dot - start));
						//version_minor = std::stoi(format_line.substr(dot + 1, end - dot - 1));
						has_version = true;
					}
				}
			} else if (format_line.starts_with("<?")) {
				throw std::invalid_argument("File has escaped header line \"<?\" but the type that follows is not" + format_name + "!");
			}

			if (verbose) {
				if (!has_version) {
					output_stream << "No version found; proceeding with reader version: 1.0!" << std::endl;
				}
				//output_stream << "Reader version: " << (has_version ? std::to_string(version_major) + "." + std::to_string(version_minor) : "1.0") << "!" << std::endl;
			}

			return "";
		}

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
		 */
		std::vector<std::string> parse_column_names(const std::string& columns_line, const std::vector<std::string>& mandatory_columns, std::ostream* warning_stream) {
			std::vector<std::string> column_names;
			std::stringstream col_names(columns_line);
			std::string col_name;
			unsigned int column_count = 0;
			
			while (std::getline(col_names, col_name, '\t')) {
				if (warning_stream) {
					col_name = clean_column_name(col_name, *warning_stream);
				} else if (!dbt::DataIO::is_valid_colname(col_name)) {
					throw std::invalid_argument("Column name " + col_name + " contains invalid symbols! Is not allowed to start with a digit and should only contain alphanumeric " + 
						"values or the following symbols: . - = ? & $ §");
				}

				if(column_count < mandatory_columns.size()) {
					// We have maximal two mandatory columns at the beginning
					switch (column_count) {
						case 0:
							if (col_name != mandatory_columns[0]) {
								throw std::invalid_argument("First column name has to be \"" + mandatory_columns[0] + "\"!");
							}
							break;
						case 1:
							if (col_name != mandatory_columns[1]) {
								throw std::invalid_argument("Second column name has to be \"" +  mandatory_columns[1] + "\"!");
							}
							break;
					}
				}

				column_names.push_back(col_name);
				column_count++;
			}

			return column_names;
		}

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
		 */
		std::string get_text_from_metadata_line(const std::string& line) {
			std::size_t idx = line.substr(1).find_first_not_of(" \t");
			// npos + 1 wrapped to zero and returned "# " for a blank user comment.
			return idx == std::string::npos ? "" : line.substr(idx + 1);
		}

		// stoi rejected keys above 32 bits. Parse 64 bits and enforce the shared range.
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
		Key parse_key_cell(const std::string& text, std::size_t* consumed) {
			const auto value = std::stoll(text, consumed);
			if (value < -MAX_EXACT_KEY || value > MAX_EXACT_KEY)
				throw std::out_of_range("Key is outside the exact integer range +/-2^53.");
			return static_cast<Key>(value);
		}

		// stod throws on underflow even when strtod produced a representable subnormal.
		// Recover that nonzero finite value; keep existing errors for overflow/underflow to zero.
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
		double parse_numeric_cell(const std::string& text, std::size_t* consumed) {
			try {
				return std::stod(text, consumed);
			} catch (const std::out_of_range&) {
				char* end = nullptr;
				const double value = std::strtod(text.c_str(), &end);
				if (end != text.c_str() && std::isfinite(value) && value != 0.0) {
					if (consumed) *consumed = static_cast<std::size_t>(end - text.c_str());
					return value;
				}
				throw;
			}
		}

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
		void warn_numeric_suffix(const std::string& text, std::size_t consumed, std::ostream& output_stream) {
			// stoi/stod accepted numeric prefixes silently; retain that value but warn about non-whitespace suffixes.
			if (consumed < text.size() && text.find_first_not_of(" \t\r\n\f\v", consumed) != std::string::npos)
				output_stream << "WARNING: Numeric field \"" << text << "\" has additional text. The reader keeps the numeric prefix \""
					<< text.substr(0, consumed) << "\". The reader ignores the additional text \"" << text.substr(consumed) << "\"." << std::endl;
		}

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
		void process_file_body(const std::vector<char>& fileContents, std::vector<Key>& keys, std::vector<std::string>& values, std::vector<std::string>& dst, std::vector<std::vector<std::string>>& further_texts, bool has_dst_info, std::ostream& output_stream) {
			const size_t reserved_cols = has_dst_info ? 3 : 2;
			const size_t columns = reserved_cols + further_texts.size();
			size_t j = 0;
			std::string word;
			word.reserve(50);
			bool missing = false;

			// Previously short/long rows misaligned columns or indexed past their end.
			// Keep each row, pad missing text with NA, and ignore undeclared fields.
			// Complete one field.
			//
			// INPUT
			// Captured word and j: current field text and zero-based position.
			// Captured columns, has_dst_info, keys, values, dst, and further_texts: parse state.
			// Captured output_stream: warning destination.
			//
			// OUTPUT
			// Appends the current field to its destination or ignores an extra field.
			// Clears word, advances j, and updates the missing-field flag.
			// SPDX-License-Identifier: AGPL-3.0-only
			// Additional permission: see MATLAB-EXCEPTION.txt.
			auto store_field = [&]() {
				if (j == 0) {
					try {
						std::size_t consumed = 0;
						keys.push_back(parse_key_cell(word, &consumed));
						warn_numeric_suffix(word, consumed, output_stream);
					} catch (const std::exception&) {
						// Integer keys cannot hold NaN; use the reserved missing-key marker.
						keys.push_back(MISSING_KEY);
						output_stream << "WARNING: Row " << keys.size() << " has an invalid or missing key. The reader uses a missing key value." << std::endl;
					}
				} else if (j < columns) {
					if (word.empty()) { word = "NA"; missing = true; }
					if (j == 1) values.push_back(word);
					else if (has_dst_info && j == 2) dst.push_back(word);
					else further_texts[j - reserved_cols].push_back(word);
				}
				word.clear();
				++j;
			};
			// Complete one buffered data row.
			//
			// INPUT
			// Captured store_field: field parser for the current row.
			// Captured columns, j, word, and missing: row state.
			// Captured output_stream and keys: warning destination and current row count.
			//
			// OUTPUT
			// Stores the last field, pads short rows, and emits row-width warnings.
			// Resets j and missing for the next row.
			// SPDX-License-Identifier: AGPL-3.0-only
			// Additional permission: see MATLAB-EXCEPTION.txt.
			auto finish_row = [&]() {
				store_field();
				const size_t fields = j;
				while (j < columns) store_field();
				if (fields != columns || missing)
					output_stream << "WARNING: Row " << keys.size() << " has " << fields << " fields; expected " << columns
						<< ". Missing cells filled with NA/NaN; extra fields ignored." << std::endl;
				j = 0;
				missing = false;
			};

			// Read the existing buffer directly; the old copy doubled file-buffer memory.
			for (char current_char : fileContents) {
				if (current_char == '\r') continue;
				if (current_char == '\t') store_field();
				else if (current_char == '\n') {
					if (j != 0 || !word.empty()) finish_row();
				} else word += current_char;
			}
			// Also finish a last row without a newline, including an empty final field.
			if (j != 0 || !word.empty()) finish_row();
		}

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
		 */
		int decimal_positions(std::string strValue, bool non_zero) {
			// Find the position of the decimal point
			size_t decimalPos = strValue.find('.');
			if (decimalPos == std::string::npos) {
				return 0; // No decimal point means no decimal places
			}

			if (non_zero) {
				// Iterate through characters after the decimal point
				for (size_t i = decimalPos + 1; i < strValue.length(); ++i) {
					if (strValue[i] != '0') {
						return i - decimalPos; // Position is 1-based after the decimal point
					}
				}
			}
			else {
				// If in the future trailing zeros are wanted, this can be used
				// Return the total number of digits after the decimal point
				std::size_t pos = strValue.find_last_not_of('0');
				if (pos > decimalPos) {
					return pos - decimalPos;
				}
				else {
					return 0; // There are no significant decimal places
				}
			}

			return 0; // All digits after the decimal point are zero or no digits after the decimal point
		}

		// Get the number of significant numbers behind the decimal place for every column, through finding the absolute smallest measurement and from the first
		// non-zero entry behind the decimal point, the significant digits are counted. This is similar to the R format function, when digits is used.
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
		 */
		std::vector<int> signif_per_col(std::vector<std::vector<double>>& numerics, int significant_digits) {

			size_t numRows = numerics.size();
			size_t numCols = numerics[0].size();
			std::vector<double> min_abs_values(numCols, std::numeric_limits<double>::max());
			std::vector<int> max_decimal_places(numCols, 0);
			std::vector<int> signif_decimal_pos(numCols, 0);


			// Iterate through each column
			for (size_t col = 0; col < numCols; ++col) {
				// Examine values directly; the former copied column was never used.
				for (size_t row = 0; row < numRows; ++row) {
					double v = numerics[row][col];
					double abs_v = std::abs(v);
					if (v != 0 && abs_v < min_abs_values[col]) min_abs_values[col] = abs_v;
					std::stringstream ss;
					ss << std::fixed << std::setprecision(15) << v;
					int d = decimal_positions(ss.str(), false);
					if (d > max_decimal_places[col]) max_decimal_places[col] = d;
				}
			}

			// Get the first non zero value after the decimal point (if there is any) and determine the place of the first non-zero entry, ignore trailing zeros.
			for (size_t i = 0; i < numCols; i++) {
				double min_abs_val = min_abs_values[i];
				std::stringstream ss;
				ss << std::fixed << std::setprecision(15) << min_abs_val;

				int p = decimal_positions(ss.str(), true);

				int k = 0;

				int decimalPos = ss.str().find('.');
				// if p = 0, we change nothing. Same counts for the case, that the digits before the decimal point are more than significant_digits
				if (p != 0) {
					// k is the number of significant digits, after the decimal, which we want to keep
					if (min_abs_val < 1) k = p + (significant_digits - 1);
					// If digits are before the decimal point (we ignore 0), then take them into account
					else k = significant_digits - decimalPos;
					if (k < 0) k = 0;
					// if the number of significant digits for the decimal places is greater than the maximal decimal places in data, we cap at this value
					if (k > max_decimal_places[i]) k = max_decimal_places[i];
				}
				signif_decimal_pos[i] = k;
			}

			return signif_decimal_pos;
		}
	}
}
