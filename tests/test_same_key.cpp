// INPUT
// Fixed numeric sequences, including order, precision, and missing-value cases.
// OUTPUT
// Failed comparisons stop the test; no files are created.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.

#include "DataIO/the_same_key.hpp"
#include <cassert>
#include <cmath>
#include <limits>

int main() {
    const auto the_same_key = static_cast<bool (*)(const std::vector<double>&,
        const std::vector<double>&) noexcept>(&dbt::DataIO::the_same_key);
    assert(the_same_key({}, {}));
    assert(!the_same_key({}, {1}));
    assert(!the_same_key({1}, {}));
    assert(the_same_key({1, 2, 3}, {1, 2, 3}));
    assert(!the_same_key({1, 2, 3}, {1, 3, 2}));
    assert(!the_same_key({1, 2}, {1, 2, 3}));
    assert(!the_same_key({1, 2}, {1, 3}));
    assert(the_same_key({1, 1}, {1, 1}));
    assert(the_same_key({1.5, -0.0}, {1.5, 0.0}));
    assert(!the_same_key({1}, {std::nextafter(1.0, 2.0)}));
    assert(the_same_key({-9007199254740992.0, 9007199254740992.0},
                        {-9007199254740992.0, 9007199254740992.0}));
    const double nan = std::numeric_limits<double>::quiet_NaN();
    assert(!the_same_key({nan}, {nan}));
    assert(!the_same_key({1, nan}, {1, 2}));
    const double inf = std::numeric_limits<double>::infinity();
    assert(the_same_key({inf, -inf}, {inf, -inf}));
    assert(!the_same_key({inf}, {-inf}));
    const std::vector<double> values{3, 1, 2};
    assert(the_same_key(values, values));
    assert((values == std::vector<double>{3, 1, 2}));
    using dbt::DataIO::Key;
    const std::vector<Key> a{INT64_C(9007199254740993)};
    const std::vector<Key> b{INT64_C(9007199254740992)};
    assert(dbt::DataIO::the_same_key(a, a));
    assert(!dbt::DataIO::the_same_key(a, b));
    const std::vector<Key> missing{dbt::DataIO::MISSING_KEY};
    assert(!dbt::DataIO::the_same_key(missing, missing));
}
