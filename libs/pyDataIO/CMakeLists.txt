# OUTPUT
# Build and package targets for the pyDataIO component.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

set(TARGET_NAME pyDataIO)

# Select one interpreter for compilation, packaging and tests.
set(PYBIND11_FINDPYTHON ON)
# CMake 3.18 can find module headers without an interpreter-embedding library.
if(CMAKE_VERSION VERSION_LESS 3.18)
    find_package(Python 3.9 REQUIRED COMPONENTS Interpreter Development)
else()
    find_package(Python 3.9 REQUIRED COMPONENTS Interpreter Development.Module)
endif()
find_package(pybind11 CONFIG REQUIRED)

file(GLOB_RECURSE sources CONFIGURE_DEPENDS src/*.cpp src/*.h src/*.hpp)
file(GLOB_RECURSE pyfiles CONFIGURE_DEPENDS py/*.py)

# This helper sets the platform/ABI suffix. PYTHON_MODULE_EXTENSION was unset
# with FindPython, which could leave a module that Python could not import.
pybind11_add_module(${TARGET_NAME} MODULE NO_EXTRAS ${sources})
target_link_libraries(${TARGET_NAME} PRIVATE CDataIO)
target_compile_definitions(${TARGET_NAME} PRIVATE MYLIB_EXPORTS)

set(PACKAGE_NAME DataBionicIO)
set(package_dir "${CMAKE_CURRENT_BINARY_DIR}/${PACKAGE_NAME}")
set_target_properties(${TARGET_NAME} PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${package_dir}/libs"
    RUNTIME_OUTPUT_DIRECTORY "${package_dir}/libs")
# Multi-config generators must put the module in the importable package too.
foreach(config ${CMAKE_CONFIGURATION_TYPES})
    string(TOUPPER "${config}" config_upper)
    set_target_properties(${TARGET_NAME} PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY_${config_upper} "${package_dir}/libs"
        RUNTIME_OUTPUT_DIRECTORY_${config_upper} "${package_dir}/libs")
endforeach()

configure_file(compat/__init__.py.in "${CMAKE_CURRENT_BINARY_DIR}/pyDataIO/__init__.py" @ONLY)
configure_file(py/__init__.py.in "${package_dir}/__init__.py" @ONLY)
configure_file(py/libs/__init__.py.in "${package_dir}/libs/__init__.py" @ONLY)

# A universal2 Python can build an arm64-only module. Do not label that wheel
# universal2 merely because the interpreter's sysconfig reports both arches.
set(PY_WHEEL_PLATFORM "")
if(APPLE)
    set(wheel_arches ${CMAKE_OSX_ARCHITECTURES})
    if(NOT wheel_arches)
        set(wheel_arches "${CMAKE_SYSTEM_PROCESSOR}")
    endif()
    list(REMOVE_DUPLICATES wheel_arches)
    list(LENGTH wheel_arches wheel_arch_count)
    if(wheel_arch_count EQUAL 2 AND "arm64" IN_LIST wheel_arches AND "x86_64" IN_LIST wheel_arches)
        set(wheel_arch "universal2")
    elseif(wheel_arch_count EQUAL 1)
        list(GET wheel_arches 0 wheel_arch)
    else()
        message(FATAL_ERROR "Unsupported wheel architecture set: ${wheel_arches}")
    endif()
    execute_process(COMMAND "${Python_EXECUTABLE}" -c "import sysconfig; print(sysconfig.get_platform())"
        OUTPUT_VARIABLE PY_WHEEL_PLATFORM OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE wheel_platform_status)
    if(NOT wheel_platform_status EQUAL 0)
        message(FATAL_ERROR "Cannot determine the Python wheel platform")
    endif()
    string(REGEX REPLACE "-[^-]+$" "-${wheel_arch}" PY_WHEEL_PLATFORM "${PY_WHEEL_PLATFORM}")
    if(CMAKE_OSX_DEPLOYMENT_TARGET)
        string(REGEX REPLACE "-[0-9.]+-" "-${CMAKE_OSX_DEPLOYMENT_TARGET}-"
            PY_WHEEL_PLATFORM "${PY_WHEEL_PLATFORM}")
    endif()
endif()
configure_file(setup.py.in "${CMAKE_CURRENT_BINARY_DIR}/setup.py" @ONLY)
include("${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/DataBionicIOLicenses.cmake")
databionicio_copy_licenses("${CMAKE_CURRENT_BINARY_DIR}")
foreach(filename ${pyfiles})
    file(RELATIVE_PATH relative "${CMAKE_CURRENT_SOURCE_DIR}/py" "${filename}")
    configure_file("${filename}" "${package_dir}/${relative}" COPYONLY)
endforeach()

add_custom_target(PyPackageBuild
    COMMAND "${Python_EXECUTABLE}" -m pip wheel --no-deps --no-build-isolation --wheel-dir dist .
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    COMMENT "Building the Python wheel from the compiled module"
    VERBATIM)
add_dependencies(PyPackageBuild ${TARGET_NAME})

add_custom_target(PyPackageInstall
    COMMAND "${Python_EXECUTABLE}" -m pip install --upgrade --force-reinstall --no-deps --no-build-isolation .
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    COMMENT "Installing DataBionicIO in the selected Python environment"
    VERBATIM)
add_dependencies(PyPackageInstall PyPackageBuild)
