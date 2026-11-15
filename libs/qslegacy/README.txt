qslegacy 0.1.0

The qslegacy R package reads legacy QS files that contain lists of matrices.
It reads each file in the current R process.
It does not write files, install packages, or compile code during a read operation.
It does not start a new R process.

INTERFACE

The public function is qread_matrices(file, strict=FALSE).
The file argument supplies the path to an existing QS file.
The result is a list of matrices with names, dimensions, and ordinary R attributes.

With strict=TRUE, a checksum mismatch or recorded-length mismatch causes an error.
With strict=FALSE, these conditions cause warnings.
Unsupported R objects and structural errors in the file cause errors.

DEPENDENCIES AND USE

The package has its own DESCRIPTION file and license.
The DataBionicIO R interface calls qread_matrices at runtime.

Install qslegacy before a read operation on a legacy QS file.

SOURCE AND LICENSE

The package uses the GPL-3 license.
The source file legacy_qs.cpp uses format definitions and decoder code from qs 0.27.3 by Travers Ching.
The initial source files are qs_common.h and qs_deserialize_common.h.
The source project is https://github.com/qsbase/qs .

The folder src/vendor contains compression, checksum, and byte-order code from qs 0.27.3.
These files keep their individual copyright and license notices.
The folder inst/LICENSES contains the license texts.
