# OUTPUT
# The Boost external-project target and its build-directory installation.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

MESSAGE( "Installing external project: Boost" )

SET(BOOST_VERSION 1.85.0)
string(REPLACE "." "_" BOOST_UNDERSCORE_VERSION ${BOOST_VERSION})


IF(WIN32)
    set(BOOST_COMPRESSION "zip")
    set(BOOST_SHA256 e712fe7eb1b9ec37ac25102525412fb4d74e638996443944025791f48f29408a)
    set(BOOST_BOOTSTRAP_COMMAND ./bootstrap.bat)
    set(BOOST_B2_COMMAND b2.exe)
ELSEIF(UNIX)
    set(BOOST_COMPRESSION "tar.bz2")
    set(BOOST_SHA256 7009fe1faa1697476bdc7027703a2badb84e849b7b0baad5086b087b971f8617)
    set(BOOST_BOOTSTRAP_COMMAND ./bootstrap.sh)
    set(BOOST_B2_COMMAND ./b2)
ENDIF()


SET(BOOST_URL "https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_UNDERSCORE_VERSION}.${BOOST_COMPRESSION}")

ExternalProject_Add(
        Boost
        URL         ${BOOST_URL}
        URL_HASH      SHA256=${BOOST_SHA256}
        BUILD_IN_SOURCE   1
        CONFIGURE_COMMAND   ${BOOST_BOOTSTRAP_COMMAND}
        ${BOOST_LIBRARIES_WITH}                 # this declares the used libraries on unix
        BUILD_COMMAND  ${BOOST_B2_COMMAND} install
          --toolset=gcc
          --without-python
          --with-regex
          --without-mpi
          --disable-icu
          --prefix=${CMAKE_BINARY_DIR}/INSTALL
          --threading=single,multi
          --link=static
          --variant=release
          -j8
        INSTALL_COMMAND       "")

message(STATUS "Added Target Boost.")