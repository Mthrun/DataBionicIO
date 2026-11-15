# OUTPUT
# Build and package targets for the cDataIO component.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

set(TARGET_NAME CDataIO)

file(GLOB_RECURSE headers include/DataIO/*.h include/DataIO/*.hpp src/*.h src/*.hpp)
file(GLOB_RECURSE sources src/*.cpp)

add_library(${TARGET_NAME} ${sources} ${headers})

target_compile_definitions(${TARGET_NAME} PRIVATE MYLIB_EXPORTS)
target_include_directories(${TARGET_NAME} PRIVATE include/)
target_include_directories(${TARGET_NAME} SYSTEM INTERFACE include/)

set_target_properties(CDataIO PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
)
set_target_properties(CDataIO PROPERTIES
    LIBRARY_INCLUDE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/include"
)