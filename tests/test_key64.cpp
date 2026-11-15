// OUTPUT
// Test results reported through assertions, errors, or the process exit status.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.

#include "DataIO/read_lrn.hpp"
#include "DataIO/write_lrn.hpp"
#include "DataIO/read_cls.hpp"
#include "DataIO/write_cls.hpp"
#include "DataIO/read_names.hpp"
#include "DataIO/write_names.hpp"
#include "DataIO/read_dates.hpp"
#include "DataIO/write_dates.hpp"
#include <cassert>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <limits>
#include <sstream>

// Run with a temporary output directory. Test all formats through their public C++ API.
int main(int argc, char** argv) {
    using namespace dbt::DataIO;
    assert(argc == 2);
    static_assert(sizeof(Key) == 8);
    const std::filesystem::path directory(argv[1]);
    std::filesystem::create_directories(directory);
    std::ostringstream warnings;
    auto write = [&](int format, const std::vector<Key>& keys, const std::string& path) {
        const std::vector<std::vector<double>> data(keys.size(), {1.23456});
        const std::vector<std::string> names(keys.size(), "sample");
        if (format == 0) write_lrn({"Value"}, keys, data, {}, path, "", 4, -1, false, true, false, 2, 0, warnings);
        if (format == 1) write_cls(keys, std::vector<double>(keys.size(), 1), NAN, path, "", true, false, 2, 0, warnings);
        if (format == 2) write_names(names, {"Names"}, keys, {}, path, "", true, false, 2, 0, warnings);
        if (format == 3) write_dates({"Value"}, keys, std::vector<std::string>(keys.size(), "2024-01-01"), data, path, "", 1, true, false, 2, 0, warnings);
    };
    auto read = [&](int format, const std::string& path) -> std::vector<Key> {
        if (format == 0) return std::get<1>(read_lrn(path, false, warnings));
        if (format == 1) return std::get<0>(read_cls(path, false, warnings));
        if (format == 2) return std::get<1>(read_names(path, false, warnings));
        return std::get<1>(read_dates(path, false, warnings));
    };
    const std::vector<Key> expected = {1, 2147483647, 2147483648LL, -2147483648LL,
        1234567890123LL, MAX_EXACT_KEY - 1, MAX_EXACT_KEY, -MAX_EXACT_KEY};
    const std::vector<std::string> extensions = {"lrn", "cls", "names", "dts"};
    for (int format = 0; format < 4; ++format) {
        const std::string path = (directory / ("keys." + extensions[format])).string();
        write(format, expected, path);
        assert(read(format, path) == expected);

        // Check actual file digits, not only an in-memory conversion.
        std::ifstream source(path);
        std::string text((std::istreambuf_iterator<char>(source)), {});
        assert(text.find("9007199254740992\t") != std::string::npos);
        assert(text.find("-2147483648\t") != std::string::npos);

        // Invalid writes must leave the existing file intact.
        for (const auto& invalid : std::vector<std::vector<Key>>{
                {MAX_EXACT_KEY + 1}, {-MAX_EXACT_KEY - 1}, {MISSING_KEY},
                {std::numeric_limits<Key>::max()}, {2147483648LL, 2147483648LL}}) {
            bool rejected = false;
            try { write(format, invalid, path); }
            catch (const std::invalid_argument&) { rejected = true; }
            assert(rejected);
            assert(read(format, path) == expected);
        }

        // Preserve rows and prefixes. Reject a key beyond the exact range before a double cast.
        auto replace_key = [&](const std::string& from, const std::string& to) {
            const auto pos = text.find("\n" + from + "\t");
            assert(pos != std::string::npos);
            text.replace(pos + 1, from.size(), to);
        };
        replace_key("2147483647", "2147483647oops");
        replace_key("2147483648", "");
        replace_key("1234567890123", "9007199254740993");
        replace_key("9007199254740991", "9223372036854775808");
        std::ofstream changed(path); changed << text; changed.close();
        warnings.str(""); warnings.clear();
        auto repaired = expected;
        repaired[2] = repaired[4] = repaired[5] = MISSING_KEY;
        assert(read(format, path) == repaired);
        assert(warnings.str().find("WARNING") != std::string::npos);
    }
    std::cout << "64-bit key tests passed for LRN, CLS, NAMES, and DATES.\n";
}
