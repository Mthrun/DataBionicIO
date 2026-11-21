# OUTPUT
# Build targets for the shared C++ library and the selected language packages.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

cmake_minimum_required(VERSION 3.15)

option(BUILD_RPACKAGE "Build RPackage bindings" ON)
option(BUILD_PYPACKAGE "Build Python package bindings" ON)
option(BUILD_PYTHON_TESTS "Register Python binding tests" ON)
option(BUILD_MATLABPACKAGE "Build MATLAB package bindings" OFF)
option(BUILD_JULIAPACKAGE "Build Julia package bindings" OFF)

# A Python interpreter may target an older macOS than the compiler's default.
# Select one explicit deployment target for the core, binding and wheel tag.
# Respect the user's CMake/environment target; otherwise use the host's major
# release (macOS wheel compatibility tags use .0 for releases 11 and later).
if(CMAKE_HOST_APPLE AND BUILD_PYPACKAGE AND NOT CMAKE_OSX_DEPLOYMENT_TARGET
        AND "$ENV{MACOSX_DEPLOYMENT_TARGET}" STREQUAL "")
    execute_process(COMMAND sw_vers -productVersion OUTPUT_VARIABLE host_macos
        OUTPUT_STRIP_TRAILING_WHITESPACE RESULT_VARIABLE host_macos_status)
    if(NOT host_macos_status EQUAL 0)
        message(FATAL_ERROR "Set CMAKE_OSX_DEPLOYMENT_TARGET for the Python build")
    endif()
    if(host_macos VERSION_LESS "11")
        string(REGEX MATCH "^[0-9]+[.][0-9]+" default_macos_target "${host_macos}")
    else()
        string(REGEX MATCH "^[0-9]+" default_macos_target "${host_macos}")
        string(APPEND default_macos_target ".0")
    endif()
    set(CMAKE_OSX_DEPLOYMENT_TARGET "${default_macos_target}" CACHE STRING "Minimum macOS version" FORCE)
endif()
project(DataBionicIO VERSION 1.0.2)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake")

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if (MSVC)
    # warning level 4 and all warnings as errors
    add_compile_options(/W4 /WX-)
else ()
    # lots of warnings and all warnings as errors
    add_compile_options(-Wall -Wextra -Wold-style-cast -pedantic -Wno-error)
endif ()

# Use the project version for the C++, Python, and R packages.
set(CppLIB_VERSION "${PROJECT_VERSION}")
set(RPACKAGE_VERSION "${PROJECT_VERSION}")
add_subdirectory(libs/cDataIO)

define_property(TARGET PROPERTY Package_Name
        BRIEF_DOCS "The name of R/Python package to be installed"
        FULL_DOCS "The name of R/Python package to be installed"
        )

enable_testing()
if (BUILD_JULIAPACKAGE)
    add_subdirectory(libs/juliaDataIO)
endif ()
if (BUILD_MATLABPACKAGE)
    add_subdirectory(libs/matlabDataIO)
endif ()
if (BUILD_RPACKAGE)
    add_subdirectory(libs/RDataIO)
endif ()

if (BUILD_PYPACKAGE)
	INCLUDE(CheckIncludeFileCXX)
	CHECK_INCLUDE_FILE_CXX(span HAS_SPAN)
	if (NOT HAS_SPAN)
    		message(FATAL_ERROR "Could not find span header, but it is required for the numpy bindings")
	endif ()
    add_subdirectory(libs/pyDataIO)
    if (BUILD_PYTHON_TESTS)
        add_subdirectory(tests/Python)
    endif ()
endif ()
