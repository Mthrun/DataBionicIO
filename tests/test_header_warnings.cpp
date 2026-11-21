// OUTPUT
// Test results reported through assertions, errors, or the process exit status.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.

#include "DataIO/write_lrn.hpp"
#include "DataIO/write_names.hpp"
#include "DataIO/read_lrn.hpp"
#include "DataIO/read_names.hpp"
#include "DataIO/helpers.hpp"
#include <cassert>
#include <filesystem>
#include <fstream>
#include <sstream>

// Build with the shared sources. Supply a temporary output directory.
int main(int argc, char** argv) {
    using namespace dbt::DataIO;
    assert(argc == 2);
    const std::filesystem::path directory(argv[1]);
    std::filesystem::create_directories(directory);
    for (bool lrn : {false, true}) {
        std::ostringstream warnings;
        const auto path = (directory / (lrn ? "labels.lrn" : "labels.names")).string();
        auto write = [&](const std::string& label) {
            if (lrn)
                write_lrn({label}, {}, {{1}, {2}}, {}, path, "", -1, -1,
                          false, true, false, 2, 0, warnings);
            else
                write_names({"1.0.4", "1.0.5"}, {label}, {}, {}, path,
                            "", true, false, 2, 0, warnings);
        };
        auto bytes = [&]() {
            std::ifstream file(path, std::ios::binary);
            return std::string(std::istreambuf_iterator<char>(file), {});
        };
        write("1.0.4");
        assert(warnings.str().find("Supply Key") != std::string::npos);
        assert(warnings.str().find("Keeping it unchanged") != std::string::npos);
        if (lrn) {
            auto result = read_lrn(path, false, warnings);
            assert((std::get<1>(result) == std::vector<Key>{1, 2}));
            assert(std::get<0>(result)[0] == "1.0.4");
        } else {
            auto result = read_names(path, false, warnings);
            assert((std::get<1>(result) == std::vector<Key>{1, 2}));
            assert((std::get<2>(result) == std::vector<std::string>{"1.0.4", "1.0.5"}));
            assert(std::get<0>(result)[1] == "1.0.4");
        }
        write("Version \t,Currency;");
        assert(warnings.str().find("Removed spaces, tabs, commas, or semicolons") != std::string::npos);
        if (lrn) assert(std::get<0>(read_lrn(path, false, warnings))[0] == "VersionCurrency");
        else assert(std::get<0>(read_names(path, false, warnings))[1] == "VersionCurrency");
        const auto original = bytes();
        for (const auto& label : {std::string(), std::string(" \t,;"), std::string("A\nB"),
                                  std::string("A\rB"), std::string("A\0B", 3)}) {
            bool rejected = false;
            try { write(label); }
            catch (const std::invalid_argument&) { rejected = true; }
            assert(rejected && bytes() == original);
        }
    }
    // Text changes must be reported even when progress output is disabled.
    for (bool verbose : {false, true}) {
        for (char delimiter : {'\t', '\r', '\n', '\0'}) {
            for (bool in_name : {false, true}) {
                std::ostringstream warnings;
                const auto path = (directory / "text.names").string();
                const std::string dirty = std::string("A") + delimiter + "B";
                write_names({in_name ? dirty : "AB"}, {"Names", "Extra"},
                            {17}, {{in_name ? "AB" : dirty}}, path, "", true,
                            verbose, 2, 0, warnings);
                assert(warnings.str().find("WARNING: Replaced 1 forbidden text characters in 1 fields") != std::string::npos);
                const auto result = read_names(path, false, warnings);
                assert(std::get<2>(result)[0] == (in_name ? "A_B" : "AB"));
                assert(std::get<3>(result)[0][0] == (in_name ? "AB" : "A_B"));
            }
        }
    }
    // DATES keeps its existing name checks; this change is for LRN and NAMES.
    bool rejected = false;
    try { parse_column_names("Key\tTime\tVersion Currency", {"Key", "Time"}); }
    catch (const std::invalid_argument&) { rejected = true; }
    assert(rejected);
}
