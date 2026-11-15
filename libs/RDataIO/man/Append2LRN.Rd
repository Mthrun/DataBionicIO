\name{Append2LRN}
\alias{Append2LRN}
\title{Append rows to an LRN file}
\description{Append numeric rows and update the row count of an existing LRN file.}
\usage{
Append2LRN(FileName, Data, Key, OutDirectory = getwd())
}
\arguments{
\item{FileName}{Name of the existing file. The extension .lrn is added if needed.}
\item{Data}{Numeric matrix with one row per key and the same data columns as the file.
A numeric vector is converted to a one-column matrix with a warning.}
\item{Key}{Unique finite integer keys within \code{+/- .Machine$integer.max}.
Keys must not already occur in the file. Invalid keys are rejected before writing.}
\item{OutDirectory}{Directory containing the file. Default is the current directory.}
}
\details{
Existing data text and comments are preserved. New values use 17 significant digits;
missing values are written as NaN. The column count includes the key column.
The new file is written in the same directory before it replaces the original.
On Windows, a temporary backup permits restoration if replacement fails.
The working directory does not change.
}
\value{Returns \code{NULL} invisibly. Updates the LRN file.}
\author{QMS}
\seealso{\code{\link{ReadLRN}}, \code{\link{WriteLRN}}}
\keyword{file}
