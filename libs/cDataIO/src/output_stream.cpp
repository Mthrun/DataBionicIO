// INPUT
// The build setting DATAIO_R_CONSOLE; no runtime arguments.
// OUTPUT
// The default diagnostic stream. R output uses the Rcpp console connection.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.
#include "DataIO/output_stream.hpp"

#ifdef DATAIO_R_CONSOLE
#include <Rcpp.h>
#else
#include <iostream>
#endif

namespace dbt::DataIO {
    std::ostream& default_output_stream() {
#ifdef DATAIO_R_CONSOLE
        return Rcpp::Rcout;
#else
        return std::cout;
#endif
    }
}
