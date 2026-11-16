// INPUT
// Julia calls with paths, data, metadata, and writer options.
// OUTPUT
// CxxWrap methods for the four shared formats. Diagnostics accompany results.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.

#include <jlcxx/jlcxx.hpp>
#include <jlcxx/stl.hpp>
#include <jlcxx/tuple.hpp>
#include <sstream>
#include <stdexcept>
#include <tuple>
#include <utility>
#include "DataIO/the_same_key.hpp"
#include "DataIO/read_lrn.hpp"
#include "DataIO/write_lrn.hpp"
#include "DataIO/read_cls.hpp"
#include "DataIO/write_cls.hpp"
#include "DataIO/read_names.hpp"
#include "DataIO/write_names.hpp"
#include "DataIO/read_dates.hpp"
#include "DataIO/write_dates.hpp"

namespace {
using Keys = std::vector<dbt::DataIO::Key>;
using Strings = std::vector<std::string>;
using Numbers = std::vector<std::vector<double>>;
using Texts = std::vector<std::vector<std::string>>;

// INPUT
// operation: a reader taking a diagnostic stream and returning a tuple.
// OUTPUT
// Reader fields followed by diagnostic text. Exceptions retain prior diagnostics.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
template<class Operation>
auto read_with_messages(Operation operation) {
    std::ostringstream messages;
    try {
        auto result = operation(messages);
        return std::tuple_cat(std::move(result), std::make_tuple(messages.str()));
    } catch (const std::exception& error) {
        throw std::runtime_error(messages.str() + error.what());
    }
}

// INPUT
// operation: a writer taking a diagnostic stream.
// OUTPUT
// Writer diagnostics. Exceptions retain prior diagnostics and propagate to Julia.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
template<class Operation>
std::string write_with_messages(Operation operation) {
    std::ostringstream messages;
    try {
        operation(messages);
        return messages.str();
    } catch (const std::exception& error) {
        throw std::runtime_error(messages.str() + error.what());
    }
}
}

// INPUT
// mod: CxxWrap module under construction.
// OUTPUT
// Registers file operations and key comparison. Exceptions become Julia errors.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
JLCXX_MODULE define_julia_module(jlcxx::Module& mod) {
    mod.method("_the_same_key", [](const std::vector<double>& a, const std::vector<double>& b) {
        return dbt::DataIO::the_same_key(a, b);
    });
    mod.method("_read_lrn", [](const std::string& path, bool verbose) {
        return read_with_messages([&](std::ostream& out) {
            return dbt::DataIO::read_lrn(path, verbose, out);
        });
    });
    mod.method("_read_cls", [](const std::string& path, bool verbose) {
        return read_with_messages([&](std::ostream& out) {
            return dbt::DataIO::read_cls(path, verbose, out);
        });
    });
    mod.method("_read_names", [](const std::string& path, bool verbose) {
        return read_with_messages([&](std::ostream& out) {
            return dbt::DataIO::read_names(path, verbose, out);
        });
    });
    mod.method("_read_dates", [](const std::string& path, bool verbose) {
        return read_with_messages([&](std::ostream& out) {
            return dbt::DataIO::read_dates(path, verbose, out);
        });
    });
    mod.method("_write_lrn", [](const Strings& header, const Keys& keys,
        const Numbers& data, const std::vector<int>& types, const std::string& path,
        const std::string& comment, int significant, int decimals, bool scientific,
        bool overwrite, bool verbose) {
        return write_with_messages([&](std::ostream& out) {
            dbt::DataIO::write_lrn(header, keys, data, types, path, comment,
                significant, decimals, scientific, overwrite, verbose, 2, 0, out);
        });
    });
    mod.method("_write_cls", [](const Keys& keys, const std::vector<double>& classes,
        double missing_class, const std::string& path, const std::string& comment,
        bool overwrite, bool verbose) {
        return write_with_messages([&](std::ostream& out) {
            dbt::DataIO::write_cls(keys, classes, missing_class, path, comment,
                overwrite, verbose, 2, 0, out);
        });
    });
    mod.method("_write_names", [](const Strings& names, const Strings& header,
        const Keys& keys, const Texts& texts, const std::string& path,
        const std::string& comment, bool overwrite, bool verbose) {
        return write_with_messages([&](std::ostream& out) {
            dbt::DataIO::write_names(names, header, keys, texts, path, comment,
                overwrite, verbose, 2, 0, out);
        });
    });
    mod.method("_write_dates", [](const Strings& header, const Keys& keys,
        const Strings& times, const Numbers& data, const std::string& path,
        const std::string& comment, int format, bool overwrite, bool verbose) {
        return write_with_messages([&](std::ostream& out) {
            dbt::DataIO::write_dates(header, keys, times, data, path, comment,
                format, overwrite, verbose, 2, 0, out);
        });
    });
}
