// Register the native Python module.
// INPUT
// m is the pybind11 module handle supplied by module initialization.
// OUTPUT
// The pyDataIO extension module with C++ reader and writer bindings.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.

#include "DataIO/the_same_key.hpp"
#include "DataIO/read_dates.hpp"
#include "DataIO/write_dates.hpp"
#include "DataIO/read_lrn.hpp"
#include "DataIO/write_lrn.hpp"
#include "DataIO/read_cls.hpp"
#include "DataIO/write_cls.hpp"
#include "DataIO/read_names.hpp"
#include "DataIO/write_names.hpp"




#include <functional>
#include <sstream>
#include <iostream>
#include <pybind11/iostream.h>
#include <pybind11/pybind11.h>
#include <pybind11/stl.h>

// INPUT: captured native diagnostics. OUTPUT: encoding warnings through Python warnings.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
static void text_messages(const std::string& messages) {
    std::istringstream input(messages);
    for (std::string line; std::getline(input, line);) {
        if (line.starts_with("WARNING: Converted input") || line.starts_with("WARNING: Replaced "))
            pybind11::module_::import("warnings").attr("warn")(line.substr(9), pybind11::module_::import("builtins").attr("UserWarning"));
        else std::cout << line << std::endl;
    }
}

PYBIND11_MODULE(pyDataIO, m)
{
    namespace py = pybind11;
    m.def("_the_same_key", [](const std::vector<double>& a, const std::vector<double>& b) {
        return dbt::DataIO::the_same_key(a, b);
    });

    //static_cast<SomeType*>(nullptr)
    py::add_ostream_redirect(m, "ostream_redirect");
    
    py::class_<dbt::DataIO::LRN_Reader>(m, "LRN_Reader")
        .def(py::init<>())
        .def_readwrite("N", &dbt::DataIO::LRN_Reader::N)
        .def_readwrite("d", &dbt::DataIO::LRN_Reader::d)
        .def_readwrite("column_names", &dbt::DataIO::LRN_Reader::column_names)
        .def_readwrite("numerics", &dbt::DataIO::LRN_Reader::numerics)
        .def_readwrite("keys", &dbt::DataIO::LRN_Reader::keys)
        .def_readwrite("types", &dbt::DataIO::LRN_Reader::types)
        .def_readwrite("comment", &dbt::DataIO::LRN_Reader::comment)
        .def_readwrite("has_header", &dbt::DataIO::LRN_Reader::has_header)
        .def_readwrite("has_types", &dbt::DataIO::LRN_Reader::has_types)
        .def_readwrite("has_keys", &dbt::DataIO::LRN_Reader::has_keys)
        .def_readwrite("has_nan", &dbt::DataIO::LRN_Reader::has_nan)
        .def_readwrite("row", &dbt::DataIO::LRN_Reader::row)
        .def_readwrite("version_major", &dbt::DataIO::LRN_Reader::version_major)
        .def_readwrite("version_minor", &dbt::DataIO::LRN_Reader::version_minor)
        .def_readwrite("first_line", &dbt::DataIO::LRN_Reader::first_line)
        // A raw ostream pointer cannot be owned/set by Python (None could crash).
        .def("readNextLine", &dbt::DataIO::LRN_Reader::readNextLine,
             py::arg("line"), py::arg("verbose") = true)
        .def("getLRN", &dbt::DataIO::LRN_Reader::getLRN)
        .def("isFinished", &dbt::DataIO::LRN_Reader::isFinished)
        ;
 

    m.def("_read_dates", [](std::string path, bool verbose, const std::string& encoding) {
        std::ostringstream log;
        auto result = dbt::DataIO::read_dates(path, verbose, log, encoding);
        text_messages(log.str()); return result;
    }, py::arg("path"), py::arg("verbose"), py::arg("encoding") = "");
    m.def("_write_dates", py::overload_cast<std::vector<std::string>, std::vector<dbt::DataIO::Key>, std::vector<std::string>, std::vector<std::vector<double>>, std::string, std::string, int, bool, bool, int, int>(&dbt::DataIO::write_dates));
    m.def("_read_lrn", [](std::string path, bool verbose, const std::string& encoding) {
        std::ostringstream log;
        auto result = dbt::DataIO::read_lrn(path, verbose, log, encoding);
        text_messages(log.str()); return result;
    }, py::arg("path"), py::arg("verbose"), py::arg("encoding") = "");
    m.def("_write_lrn", py::overload_cast<std::vector<std::string>, std::vector<dbt::DataIO::Key>, std::vector<std::vector<double>>, std::vector<int>, std::string, std::string, int, int, bool, bool, bool, int, int>(&dbt::DataIO::write_lrn));
    m.def("_read_names", [](std::string path, bool verbose, const std::string& encoding) {
        std::ostringstream log;
        auto result = dbt::DataIO::read_names(path, verbose, log, encoding);
        text_messages(log.str()); return result;
    }, py::arg("path"), py::arg("verbose"), py::arg("encoding") = "");
    m.def("_write_names", [](std::vector<std::string> names, std::vector<std::string> header,
        std::vector<dbt::DataIO::Key> keys, std::vector<std::vector<std::string>> texts,
        std::string path, std::string comment, bool overwrite, bool verbose, int major, int minor,
        const std::string& replacement) {
        std::ostringstream log;
        dbt::DataIO::write_names(std::move(names), std::move(header), std::move(keys), std::move(texts),
            path, comment, overwrite, verbose, major, minor, log, replacement);
        text_messages(log.str());
    }, py::arg("names"), py::arg("header"), py::arg("keys"), py::arg("texts"), py::arg("path"),
       py::arg("comment"), py::arg("overwrite"), py::arg("verbose"), py::arg("major"), py::arg("minor"),
       py::arg("replacement") = "_");
    m.def("_read_cls", [](std::string path, bool verbose, const std::string& encoding) {
        std::ostringstream log;
        auto result = dbt::DataIO::read_cls(path, verbose, log, encoding);
        text_messages(log.str()); return result;
    }, py::arg("path"), py::arg("verbose"), py::arg("encoding") = "");
    m.def("_write_cls", py::overload_cast<std::vector<dbt::DataIO::Key>, std::vector<double>, double, std::string, std::string, bool, bool, int, int>(&dbt::DataIO::write_cls));




    }
