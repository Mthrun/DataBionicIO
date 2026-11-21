/***********************************************************************************************
 * 
 * Function implementations for read_lrn.
 * 
 * AUTHOR: JULIAN MÄRTE (IAP-GmbH Intelligent Analytics Projects), LUCA BRINKMANN (IAP-GmbH Intelligent Analytics Projects)
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 * Reimplemented from the original R function ReadLRN by Michael Thrun.
 * 
 ***********************************************************************************************/


#include "DataIO/read_lrn.hpp"

#include <iostream>
#include <fstream>
#include <exception>
#include <sstream>
#include <filesystem>
#include <limits>
#include <utility>
#include <regex>
#include <algorithm>

#include "DataIO/helpers.hpp"
#include "DataIO/text_encoding.hpp"
#include "DataIO/legacy_readers.hpp"


namespace dbt {
	namespace DataIO {

		/**
		 * Consume one line in the incremental LRN reader.
		 *
		 * INPUT
		 * line  File line without its line terminator.
		 * verbose  Select information messages.
		 * this  Reader state, including its diagnostic stream.
		 *
		 * OUTPUT
		 * Updates metadata or appends a data row. Invalid metadata throws; recoverable row errors cause warnings.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		void LRN_Reader::readNextLine(const std::string& line, bool verbose) {
			std::string line_copy = line;

			if (first_line) {
				// Legacy entry point: parse the version before selecting old header rules.
				// The old substring lost the closing quote when the tag had no timestamp.
				const bool legacy_format = legacy::is_legacy_format(line_copy, "lrn");
				const bool has_version = line_copy.starts_with("#<?lrn ");
				version_major = legacy_format ? 1 : 2;
				version_minor = 0;
				if (has_version) line_copy.clear();

				if (verbose) {
					if (!has_version) {
						if(verbose) (*output_stream) << "No version found; proceeding with reader version: 1.0!" << std::endl;
					}
					// Currently this output is not wanted
					//else {
					//	(*output_stream) << "Reader version: " << version_major << "." << version_minor << "!" << std::endl;
					//}
				}

				first_line = false;
			}

			const auto start = line_copy.find_first_not_of(" \t");
			if (start == std::string::npos) {
				// A row of tabs contains missing cells; keep it after the header.
				if (!has_header || line_copy.find('\t') == std::string::npos) return;
			} else {
				// Keep the last header label intact until its separators are removed with a warning.
				const auto end = (!has_header && has_types && line_copy[start] == '%')
					? line_copy.size() - 1 : line_copy.find_last_not_of(" \t");
				const auto range = end - start + 1;
				line_copy = line_copy.substr(start, range);
			}

			// Legacy entry point: adapt old metadata, then use the current header parser.
			if (version_major == 1 && N >= 0 && d >= 0 && !has_header)
				legacy::lrn_header(line_copy, d, has_types, legacy_key_column, *output_stream);

			if (line_copy == "")
				return;
			if (line_copy.starts_with("#")) {
				// COMMENT
				line_copy = line_copy.substr(1);
				std::size_t idx = line_copy.find_first_not_of(" \t");
				// Blank comment lines yielded npos and threw; preserve their empty text safely.
				if (idx == std::string::npos) idx = line_copy.size();
				if (comment == "")
					comment += line_copy.substr(idx);
				else
					comment += "\n" + line_copy.substr(idx);
				return;
			}
			else if (line_copy.starts_with("%")) {
				// HEADER
				line_copy = line_copy.substr(1);
				std::size_t idx = line_copy.find_first_not_of(" \t");
				line_copy = line_copy.substr(idx);

				if (N < 0) {
					N = std::stoi(line_copy);
				}
				else if (d < 0) {
					d = std::stoi(line_copy);
				}
				else if (types.empty()) {
					// read types
					std::stringstream types_line(line_copy);
					std::string type;
					bool first = true;
					while (std::getline(types_line, type, '\t')) {
						if (type != "") {
							int type_int;
							try {
								type_int = std::stoi(type);
							}
							catch (...) {
								throw std::invalid_argument("Type \"" + type + "\" could not be cast into an integer! ");
							}
							if (first) {
								if (type_int != 9)
									throw std::invalid_argument("First column is not a key column!");
								first = false;
							}
							types.push_back(type_int);
						}
					}

					if (static_cast<int>(types.size()) != d) {
						throw std::invalid_argument(std::to_string(types.size()) + " column names are defined but by header definition we have " + std::to_string(d) + " columns of data!");
					}

					has_types = true;
				}
				else {
					// have types, now comes column names
					std::stringstream col_names(line_copy);
					std::string col_name;
					while (std::getline(col_names, col_name, '\t')) {
						col_name = clean_column_name(col_name, *output_stream);
						if (!has_keys) {
							if (col_name != "Key") {
								throw std::invalid_argument("First column name has to be \"Key\"!");
							}
							has_keys = true;
						} else {
							column_names.push_back(col_name);
						}
					}

					if (static_cast<int>(column_names.size()) + 1 != d) {
						throw std::invalid_argument(std::to_string(column_names.size()) + " column names are defined but by header definition we have " + std::to_string(d) + " columns of data!");
					}

					has_header = true;
					numerics.reserve(N);
					keys.reserve(N);
				}
			}
			else {
				if (!has_header || !has_types) {
					throw std::invalid_argument("A non-escaped line (#, %) was found before a header/type section was completed! Something seems to be wrong with the header section...");
				}

				// Short rows previously reached unchecked matrix indexing; keep the declared width.
				std::vector<double> x(d - 1, std::numeric_limits<double>::quiet_NaN());
				// Legacy entry point: move or generate keys without copying number parsing.
				std::string adapted_line;
				if (version_major == 1 && (legacy_key_column != 0 ||
					(line.find('\t') == std::string::npos && line.find_first_of(" \f\v") != std::string::npos)))
					adapted_line = legacy::lrn_row(line, d, legacy_key_column, static_cast<Key>(row) + 1, *output_stream);
				const std::string& body_line = adapted_line.empty() ? line : adapted_line;
				std::stringstream vals(body_line); // Preserve leading/trailing tabs (missing cells).
				std::string val;
				int j = 0;
				bool missing = false;
				while (std::getline(vals, val, '\t')) {
					if (j == 0) {
						// Keep a readable numeric prefix; warn if trailing characters were ignored.
						try {
							std::size_t consumed = 0;
							keys.push_back(parse_key_cell(val, &consumed));
							warn_numeric_suffix(val, consumed, *output_stream);
						}
						catch (...) {
							keys.push_back(MISSING_KEY); // Missing key, not an invented ID.
							(*output_stream) << "WARNING: LRN row " << row + 1 << " has an invalid or missing key. The reader uses a missing key value." << std::endl;
						}
					} else if (j < d) {
						// Missing cells caused conversion exceptions; keep NaN and the same row warning directly.
						if (val.empty() || val == "NA") missing = true;
						else try {
							std::size_t consumed = 0;
							x[j - 1] = parse_numeric_cell(val, &consumed);
							warn_numeric_suffix(val, consumed, *output_stream);
						}
						catch (...) {
							missing = true; // Empty, NA or invalid numeric cell stays NaN.
						}
					}
					++j;
				}
				if (!body_line.empty() && body_line.back() == '\t') { ++j; missing = true; }
				if (j != d || missing)
					(*output_stream) << "WARNING: LRN row " << row + 1 << " has " << j << " fields; expected " << d
						<< ". Missing/invalid cells filled with NaN; extra fields ignored." << std::endl;
				// Transfer the completed row instead of copying its allocation.
				numerics.push_back(std::move(x));
				row++;
			}
		}


		/**
		 * Copy the accumulated LRN result.
		 *
		 * INPUT
		 * this  Reader state after zero or more readNextLine calls.
		 *
		 * OUTPUT
		 * Tuple: data-column labels, keys, numeric rows, type codes including Key, comments.
		 * Invalid keys use MISSING_KEY; invalid numeric cells use NaN. Actual rows are retained.
		 * A mismatch between the declared and actual row count causes a warning.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::vector<double>>, std::vector<int>, std::string> LRN_Reader::getLRN() {
			if (row != N) {
				// A stale row count must not discard actual rows.
				(*output_stream) << "WARNING: LRN header declares " << N << " rows. The reader keeps all " << row << " actual rows." << std::endl;
			}
			return { column_names, keys, numerics, types, comment };
		}

		/**
		 * Compare the consumed and declared row counts.
		 *
		 * INPUT
		 * this  Reader state containing row and N.
		 *
		 * OUTPUT
		 * TRUE exactly when row equals N; this does not check the input stream for EOF.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		bool LRN_Reader::isFinished() {
			if (row != N) {
				return false;
			} else {
				return true;
			}
		}


		
		/**
		 * Read a LRN file through the shared core.
		 *
		 * INPUT
		 * path  Filesystem path.
		 * verbose  Select information messages; data warnings can remain active.
		 * output_stream  Destination stream for diagnostics.
		 *
		 * OUTPUT
		 * Tuple: data-column labels, keys, numeric rows, type codes including Key, comments.
		 * Invalid keys use MISSING_KEY; invalid numeric cells use NaN. Actual rows are retained.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::vector<double>>, std::vector<int>, std::string> read_lrn(std::string path, bool verbose, std::ostream& output_stream) {
			return read_lrn(path, verbose, output_stream, "");
		}

		// INPUT: path, diagnostic settings, and optional input encoding.
		// OUTPUT: decoded LRN fields; malformed encoding throws.
		// SPDX-License-Identifier: AGPL-3.0-only
		// Additional permission: see MATLAB-EXCEPTION.txt.
		std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::vector<double>>, std::vector<int>, std::string> read_lrn(std::string path, bool verbose, std::ostream& output_stream, const std::string& encoding) {
			path = addext_checkext(path, "lrn");
			TextInput stream(open_read(path), encoding, output_stream);
			LRN_Reader doc;
			doc.output_stream = &output_stream;

			for (std::string line; getline(stream, line);) {
				// handle CRLF
				if (!line.empty() && line.back() == '\r') {
					line.pop_back();
				}
				// Preserve tab-only data records so missing cells do not remove a row.
				if (line.empty() || (line.find('\t') == std::string::npos && std::all_of(line.begin(), line.end(), isspace))) continue;

				doc.readNextLine(line, verbose);
			}

			// The local reader is finished: move its data instead of copying the complete matrix.
			if (!doc.isFinished())
				output_stream << "WARNING: LRN header declares " << doc.N << " rows. The reader keeps all " << doc.row << " actual rows." << std::endl;
			return { std::move(doc.column_names), std::move(doc.keys), std::move(doc.numerics), std::move(doc.types), std::move(doc.comment) };
		}

		/**
		 * Read a LRN file through the shared core.
		 *
		 * INPUT
		 * path  Filesystem path.
		 * verbose  Select information messages; data warnings can remain active.
		 *
		 * OUTPUT
		 * Tuple: data-column labels, keys, numeric rows, type codes including Key, comments.
		 * Invalid keys use MISSING_KEY; invalid numeric cells use NaN. Actual rows are retained.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		std::tuple<std::vector<std::string>, std::vector<Key>, std::vector<std::vector<double>>, std::vector<int>, std::string> read_lrn(std::string path, bool verbose) {
			return read_lrn(path, verbose, default_output_stream());
		}
	}
}
