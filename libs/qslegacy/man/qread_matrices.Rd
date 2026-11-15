\name{qread_matrices}
\alias{qread_matrices}
\title{Read a Legacy QS List of Matrices}
\description{Reads legacy qs data in the current R process, including R 4.6, without writing any files.}
\usage{qread_matrices(file, strict=FALSE)}
\arguments{
\item{file}{Existing legacy qs file, including its path.}
\item{strict}{If TRUE, checksum and recorded-length mismatches are errors; otherwise they produce warnings. Structural damage always produces an error.}
}
\value{A list of matrices, preserving names, dimensions, dimnames and supported attributes. An empty list is allowed.}
\details{
Supports numeric, integer, logical, character, complex, raw and list matrices,
with attributes composed of these ordinary data types, lists and NULL.
Functions, environments, promises, S4 objects and embedded general R serialization
are intentionally unsupported. An unsupported object is never replaced or omitted.
Legacy zstd, lz4, lz4hc, zstd stream and uncompressed files are supported.
Decoding is sequential. The input byte order must match the host, as in qs 0.27.3.
No older R installation or original qs package is needed.
}
\author{Derived from the qs format by Travers Ching; maintained for DataIO by Michael Thrun.}
\keyword{file}
