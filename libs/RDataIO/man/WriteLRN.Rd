\name{WriteLRN}
\alias{WriteLRN}
\title{Write an LRN file}
\description{
Write numeric data, column names, and column type codes to an LRN file in format 2.0.
See \link{DataIO-text-formats} for the file layout.
}
\usage{
WriteLRN(FileName, Data, Header = NULL, Key = NULL, DataDefined = NULL,
         OutDirectory = getwd(), Comments = NULL, SignificantDigits = NULL,
         DecimalDigits = NULL, Scientific = FALSE, Overwrite = TRUE,
         Verbose = TRUE)
}
\arguments{
\item{FileName}{Name of the output file.
The writer accepts \code{.lrn} and \code{.csv} extensions.
For other extensions, the writer adds \code{.lrn}.}
\item{Data}{Numeric matrix with one record per row and one variable per column.
The matrix can contain \code{NA} and \code{NaN} values.
The writer converts a data frame with \code{as.matrix(Data)}, then \code{mode(Data) = "numeric"}.
It gives a warning for this conversion.

The conversion uses factor labels.
Values that R cannot convert become \code{NA} with an R warning.
The writer rejects other inputs, such as standalone factors and nonnumeric matrices.
Prepare the input values before you call the writer.}
\item{Header}{Optional character vector with one name per data column.
A vector with one additional name includes the key column first.
For this full vector, the writer changes the first name to \code{Key}.
The writer rejects other nonempty header lengths before it writes data.

If you omit \code{Header}, the writer uses the matrix column names when they exist.
Otherwise, the writer supplies column names.
An empty \code{Header} also selects automatic names.}
\item{Key}{Numeric or integer vector with one unique key per row.
Keys must be finite whole numbers in \code{[-2^53, 2^53]}.
If \code{Key} is absent or empty, the writer uses \code{1:n} and gives a warning.
The writer rejects invalid supplied keys before it opens the output file.
Use ordinary numeric or integer vectors.
Do not use \code{bit64::integer64} vectors.}
\item{DataDefined}{Optional vector with one type code per data column.
A vector with one additional code includes type 9 for the key column first.
Types 0, 1, 2, and 3 identify other columns.
See \link{DataIO-text-formats} for these codes.
An empty vector selects type 1 for each data column and type 9 for Key.}
\item{OutDirectory}{Directory for the output file. The default is \code{getwd()}.}
\item{Comments}{Optional comment text.
The writer puts comment lines before the header, with \code{#} as the prefix.
The default is no comment.}
\item{SignificantDigits}{One finite positive integer, at most \code{.Machine$integer.max}, or \code{NULL}.
This number sets the significant digits for each value, independently of \code{Scientific}.
The writer omits trailing decimal zeros.
For example, an exact integer 1 stays 1.
This argument takes precedence over \code{DecimalDigits}.
The default, \code{NULL}, does not set a significant-digit limit.}
\item{DecimalDigits}{One finite non-negative integer, at most \code{.Machine$integer.max}, or \code{NULL}.
This number sets the decimal places for each value.
Zero rounds to whole numbers.
The writer rounds values before it applies fixed or scientific notation.
The default, \code{NULL}, does not set a decimal-place limit.}
\item{Scientific}{Select scientific notation. The default is \code{FALSE}.}
\item{Overwrite}{If true, the writer can replace an existing file. The default is \code{TRUE}.}
\item{Verbose}{Enable information messages. The default is \code{TRUE}.
Data warnings can occur when this argument is \code{FALSE}.}
}
\details{
For file exchange, start a variable name with a letter.
Use letters, digits, periods, and underscores.
The writer removes spaces, tabs, commas, and semicolons from header labels with a warning.
For example, \code{"Version Currency"} becomes \code{"VersionCurrency"}.

The readers also remove spaces, commas, and semicolons from labels with a warning.
Tabs in a file separate columns.
The writer keeps other nonstandard labels with a warning.
These labels can reduce compatibility with other software.
Labels must not become empty after the writer removes separators.
Line breaks and NUL characters cause an error.

Automatic column names depend on the type codes.
The key column has the name \code{Key}.
Type 3 columns have the name \code{Cls}.
Other data columns have names such as \code{C1} and \code{C2}.
The number identifies the data column position.
}
\references{
\url{www.uni-marburg.de/fb12/datenbionik}
\email{databionics@mathematik.uni-marburg.de}
}
\author{Michael Thrun (IAP-GmbH Intelligent Analytics Projects), Luca Brinkmann (IAP-GmbH Intelligent Analytics Projects)}
\seealso{\code{\link{ReadLRN}}, \code{\link{addext}}, \link{DataIO-text-formats}}
\keyword{file}
