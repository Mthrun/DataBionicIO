\name{ReadQS2}
\alias{ReadQS2}
\title{Read a qs2 file}
\description{Reads an object saved in the current qs2 format.}
\usage{
ReadQS2(FileName, InDirectory=getwd(), NThreads=1, Strict=FALSE)
}
\arguments{
\item{FileName}{A single file name, with or without the appropriate extension.}
\item{InDirectory}{Input directory; defaults to the working directory.}
\item{NThreads}{Positive number of threads passed to the serialization package.}
\item{Strict}{Logical. For legacy qs, report checksum problems as errors if TRUE, warnings otherwise. For qs2, validate the checksum before deserialization if TRUE.}
}
\details{
Requires the optional \pkg{qs2} package. This function does not read legacy .qs files; use \code{ReadQS} for those.
}
\value{The stored R object.}
\author{DataIO package contributors}
\examples{
if (requireNamespace("qs2", quietly=TRUE)) {
  name <- basename(tempfile("DataIO-example-"))
  x <- matrix(1:6, ncol=2)
  path <- WriteQS2(name, x, OutDirectory=tempdir())
  stopifnot(identical(x, ReadQS2(name, InDirectory=tempdir())))
  unlink(path)
}
}
\seealso{\code{\link{ReadQS}}, \code{\link{ReadQS2}}, \code{\link{WriteQS2}}, \code{\link{ConvertQSToQS2}}}
\keyword{file}
