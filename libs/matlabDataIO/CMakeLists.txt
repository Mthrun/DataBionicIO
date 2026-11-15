# OUTPUT
# Build and package targets for the matlabDataIO component.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Build the MEX file with the same core sources as the R and Python packages.
find_package(Matlab 9.12 REQUIRED COMPONENTS MX_LIBRARY MEX_COMPILER)
if (NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(FATAL_ERROR "DataIO requires 64-bit MATLAB and a 64-bit compiler.")
endif ()
file(GLOB core_sources CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/../cDataIO/src/*.cpp")
matlab_add_mex(NAME dataio_mex R2017b SRC src/dataio_mex.cpp ${core_sources})
target_include_directories(dataio_mex PRIVATE ../cDataIO/include)
target_compile_definitions(dataio_mex PRIVATE DATAIO_STATIC)
set_target_properties(dataio_mex PROPERTIES CXX_STANDARD 20 CXX_STANDARD_REQUIRED ON)
if (MSVC)
    target_compile_options(dataio_mex PRIVATE /utf-8)
endif ()

# Each build has its own package. Do not put generated binaries in the sources.
set(matlab_package "${CMAKE_CURRENT_BINARY_DIR}/DataBionicIO")
file(MAKE_DIRECTORY "${matlab_package}/bin")
file(COPY modern native legacy archive tests DESTINATION "${matlab_package}")
file(COPY setupDataIO.m buildDataIO.m README.md ORIGIN.txt DESTINATION "${matlab_package}")
include("${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/DataBionicIOLicenses.cmake")
databionicio_copy_licenses("${matlab_package}")
add_custom_command(TARGET dataio_mex POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:dataio_mex>" "${matlab_package}/bin/")
add_custom_target(MatlabPackage DEPENDS dataio_mex)
install(DIRECTORY "${matlab_package}/" DESTINATION matlab/DataBionicIO)
