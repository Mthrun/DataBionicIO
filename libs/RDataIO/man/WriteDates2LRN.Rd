\name{WriteDates2LRN}
\alias{WriteDates2LRN}
\title{Write an LRN file with date keys}
\description{Convert dates to keys and write a numeric matrix with \code{WriteLRN}.}
\usage{
WriteDates2LRN(FileName, Data, DatesTime, Header, DataDefined = c(),
              OutDirectory = getwd(), Comments = NULL,
              SignificantDigits = NULL, DecimalDigits = NULL, Scientific = F)
}
\arguments{
\item{FileName}{Name of the LRN file to write.}
\item{Data}{Numeric matrix with cases in rows and variables in columns.}
\item{DatesTime}{One date or numeric key per row. Date objects become YYYYMMDD keys;
other inputs use \code{as.numeric}. Keys must be unique finite integers within
\code{+/- .Machine$integer.max}. Fractional or out-of-range keys are rejected.}
\item{Header}{Data column names, optionally preceded by a key name. Defaults to \code{colnames(Data)}.}
\item{DataDefined}{Column type codes passed to \code{WriteLRN}.}
\item{OutDirectory}{Output directory. Default is the current directory.}
\item{Comments}{User comment text passed to \code{WriteLRN}.}
\item{SignificantDigits}{Number of significant digits; takes precedence over DecimalDigits.}
\item{DecimalDigits}{Number of decimal places; zero rounds to whole numbers.}
\item{Scientific}{Logical flag to use scientific notation. Passed unchanged to \code{WriteLRN}.}
}
\value{Creates an LRN file. Returns the result of \code{WriteLRN}.}
\author{Michael Thrun (IAP-GmbH Intelligent Analytics Projects)}
\seealso{\code{\link{WriteLRN}}, \code{\link{WriteDates}}}
\keyword{file}
