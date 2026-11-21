// INPUT
// Byte streams and Unicode text for the four shared formats.
// OUTPUT
// UTF-8 validation, explicit legacy decoding, and NAMES field replacement.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
#include "DataIO/text_encoding.hpp"
#include <array>
#include <cstdint>
#include <cstring>
#include <iomanip>
#include <stdexcept>

namespace dbt::DataIO {
namespace {
// INPUT: consecutive UTF-8 chunks. OUTPUT: decoder state or an exception.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
struct Utf8State {
    unsigned remaining = 0, low = 0x80, high = 0xbf;
    void check(std::string_view bytes, bool final = false) {
        size_t i = 0;
        while (i < bytes.size()) {
            if (!remaining) {
                while (i + 8 <= bytes.size()) {
                    uint64_t word; std::memcpy(&word, bytes.data() + i, 8);
                    if (word & UINT64_C(0x8080808080808080)) break;
                    i += 8;
                }
                if (i == bytes.size()) break;
            }
            const auto c = static_cast<unsigned char>(bytes[i++]);
            if (remaining) {
                if (c < low || c > high) throw std::invalid_argument("Invalid UTF-8 input.");
                --remaining; low = 0x80; high = 0xbf;
            } else if (c < 0x80) continue;
            else if (c >= 0xc2 && c <= 0xdf) remaining = 1;
            else if (c >= 0xe0 && c <= 0xef) {
                remaining = 2;
                if (c == 0xe0) low = 0xa0;
                if (c == 0xed) high = 0x9f;
            } else if (c >= 0xf0 && c <= 0xf4) {
                remaining = 3;
                if (c == 0xf0) low = 0x90;
                if (c == 0xf4) high = 0x8f;
            } else throw std::invalid_argument("Invalid UTF-8 input.");
        }
        if (final && remaining) throw std::invalid_argument("Truncated UTF-8 input.");
    }
};

// INPUT: a binary file positioned after an optional BOM.
// OUTPUT: buffered UTF-8 bytes; each disk block is validated once as it is read.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
class Utf8Buffer : public std::streambuf {
    std::ifstream& file;
    std::array<char, 65536> bytes;
    Utf8State state;
protected:
    int_type underflow() override {
        if (gptr() && gptr() < egptr()) return traits_type::to_int_type(*gptr());
        file.read(bytes.data(), bytes.size());
        const auto n = file.gcount();
        if (file.bad()) throw std::runtime_error("Failed to read input file.");
        state.check(std::string_view(bytes.data(), static_cast<size_t>(n)), file.eof());
        setg(bytes.data(), bytes.data(), bytes.data() + n);
        return n ? traits_type::to_int_type(*gptr()) : traits_type::eof();
    }
    pos_type seekoff(off_type offset, std::ios_base::seekdir way, std::ios_base::openmode) override {
        const auto unread = gptr() ? egptr() - gptr() : 0;
        file.clear();
        if (way == std::ios_base::cur && offset == 0) return file.tellg() - off_type(unread);
        if (way == std::ios_base::cur) offset -= unread;
        file.seekg(offset, way);
        if (!file) return pos_type(off_type(-1));
        setg(nullptr, nullptr, nullptr); state = Utf8State{};
        return file.tellg();
    }
    pos_type seekpos(pos_type pos, std::ios_base::openmode mode) override {
        return seekoff(off_type(pos), std::ios_base::beg, mode);
    }
public:
    explicit Utf8Buffer(std::ifstream& input) : file(input) {}
};

// INPUT: a Unicode scalar. OUTPUT: its UTF-8 bytes appended to text.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
void append_scalar(std::string& text, uint32_t c) {
    if (c > 0x10ffff || (c >= 0xd800 && c <= 0xdfff))
        throw std::invalid_argument("Invalid Unicode scalar in input.");
    if (c < 0x80) text += char(c);
    else if (c < 0x800) { text += char(0xc0 | c >> 6); text += char(0x80 | (c & 63)); }
    else if (c < 0x10000) {
        text += char(0xe0 | c >> 12); text += char(0x80 | ((c >> 6) & 63)); text += char(0x80 | (c & 63));
    } else {
        text += char(0xf0 | c >> 18); text += char(0x80 | ((c >> 12) & 63));
        text += char(0x80 | ((c >> 6) & 63)); text += char(0x80 | (c & 63));
    }
}

// INPUT: legacy bytes and a known encoding. OUTPUT: decoded UTF-8, without normalization.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
std::string decode(std::string_view input, const std::string& encoding) {
    std::string output; output.reserve(input.size());
    if (encoding == "Windows-1252" || encoding == "ISO-8859-1") {
        static constexpr uint16_t cp1252[] = {0x20ac,0,0x201a,0x192,0x201e,0x2026,0x2020,0x2021,
            0x2c6,0x2030,0x160,0x2039,0x152,0,0x17d,0,0,0x2018,0x2019,0x201c,0x201d,0x2022,
            0x2013,0x2014,0x2dc,0x2122,0x161,0x203a,0x153,0,0x17e,0x178};
        for (unsigned char b : input) {
            uint32_t c = b;
            if (encoding == "Windows-1252" && b >= 0x80 && b <= 0x9f) {
                c = cp1252[b - 0x80];
                if (!c) throw std::invalid_argument("Undefined Windows-1252 byte.");
            }
            append_scalar(output, c);
        }
    } else {
        const size_t width = encoding.starts_with("UTF-16") ? 2 : 4;
        const bool le = encoding.ends_with("LE");
        if (input.size() % width) throw std::invalid_argument("Truncated " + encoding + " input.");
        for (size_t i = 0; i < input.size();) {
            uint32_t c = 0;
            for (size_t j = 0; j < width; ++j) c |= uint32_t(static_cast<unsigned char>(input[i++])) << (8 * (le ? j : width - 1 - j));
            if (width == 2 && c >= 0xd800 && c <= 0xdbff) {
                if (i == input.size()) throw std::invalid_argument("Truncated UTF-16 surrogate pair.");
                uint32_t d = 0;
                for (size_t j = 0; j < 2; ++j) d |= uint32_t(static_cast<unsigned char>(input[i++])) << (8 * (le ? j : 1 - j));
                if (d < 0xdc00 || d > 0xdfff) throw std::invalid_argument("Invalid UTF-16 surrogate pair.");
                c = 0x10000 + ((c - 0xd800) << 10) + d - 0xdc00;
            }
            append_scalar(output, c);
        }
    }
    return output;
}
}

void validate_utf8(std::string_view text) { Utf8State{}.check(text, true); }
void validate_utf8(const std::vector<std::string>& text) { for (const auto& value : text) validate_utf8(value); }

TextInput::TextInput(std::ifstream file, const std::string& encoding, std::ostream& output)
    : std::istream(nullptr), file_(std::move(file)) {
    if (!file_) throw std::invalid_argument("Failed to open input file.");
    std::string selected = encoding;
    if (selected == "Latin-1") selected = "ISO-8859-1";
    if (!selected.empty() && selected != "UTF-8" && selected != "Windows-1252" && selected != "ISO-8859-1")
        throw std::invalid_argument("Encoding must be UTF-8, Windows-1252, or ISO-8859-1.");
    unsigned char b[4]{}; file_.read(reinterpret_cast<char*>(b), 4); const auto n = file_.gcount();
    std::string bom; size_t skip = 0;
    if (n >= 4 && b[0] == 0 && b[1] == 0 && b[2] == 0xfe && b[3] == 0xff) { bom = "UTF-32BE"; skip = 4; }
    else if (n >= 4 && b[0] == 0xff && b[1] == 0xfe && b[2] == 0 && b[3] == 0) { bom = "UTF-32LE"; skip = 4; }
    else if (n >= 3 && b[0] == 0xef && b[1] == 0xbb && b[2] == 0xbf) { bom = "UTF-8"; skip = 3; }
    else if (n >= 2 && b[0] == 0xfe && b[1] == 0xff) { bom = "UTF-16BE"; skip = 2; }
    else if (n >= 2 && b[0] == 0xff && b[1] == 0xfe) { bom = "UTF-16LE"; skip = 2; }
    if (!selected.empty() && !bom.empty() && selected != bom)
        throw std::invalid_argument("Encoding conflicts with the file BOM.");
    if (selected.empty()) selected = bom.empty() ? "UTF-8" : bom;
    file_.clear(); file_.seekg(skip);
    if (selected == "UTF-8") buffer_ = std::make_unique<Utf8Buffer>(file_);
    else {
        const auto start = file_.tellg(); file_.seekg(0, std::ios::end); const auto end = file_.tellg(); file_.seekg(start);
        std::string bytes(static_cast<size_t>(end - start), '\0');
        file_.read(bytes.data(), bytes.size());
        if (file_.gcount() != static_cast<std::streamsize>(bytes.size())) throw std::runtime_error("Failed to read input file.");
        buffer_ = std::make_unique<std::stringbuf>(decode(bytes, selected), std::ios::in);
        output << "WARNING: Converted input from " << selected << " to UTF-8." << std::endl;
    }
    rdbuf(buffer_.get()); exceptions(std::ios::badbit);
}
TextInput::~TextInput() = default;

std::vector<char> TextInput::read_remaining() {
    clear(); const auto start = tellg(); seekg(0, std::ios::end); const auto end = tellg(); seekg(start);
    if (start < 0 || end < start) throw std::runtime_error("Cannot determine input length.");
    std::vector<char> bytes(static_cast<size_t>(end - start));
    read(bytes.data(), bytes.size());
    if (gcount() != static_cast<std::streamsize>(bytes.size())) throw std::runtime_error("Failed to read input file.");
    // Check an unfinished sequence even when the requested length ended at a block boundary.
    peek();
    return bytes;
}

TextReplacement::TextReplacement(const std::string& replacement) : replacement_(replacement) {
    validate_utf8(replacement_);
    if (replacement_.empty() || replacement_.find_first_of("\t\r\n\0", 0, 4) != std::string::npos)
        throw std::invalid_argument("TextReplacement must be nonempty text without TAB, LF, CR, or NUL.");
}
void TextReplacement::apply(std::string& text) {
    validate_utf8(text);
    size_t pos = text.find_first_of("\t\r\n\0", 0, 4);
    if (pos == std::string::npos) return;
    ++fields_;
    if (replacement_.size() == 1) {
        do { text[pos] = replacement_[0]; ++characters_; pos = text.find_first_of("\t\r\n\0", pos + 1, 4); } while (pos != std::string::npos);
    } else {
        std::string result; result.reserve(text.size()); size_t start = 0;
        do { result.append(text, start, pos - start); result += replacement_; ++characters_; start = pos + 1;
             pos = text.find_first_of("\t\r\n\0", start, 4); } while (pos != std::string::npos);
        result.append(text, start, std::string::npos); text = std::move(result);
    }
}
void TextReplacement::warn(std::ostream& output) const {
    if (characters_) output << "WARNING: Replaced " << characters_ << " forbidden text characters in " << fields_
        << " fields with " << std::quoted(replacement_) << "." << std::endl;
}
}
