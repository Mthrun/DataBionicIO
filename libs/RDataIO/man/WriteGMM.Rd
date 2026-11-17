\name{WriteGMM}
\alias{WriteGMM}
\title{Write Gaussian Mixture Model Parameters}
\description{
Writes means, standard deviations and mixture weights as three blocks in an LRN file.
}
\usage{
WriteGMM(GMMfile, GMMdir, Means, Sdevs, Weights)
}
\arguments{
\item{GMMfile}{Output file name. The LRN extension is added if needed.}
\item{GMMdir}{Output directory.}
\item{Means}{Numeric matrix with variables in rows and mixture components in columns,
or a numeric vector for one variable.}
\item{Sdevs}{Standard deviations with the same dimensions as \code{Means}.}
\item{Weights}{Mixture weights with the same dimensions as \code{Means}.}
}
\details{
The blocks use keys starting at 1 for means, 101 for standard deviations and
1001 for weights. The comment describes the block layout.
The writer supports both the native R and cdbt.DataIO versions of \code{WriteLRN}.
}
\value{Used for its side effect of writing an LRN file.}
\seealso{\code{ReadGMM}, \code{\link{WriteLRN}}}
\keyword{file}
\author{Michael Thrun (IAP-GmbH Intelligent Analytics Projects)}
