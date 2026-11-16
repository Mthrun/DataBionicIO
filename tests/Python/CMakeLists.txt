# OUTPUT
# Build targets and registered tests for this test directory.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

find_package(Python 3.9 REQUIRED COMPONENTS Interpreter)

# Test the build directly; do not create environments or install/download packages.
add_test(NAME python-keys
    COMMAND "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/test_key64.py"
            "$<TARGET_FILE:pyDataIO>")
add_test(NAME python-wrappers
    COMMAND "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/test_wrappers.py"
            "${CMAKE_BINARY_DIR}/libs/pyDataIO")
add_test(NAME python-same-key
    COMMAND "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/test_same_key.py"
            "${CMAKE_BINARY_DIR}/libs/pyDataIO")
set(python_tests python-keys python-wrappers python-same-key)
set(DATAIO_R_TEST_LIBRARY "" CACHE PATH "Fresh isolated R library for the optional Python/R comparison")
if(DATAIO_R_TEST_LIBRARY)
    add_test(NAME python-interop
        COMMAND "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/test_interop.py"
                "${CMAKE_BINARY_DIR}/libs/pyDataIO" "${DATAIO_R_TEST_LIBRARY}")
    list(APPEND python_tests python-interop)
endif()
set_tests_properties(${python_tests} PROPERTIES
    ENVIRONMENT "PYTHONDONTWRITEBYTECODE=1")

add_custom_target(PyTests
    COMMAND "${CMAKE_CTEST_COMMAND}" --output-on-failure -C "$<CONFIG>" -R "^python-"
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    VERBATIM)
add_dependencies(PyTests pyDataIO)
