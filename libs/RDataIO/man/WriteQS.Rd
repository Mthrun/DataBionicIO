\name{WriteQS}
\alias{WriteQS}
\title{Compatibility writer using qs2}
\description{Preserves the existing WriteQS entry point while saving new files as .qs2.}
\usage{
WriteQS(FileName, Data, Names=NULL, OutDirectory=getwd(), NThreads=1,
        Preset="high", Algorithm="zstd", Compress_level=4L,
        Shuffle_control=15L, Check_hash=TRUE)
}
\arguments{
\item{FileName}{A single file name, with or without the appropriate extension.}
\item{Data}{The R object to save. WriteQS retains its numeric-matrix or list interface; WriteQS2 supports general R serialization.}
\item{Names}{Optional unique, non-missing names for list elements.}
\item{OutDirectory}{Existing output directory.}
\item{NThreads}{Positive number of threads passed to the serialization package.}
\item{Preset}{Compatibility preset: fast=1, balanced=3, high=4, archive=19. Custom uses Compress_level. Uncompressed warns and uses level -5, since qs2 has no uncompressed equivalent.}
\item{Algorithm}{Legacy option. qs2 always uses Zstandard; a different custom algorithm warns.}
\item{Compress_level}{Zstandard compression level; default 4. In WriteQS this is used only for the custom preset.}
\item{Shuffle_control}{Legacy shuffle mask: zero disables shuffling, 15 enables it. Other masks warn and enable shuffling.}
\item{Check_hash}{Legacy option. qs2 always stores a checksum; FALSE warns.}
}
\details{
Prefer \code{WriteQS2} for new code. The original argument names remain accepted, but compression settings follow qs2 rather than qs. Unsupported legacy settings produce warnings. The default writes Zstandard level 4 with shuffling and a checksum. An explicit .qs suffix is replaced by .qs2; original .qs files are not overwritten.
}
\value{The saved .qs2 file path, invisibly.}
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
