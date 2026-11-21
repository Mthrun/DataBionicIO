// INPUT
// The build setting DATAIO_R_CONSOLE; no runtime arguments.
// OUTPUT
// The default diagnostic stream: the R console for R builds, std::cout otherwise.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
#pragma once

#include <ostream>
#include "dataio_exports.hpp"

namespace dbt::DataIO {
    MYLIB_API std::ostream& default_output_stream();
}
