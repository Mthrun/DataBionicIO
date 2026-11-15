// OUTPUT
// Test results reported through assertions, errors, or the process exit status.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.

#include "DataIO/read_lrn.hpp"
#include "DataIO/read_cls.hpp"
#include "DataIO/read_names.hpp"
#include "DataIO/write_lrn.hpp"
#include "DataIO/write_cls.hpp"
#include "DataIO/write_names.hpp"
#include <cassert>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <type_traits>

// Build with the shared sources and sanitizers. Supply a temporary output directory.
int main(int argc, char** argv) {
    using namespace dbt::DataIO;
    assert(argc == 2);
    static_assert(std::is_copy_constructible_v<LRN_Reader>);
    const std::filesystem::path directory(argv[1]);
    std::filesystem::create_directories(directory);
    std::ostringstream warnings;
    auto fixture = [&](const std::string& name, const std::string& contents) {
        const auto path = (directory / name).string();
        std::ofstream file(path, std::ios::binary);
        file << contents;
        return path;
    };
    auto moved = read_lrn(fixture("moved.lrn",
        "% 4\r\n% 3\r\n% 1\t9\t1\r\n% Left\tID\tRight\r\n"
        "10\t\t30\r\n\t9007199254740992\t\r\n20\r\n21\t43\t31\textra"), false, warnings);
    assert((std::get<1>(moved) == std::vector<Key>{MISSING_KEY, MAX_EXACT_KEY, MISSING_KEY, 43}));
    assert((std::get<0>(moved) == std::vector<std::string>{"Left", "Right"}));
    assert((std::get<3>(moved) == std::vector<int>{9, 1, 1}));
    const auto& values = std::get<2>(moved);
    assert(values[0][0] == 10 && values[0][1] == 30);
    assert(std::isnan(values[1][0]) && std::isnan(values[1][1]));
    assert(values[2][0] == 20 && std::isnan(values[2][1]));
    assert(values[3][0] == 21 && values[3][1] == 31);

    auto generated = read_lrn(fixture("generated.lrn",
        "% 3\n% 2\n% 1\t1\n% A\tB\n12oops\t3,4oops\n7\n\t"), false, warnings);
    assert((std::get<1>(generated) == std::vector<Key>{1, 2, 3}));
    assert(std::get<2>(generated)[0][0] == 12 && std::get<2>(generated)[0][1] == 3);
    assert(std::isnan(std::get<2>(generated)[2][0]));

    // The incremental public reader must use the same normalization and remain copyable.
    LRN_Reader incremental;
    incremental.output_stream = &warnings;
    for (const auto& line : {"% 1", "% 2", "9%\t1", "% old_id\tValue"})
        incremental.readNextLine(line, false);
    auto copy = incremental;
    copy.readNextLine("2147483648  2.5", false);
    assert(copy.keys[0] == 2147483648LL && copy.numerics[0][0] == 2.5);
    assert(incremental.row == 0 && copy.isFinished());

    auto classes = read_cls(fixture("old.cls", "1  2\n2  3oops\n3\n\t4"), false, warnings);
    assert((std::get<0>(classes) == std::vector<Key>{1, 2, 3, MISSING_KEY}));
    assert(std::get<1>(classes)[0] == 2 && std::get<1>(classes)[1] == 3);
    assert(std::isnan(std::get<1>(classes)[2]) && std::get<1>(classes)[3] == 4);
    auto names = read_names(fixture("old.names", "% 2\n1\tAlice\tleft right\n2\t\tNA\textra"), false, warnings);
    assert((std::get<1>(names) == std::vector<Key>{1, 2}));
    assert((std::get<2>(names) == std::vector<std::string>{"Alice", "NA"}));
    assert(std::get<3>(names).size() == 1 && std::get<3>(names)[0][0] == "left right");

    // A current file with an old-only header must fail, including a tag without a timestamp.
    bool rejected = false;
    try { read_lrn(fixture("current.lrn", "#<?lrn version=\"2.0\"?>\n% 1\n% 2\n% 9\t1\n% nr\tA\n1\t2"), false, warnings); }
    catch (const std::invalid_argument&) { rejected = true; }
    assert(rejected);
    rejected = false;
    try { read_cls(fixture("current.cls", "#<?cls version=\"2.0\"?>\n1  2"), false, warnings); }
    catch (const std::invalid_argument&) { rejected = true; }
    assert(rejected);
    rejected = false;
    try { read_names(fixture("current.names", "#<?names version=\"2.0\"?>\n% 1\n1\tAlice"), false, warnings); }
    catch (const std::invalid_argument&) { rejected = true; }
    assert(rejected);
    assert(warnings.str().find("WARNING") != std::string::npos);
    // Legacy support must not let a writer label current output as version 1.0.
    for (int format = 0; format < 3; ++format) {
        const std::string extension = format == 0 ? "lrn" : format == 1 ? "cls" : "names";
        const auto path = fixture("protected." + extension, "keep this file");
        rejected = false;
        try {
            if (format == 0) write_lrn({"Value"}, {1}, {{2}}, {}, path, "", 4, -1, false, true, false, 1, 0, warnings);
            if (format == 1) write_cls({1}, {2}, NAN, path, "", true, false, 1, 0, warnings);
            if (format == 2) write_names({"Alice"}, {"Names"}, {1}, {}, path, "", true, false, 1, 0, warnings);
        } catch (const std::invalid_argument&) { rejected = true; }
        assert(rejected);
        std::ifstream file(path);
        const std::string contents((std::istreambuf_iterator<char>(file)), {});
        assert(contents == "keep this file");
    }
    std::cout << "Native legacy reader tests passed.\n";
}
