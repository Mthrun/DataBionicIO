\name{ReadCLS}
\alias{ReadCLS}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{ load *.cls files }
\description{
  Load key-class assignments from *.cls file
}
\usage{
ReadCLS(FileName, InDirectory=getwd(), Verbose = TRUE)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{FileName}{ string, name of the *.cls file }
  \item{InDirectory}{ string of the directory containing the *.cls file }
  \item{Verbose}{If \code{TRUE} (Default), then additional information is printed}
}
\details{
  Files without a generation tag, or with version 1.0, can use spaces between numeric fields.
  They can omit the row-count header; the reader warns and keeps all data rows.
  CLS colour metadata is ignored. Version 2.0 files keep the current header requirements.
  Legacy support is read-only.

  \code{ReadCLS} is the primary resouce to read a *.cls file
  For the corresponding write function see \code{WriteCLS}

}
\value{
  A list with these four elements in this order:
  \item{Key}{[1:n] numeric vector of whole-number keys within \code{+/- 2^53}. Invalid or missing file keys give \code{NA}, with a warning.}
  \item{Cls}{[1:n] numeric vector of cls}
  \item{UniqueClasses}{[1:m] numeric vector, m indicating the number of unique classes}
  \item{Comments}{String containing the comment given in the lines, which start with #. Header-line, beginning with < and ending with > as well as automatically created cls statistics (created by \code{\link{WriteCLS}}) are ignored. The result is an empty string when the file has no comment.}
}
\references{
	\url{www.uni-marburg.de/fb12/datenbionik}
	\email{databionics@mathematik.uni-marburg.de}
}
\author{Alfred Ultsch, Luca Brinkmann (IAP-GmbH Intelligent Analytics Projects)}

\seealso{ \code{\link{WriteCLS}} }

\keyword{ file, Cls, CLS }
