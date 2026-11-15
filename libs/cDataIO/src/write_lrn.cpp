/***********************************************************************************************
 * 
 * Function implementations for write_lrn.
 * 
 * AUTHOR: JULIAN MÄRTE
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 * 
 ***********************************************************************************************/


#include "DataIO/write_lrn.hpp"

// IO
#include <filesystem>
#include <iostream>
#include <fstream>
#include <sstream>
#include <utility>
#include <limits>
#include <unordered_set>
#include <algorithm>

#include "DataIO/helpers.hpp"

namespace dbt {
	namespace DataIO {

		// Round before choosing notation, then remove only redundant fractional zeros.
		// Expanding decimal text avoids a second floating-point rounding or overflow.
		/**
		 * Remove redundant fractional zeros and select numeric notation.
		 *
		 * INPUT
		 * number  Nonempty formatted numeric text.
		 * scientific  TRUE requests exponent notation; FALSE requests expanded decimal text.
		 *
		 * OUTPUT
		 * Equivalent numeric text without a second floating-point conversion; Inf/NaN stay unchanged.
		 * SPDX-License-Identifier: AGPL-3.0-only
		 * Additional permission: see MATLAB-EXCEPTION.txt.
		 */
		static std::string compact_lrn_number(std::string number, bool scientific) {
			const size_t start = number[0] == '-' ? 1 : 0;
			if (number[start] < '0' || number[start] > '9') return number; // Inf/NaN
			const size_t exp_pos = number.find('e');
			if (!scientific && exp_pos == std::string::npos) {
				// DecimalDigits=0 has no decimal point: its integer zeros must be kept.
				if (number.find('.') != std::string::npos) {
					number.erase(number.find_last_not_of('0') + 1);
					if (number.back() == '.') number.pop_back();
				}
				return number;
			}
			const int exponent = exp_pos == std::string::npos ? 0 : std::stoi(number.substr(exp_pos + 1));
			std::string digits = number.substr(start, exp_pos == std::string::npos ? exp_pos : exp_pos - start);
			const size_t dot = digits.find('.');
			int point = static_cast<int>(dot == std::string::npos ? digits.size() : dot) + exponent;
			if (dot != std::string::npos) digits.erase(dot, 1);
			const size_t first = digits.find_first_not_of('0');
			const std::string sign = number.substr(0, start);
			if (first == std::string::npos) return sign + (scientific ? "0e+00" : "0");
			point -= static_cast<int>(first);
			digits.erase(0, first);
			digits.erase(digits.find_last_not_of('0') + 1);
			if (scientific) {
				if (digits.size() > 1) digits.insert(1, ".");
				// Do not cut away the zeros in e+00 or e+10: rebuild the exponent separately.
				const int power = point - 1;
				std::string exp = std::to_string(power < 0 ? -power : power);
				if (exp.size() < 2) exp.insert(0, "0");
				return sign + digits + (power < 0 ? "e-" : "e+") + exp;
			}
			if (point <= 0) return sign + "0." + std::string(-point, '0') + digits;
			if (point >= static_cast<int>(digits.size())) return sign + digits + std::string(point - digits.size(), '0');
			digits.insert(point, ".");
			return sign + digits;
		}

		/**
		 * Write a LRN file in format 2.0.
		 *
		 * INPUT
		 * column_names  Column labels in file order; empty writer input selects default labels.
		 * keys  Row keys in [-2^53, 2^53]; an empty writer input selects keys 1:n.
		 * numerics  Numeric table with one record per inner vector.
		 * types  Column type codes; empty input selects data type 1 and key type 9.
		 * path  Filesystem path.
		 * comment  User comment text; newlines separate comment lines.
		 * significant_digits  Positive significant-digit limit, or -1 for no such limit.
		 * decimal_digits  Decimal-place limit, or -1 for no limit; significant_digits takes precedence.
		 * scientific  Select scientific notation when true.
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
		void _write_lrn(std::vector<std::string> column_names, std::vector<Key> keys, std::vector<std::vector<double>> numerics, std::vector<int> types, std::string path, std::string comment, int significant_digits, int decimal_digits, bool scientific, bool overwrite, bool verbose, int version_major, int version_minor, std::ostream& output_stream) {
			// The layout is 2.0; older version arguments must not label it as a legacy file.
			if (version_major != 2 || version_minor != 0)
				throw std::invalid_argument("Only format version 2.0 is supported for writing.");
			path = addext_checkext(path, "lrn");

			if (!overwrite && file_exists(path)) {
	        	throw std::invalid_argument("The file " + path + " already exists! Consider to set overwrite=true if you want the contents to be overwritten!");
			}
			
			int N = numerics.size();
			if (N == 0) {
				throw std::invalid_argument("Tried to write LRN with zero rows!");
			}
			int d = numerics[0].size() + 1;
			// A short first row must not shrink a supplied schema; use its declared names.
			if (!column_names.empty() && column_names.size() != static_cast<size_t>(d - 1))
				d = column_names.size() + (column_names.front() == "Key" ? 0 : 1);

			int types_size = static_cast<int>(types.size());

			// Check types
			if (types_size == 0) {
				types.resize(d-1, 1);
				types.insert(types.begin(), 9);
			} else if (types_size > d) {
				throw std::invalid_argument("Too many types given!");
			} else if (types_size < d-1) {
				throw std::invalid_argument("Not enough types given!");
			} else if(types_size == d) {
				if (types[0] != 9) {
					throw std::invalid_argument("First type has to be key-type, i.e. 9!");
				}
			}
			// Data-only types omitted the Key entry and were indexed past the end during header generation.
			if (types.size() == static_cast<size_t>(d - 1)) types.insert(types.begin(), 9);
			if (std::count(types.begin(), types.end(), 9) > 1) {
				throw std::invalid_argument("More than one value of types indicate a key column, i.e. 9!");
			}

			int column_names_size = static_cast<int>(column_names.size());

			// Check column names
			if (column_names_size == 0) {
				for (int i = 1; i <= d - 1; ++i) {
					if (types[i] == 3) {
						column_names.push_back("Cls");
					} else {
						//column_names.push_back("C" + std::to_string(i));
						std::stringstream ss;
						ss << "C" << i;
						column_names.push_back(ss.str());
					}
				}
				if (verbose) output_stream << "WARNING: Auto-generating Header now, as no valid header vector was given!" << std::endl;
			} else if (column_names_size > d) {
				throw std::invalid_argument("Too many Header names given!");
			} else if (column_names_size < d - 1) { // In case == d-1, Key is added below if necessary
				throw std::invalid_argument("Not enough Header names given!");
			}

			// Check keys
			if (static_cast<int>(keys.size()) != N) {
				if (keys.size() == 0) {
					// Missing keys are recoverable, but the warning must not depend on Verbose.
					output_stream << "WARNING: Key was not supplied. Using 1:N. Supply Key to keep row identifiers stable." << std::endl;

					for (int i = 0; i < N; i++)
						keys.push_back(i+1);
				} else {
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

			// Zero decimal places is an explicit rounding request too.
			if (significant_digits > 0 && decimal_digits >= 0) {
				if (verbose) output_stream << "WARNING: Both number of significant digits and digits after decimal where given, proceeding with significant digits!" << std::endl;
				decimal_digits = -1;
			}

			// Repair ragged rows before precision analysis, which previously indexed missing cells.
			for (size_t i = 0; i < numerics.size(); ++i) {
				if (numerics[i].size() != static_cast<size_t>(d - 1)) {
					output_stream << "WARNING: LRN row " << i + 1 << " has the wrong width; padding with NaN or ignoring extra fields." << std::endl;
					numerics[i].resize(d - 1, std::numeric_limits<double>::quiet_NaN());
				}
			}

			std::stringstream buffer;

			if (version_major == 2) {
				if (version_minor == 0) {

					// write header
					// version first:
					buffer << "#<?lrn version=\"" << version_major << "." << version_minor << "\" created_at=\"" + current_date_str() + "\"?>" << std::endl;
					
					// multi-line comment:
					auto ss = std::stringstream(comment);

				    for (std::string line; std::getline(ss, line, '\n');)
						buffer << "# " << line << std::endl;

					// HEADER
					// dimensions
					buffer << "% \t" << N << std::endl;
					buffer << "% \t" << d << std::endl;

					// column types
					if (static_cast<int>(types.size()) < d) 
						buffer << "% 9	";
					else
						buffer << "% ";

					for (auto it = types.begin(); it != types.end(); ++it) {
						buffer << *it;

						if (std::next(it) != types.end()) {
							buffer << "\t";
						}
					}
					buffer << std::endl;

					// column names
					bool has_key_part = false;
					if (static_cast<int>(column_names.size()) < d) {
						buffer << "% Key";
					}
					else {
						buffer << "% ";
						has_key_part = true;
					}
					for (auto col_name : column_names) {
						col_name = clean_column_name(col_name, output_stream);
						if (has_key_part) {
							buffer << col_name;
							has_key_part = false;
						} else {
							buffer << "\t" << col_name;
						}
					}
					buffer << std::endl;

					// The old loop built a stream for each value. Reuse one stream per file.
					std::stringstream number_stream;
					bool has_nans = false;

					// BODY
					for (int i = 0; i < N; i++) {
						const std::vector<double>& row = numerics[i];
						if (static_cast<int>(row.size()) != d - 1) {
							throw std::invalid_argument("Row " + std::to_string(i) + " has not the same number of columns as described; " + std::to_string(d) + " should be given but row has " + std::to_string(row.size()) + " columns!");
						}

						// OPTIONAL: Leave \t out to start at the beginning of the line; the formatting will not be so nice though..
						buffer << keys[i];
						for (auto val : row) {
							if (val != val) {
								if (!has_nans) {
									if (verbose)
										if (verbose) output_stream << "WARNING: Numeric data contains NaNs!" << std::endl;
									has_nans = true;
								}
								buffer << "\t" << "NaN";
							}
							else {
								std::stringstream& ss = number_stream;
								ss.str("");
								ss.clear();
								if (significant_digits > 0) {
									// Column-wide precision lost fractions when the minimum was an integer.
									// Round each value to the requested digits, independently of notation.
									ss << std::scientific << std::setprecision(significant_digits - 1) << val;
								} else if (decimal_digits >= 0) {
									// The old >0 test ignored zero; fixed rounding also handles Scientific=true.
									ss << std::fixed << std::setprecision(decimal_digits) << val;
								} else {
									// Fixed 22 decimal places turned tiny values into zero; keep double precision first.
									ss << std::scientific << std::setprecision(std::numeric_limits<double>::max_digits10 - 1) << val;
								}
								buffer << "\t" << compact_lrn_number(ss.str(), scientific);

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
		 * Write a LRN file in format 2.0.
		 *
		 * INPUT
		 * column_names  Column labels in file order; empty writer input selects default labels.
		 * keys  Row keys in [-2^53, 2^53]; an empty writer input selects keys 1:n.
		 * numerics  Numeric table with one record per inner vector.
		 * types  Column type codes; empty input selects data type 1 and key type 9.
		 * path  Filesystem path.
		 * comment  User comment text; newlines separate comment lines.
		 * significant_digits  Positive significant-digit limit, or -1 for no such limit.
		 * decimal_digits  Decimal-place limit, or -1 for no limit; significant_digits takes precedence.
		 * scientific  Select scientific notation when true.
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
		void write_lrn(std::vector<std::string> column_names, std::vector<Key> keys, std::vector<std::vector<double>> numerics, std::vector<int> types, std::string path, std::string comment, int significant_digits, int decimal_digits, bool scientific, bool overwrite, bool verbose, int version_major, int version_minor, std::ostream& output_stream) {
			// Avoid a second deep copy: these owned arguments are no longer used here.
			_write_lrn(std::move(column_names), std::move(keys), std::move(numerics), std::move(types), path, comment, significant_digits, decimal_digits, scientific, overwrite, verbose, version_major, version_minor, output_stream);
		}

		/**
		 * Write a LRN file in format 2.0.
		 *
		 * INPUT
		 * column_names  Column labels in file order; empty writer input selects default labels.
		 * keys  Row keys in [-2^53, 2^53]; an empty writer input selects keys 1:n.
		 * numerics  Numeric table with one record per inner vector.
		 * types  Column type codes; empty input selects data type 1 and key type 9.
		 * path  Filesystem path.
		 * comment  User comment text; newlines separate comment lines.
		 * significant_digits  Positive significant-digit limit, or -1 for no such limit.
		 * decimal_digits  Decimal-place limit, or -1 for no limit; significant_digits takes precedence.
		 * scientific  Select scientific notation when true.
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
		void write_lrn(std::vector<std::string> column_names, std::vector<Key> keys, std::vector<std::vector<double>> numerics, std::vector<int> types, std::string path, std::string comment, int significant_digits, int decimal_digits, bool scientific, bool overwrite, bool verbose, int version_major, int version_minor) {
			// Avoid a second deep copy: these owned arguments are no longer used here.
			_write_lrn(std::move(column_names), std::move(keys), std::move(numerics), std::move(types), path, comment, significant_digits, decimal_digits, scientific, overwrite, verbose, version_major, version_minor, std::cout);
		}
	}
}
