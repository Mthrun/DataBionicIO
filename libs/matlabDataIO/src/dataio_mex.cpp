// OUTPUT
// MEX command results, captured diagnostic messages, and error text.
// SPDX-License-Identifier: AGPL-3.0-only
// Additional permission: see MATLAB-EXCEPTION.txt.

// MATLAB C Matrix API gateway. File rules stay in the shared C++ readers/writers.
// All C++ objects leave scope before MATLAB receives an error or warning.
#include "mex.h"
#include "DataIO/read_lrn.hpp"
#include "DataIO/write_lrn.hpp"
#include "DataIO/read_names.hpp"
#include "DataIO/write_names.hpp"
#include "DataIO/read_cls.hpp"
#include "DataIO/write_cls.hpp"
#include "DataIO/read_dates.hpp"
#include "DataIO/write_dates.hpp"
#include <algorithm>
#include <cmath>
#include <limits>
#include <sstream>
#include <stdexcept>

namespace {
using namespace dbt::DataIO;
using Matrix = std::vector<std::vector<double>>;

/**
 * Check a gateway precondition.
 *
 * INPUT
 * valid  Condition to check.
 * message  Exception text.
 *
 * OUTPUT
 * No return value; throws std::invalid_argument when valid is false.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
void require(bool valid, const char* message) {
    if (!valid) throw std::invalid_argument(message);
}

/**
 * Convert a MATLAB character row to UTF-8.
 *
 * INPUT
 * value  MATLAB character row without NUL characters.
 *
 * OUTPUT
 * UTF-8 std::string; invalid shape or conversion failure throws.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
std::string text(const mxArray* value) {
    require(value && mxIsChar(value) && mxGetM(value) <= 1, "Expected one character row.");
    const auto* chars = mxGetChars(value);
    for (mwSize i = 0; i < mxGetNumberOfElements(value); ++i)
        require(chars[i] != 0, "Text must not contain a NUL character.");
    char* bytes = mxArrayToUTF8String(value);
    require(bytes != nullptr, "Cannot convert text to UTF-8.");
    std::string result(bytes);
    mxFree(bytes);
    return result;
}

/**
 * Get a required request field.
 *
 * INPUT
 * request  Scalar MATLAB struct.
 * name  Required field name.
 *
 * OUTPUT
 * Borrowed pointer to the field; an absent field throws.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
const mxArray* field(const mxArray* request, const char* name) {
    const auto* value = mxGetField(request, 0, name);
    require(value != nullptr, "A required request field is missing.");
    return value;
}

/**
 * Validate a MATLAB numeric matrix.
 *
 * INPUT
 * value  Candidate MATLAB array.
 *
 * OUTPUT
 * No return value; accepts only a full real two-dimensional double array.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
void numeric(const mxArray* value) {
    require(value && mxIsDouble(value) && !mxIsSparse(value) && !mxIsComplex(value)
            && mxGetNumberOfDimensions(value) == 2, "Expected a full real double matrix.");
}

/**
 * Read a scalar request value.
 *
 * INPUT
 * request  Scalar MATLAB request struct.
 * name  Required numeric field name.
 *
 * OUTPUT
 * Double value; a non-scalar or invalid numeric field throws.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
double scalar(const mxArray* request, const char* name) {
    const auto* value = field(request, name);
    numeric(value);
    require(mxGetNumberOfElements(value) == 1, "Expected a numeric scalar.");
    return mxGetScalar(value);
}

/**
 * Read a bounded integer option.
 *
 * INPUT
 * request  Scalar MATLAB request struct.
 * name  Required option field name.
 *
 * OUTPUT
 * Integer from -1 through 1000; other values throw.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
int integer(const mxArray* request, const char* name) {
    const double value = scalar(request, name);
    require(std::isfinite(value) && value == std::trunc(value)
        && value >= -1 && value <= 1000, "Invalid integer option.");
    return static_cast<int>(value);
}

/**
 * Read a Boolean option.
 *
 * INPUT
 * request  Scalar MATLAB request struct.
 * name  Required option field name.
 *
 * OUTPUT
 * FALSE for 0 or TRUE for 1; other values throw.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
bool flag(const mxArray* request, const char* name) {
    const double value = scalar(request, name);
    require(value == 0 || value == 1, "A flag must be 0 or 1.");
    return value != 0;
}

/**
 * Copy a MATLAB double vector.
 *
 * INPUT
 * value  Full real double row or column vector, or an empty matrix.
 *
 * OUTPUT
 * Vector of doubles in MATLAB storage order.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
std::vector<double> numbers(const mxArray* value) {
    numeric(value);
    const auto count = mxGetNumberOfElements(value);
    require(count == 0 || mxGetM(value) == 1 || mxGetN(value) == 1, "Expected a numeric vector.");
    if (count == 0) return {};
    return {mxGetPr(value), mxGetPr(value) + count};
}

/**
 * Validate and copy MATLAB keys.
 *
 * INPUT
 * value  Full real int64, uint64, or double vector.
 *
 * OUTPUT
 * Signed key vector with finite whole values in [-2^53, 2^53]; invalid keys throw.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
std::vector<Key> keys(const mxArray* value) {
    require(value && !mxIsSparse(value) && !mxIsComplex(value)
        && mxGetNumberOfDimensions(value) == 2, "Expected a full real key vector.");
    const auto count = mxGetNumberOfElements(value);
    require(count == 0 || mxGetM(value) == 1 || mxGetN(value) == 1, "Expected a key vector.");
    std::vector<Key> result;
    result.reserve(count);
    // Check int64/uint64 before conversion to double. Larger IDs can otherwise round into range.
    for (mwSize i = 0; i < count; ++i) {
        Key key;
        if (mxIsInt64(value)) {
            key = static_cast<const int64_T*>(mxGetData(value))[i];
            require(key >= -MAX_EXACT_KEY && key <= MAX_EXACT_KEY, "Key is outside +/-2^53.");
        } else if (mxIsUint64(value)) {
            const auto raw = static_cast<const uint64_T*>(mxGetData(value))[i];
            require(raw <= static_cast<uint64_T>(MAX_EXACT_KEY), "Key is outside +/-2^53.");
            key = static_cast<Key>(raw);
        } else {
            numeric(value);
            const double raw = mxGetPr(value)[i];
            require(std::isfinite(raw) && raw == std::trunc(raw)
                && raw >= -MAX_EXACT_KEY && raw <= MAX_EXACT_KEY,
                "Keys must be finite whole numbers in +/-2^53.");
            key = static_cast<Key>(raw);
        }
        result.push_back(key);
    }
    return result;
}

/**
 * Copy MATLAB text cells.
 *
 * INPUT
 * value  Cell array of character rows.
 *
 * OUTPUT
 * UTF-8 strings in column-major cell order.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
std::vector<std::string> strings(const mxArray* value) {
    require(value && mxIsCell(value), "Expected a cell array of character rows.");
    std::vector<std::string> result;
    result.reserve(mxGetNumberOfElements(value));
    for (mwIndex i = 0; i < mxGetNumberOfElements(value); ++i) result.push_back(text(mxGetCell(value, i)));
    return result;
}

/**
 * Convert a MATLAB matrix to a core row table.
 *
 * INPUT
 * value  Full real double matrix.
 *
 * OUTPUT
 * Nested vectors with one record per inner vector.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
Matrix rows(const mxArray* value) {
    numeric(value);
    const auto n = mxGetM(value), d = mxGetN(value);
    Matrix result(n, std::vector<double>(d));
    const auto* data = mxGetPr(value);
    for (mwSize j = 0; j < d; ++j)
        for (mwSize i = 0; i < n; ++i) result[i][j] = data[i + n*j];
    return result;
}

/**
 * Allocate a MATLAB numeric column vector.
 *
 * INPUT
 * values  Vector of values convertible to double.
 *
 * OUTPUT
 * New MATLAB double column; the caller owns the returned array.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
template<class T> mxArray* vector_out(const std::vector<T>& values) {
    auto* result = mxCreateDoubleMatrix(values.size(), 1, mxREAL);
    for (mwSize i = 0; i < values.size(); ++i) mxGetPr(result)[i] = static_cast<double>(values[i]);
    return result;
}

/**
 * Allocate a MATLAB column for core keys.
 *
 * INPUT
 * values  Core keys, possibly including MISSING_KEY.
 *
 * OUTPUT
 * New MATLAB double column with NaN for missing keys; the caller owns it.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
mxArray* keys_out(const std::vector<Key>& values) {
    auto* result = vector_out(values);
    for (mwSize i = 0; i < values.size(); ++i)
        if (values[i] == MISSING_KEY) mxGetPr(result)[i] = mxGetNaN();
    return result;
}

/**
 * Allocate a MATLAB cell column for strings.
 *
 * INPUT
 * values  Text strings.
 *
 * OUTPUT
 * New cell column containing character arrays; the caller owns it.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
mxArray* strings_out(const std::vector<std::string>& values) {
    auto* result = mxCreateCellMatrix(values.size(), 1);
    for (mwIndex i = 0; i < values.size(); ++i) mxSetCell(result, i, mxCreateString(values[i].c_str()));
    return result;
}

/**
 * Allocate a MATLAB matrix from a core table.
 *
 * INPUT
 * values  Rectangular row or column table.
 * n  Output row count.
 * d  Output column count.
 * columns  TRUE means inner vectors contain columns; FALSE means rows.
 *
 * OUTPUT
 * New n-by-d double matrix; inconsistent dimensions throw. The caller owns the array.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
mxArray* matrix_out(const Matrix& values, mwSize n, mwSize d, bool columns) {
    auto* result = mxCreateDoubleMatrix(n, d, mxREAL);
    for (mwSize j = 0; j < d; ++j)
        for (mwSize i = 0; i < n; ++i) mxGetPr(result)[i+n*j] = columns ? values.at(j).at(i) : values.at(i).at(j);
    return result;
}

/**
 * Add a field to the MATLAB result struct.
 *
 * INPUT
 * result  Scalar output struct.
 * name  New field name.
 * value  Allocated MATLAB value to transfer to the struct.
 *
 * OUTPUT
 * No return value. The result struct owns value after assignment.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
void put(mxArray* result, const char* name, mxArray* value) {
    mxAddField(result, name);
    mxSetField(result, 0, name, value);
}

/**
 * Execute a DataIO gateway command.
 *
 * INPUT
 * command  version or one of the eight read/write command names.
 * request  Scalar struct with the fields required by the command.
 * result  Scalar output struct to populate.
 * log  Destination for core diagnostics.
 *
 * OUTPUT
 * Updates result; write commands also create files. Invalid commands or arguments throw.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
void dispatch(const std::string& command, const mxArray* request, mxArray* result, std::ostream& log) {
    if (command == "version") {
        put(result, "API", mxCreateDoubleScalar(1));
        return;
    }
    const auto path = text(field(request, "Path"));
    // Collect all messages. MATLAB decides which information to show after this function returns.
    if (command == "read_lrn") {
        const auto value = read_lrn(path, true, log);
        put(result, "Header", strings_out(std::get<0>(value)));
        put(result, "Key", keys_out(std::get<1>(value)));
        put(result, "Data", matrix_out(std::get<2>(value), std::get<1>(value).size(), std::get<0>(value).size(), false));
        put(result, "DataDefined", vector_out(std::get<3>(value)));
        put(result, "Comment", mxCreateString(std::get<4>(value).c_str()));
    } else if (command == "read_cls") {
        const auto value = read_cls(path, true, log);
        put(result, "Key", keys_out(std::get<0>(value)));
        put(result, "Cls", vector_out(std::get<1>(value)));
        put(result, "UniqueClasses", vector_out(std::get<2>(value)));
        put(result, "Comment", mxCreateString(std::get<3>(value).c_str()));
    } else if (command == "read_names") {
        const auto value = read_names(path, true, log);
        const auto n = std::get<1>(value).size();
        const auto& rest = std::get<3>(value); // The reader returns columns; the writer accepts rows.
        auto* cells = mxCreateCellMatrix(n, rest.size());
        for (mwSize j = 0; j < rest.size(); ++j)
            for (mwSize i = 0; i < n; ++i) mxSetCell(cells, i+n*j, mxCreateString(rest[j][i].c_str()));
        put(result, "Header", strings_out(std::get<0>(value)));
        put(result, "Key", keys_out(std::get<1>(value)));
        put(result, "Names", strings_out(std::get<2>(value)));
        put(result, "FurtherTexts", cells);
        put(result, "Comment", mxCreateString(std::get<4>(value).c_str()));
    } else if (command == "read_dates") {
        const auto value = read_dates(path, true, log);
        put(result, "Header", strings_out(std::get<0>(value)));
        put(result, "Key", keys_out(std::get<1>(value)));
        put(result, "DST", strings_out(std::get<2>(value)));
        put(result, "Time", strings_out(std::get<3>(value)));
        put(result, "Data", matrix_out(std::get<4>(value), std::get<1>(value).size(), std::get<4>(value).size(), true));
        put(result, "Comment", mxCreateString(std::get<5>(value).c_str()));
        put(result, "Timezone", mxCreateString(std::get<6>(value).c_str()));
    } else {
        const auto key = keys(field(request, "Key"));
        const auto comment = text(field(request, "Comment"));
        const bool overwrite = flag(request, "Overwrite");
        if (command == "write_lrn") {
            const int significant = integer(request, "SignificantDigits");
            require(significant == -1 || significant > 0, "SignificantDigits must be positive or -1.");
            std::vector<int> types;
            for (double type : numbers(field(request, "DataDefined"))) {
                require(std::isfinite(type) && type == std::trunc(type) && type >= 0 && type <= 9, "DataDefined must contain integers from 0 to 9.");
                types.push_back(static_cast<int>(type));
            }
            write_lrn(strings(field(request, "Header")), key, rows(field(request, "Data")), types, path, comment,
                significant, integer(request, "DecimalDigits"), flag(request, "Scientific"), overwrite, true, 2, 0, log);
        } else if (command == "write_cls") {
            write_cls(key, numbers(field(request, "Cls")), scalar(request, "NaNReplacement"), path, comment, overwrite, true, 2, 0, log);
        } else if (command == "write_names") {
            const auto* cells = field(request, "FurtherTexts");
            const auto values = strings(cells);
            const auto n = mxGetM(cells), d = mxGetN(cells);
            std::vector<std::vector<std::string>> rest(n, std::vector<std::string>(d));
            for (mwSize j = 0; j < d; ++j)
                for (mwSize i = 0; i < n; ++i) rest[i][j] = values[i+n*j];
            write_names(strings(field(request, "Names")), strings(field(request, "Header")), key, rest, path, comment, overwrite, true, 2, 0, log);
        } else if (command == "write_dates") {
            const int format = integer(request, "Format");
            require(format == -1 || (format >= 1 && format <= 3), "Format must be -1, 1, 2, or 3.");
            write_dates(strings(field(request, "Header")), key, strings(field(request, "Time")), rows(field(request, "Data")), path, comment,
                format, overwrite, true, 2, 0, log);
        } else throw std::invalid_argument("Unknown DataIO command.");
    }
}
} // namespace

/**
 * Run the MATLAB gateway and capture C++ errors.
 *
 * INPUT
 * nlhs  Number of requested outputs; must be 3.
 * plhs  Output pointer array with three slots.
 * nrhs  Number of inputs; must be 2.
 * prhs  Command character row and scalar request struct.
 *
 * OUTPUT
 * plhs contains a result struct, diagnostic text, and error text. Invalid call shape raises DataIO:Gateway.
 * SPDX-License-Identifier: AGPL-3.0-only
 * Additional permission: see MATLAB-EXCEPTION.txt.
 */
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
    if (nrhs != 2 || nlhs != 3 || !mxIsStruct(prhs[1]) || mxGetNumberOfElements(prhs[1]) != 1)
        mexErrMsgIdAndTxt("DataIO:Gateway", "Use the public DataIO MATLAB functions.");
    std::ostringstream log;
    std::string error;
    plhs[0] = mxCreateStructMatrix(1, 1, 0, nullptr);
    try { dispatch(text(prhs[0]), prhs[1], plhs[0], log); }
    catch (const std::exception& exception) { error = exception.what(); }
    catch (...) { error = "Unknown C++ error."; }
    plhs[1] = mxCreateString(log.str().c_str());
    plhs[2] = mxCreateString(error.c_str());
}
