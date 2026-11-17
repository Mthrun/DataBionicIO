/***********************************************************************************************
 *
 * Function implementations for write_names.
 *
 * AUTHOR: LUCA BRINKMANN (IAP-GmbH Intelligent Analytics Projects)
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 * Reimplemented from the original R function WriteNAMES by Michael Thrun.
 *
 ***********************************************************************************************/


#include "DataIO/write_names.hpp"

 // IO
#include <filesystem>
#include <iostream>
#include <fstream>
#include <sstream>
#include <utility>
#include <unordered_set>
#include <algorithm>

#include "DataIO/helpers.hpp"

namespace dbt {
	namespace DataIO {

		/**
		 * Write a NAMES file in format 2.0.
		 *
		 * INPUT
		 * names  One name string per record.
		 * column_names  Column labels in file order; empty writer input selects default labels.
		 * keys  Row keys in [-2^53, 2^53]; an empty writer input selects keys 1:n.
		 * further_texts  Additional text table with one record per inner vector.
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
		void _write_names(std::vector<std::string> names, std::vector<std::string> column_names, std::vector<Key> keys, std::vector<std::vector<std::string>> further_texts, std::string path, std::string comment, bool overwrite, bool verbose, int version_major, int version_minor, std::ostream& output_stream) {
			// The layout is 2.0; older version arguments must not label it as a legacy file.
			if (version_major != 2 || version_minor != 0)
				throw std::invalid_argument("Only format version 2.0 is supported for writing.");
			path = addext_checkext(path, "names");

			if (!overwrite && file_exists(path)) {
				throw std::invalid_argument("The file " + path + " already exists! Consider to set overwrite=true if you want the contents to be overwritten!");
			}

			int N = names.size();
			//int M = static_cast<int>(further_texts.size())
			int M = further_texts.size();

			if (M != 0 && N != M) {
				throw std::invalid_argument("Names and FurtherTexts do not have the same amount of rows!");
			}

			if (N == 0) {
				throw std::invalid_argument("Tried to write NAMES with zero rows!");
			}
			int d = 1;
			if (M != 0) {
				// Columns of further text + names column (keys column handled seperately below)
				d = further_texts[0].size() + 1;
			}

			int column_names_size = static_cast<int>(column_names.size());

			// Check column names
			if (column_names_size == 0) {
				column_names.push_back("Names");
				for (int i = 1; i <= d - 1; ++i) {
					column_names.push_back("C" + std::to_string(i));
				}
				if (verbose) output_stream << "WARNING: Auto-generating Header now, as no valid header vector was given!" << std::endl;
			}
			else if (column_names_size > d) {
				// if bigger then d (names column + furthertexts columns) check if d+1 is the case and "Key" is given. If so remove "Key", since it is handled below
				if (to_lower_string(column_names[0]) == "key") {
					column_names.erase(column_names.begin());
					column_names_size -= 1;
				}
				if (!(column_names_size == d)) {
					for (int i = column_names_size; i > d; i--) {
						column_names.pop_back();
					}
					output_stream << "WARNING: Header has more entries than the columns of FurtherTexts and Names combind. Using the first entries of Header!" << std::endl;
				}

			}
			else if (column_names_size < d - 1) { // In case == d-1, Key is added below if necessary
				output_stream << "WARNING: Header has not enough entries for the columns of FurtherTexts, adding Elements!" << std::endl;
				for (int i = column_names_size + 1; i <= d; i++) {
					column_names.push_back("C" + std::to_string(i));
				}
			} else if (column_names_size == d - 1) {
				// A short header can name only FurtherTexts; report the added Names label.
				output_stream << "WARNING: Header has no label for Names. Adding Names before the FurtherTexts labels." << std::endl;
				column_names.insert(column_names.begin(), "Names");
			}
			
			// Check no longer wanted at the moment
			/*
			if (column_names[0] != "Names") {
				output_stream << "WARNING: Second column (first header element) has to be \"Names\". Changing first Header element to \"Names\"!" << std::endl;
				column_names[0] = "Names";
			}
			*/

			// Check keys
			if (static_cast<int>(keys.size()) != N) {
				if (keys.size() == 0) {
					// Missing keys are recoverable, but the warning must not depend on Verbose.
					output_stream << "WARNING: Key was not supplied. Using 1:N. Supply Key to keep row identifiers stable." << std::endl;

					for (int i = 0; i < N; i++)
						keys.push_back(i + 1);
				}
				else {
					throw std::invalid_argument("Keys do not have the same length as the table but also are not empty!");
				}
			}

			// Larger IDs can lose precision in R/MATLAB; reject them before writing.
			if (std::any_of(keys.begin(), keys.end(), [](Key key) { return key < -MAX_EXACT_KEY || key > MAX_EXACT_KEY; }))
				throw std::invalid_argument("Key must be between -9007199254740992 and 9007199254740992 (2^53).");

			std::unordered_set<Key> keys_unique(keys.begin(), keys.end());

			if (keys.size() != keys_unique.size()) {
				throw std::invalid_argument("Not all Keys are unique!");
			}
			

			std::stringstream buffer;

			if (version_major == 2) {
				if (version_minor == 0) {

					// write header
					// version first:
					buffer << "#<?names version=\"" << version_major << "." << version_minor << "\" created_at=\"" + current_date_str() + "\"?>" << std::endl;

					// multi-line comment:
					auto ss = std::stringstream(comment);

					for (std::string line; std::getline(ss, line, '\n');)
						buffer << "# " << line << std::endl;

					// HEADER
					// dimensions
					buffer << "% \t" << N << std::endl;
					buffer << "% \t" << d+1 << std::endl;

					// column names
					buffer << "% Key";

					for (auto col_name : column_names) {
						col_name = clean_column_name(col_name, output_stream);
						buffer << "\t" << col_name;
					}
					buffer << std::endl;

					bool cleaned_text = false;
					// BODY
					for (int i = 0; i < N; i++) {

						buffer << keys[i];

						std::string name = names[i];

						if (contains_break(name)) {
							name = clean_string(name);
							cleaned_text = true;
						}

						buffer << "\t" << name;

						if (M != 0) {
							const std::vector<std::string>& row = further_texts[i];
							if (static_cast<int>(row.size()) != d - 1) {
								throw std::invalid_argument("Row " + std::to_string(i) + " has not the same number of columns as described; " + std::to_string(d) + " should be given but row has " + std::to_string(row.size()) + " columns!");
							}

							for (std::string val : row) {

								if (contains_break(val)) {
									val = clean_string(val);
									cleaned_text = true;
								}
								buffer << "\t" << val;

							}
						}
						if (i != N - 1)
							buffer << std::endl;
					}
					if (cleaned_text) {
						output_stream << "WARNING: Detected line breaks, tabs or carriage return symbols in text and deleted them" << std::endl;
					}
				}
				else {
					throw std::invalid_argument("There is no writer for version " + std::to_string(version_major) + "." + std::to_string(version_minor) + "!");
				}
			}
			else {
				throw std::invalid_argument("There is no writer for version " + std::to_string(version_major) + "." + std::to_string(version_minor) + "!");
			}

			std::ofstream of_stream = open_write(path, verbose, output_stream);
			of_stream << buffer.rdbuf();
			close_write(of_stream);
		}

		/**
		 * Write a NAMES file in format 2.0.
		 *
		 * INPUT
		 * names  One name string per record.
		 * column_names  Column labels in file order; empty writer input selects default labels.
		 * keys  Row keys in [-2^53, 2^53]; an empty writer input selects keys 1:n.
		 * further_texts  Additional text table with one record per inner vector.
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
		void write_names(std::vector<std::string> names, std::vector<std::string> column_names, std::vector<Key> keys, std::vector<std::vector<std::string>> further_texts, std::string path, std::string comment, bool overwrite, bool verbose, int version_major, int version_minor, std::ostream& output_stream) {
			// Avoid a second deep copy: these owned arguments are no longer used here.
			_write_names(std::move(names), std::move(column_names), std::move(keys), std::move(further_texts), path, comment, overwrite, verbose, version_major, version_minor, output_stream);
		}

		/**
		 * Write a NAMES file in format 2.0.
		 *
		 * INPUT
		 * names  One name string per record.
		 * column_names  Column labels in file order; empty writer input selects default labels.
		 * keys  Row keys in [-2^53, 2^53]; an empty writer input selects keys 1:n.
		 * further_texts  Additional text table with one record per inner vector.
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
		void write_names(std::vector<std::string> names, std::vector<std::string> column_names, std::vector<Key> keys, std::vector<std::vector<std::string>> further_texts, std::string path, std::string comment, bool overwrite, bool verbose, int version_major, int version_minor) {
			// Avoid a second deep copy: these owned arguments are no longer used here.
			_write_names(std::move(names), std::move(column_names), std::move(keys), std::move(further_texts), path, comment, overwrite, verbose, version_major, version_minor, std::cout);
		}

	}
}
