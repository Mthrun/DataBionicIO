// OUTPUT
// Legacy format decisions, normalized headers and rows, and parsed name fields.
// The helpers report recoverable file errors through the output stream.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.

#include "DataIO/legacy_readers.hpp"
#include "DataIO/helpers.hpp"
#include <sstream>
#include <stdexcept>

namespace dbt::DataIO::legacy {
    namespace {
        /**
         * Remove surrounding whitespace.
         *
         * INPUT
         * text  Text to trim.
         *
         * OUTPUT
         * Text without leading or trailing spaces, tabs, CR, or LF.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        std::string trim(const std::string& text) {
            const auto first = text.find_first_not_of(" \t\r\n");
            if (first == std::string::npos) return "";
            return text.substr(first, text.find_last_not_of(" \t\r\n") - first + 1);
        }

        /**
         * Split one legacy data or header line.
         *
         * INPUT
         * line  Text to split.
         * numeric  Allow whitespace separators when the line has no tab.
         *
         * OUTPUT
         * Field strings; tab separators retain empty fields, including the last field.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        std::vector<std::string> fields(const std::string& line, bool numeric) {
            std::istringstream input(line);
            std::vector<std::string> result;
            std::string value;
            // Tabs retain empty cells. Only old numeric rows can use spaces instead.
            if (numeric && line.find('\t') == std::string::npos) {
                while (input >> value) result.push_back(value);
            } else {
                while (std::getline(input, value, '\t')) result.push_back(value);
                if (!line.empty() && line.back() == '\t') result.push_back("");
            }
            return result;
        }

        /**
         * Join fields with tab separators.
         *
         * INPUT
         * values  Ordered field strings.
         *
         * OUTPUT
         * One tab-separated string; an empty vector gives an empty string.
         * SPDX-License-Identifier: AGPL-3.0-only
         * Additional permission: see MATLAB-EXCEPTION.txt.
         */
        std::string join(const std::vector<std::string>& values) {
            std::string result;
            for (std::size_t i = 0; i < values.size(); ++i) {
                if (i) result += '\t';
                result += values[i];
            }
            return result;
        }
    }

    /**
     * Select legacy parsing from the generation tag.
     *
     * INPUT
     * first_line  First file line.
     * format  Expected format name.
     *
     * OUTPUT
     * TRUE for no generation tag or version 1.0; FALSE for version 2.0.
     * A mismatched format, absent version in a tag, or unsupported version throws.
     * SPDX-License-Identifier: AGPL-3.0-only
     * Additional permission: see MATLAB-EXCEPTION.txt.
     */
    bool is_legacy_format(const std::string& first_line, const std::string& format) {
        if (!first_line.starts_with("#<?")) return true;
        if (!first_line.starts_with("#<?" + format + " "))
            throw std::invalid_argument("The generation tag does not identify " + format + ".");
        const auto start = first_line.find("version=\"");
        if (start == std::string::npos)
            throw std::invalid_argument("The generation tag has no format version.");
        const auto end = first_line.find('"', start + 9);
        const auto version = first_line.substr(start + 9, end - start - 9);
        // An explicit current or unknown version must never enable old header rules.
        if (version == "1.0") return true;
        if (version == "2.0") return false;
        throw std::invalid_argument("Unsupported " + format + " format version: " + version);
    }

    /**
     * Normalize legacy LRN key metadata.
     *
     * INPUT
     * line  Current header line, modified in place.
     * columns  Declared width, increased if a key column must be generated.
     * has_types  FALSE for the type line; TRUE for the column-name line.
     * key_column  Original key position, set to -1 when the key is absent.
     * output  Destination stream for diagnostics.
     *
     * OUTPUT
     * Updates line, columns, and key_column; places Key and type 9 first.
     * Writes recovery warnings; inconsistent field counts throw.
     * SPDX-License-Identifier: AGPL-3.0-only
     * Additional permission: see MATLAB-EXCEPTION.txt.
     */
    void lrn_header(std::string& line, int& columns, bool has_types,
                    int& key_column, std::ostream& output) {
        // The old MATLAB reader also accepted a transposed type-line marker.
        if (!has_types && line.starts_with("9%")) {
            line.replace(0, 2, "%9");
            output << "WARNING: Legacy LRN type marker 9% read as %9.\n";
        }
        if (!line.starts_with('%')) return;
        auto values = fields(trim(line.substr(1)), !has_types);
        if (!has_types) {
            if (static_cast<int>(values.size()) != columns)
                throw std::invalid_argument("LRN type count differs from the declared column count.");
            key_column = -1;
            for (int i = 0; i < columns; ++i) {
                if (std::stoi(values[i]) != 9) continue;
                if (key_column < 0) key_column = i;
                else output << "WARNING: Legacy LRN has more than one key column; using the first.\n";
            }
            if (key_column < 0) {
                ++columns;
                output << "WARNING: Legacy LRN has no key column; generating keys 1:n.\n";
            } else values.erase(values.begin() + key_column);
            values.insert(values.begin(), "9");
        } else {
            const int file_columns = columns - (key_column < 0 ? 1 : 0);
            if (static_cast<int>(values.size()) != file_columns)
                throw std::invalid_argument("LRN name count differs from the declared column count.");
            // Old key names and positions differed. Normalize only the key metadata.
            for (auto& value : values) value = trim(value);
            if (key_column >= 0) values.erase(values.begin() + key_column);
            values.insert(values.begin(), "Key");
        }
        line = "% " + join(values);
    }

    /**
     * Normalize a legacy LRN row to key-first order.
     *
     * INPUT
     * line  Original data row.
     * columns  Normalized column count, including Key.
     * key_column  Original zero-based key column, or -1 to generate a key.
     * row_key  Generated key and row number for warnings.
     * output  Destination stream for diagnostics.
     *
     * OUTPUT
     * Tab-separated row of the requested width; missing fields are empty and extra fields are discarded.
     * SPDX-License-Identifier: AGPL-3.0-only
     * Additional permission: see MATLAB-EXCEPTION.txt.
     */
    std::string lrn_row(const std::string& line, int columns, int key_column,
                        Key row_key, std::ostream& output) {
        auto values = fields(line, true);
        const int file_columns = columns - (key_column < 0 ? 1 : 0);
        if (static_cast<int>(values.size()) != file_columns)
            output << "WARNING: Legacy LRN row " << row_key << " has " << values.size()
                   << " fields; expected " << file_columns
                   << ". Missing cells filled with NaN; extra fields ignored.\n";
        values.resize(file_columns); // Keep the file width before moving or adding a key.
        const std::string key = key_column < 0 ? std::to_string(row_key) : values[key_column];
        if (key_column >= 0) values.erase(values.begin() + key_column);
        values.insert(values.begin(), key);
        return join(values);
    }

    /**
     * Normalize a legacy CLS row.
     *
     * INPUT
     * line  Data row, modified in place.
     * has_header  Whether a header or a previous missing-header warning was seen.
     * output  Destination stream for diagnostics.
     *
     * OUTPUT
     * Updates line to tab-separated fields and sets has_header after a missing-header warning.
     * SPDX-License-Identifier: AGPL-3.0-only
     * Additional permission: see MATLAB-EXCEPTION.txt.
     */
    void cls_row(std::string& line, bool& has_header, std::ostream& output) {
        if (!has_header) {
            output << "WARNING: Legacy CLS has no row-count header; keeping all data rows.\n";
            has_header = true;
        }
        // The tab-only parser lost class values in old space-separated CLS files.
        if (line.find('\t') == std::string::npos) line = join(fields(line, true));
    }

    /**
     * Read a legacy NAMES width or column-name line.
     *
     * INPUT
     * line  Metadata text without its marker.
     * names  Destination for parsed names when line is not an integer.
     * output  Destination stream for diagnostics.
     *
     * OUTPUT
     * Column count; names changes only when the line supplies names.
     * SPDX-License-Identifier: AGPL-3.0-only
     * Additional permission: see MATLAB-EXCEPTION.txt.
     */
    int names_column_count(const std::string& line, std::vector<std::string>& names, std::ostream& output) {
        // Older NAMES files put column names directly after the row count.
        try { return std::stoi(line); }
        catch (const std::invalid_argument&) {
            names = parse_column_names(line, {"Key"}, &output);
            return static_cast<int>(names.size());
        }
    }

    /**
     * Infer missing legacy NAMES labels from the first data row.
     *
     * INPUT
     * body  File-body bytes.
     * verbose  Select information messages; data warnings can remain active.
     * output  Destination stream for diagnostics.
     *
     * OUTPUT
     * Labels Key, Names, C1, ...; fewer than two fields causes an error.
     * SPDX-License-Identifier: AGPL-3.0-only
     * Additional permission: see MATLAB-EXCEPTION.txt.
     */
    std::vector<std::string> names_columns(const std::vector<char>& body,
                                           bool verbose, std::ostream& output) {
        // Older NAMES files can omit both the column count and column names.
        // Use only the first row; later rows must not create extra columns.
        int columns = 1;
        for (char c : body) {
            if (c == '\r' || c == '\n') break;
            if (c == '\t') ++columns;
        }
        if (columns < 2) throw std::invalid_argument("Not able to get the number of columns in file");
        if (verbose) output << "INFO: No column number and header information found, assuming old NAMES format\n";
        std::vector<std::string> names = {"Key", "Names"};
        for (int i = 2; i < columns; ++i) names.push_back("C" + std::to_string(i - 1));
        return names;
    }
}
