// OUTPUT
// Test results reported through assertions, errors, or the process exit status.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.

#include "DataIO/read_dates.hpp"
#include "DataIO/read_names.hpp"
#include "DataIO/helpers.hpp"
#include <cassert>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <sstream>

// Exercise the documented return layout and recoverable errors with fixed input.
int main(int argc, char** argv) {
    using namespace dbt::DataIO;
    assert(argc == 2);
    const std::filesystem::path directory(argv[1]);
    std::filesystem::create_directories(directory);
    const auto dates = directory / "documented.dts";
    {
        std::ofstream file(dates);
        file << "#<?dates version=\"2.0\"?>\n# Example.\n# Timezone: UTC\n"
             << "% 9\n% 4\n% Key\tTime\tLeft\tRight\n"
             << "11\t2025-01-01\t1.5\t10\n"
             << "\t2025-01-02\tbad\t20\n";
    }
    std::ostringstream warnings;
    const auto result = read_dates(dates.string(), false, warnings);
    assert((std::get<0>(result) == std::vector<std::string>{"Key", "Time", "Left", "Right"}));
    assert((std::get<1>(result) == std::vector<Key>{11, MISSING_KEY}));
    assert(std::get<2>(result).empty());
    assert((std::get<3>(result) == std::vector<std::string>{"2025-01-01", "2025-01-02"}));
    const auto& columns = std::get<4>(result);
    assert(columns.size() == 2 && columns[0].size() == 2 && columns[1].size() == 2);
    assert(columns[0][0] == 1.5 && std::isnan(columns[0][1]));
    assert(columns[1][0] == 10 && columns[1][1] == 20);
    assert(std::get<5>(result) == "Example." && std::get<6>(result) == "UTC");
    assert(warnings.str().find("missing key") != std::string::npos);
    assert(warnings.str().find("numeric cell") != std::string::npos);
    assert(warnings.str().find("Header declares 9 rows") != std::string::npos);
    // MATLAB dispatches each complete diagnostic by this prefix.
    std::istringstream diagnostic_lines(warnings.str());
    for (std::string line; std::getline(diagnostic_lines, line);)
        assert(line.rfind("WARNING:", 0) == 0);

    const auto names = directory / "documented.names";
    {
        std::ofstream file(names);
        file << "#<?names version=\"2.0\"?>\n% 1\n% 3\n% Key\tLabel\tGroup\n"
             << "11\tA\talpha\n12\tB\tNA\n";
    }
    warnings.str(""); warnings.clear();
    const auto text = read_names(names.string(), false, warnings);
    assert((std::get<2>(text) == std::vector<std::string>{"A", "B"}));
    assert((std::get<3>(text) == std::vector<std::vector<std::string>>{{"alpha", "NA"}}));
    assert(warnings.str().find("Header declares 1 rows") != std::string::npos);

    // The diagnostic must describe the actual validation set, not an OS policy.
    const std::string rejected_characters = "*?\"<>";
    for (char value : rejected_characters) {
        bool rejected = false;
        try { addext_checkext("file" + std::string(1, value), "lrn"); }
        catch (const std::invalid_argument& error) {
            rejected = true;
            const std::string message(error.what());
            assert(message.find("Remove characters from this set: " + rejected_characters + ".") != std::string::npos);
        }
        assert(rejected);
    }
    assert(addext_checkext("part:one|two", "lrn") == "part:one|two.lrn");
    assert(addext_checkext("data.csv", "lrn") == "data.csv");
}
