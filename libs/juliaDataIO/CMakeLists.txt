# OUTPUT
# A Julia package, CxxWrap module, and CTest entry in the build directory.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

find_program(Julia_EXECUTABLE NAMES julia)
if(NOT Julia_EXECUTABLE)
    message(FATAL_ERROR "Set Julia_EXECUTABLE to a Julia 1.10 or newer executable")
endif()
set(julia_package "${CMAKE_CURRENT_BINARY_DIR}/DataBionicIO")
set(Julia_PROJECT "${julia_package}" CACHE PATH "Julia environment with CxxWrap 0.17")
execute_process(
    COMMAND "${Julia_EXECUTABLE}" --startup-file=no "--project=${Julia_PROJECT}" -e
        "VERSION >= v\"1.10\" || error(\"Julia 1.10 or newer is required\"); using Pkg, libcxxwrap_julia_jll; v=Pkg.dependencies()[Base.UUID(\"1f15a43c-97ca-5a2a-ae31-89f07a497df4\")].version; v\"0.17\" <= v < v\"0.18\" || error(\"CxxWrap 0.17 is required\"); print(dirname(dirname(libcxxwrap_julia_jll.libcxxwrap_julia_path)))"
    RESULT_VARIABLE julia_status OUTPUT_VARIABLE julia_prefix
    ERROR_VARIABLE julia_error OUTPUT_STRIP_TRAILING_WHITESPACE)
if(NOT julia_status EQUAL 0)
    message(FATAL_ERROR "Cannot locate the CxxWrap runtime: ${julia_error}\nStart julia libs/juliaDataIO/build.jl to prepare the package.")
endif()
list(PREPEND CMAKE_PREFIX_PATH "${julia_prefix}")
find_package(JlCxx CONFIG REQUIRED)

# Compile the same core sources into the module, without a separate core DLL.
file(GLOB core_sources CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/../cDataIO/src/*.cpp")
add_library(databionicio_julia SHARED src/bindings.cpp ${core_sources})
target_include_directories(databionicio_julia PRIVATE ../cDataIO/include)
target_compile_definitions(databionicio_julia PRIVATE DATAIO_STATIC)
target_link_libraries(databionicio_julia PRIVATE JlCxx::cxxwrap_julia JlCxx::cxxwrap_julia_stl)
set_target_properties(databionicio_julia PROPERTIES
    CXX_STANDARD 20 CXX_STANDARD_REQUIRED ON PREFIX "lib"
    # CxxWrap loads its runtime before this module. Omit local build paths.
    SKIP_BUILD_RPATH TRUE
    BUILD_WITH_INSTALL_NAME_DIR TRUE INSTALL_NAME_DIR "@rpath"
    LIBRARY_OUTPUT_DIRECTORY "${julia_package}/lib"
    RUNTIME_OUTPUT_DIRECTORY "${julia_package}/lib")
foreach(config ${CMAKE_CONFIGURATION_TYPES})
    string(TOUPPER "${config}" config_upper)
    set_target_properties(databionicio_julia PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY_${config_upper} "${julia_package}/lib"
        RUNTIME_OUTPUT_DIRECTORY_${config_upper} "${julia_package}/lib")
endforeach()
if(MSVC)
    target_compile_options(databionicio_julia PRIVATE /utf-8)
endif()

foreach(name Project.toml README.md src/DataBionicIO.jl test/runtests.jl examples/example.jl)
    configure_file("${name}" "${julia_package}/${name}" COPYONLY)
endforeach()
include("${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/DataBionicIOLicenses.cmake")
databionicio_copy_licenses("${julia_package}")
foreach(name CxxWrap-MIT.md libcxxwrap-julia-MIT.md)
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/../../LICENSES/${name}"
        "${julia_package}/LICENSES/${name}" COPYONLY)
endforeach()
file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/../../tests/legacy/samples"
    DESTINATION "${julia_package}/test")
add_custom_target(JuliaPackage DEPENDS databionicio_julia)
add_test(NAME julia-package
    COMMAND "${Julia_EXECUTABLE}" --startup-file=no "--project=${julia_package}"
        "${julia_package}/test/runtests.jl")
add_test(NAME julia-example
    COMMAND "${Julia_EXECUTABLE}" --startup-file=no "--project=${julia_package}"
        "${julia_package}/examples/example.jl")
add_custom_target(JuliaTests
    COMMAND "${CMAKE_CTEST_COMMAND}" --output-on-failure -C "$<CONFIG>" -R "^julia-"
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}" VERBATIM)
add_dependencies(JuliaTests databionicio_julia)
