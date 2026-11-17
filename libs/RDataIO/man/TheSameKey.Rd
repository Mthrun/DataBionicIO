\name{TheSameKey}
\alias{TheSameKey}
\title{ TheSameKey}
\description{
Compares numeric key vectors by length, value, and position through the shared C++ core.}
\usage{
TheSameKey(keyA, keyB)
}
\arguments{
  \item{keyA}{ A key represented by a vector of integers.}
  \item{keyB}{ Another key in the form of a vector of integers.}
}
\details{
The comparison is exact and does not sort the vectors or check uniqueness.
Two empty vectors compare equal. Any missing value gives FALSE, even when both
vectors have a missing value at the same position. Unsupported types or
non-vector dimensions give FALSE. Numeric integer and double representations
can compare equal. Names are ignored. Inputs are not changed.
This is a comparison, not validation of the file-format key constraints.
}
\examples{
TheSameKey(c(1, 2), c(1L, 2L))
TheSameKey(c(1, 2), c(2, 1))
TheSameKey(c(1, NA), c(1, NA))
}
\value{
\item{KeyOk}{A boolean value. True if both keys are the same, false otherwise.}
}
% \references{ ~put references to the literature/web site here ~ }
\author{Michael Thrun (IAP-GmbH Intelligent Analytics Projects)}
% \note{ ~~further notes~~ }
% \seealso{ ~~objects to See Also as \code{\link{help}}, ~~~ }
% \examples{}}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
% \keyword{ ~kwd1 }
% \keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
