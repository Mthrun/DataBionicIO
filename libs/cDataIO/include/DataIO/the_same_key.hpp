// INPUT
// key_a, key_b: numeric key sequences in their original row order.
// OUTPUT
// True for equal lengths and equal values at every position; otherwise false.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.

#ifndef DBT_DATA_IO_THE_SAME_KEY_HPP
#define DBT_DATA_IO_THE_SAME_KEY_HPP

#include "dataio_exports.hpp"
#include "key.hpp"
#include <vector>

namespace dbt::DataIO {
// Two empty sequences compare equal. NaN never compares equal, including to NaN.
// This comparison does not sort, change inputs, or validate key uniqueness.
MYLIB_API bool the_same_key(const std::vector<double>& key_a,
                           const std::vector<double>& key_b) noexcept;
// Native reader keys keep their full integer precision. MISSING_KEY gives false.
MYLIB_API bool the_same_key(const std::vector<Key>& key_a,
                           const std::vector<Key>& key_b) noexcept;
}

#endif
