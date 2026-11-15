\name{WriteCLS}
\alias{WriteCLS}
\title{ save *.cls files }
\description{
  write classification to a *.cls file.
}
\usage{
WriteCLS(FileName, Cls, OutDirectory = getwd(), Key, Comment=NULL,
Int4NaN = NULL, Overwrite = TRUE, Verbose = TRUE)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
\item{FileName}{ string, name of file the classifiction will be saved in }
\item{Cls}{[1:n] numeric vector of integer class values, a one-column matrix or data frame, or a two-column matrix or data frame containing Key and Cls. An explicit Key argument overrides the first column.}
\item{OutDirectory}{ Optional: string, name of directory the data will be saved in, default \code{getwd()} }
\item{Key}{ Optional: [1:n] numeric vector of unique integer values. Default is 1:n}
\item{Comment}{Optional: String to be written in the first line as # Comment}
\item{Int4NaN}{Optional: if given recodes all NaN in the *.cls file to Int4NaN}
\item{Overwrite}{Flag indicating wheather a file with the same name should be overwritten, (Default: TRUE)}
\item{Verbose}{Flag indicating wheather additional information should be printed, (Default: TRUE)}


}
\details{
    \code{WriteCLS} is the primary resouce to save a *.cls file
  For the corresponding read function see \code{\link{ReadCLS}}

  Cls is allowed to contain \code{NaN} values.

  \code{Key} must contain finite whole numbers within \code{+/- 2^53}. Invalid keys are rejected before writing. Use ordinary numeric or integer vectors, not \code{bit64::integer64}.
  Missing or invalid class values are written as NaN (or replaced by Int4NaN).
  Noninteger class values produce a warning; they are not rounded.

}
\references{
	\url{www.uni-marburg.de/fb12/datenbionik}
	\email{databionics@mathematik.uni-marburg.de}
}

\author{Michael Thrun, Alfred Ultsch, Luca Brinkmann}

\seealso{ \code{ReadCLS}, \code{addext} }

\keyword{ file, Cls, CLS }
