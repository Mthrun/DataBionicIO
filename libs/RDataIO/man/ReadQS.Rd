\name{ReadQS}
\alias{ReadQS}
\title{Read legacy qs matrices or current qs2 files}
\description{Explicit extensions choose the format. Without an extension, an existing .qs2 file is preferred; otherwise .qs is attempted. Reading never creates files.}
\usage{ReadQS(FileName, InDirectory=getwd(), NThreads=1, Strict=FALSE)}
\arguments{
\item{FileName}{A single file name, with or without the appropriate extension.}
\item{InDirectory}{Input directory; defaults to the working directory.}
\item{NThreads}{Positive number of threads for qs2. Legacy qs decoding is sequential.}
\item{Strict}{Logical. Legacy checksum and recorded-length mismatches are errors if TRUE, warnings otherwise. For qs2, validate the checksum before deserialization if TRUE. Structural damage always produces an error.}
}
\details{
Legacy \code{.qs} reading requires the \code{qslegacy} companion package supplied
with DataIO. It runs directly in the current R process, including R 4.6.1.
No original qs package, older R installation, subprocess, temporary file,
RDS handoff, package installation or disk cache is used while reading.

Legacy input must be a list whose elements are matrices. Empty lists are allowed.
Names, dimensions, dimnames and ordinary data attributes are preserved.
Numeric, integer, logical, character, complex, raw and list matrices are supported.
Functions, environments, promises, S4 objects and embedded general R serialization
are unsupported, including when stored inside attributes. Unsupported contents
produce an error; they are never replaced or omitted. qs2 reading still accepts
the general objects supported by qs2.

A successful legacy read emits a migration warning once per local calendar day
within the current R session. The date is stored only in option
\code{DataIO.qs.warning_day}, shared by both DataIO packages. A fresh R session
warns again, so no persistent file needs to be written. No file is automatically
converted, rewritten or deleted; use \code{ConvertQSToQS2} explicitly to convert.
}
\value{The stored R object for qs2, or a list of matrices for legacy qs.}
\author{DataIO package contributors}
\seealso{\code{\link{ReadQS2}}, \code{\link{WriteQS2}}, \code{\link{ConvertQSToQS2}}}
\keyword{file}
