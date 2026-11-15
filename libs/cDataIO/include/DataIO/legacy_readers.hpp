// OUTPUT
// Declarations for legacy LRN, CLS, and NAMES parsing helpers.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.

#ifndef DBT_DATA_IO_LEGACY_READERS_HPP
#define DBT_DATA_IO_LEGACY_READERS_HPP

#include <ostream>
#include <string>
#include <vector>
#include "key.hpp"

// Read-only compatibility for LRN, CLS, and NAMES. No writer uses this module.
// Keep numeric conversion and row recovery in the current readers.
namespace dbt::DataIO::legacy {
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
    bool is_legacy_format(const std::string& first_line, const std::string& format);
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
                    int& key_column, std::ostream& output);
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
                        Key row_key, std::ostream& output);
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
    void cls_row(std::string& line, bool& has_header, std::ostream& output);
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
    int names_column_count(const std::string& line, std::vector<std::string>& names, std::ostream& output);
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
                                           bool verbose, std::ostream& output);
}

#endif
