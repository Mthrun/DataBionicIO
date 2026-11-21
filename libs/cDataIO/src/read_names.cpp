/***********************************************************************************************
 *
 * Function implementations for read_names.
 *
 * AUTHOR: LUCA BRINKMANN (IAP-GmbH Intelligent Analytics Projects), OLEKSANDER DOSKALIUK (IAP-GmbH Intelligent Analytics Projects)
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 * Reimplemented from the original R function ReadNAMES by Michael Thrun.
 *
 ***********************************************************************************************/


#include "DataIO/read_names.hpp"

#include <iostream>
#include <fstream>
#include <exception>
#include <sstream>
#include <filesystem>
#include <limits>
#include <utility>

#include "DataIO/helpers.hpp"
#include "DataIO/text_encoding.hpp"
#include "DataIO/legacy_readers.hpp"

namespace dbt {
	namespace DataIO {
		struct FileHeaderMetadata {
			int number_of_records;
			int number_of_columns;
			std::vector<std::string> column_names;
			std::string names_format;
			std::string comment;
		};

		/**
		 * Read NAMES counts, labels, and comments.
		 *
		 * INPUT
		 * headerLines  Header lines in file order, including metadata markers.
		 * mandatory_columns  Required leading column labels.
		 * format_name  Expected format name, such as names or dates.
		 * verbose  Select information messages; data warnings can remain active.
		 * output_stream  Destination stream for diagnostics.
		 *
		 * OUTPUT
		 * FileHeaderMetadata; legacy files can omit column metadata. Invalid counts or labels throw.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		FileHeaderMetadata process_header_lines(const std::vector<std::string>& headerLines, const std::vector<std::string>& mandatory_columns, const std::string& format_name, bool verbose = true, std::ostream& output_stream = default_output_stream()) {
			if (headerLines.empty()) {
				throw std::invalid_argument("Header lines are empty!");
			}

			// Legacy entry point: only untagged or version 1.0 files can omit metadata.
			const bool legacy_format = legacy::is_legacy_format(headerLines[0], format_name);
			std::string names_format = parse_format_line(headerLines[0], format_name, verbose, output_stream);
			std::vector<std::string> column_names;
			std::string comment = "";
			bool found_comment = false;
			int N = -1;
			int d = -1;

			int it_offset = names_format.empty() ? 0 : 1;

			for (auto it = headerLines.begin() + it_offset; it != headerLines.end(); ++it) {
				const auto& line = *it;
				if (line.starts_with("#")) {
					// The OR condition was always true and mixed the generation tag into user comments.
					if (!line.starts_with("#<?names") && !line.starts_with("<?names")) {
						std::string comment_line = get_text_from_metadata_line(line);
						// An empty first comment is still a line; keep its separator.
						if (found_comment) comment += "\n";
						comment += comment_line;
						found_comment = true;
					}
				} 
				else if (line.starts_with("%")) {
					// META DATA
					std::string meta_data_line = get_text_from_metadata_line(line);
					if (N < 0) {
						N = std::stoi(meta_data_line);
					}
					else if (d < 0) {
						// Legacy entry point: old files can omit the column-count line.
						d = legacy_format ? legacy::names_column_count(meta_data_line, column_names, output_stream) : std::stoi(meta_data_line);
						if (d < 2) throw std::invalid_argument("NAMES needs at least Key and Names columns.");
					} 
					else {
						// column names
						column_names = parse_column_names(meta_data_line, mandatory_columns, &output_stream);
					}
				}
			}

			if (N < 0 || (d < 0 && !legacy_format))
				throw std::invalid_argument("NAMES requires row and column counts.");
			if (d >= 0 && static_cast<int>(column_names.size()) != d) {
				throw std::invalid_argument(std::to_string(column_names.size()) + " column names are defined but by header definition we have " + std::to_string(d) + " columns of data!");
			}

			return {N, d, column_names, names_format, comment};
		}

		/**
		 * Read a NAMES file through the shared core.
		 *
		 * INPUT
		 * path  Filesystem path.
		 * verbose  Select information messages; data warnings can remain active.
		 * output_stream  Destination stream for diagnostics.
		 * encoding  Optional source encoding; empty selects BOM detection, otherwise UTF-8.
		 *
		 * OUTPUT
		 * Tuple: all column labels, keys, names, additional text columns, comments.
		 * The additional text uses one vector per column; missing text is NA.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::string>, std::vector<std::vector<std::string>>, std::string> _read_names(std::string path, bool verbose, std::ostream& output_stream, const std::string& encoding) {
			std::vector<Key> keys;
			std::vector<std::string> names;
			std::vector<std::vector<std::string>> further_texts;
			std::string comment = "";

			std::vector<std::string> MANDATORY_COLUMNS = { "Key"};

			std::string FORMAT_NAME = "names";

			path = addext_checkext(path, FORMAT_NAME);

			TextInput inputFile(std::ifstream(path, std::ios::binary), encoding, output_stream);
			if (!inputFile) {
				throw std::invalid_argument("Failed to open file");
			}

			auto [headerLines, posAfterHeader] = read_header_lines(inputFile, output_stream, verbose);

			FileHeaderMetadata file_metadata = process_header_lines(headerLines, MANDATORY_COLUMNS, FORMAT_NAME, verbose, output_stream);

			inputFile.seekg(posAfterHeader);

			auto fileContents = inputFile.read_remaining();
			// close file stream
			inputFile.close();
			
			keys.reserve(file_metadata.number_of_records);
			names.reserve(file_metadata.number_of_records);
			
			// Legacy entry point: infer a missing width once, before reading data cells.
			if (file_metadata.number_of_columns == -1) {
				file_metadata.column_names = legacy::names_columns(fileContents, verbose, output_stream);
				file_metadata.number_of_columns = static_cast<int>(file_metadata.column_names.size());
			}
			if (file_metadata.number_of_columns > 2) {
				further_texts.resize(file_metadata.number_of_columns - 2);
				for (auto& column : further_texts) column.reserve(file_metadata.number_of_records);
			}

			std::vector<std::string> dst; // for read names, this is just a dummy here and not needed
			process_file_body(fileContents, keys, names, dst, further_texts, false, output_stream);
			
			if (keys.size() != static_cast<unsigned int>(file_metadata.number_of_records)) {
				// Keep actual rows when N is stale; previously an otherwise readable file failed.
				output_stream << "WARNING: Header declares " << file_metadata.number_of_records << " rows. The reader keeps all " << keys.size() << " actual rows." << std::endl;
			}			

			// Transfer the completed result instead of copying all text columns.
			return { std::move(file_metadata.column_names), std::move(keys), std::move(names), std::move(further_texts), std::move(file_metadata.comment) };

		}

		// INPUT: path, diagnostics, optional input encoding.
		// OUTPUT: decoded fields; malformed encoding throws.
		// SPDX-License-Identifier: AGPL-3.0-only
		// Additional permission: see MATLAB-EXCEPTION.txt.
		std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::string>, std::vector<std::vector<std::string>>, std::string> read_names(std::string path, bool verbose, std::ostream& output_stream, const std::string& encoding) {
			return _read_names(path, verbose, output_stream, encoding);
		}

		/**
		 * Read a NAMES file through the shared core.
		 *
		 * INPUT
		 * path  Filesystem path.
		 * verbose  Select information messages; data warnings can remain active.
		 * output_stream  Destination stream for diagnostics.
		 *
		 * OUTPUT
		 * Tuple: all column labels, keys, names, additional text columns, comments.
		 * The additional text uses one vector per column; missing text is NA.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::string>, std::vector<std::vector<std::string>>, std::string> read_names(std::string path, bool verbose, std::ostream& output_stream) {
			return(_read_names(path, verbose, output_stream, ""));
		}

		/**
		 * Read a NAMES file through the shared core.
		 *
		 * INPUT
		 * path  Filesystem path.
		 * verbose  Select information messages; data warnings can remain active.
		 *
		 * OUTPUT
		 * Tuple: all column labels, keys, names, additional text columns, comments.
		 * The additional text uses one vector per column; missing text is NA.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::string>, std::vector<std::vector<std::string>>, std::string> read_names(std::string path, bool verbose) {
			return(_read_names(path, verbose, default_output_stream(), ""));
		}
	}
}
