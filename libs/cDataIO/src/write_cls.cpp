/***********************************************************************************************
 *
 * Function implementations for write_cls.
 *
 * AUTHOR: LUCA BRINKMANN (IAP-GmbH Intelligent Analytics Projects)
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 * Reimplemented from the original R function WriteCLS by Michael Thrun.
 *
 ***********************************************************************************************/


#include "DataIO/write_cls.hpp"

 // IO
#include <filesystem>
#include <iostream>
#include <fstream>
#include <sstream>
#include <utility>
#include <unordered_set>
#include <map>
#include <algorithm>
#include <cmath>
#include <climits>
#include <limits>


#include "DataIO/helpers.hpp"
#include "DataIO/text_encoding.hpp"

namespace dbt {
	namespace DataIO {

		/**
		 * Write a CLS file in format 2.0.
		 *
		 * INPUT
		 * keys  Row keys in [-2^53, 2^53]; an empty writer input selects keys 1:n.
		 * cls  One numeric class value per record.
		 * nan_replacement  Replacement for missing classes; NaN preserves the missing-value marker.
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
		 * Validation and I/O failures throw; diagnostics use output_stream or the build-specific console.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		void _write_cls(std::vector<Key> keys, std::vector<double> cls, double nan_replacement, std::string path, std::string comment, bool overwrite, bool verbose, int version_major, int version_minor, std::ostream& output_stream) {
			validate_utf8(comment);
			// The layout is 2.0; older version arguments must not label it as a legacy file.
			if (version_major != 2 || version_minor != 0)
				throw std::invalid_argument("Only format version 2.0 is supported for writing.");
			path = addext_checkext(path, "cls");




			if (!overwrite && file_exists(path)) {
				throw std::invalid_argument("The file " + path + " already exists! Consider to set overwrite=true if you want the contents to be overwritten!");
			}

			int N = cls.size();

			if (N == 0) {
				throw std::invalid_argument("Tried to write Cls with zero rows!");
			}

			// Check keys
			if (static_cast<int>(keys.size()) != N) {
				if (keys.size() == 0) {
					if(verbose) output_stream << "WARNING: Auto-generating key 1:N now as no valid key column was given!" << std::endl;
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


			// Validate the effective value before any int cast (NaN/infinity/range overflow was undefined).
			// Replacing NaN here also keeps the class counts and written labels consistent.
			for (double& value : cls) {
				if (std::isnan(value)) value = nan_replacement;
				if (!std::isnan(value) && (!std::isfinite(value) || value < INT_MIN || value > INT_MAX || std::trunc(value) != value)) {
					output_stream << "WARNING: Invalid CLS value " << value << "; using NaN." << std::endl;
					value = std::numeric_limits<double>::quiet_NaN();
				}
			}
			// Replacement is already applied; invalid replacements must not be cast later.
			nan_replacement = std::numeric_limits<double>::quiet_NaN();

			// The old loop converted each class to text. Count integers and convert once per class.
			std::map<std::string, int> count_per_cluster;
			{
				std::map<int, int> integer_counts;
				int missing_count = 0;
				for (double v : cls) {
					if (std::isnan(v)) ++missing_count;
					else ++integer_counts[static_cast<int>(v)];
				}
				// Keep the existing text order in the statistics header (for example, 1, 10, 2).
				for (const auto& pair : integer_counts)
					count_per_cluster[std::to_string(pair.first)] = pair.second;
				if (missing_count > 0) count_per_cluster["NaN"] = missing_count;
			}

			int nr_clusters = count_per_cluster.size();

			std::vector<std::string> unique_cls;

			std::map<std::string, double> percentage_per_cluster;
			for (const auto& pair : count_per_cluster) {
				unique_cls.push_back(pair.first);
				std::string cluster = pair.first;
				int count = pair.second;
				double percentage = (static_cast<double>(count) / N) * 100.0;
				percentage = static_cast<double>(static_cast<int>(percentage * 10.)) / 10.;
				percentage_per_cluster[cluster] = percentage;
			}

			std::vector<std::string> column_names = { "Class", "N", "Percent"};


			std::stringstream buffer;

			if (version_major == 2) {
				if (version_minor == 0) {

					// write header
					// version first:
					buffer << "#<?cls version=\"" << version_major << "." << version_minor << "\" created_at=\"" + current_date_str() + "\"?>" << std::endl;

					// multi-line comment:
					auto ss = std::stringstream(comment);


					for (std::string line; std::getline(ss, line, '\n');)
						buffer << "# " << line << std::endl;

					buffer << "#";
					for (auto col_name : column_names) {
						if (is_valid_colname(col_name)) {
							buffer << "\t" << col_name;
						}
						else {
							throw std::invalid_argument("Column name " + col_name + " starts with a digit or contains letters not alpha-numerical and not '_'!");
						}
					}
					buffer << std::endl;

					for (int i = 0; i < nr_clusters; i++) {
						std::string u_cls = unique_cls[i];
						buffer << "#" << "\t" << u_cls << "\t" << count_per_cluster[u_cls] << "\t" << percentage_per_cluster[u_cls] << std::endl;
					}

					buffer << "%" << "\t" << N << std::endl;


					// BODY
					bool has_nans = false;

					for (int i = 0; i < N; i++) {

						buffer << keys[i];

						auto val = cls[i];
						if (std::isnan(val)) {
							if (std::isnan(nan_replacement)) {
								buffer << "\t" << "NaN";
								if (!has_nans) {
									if (verbose)
										output_stream << "WARNING: Cls contains NaNs with no replacement!" << std::endl;
									has_nans = true;
								}
							}
						}
						else {
							// Floating output rounded large class IDs; write the validated integer exactly.
							buffer << "\t" << static_cast<int>(val);
						}
						if (i != N - 1)
							buffer << std::endl;
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
		 * Write a CLS file in format 2.0.
		 *
		 * INPUT
		 * keys  Row keys in [-2^53, 2^53]; an empty writer input selects keys 1:n.
		 * cls  One numeric class value per record.
		 * nan_replacement  Replacement for missing classes; NaN preserves the missing-value marker.
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
		 * Validation and I/O failures throw; diagnostics use output_stream or the build-specific console.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		void write_cls(std::vector<Key> keys, std::vector<double> cls, double nan_replacement, std::string path, std::string comment, bool overwrite, bool verbose, int version_major, int version_minor, std::ostream& output_stream) {
			// Avoid a second deep copy: these owned arguments are no longer used here.
			_write_cls(std::move(keys), std::move(cls), nan_replacement, path, comment, overwrite, verbose, version_major, version_minor, output_stream);
		}

		/**
		 * Write a CLS file in format 2.0.
		 *
		 * INPUT
		 * keys  Row keys in [-2^53, 2^53]; an empty writer input selects keys 1:n.
		 * cls  One numeric class value per record.
		 * nan_replacement  Replacement for missing classes; NaN preserves the missing-value marker.
		 * path  Filesystem path.
		 * comment  User comment text; newlines separate comment lines.
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
		 */
		void write_cls(std::vector<Key> keys, std::vector<double> cls, double nan_replacement, std::string path, std::string comment, bool overwrite, bool verbose, int version_major, int version_minor) {
			// Avoid a second deep copy: these owned arguments are no longer used here.
			_write_cls(std::move(keys), std::move(cls), nan_replacement, path, comment, overwrite, verbose, version_major, version_minor, default_output_stream());
		}

	}
}
