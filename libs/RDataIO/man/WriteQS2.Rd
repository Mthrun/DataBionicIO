\name{WriteQS2}
\alias{WriteQS2}
\title{Save an R object as qs2}
\description{Saves an R object using qs2 compression and R serialization.}
\usage{
WriteQS2(FileName, Data, Names=NULL, OutDirectory=getwd(), NThreads=1,
         Compress_level=4L, Shuffle=TRUE, Overwrite=TRUE)
}
\arguments{
\item{FileName}{A single file name, with or without the appropriate extension.}
\item{Data}{The R object to save. WriteQS retains its numeric-matrix or list interface; WriteQS2 supports general R serialization.}
\item{Names}{Optional unique, non-missing names for list elements.}
\item{OutDirectory}{Existing output directory.}
\item{NThreads}{Positive number of threads passed to the serialization package.}
\item{Compress_level}{Zstandard compression level; default 4. In WriteQS this is used only for the custom preset.}
\item{Shuffle}{Logical; enable byte shuffling.}
\item{Overwrite}{Logical; allow replacing the destination. ConvertQSToQS2 defaults to FALSE; WriteQS2 defaults to TRUE.}
}
\details{
Requires the optional \pkg{qs2} package. A .qs extension is replaced by .qs2; an absent .qs2 extension is appended. Existing list names are retained unless Names is supplied.
}
\value{The saved file path, invisibly.}
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
