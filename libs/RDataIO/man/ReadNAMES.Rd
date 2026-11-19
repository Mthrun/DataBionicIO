\name{ReadNAMES}
\alias{ReadNAMES}
\title{Read a NAMES file}
\description{
Read keys, names, other text columns, and comments from a NAMES file.
See \link{DataIO-text-formats} for the file layout.
}
\usage{
ReadNAMES(FileName, InDirectory = getwd(), Verbose = TRUE)
}
\arguments{
\item{FileName}{Name of the input file. The reader accepts \code{.names} and \code{.csv} extensions.}
\item{InDirectory}{Directory that contains the input file. The default is \code{getwd()}.}
\item{Verbose}{Enable information messages. The default is \code{TRUE}.
Data warnings can occur when this argument is \code{FALSE}.}
}
\details{
The reader removes spaces, commas, and semicolons from header labels with a warning.
Tabs separate fields. Text values keep spaces, commas, and semicolons.

Files without a version tag and files with version 1.0 can omit the column count.
If both the count and column names are absent, the first data row sets the number of columns.
Additional fields in later rows do not add columns.
Version 2.0 files require the current header.

The reader adds \code{.names} if the filename has neither a \code{.names} nor a \code{.csv} extension.
The read operation does not change the input file.
}
\value{
A list with these elements in this order:
\item{Key}{Numeric vector with one key per row.
Keys are whole numbers in \code{[-2^53, 2^53]}.
Missing keys and keys outside this range become \code{NA} with a warning.
A numeric prefix can supply a key. Additional text after that prefix causes a warning.}
\item{Names}{Character vector from the second file column.
The file marker \code{"NA"} becomes an R missing value.}
\item{FurtherTexts}{Character matrix from the third and subsequent file columns.
Without additional text columns, this matrix has one row per record and zero columns.
Each matrix row contains one record.
The file marker \code{"NA"} becomes an R missing value.}
\item{Header}{Character vector with the column names for \code{FurtherTexts}.
Without additional text columns, this vector is empty.}
\item{Comments}{String from the comment lines.
The result contains an empty string when the file has no comment.
The format tag is not part of the comment.}
}
\author{Michael Thrun (IAP-GmbH Intelligent Analytics Projects), Luca Brinkmann (IAP-GmbH Intelligent Analytics Projects)}
\seealso{\code{\link{WriteNAMES}}, \link{DataIO-text-formats}}
\keyword{file}
