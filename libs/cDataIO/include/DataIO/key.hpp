// OUTPUT
// The Key integer type and the MAX_EXACT_KEY and MISSING_KEY constants.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.

#ifndef DBT_DATA_IO_KEY_HPP
#define DBT_DATA_IO_KEY_HPP

#include <cstdint>
#include <limits>

namespace dbt {
    namespace DataIO {
        // A 32-bit int lost large keys. Use one 64-bit type in all interfaces.
        using Key = std::int64_t;

        // R and MATLAB doubles keep every integer in this range exact.
        // Reserve a value outside this range for missing keys, not a valid ID.
        constexpr Key MAX_EXACT_KEY = INT64_C(9007199254740992); // 2^53
        constexpr Key MISSING_KEY = std::numeric_limits<Key>::min();
    }
}

#endif
