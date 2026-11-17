\name{ConvertQSToQS2}
\alias{ConvertQSToQS2}
\title{Convert a legacy qs list of matrices to qs2}
\description{Reads a legacy .qs list of matrices and explicitly writes the same object as .qs2, retaining the original file.}
\usage{
ConvertQSToQS2(FileName, InDirectory=getwd(), OutDirectory=InDirectory,
               NThreads=1, Strict=TRUE, Overwrite=FALSE)
}
\arguments{
\item{FileName}{A single legacy file name, with or without the .qs extension.}
\item{InDirectory}{Input directory; defaults to the working directory.}
\item{OutDirectory}{Existing output directory.}
\item{NThreads}{Positive number of qs2 writer threads; legacy reading is sequential.}
\item{Strict}{Logical; checksum and recorded-length mismatches are errors if TRUE, warnings otherwise. Structural damage always produces an error.}
\item{Overwrite}{Allow replacing the destination; default is FALSE.}
}
\details{
Requires the qslegacy companion package and qs2. See \code{ReadQS} for supported
matrix types and attributes. Legacy decoding runs in the current R process;
no older R installation is required. The migration warning occurs once per day
within the current R session and is tracked only in memory.

Unlike the read-only \code{ReadQS} function, this conversion function explicitly
writes a new file. The output uses the input basename with the .qs2 extension.
The original .qs file is kept. Existing output is refused unless Overwrite=TRUE.
A temporary destination file prevents publishing incomplete output. Replacement
on Windows uses a file copy and is not atomic.
}
\value{The converted .qs2 path, invisibly.}
\author{Michael Thrun (IAP-GmbH Intelligent Analytics Projects)}
\examples{\dontrun{ConvertQSToQS2("old-data.qs", InDirectory="/path/to/data")}}
\seealso{\code{\link{ReadQS}}, \code{\link{ReadQS2}}, \code{\link{WriteQS2}}}
\keyword{file}
