# OUTPUT
# Build targets and registered tests for this test directory.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

cmake_minimum_required(VERSION 3.15)
project(DataBionicIOTests LANGUAGES CXX)
enable_testing()
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Build only the shared core. No R, Python, or MATLAB library is required here.
file(GLOB core_sources "${CMAKE_CURRENT_SOURCE_DIR}/../libs/cDataIO/src/*.cpp")
add_library(dataio_test_core OBJECT ${core_sources})
target_include_directories(dataio_test_core PUBLIC "../libs/cDataIO/include")
# This existing macro removes DLL import/export attributes for directly linked objects.
target_compile_definitions(dataio_test_core PUBLIC COMPILING_FROM_R)

function(dataio_test name source)
    add_executable(${name} ${source})
    target_link_libraries(${name} PRIVATE dataio_test_core)
    # Release builds must still execute the assertions in these tests.
    if(MSVC)
        target_compile_options(${name} PRIVATE /UNDEBUG)
    else()
        target_compile_options(${name} PRIVATE -UNDEBUG)
    endif()
    add_test(NAME ${name} COMMAND ${name} "${CMAKE_CURRENT_BINARY_DIR}/${name}-files")
endfunction()

dataio_test(keys test_key64.cpp)
dataio_test(headers test_header_warnings.cpp)
dataio_test(legacy legacy/test_readers.cpp)
dataio_test(documented-readers test_documented_readers.cpp)

# Documentation checks need only the Python standard library.
find_package(Python3 3.9 QUIET COMPONENTS Interpreter)
if(Python3_Interpreter_FOUND)
    add_test(NAME documentation
        COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/check_documentation.py")
    add_test(NAME documentation-checker
        COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/test_documentation_check.py")
    set_tests_properties(documentation documentation-checker PROPERTIES
        ENVIRONMENT "PYTHONDONTWRITEBYTECODE=1")
endif()
