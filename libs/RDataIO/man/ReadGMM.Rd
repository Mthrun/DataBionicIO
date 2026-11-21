\name{ReadGMM}
\alias{ReadGMM}
\title{Read Gaussian Mixture Model Parameters}
\description{
Reads means, standard deviations and mixture weights from the blocks of an LRN file.
}
\usage{
ReadGMM(GMMfile, GMMdir)
}
\arguments{
\item{GMMfile}{Input file name passed to \code{ReadLRN}.}
\item{GMMdir}{Input directory.}
}
\details{
Keys below 100 select means. Keys from 100 through 999 select standard deviations.
Keys of at least 1000 select mixture weights.
The three blocks must have the same number of rows.
}
\value{
A list with these elements:
\item{Means}{Means, with variables in rows and mixture components in columns.}
\item{Sdevs}{Standard deviations with the same layout.}
\item{Weights}{Mixture weights with the same layout.}
\item{GMMheader}{Column labels returned by \code{ReadLRN}.}
Each numeric block is a matrix. A block with one row or one column is returned as a vector.
}
\author{Michael Thrun (IAP-GmbH Intelligent Analytics Projects)}
\seealso{\code{\link{WriteGMM}}, \code{\link{ReadLRN}}}
\keyword{file}
