# OUTPUT
# Copies of the canonical license files in the destination folder.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

set(DATABIONICIO_LICENSE_ROOT "${CMAKE_CURRENT_LIST_DIR}/..")
set(DATABIONICIO_LICENSE_FILES
    LICENSE LICENSING.md MATLAB-EXCEPTION.txt COMMERCIAL-LICENSE.txt
    NOTICE.txt THIRD-PARTY-NOTICES.txt LICENSES/pybind11-BSD-3-Clause.txt)

function(databionicio_copy_licenses destination)
    foreach(name IN LISTS DATABIONICIO_LICENSE_FILES)
        configure_file("${DATABIONICIO_LICENSE_ROOT}/${name}"
                       "${destination}/${name}" COPYONLY)
    endforeach()
endfunction()
