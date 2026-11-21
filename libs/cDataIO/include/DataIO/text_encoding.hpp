// INPUT
// File bytes, Unicode text, and optional input encoding or replacement settings.
// OUTPUT
// Validated UTF-8 streams and text; malformed input throws before file output.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
#pragma once
#include <fstream>
#include <sstream>
#include <memory>
#include <string_view>
#include <vector>

namespace dbt::DataIO {
// INPUT: text is a byte sequence. OUTPUT: throws for malformed UTF-8.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
void validate_utf8(std::string_view text);
void validate_utf8(const std::vector<std::string>& text);

// INPUT: owned binary input and optional Encoding; empty means BOM or UTF-8.
// OUTPUT: validated UTF-8 input; conversion warnings use output.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
class TextInput : public std::istream {
    std::ifstream file_;
    std::unique_ptr<std::streambuf> buffer_;
public:
    TextInput(std::ifstream file, const std::string& encoding, std::ostream& output);
    ~TextInput();
    std::vector<char> read_remaining();
    void close() { file_.close(); }
};

// INPUT: a replacement string and owned text fields.
// OUTPUT: validated fields with forbidden characters replaced; summary counts.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
class TextReplacement {
    std::string replacement_;
    size_t characters_ = 0, fields_ = 0;
public:
    explicit TextReplacement(const std::string& replacement);
    void apply(std::string& text);
    void warn(std::ostream& output) const;
};
}
