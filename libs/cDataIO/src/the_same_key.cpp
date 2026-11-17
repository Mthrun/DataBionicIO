// INPUT
// key_a, key_b: numeric sequences to compare without a tolerance.
// OUTPUT
// One Boolean result. Inputs remain unchanged; no diagnostics or file output.
// AUTHOR: Michael Thrun (IAP-GmbH Intelligent Analytics Projects)
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.

#include "DataIO/the_same_key.hpp"
#include <algorithm>

namespace dbt::DataIO {
bool the_same_key(const std::vector<double>& key_a,
                  const std::vector<double>& key_b) noexcept {
    return key_a.size() == key_b.size()
        && std::equal(key_a.begin(), key_a.end(), key_b.begin());
}

bool the_same_key(const std::vector<Key>& key_a,
                  const std::vector<Key>& key_b) noexcept {
    return key_a.size() == key_b.size()
        && std::equal(key_a.begin(), key_a.end(), key_b.begin(), [](Key a, Key b) {
            return a != MISSING_KEY && a == b;
        });
}
}
