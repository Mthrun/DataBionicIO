\name{ReadLRN}
\alias{ReadLRN}
\title{Read an LRN file}
\description{
Read numeric data, keys, and metadata from an LRN file.
See \link{DataIO-text-formats} for the file layout.
}
\usage{
ReadLRN(FileName, InDirectory = getwd(), Verbose = TRUE, ...)
}
\arguments{
\item{...}{Optional exact named encoding setting. Normally omit it. See Details.}
\item{FileName}{Name of the input file.
Supply a character string.
The reader accepts \code{.lrn} and \code{.csv} files.}
\item{InDirectory}{Directory that contains the input file. The default is \code{getwd()}.}
\item{Verbose}{Enable information messages. The default is \code{TRUE}.
Data warnings can occur when this argument is \code{FALSE}.}
}
\details{
The optional named argument \code{Encoding} in \code{...} is normally unnecessary.
Omit it in the typical workflow. The reader detects a BOM; otherwise it assumes UTF-8.
Use \code{Encoding="Windows-1252"} or \code{Encoding="ISO-8859-1"} only for a known input encoding.
\code{Encoding="UTF-8"} explicitly selects UTF-8. An incompatible BOM causes an error.
One initial UTF-8 BOM is skipped. UTF-16 and UTF-32 BOMs select complete decoding.
Legacy conversion gives one warning, also with \code{Verbose=FALSE}.
Malformed encoding causes an error; the reader does not guess or replace invalid bytes.
Unicode character sequences are preserved without automatic normalization.
Unknown, duplicate, or unnamed options in \code{...} cause an error.


The reader removes spaces, commas, and semicolons from header labels with a warning.
Tabs in the file separate columns.
The reader does not apply these header rules to text values.

Files without a format tag or with version 1.0 can use legacy key names and positions.
Type 9 identifies the key column.
Without this type, the reader supplies keys from 1 to the row count and gives a warning.
The returned type vector puts the key type first.
The data columns keep their original order.

Version 2.0 files require the current header.
The writer supplies format 2.0 files.
See \code{\link{WriteLRN}} for the write function.
}
\value{
A list with these elements in this order:
\item{Key}{Numeric vector with whole-number keys in \code{[-2^53, 2^53]}.
Missing keys and keys outside this range become \code{NA} with a warning.
A numeric prefix can supply a key. Additional text after that prefix causes a warning.}
\item{Data}{Numeric matrix with one row per record and one column per data variable.}

\item{Header}{Column names for \code{Data}.}
\item{DataDefined}{Column type codes, with the key type first.
See \link{DataIO-text-formats} for the type codes.}
\item{Comments}{String from the comment lines.
The result contains an empty string when the file has no comment.
The format tag is not part of the comment.}
}
\references{
\url{www.uni-marburg.de/fb12/datenbionik}
\email{databionics@mathematik.uni-marburg.de}
}
\author{Michael Thrun (IAP-GmbH Intelligent Analytics Projects)}
\seealso{\code{\link{WriteLRN}}, \link{DataIO-text-formats}}
\keyword{file}
