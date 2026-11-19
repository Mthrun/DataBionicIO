set(TARGET_NAME DataBionicIO)

#find_package(Rcpp REQUIRED)
file(GLOB_RECURSE sources src/*.cpp)
file(GLOB_RECURSE rfiles R/*.R)

macro(create_file_if_not_existing filename content)
    if (NOT EXISTS "${filename}")
        file(WRITE "${filename}" "${content}")
    endif ()
endmacro()
set(RCPP_EXPORTS_FILE "${CMAKE_CURRENT_BINARY_DIR}/src/RcppExports.cpp")
create_file_if_not_existing(${RCPP_EXPORTS_FILE} "")
list(APPEND sources "${RCPP_EXPORTS_FILE}")


list(TRANSFORM sources PREPEND "\"")
list(TRANSFORM sources APPEND "\"")

set(sources_str "")
list(LENGTH sources sources_length)
set(counter 0)

foreach(item IN LISTS sources)
    MESSAGE(${item})
    math(EXPR counter "${counter} + 1")
    set(sources_str "${sources_str}${item}")
    if (NOT counter EQUAL sources_length)
        set(sources_str "${sources_str} ")
    endif()
endforeach()




#add_library(${TARGET_NAME} MODULE ${sources})
set(output_lib "${CMAKE_CURRENT_BINARY_DIR}/src/${TARGET_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}")
get_target_property(LIBRARY_PATH CDataIO LIBRARY_OUTPUT_DIRECTORY)
get_target_property(LIBRARY_INCLUDE_PATH CDataIO LIBRARY_INCLUDE_DIRECTORY)

MESSAGE("${output_lib} ${LIBRARY_PATH}")
MESSAGE(${sources_str})


set(CMAKE_VERBOSE_MAKEFILE TRUE)


if (WIN32)
else ()
    set(R_EXECUTABLE R)
    set(R_COMMAND R)
endif ()

execute_process (
    COMMAND R --slave -e "cat(Rcpp:::CxxFlags())"
    OUTPUT_VARIABLE RCPP_CXXFLAGS
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
MESSAGE("PKG_CPPFLAGS=\"${RCPP_CXXFLAGS} -I${LIBRARY_INCLUDE_PATH}\" PKG_LIBS=\"-L${LIBRARY_PATH} -lCDataIO\" ${R_EXECUTABLE} CMD SHLIB ${sources_str} -o \"${output_lib}\"")
string(REGEX MATCHALL "-I[^ ]+" RCPP_INCLUDE_FLAGS ${RCPP_CXXFLAGS})


add_custom_command(
  OUTPUT "${output_lib}"
  COMMAND bash -c "PKG_CPPFLAGS=\"${RCPP_CXXFLAGS} -I${LIBRARY_INCLUDE_PATH}\" PKG_LIBS=\"-L${LIBRARY_PATH} -lCDataIO\" ${R_EXECUTABLE} CMD SHLIB ${sources_str} -o \"${output_lib}\""
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
  COMMENT "Building Rcpp module using R CMD SHLIB ${LIBRARY_PATH} ${output_lib}"
)


# Register it as a target so other targets can depend on it
add_custom_target(${TARGET_NAME} ALL DEPENDS "${output_lib}")
add_dependencies(${TARGET_NAME} CDataIO)




set(SHARED_OUTPUT_NAME ${TARGET_NAME})




set_source_files_properties(${RCPP_EXPORTS_FILE} PROPERTIES COMPILE_FLAGS
        "$<$<CXX_COMPILER_ID:GNU>:-Wno-old-style-cast> -Wno-cast-function-type")

execute_process(COMMAND "${R_COMMAND}" --silent --slave -e "cat(R.Version()$platform)" OUTPUT_VARIABLE R_PLATFORM)
if (WIN32)
    set(RPACKAGE_PLATFORM_POSTFIX ".zip")
    create_file_if_not_existing("${CMAKE_CURRENT_BINARY_DIR}/src/Makefile.win" "all:")
else ()
    set(RPACKAGE_PLATFORM_POSTFIX "_R_${R_PLATFORM}.tar.gz")
    create_file_if_not_existing("${CMAKE_CURRENT_BINARY_DIR}/src/Makefile" "all:")
endif ()
set(RPACKAGE_NAME ${TARGET_NAME}_${RPACKAGE_VERSION}${RPACKAGE_PLATFORM_POSTFIX})
message(STATUS "Detected RPackage filename ${RPACKAGE_NAME}")
message(STATUS "R_EXECUTABLE ${R_EXECUTABLE}")

#target_link_libraries(${TARGET_NAME} PRIVATE rcpp CDataIO)
#target_compile_definitions(${TARGET_NAME} PRIVATE $<$<AND:$<CXX_COMPILER_ID:GNU>,$<PLATFORM_ID:Windows>>:STRICT_R_HEADERS>)
#target_link_options(${TARGET_NAME} PRIVATE $<$<CXX_COMPILER_ID:GNU>:-Wl,--no-undefined>)

set_target_properties(${TARGET_NAME} PROPERTIES
        PREFIX ""
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/src"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/src")

configure_file(DESCRIPTION.in ${CMAKE_CURRENT_BINARY_DIR}/DESCRIPTION @ONLY)
configure_file(NAMESPACE.in ${CMAKE_CURRENT_BINARY_DIR}/NAMESPACE @ONLY)
configure_file(LICENSE ${CMAKE_CURRENT_BINARY_DIR}/LICENSE COPYONLY)
include("${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/DataBionicIOLicenses.cmake")
databionicio_copy_licenses("${CMAKE_CURRENT_BINARY_DIR}/inst/licenses/DataBionicIO")

add_library(RPackageRScripts INTERFACE)
target_sources(RPackageRScripts INTERFACE ${rfiles})

add_custom_target(RcppCompileAttributes
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_CURRENT_SOURCE_DIR}/R ${CMAKE_CURRENT_BINARY_DIR}/R
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_CURRENT_SOURCE_DIR}/src ${CMAKE_CURRENT_BINARY_DIR}/src
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_CURRENT_SOURCE_DIR}/man ${CMAKE_CURRENT_BINARY_DIR}/man
	#COMMAND ${CMAKE_COMMAND} -E copy
    #    ${CMAKE_CURRENT_SOURCE_DIR}/NAMESPACE ${CMAKE_CURRENT_BINARY_DIR}/NAMESPACE
        COMMAND "${R_COMMAND}" --silent -e "\"library(Rcpp);Rcpp::compileAttributes()\""
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        COMMENT "Running Rcpp::compileAttributes")

add_custom_target(RPackageBuild
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_CURRENT_BINARY_DIR}/_build_tmp
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_CURRENT_BINARY_DIR}/Rpkg/man
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/_build_tmp
        COMMAND "${R_COMMAND}" CMD INSTALL --build --library=_build_tmp .
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        COMMENT "Building Rpackage"
        )
add_dependencies(${TARGET_NAME} RcppCompileAttributes)
add_dependencies(RPackageBuild ${TARGET_NAME} RPackageRScripts)

# The legacy qs decoder is a separate GPL package, built at installation time.
# ReadQS must never compile code, launch older R, or create transfer/cache files.
add_custom_target(QSlegacyBuild
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/qslegacy-build/library"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_CURRENT_SOURCE_DIR}/../qslegacy" "${CMAKE_CURRENT_BINARY_DIR}/qslegacy-build/qslegacy"
        COMMAND "${R_COMMAND}" CMD build --no-build-vignettes qslegacy
        COMMAND "${R_COMMAND}" CMD INSTALL --build --library=library qslegacy
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/qslegacy-build"
        COMMENT "Building the read-only legacy qs companion package")
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/qslegacy-build")
add_dependencies(RPackageBuild QSlegacyBuild)

set_target_properties(RPackageBuild PROPERTIES Package_Name ${RPACKAGE_NAME})
add_custom_target(RPackageInstall
        COMMAND "${R_COMMAND}" CMD INSTALL ${TARGET_NAME}_${RPACKAGE_VERSION}${RPACKAGE_PLATFORM_POSTFIX}
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        COMMENT "Installing ${TARGET_NAME} within R"
        )
add_dependencies(RPackageInstall RPackageBuild)

add_custom_target(QSlegacyInstall
        COMMAND "${R_COMMAND}" CMD INSTALL qslegacy
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/qslegacy-build"
        COMMENT "Installing the legacy qs companion package")
add_dependencies(QSlegacyInstall QSlegacyBuild)
add_dependencies(RPackageInstall QSlegacyInstall)
