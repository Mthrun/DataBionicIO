// INPUT
// Output directory, format, character set, row count, operation, and repetitions.
// OUTPUT
// Per-operation elapsed seconds for an in-process encoding benchmark.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
#include "DataIO/read_lrn.hpp"
#include "DataIO/read_cls.hpp"
#include "DataIO/read_names.hpp"
#include "DataIO/read_dates.hpp"
#include "DataIO/write_lrn.hpp"
#include "DataIO/write_cls.hpp"
#include "DataIO/write_names.hpp"
#include "DataIO/write_dates.hpp"
#include <chrono>
#include <filesystem>
#include <iostream>
#include <numeric>
#include <sstream>
#include <stdexcept>
#include <sys/resource.h>
int main(int argc, char** argv) {
    using namespace dbt::DataIO;
    if (argc != 7) return 2;
    std::filesystem::create_directories(argv[1]);
    const std::string format = argv[2], charset = argv[3], operation = argv[5];
    const size_t n = std::stoul(argv[4]); const int repetitions = std::stoi(argv[6]);
    const auto path = (std::filesystem::path(argv[1]) / ("bench." + format)).string();
    std::vector<Key> keys(n); std::iota(keys.begin(), keys.end(), 1);
    std::vector<std::vector<double>> numbers;
    std::vector<double> classes;
    std::vector<std::string> names, times;
    std::vector<std::vector<std::string>> texts;
    const std::string label = charset == "ascii" ? "Sample measurement text with ordinary spaces 123456789" : "Grüße Ελληνικά 日本語 🙂 e\u0301 Messwert 123456789";
    if (format == "names") { names.assign(n, label); texts.assign(n, {label, label}); }
    if (format == "lrn" || format == "dts") numbers.assign(n, {1.23456789, -987.654321, 0.123});
    if (format == "cls") classes.assign(n, 7);
    if (format == "dts") times.assign(n, "2026-11-20 12:34:56");
    std::ostringstream log;
    auto write = [&]() {
        if (format == "names") write_names(names, {"Names", "A", "B"}, keys, texts, path, label, true, false, 2, 0, log);
        if (format == "lrn") write_lrn({"A", "B", "C"}, keys, numbers, {}, path, label, -1, -1, false, true, false, 2, 0, log);
        if (format == "cls") write_cls(keys, classes, -1, path, label, true, false, 2, 0, log);
        if (format == "dts") write_dates({"A", "B", "C"}, keys, times, numbers, path, "Timezone: UTC\n" + label, -1, true, false, 2, 0, log);
    };
    write();
    for (int i = -1; i < repetitions; ++i) {
        log.str(""); log.clear();
        const auto start = std::chrono::steady_clock::now();
        if (operation == "write") write();
        else {
            if (format == "names" && std::get<1>(read_names(path, false, log)).size() != n) return 3;
            if (format == "lrn" && std::get<1>(read_lrn(path, false, log)).size() != n) return 3;
            if (format == "cls" && std::get<0>(read_cls(path, false, log)).size() != n) return 3;
            if (format == "dts" && std::get<1>(read_dates(path, false, log)).size() != n) return 3;
        }
        const auto seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - start).count();
        if (i >= 0) std::cout << seconds << '\n';
    }
    rusage usage{};
    getrusage(RUSAGE_SELF, &usage);
    std::cerr << usage.ru_maxrss << " maximum resident set size\n";
}
