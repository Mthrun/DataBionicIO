\name{ReadDates}
\alias{ReadDates}
\title{Read a DATES file}
\description{
Read time values, numeric data, keys, and metadata from a DATES file.
See \link{DataIO-text-formats} for the file layout.
}
\usage{
ReadDates(FileName, InDirectory = getwd(), Verbose = TRUE)
}
\arguments{
\item{FileName}{Name of the input file. The reader accepts \code{.dts} and \code{.csv} files.}
\item{InDirectory}{Directory that contains the input file. The default is \code{getwd()}.}
\item{Verbose}{Enable information messages. The default is \code{TRUE}.
Data warnings can occur when this argument is \code{FALSE}.}
}
\details{
If all time values contain dates only, the reader returns a \code{Date} vector.
If a time value contains hours, minutes, and seconds, the reader returns a \code{POSIXct} vector.
The reader uses the file time zone for these timestamps.

Daylight saving time (DST) markers identify the occurrence of a repeated local time.
The reader compares each marker with the time zone rules for its timestamp.
If the marker does not identify one valid instant, the reader keeps the row.
Its time becomes \code{NA}, and the reader gives a warning.

\strong{Time zone restriction:}
The DATES writer cannot use numeric time zone abbreviations in \code{TZ_DST}.
Examples include \code{+11}, \code{+1030}, and \code{-02}.
Affected zones include \code{Australia/Lord_Howe}, \code{Pacific/Chatham}, and historical DST dates in \code{America/Sao_Paulo}.
Their aliases include \code{Australia/LHI}, \code{NZ-CHAT}, and \code{Brazil/East}.
These examples do not include all affected zones.
Support depends on the abbreviation for the actual date.

The C++ writer requires a letter as the first character of the time zone suffix.
For affected POSIXt input, set \code{tz = "UTC"} when you call \code{WriteDates}.
Date-only values do not need \code{TZ_DST}.
}
\value{
A list with these elements in this order:
\item{Key}{Numeric vector with whole-number keys in \code{[-2^53, 2^53]}.
Missing keys and keys outside this range become \code{NA} with a warning.
A numeric prefix can supply a key. Additional text after that prefix causes a warning.}
\item{Time}{A \code{Date} or \code{POSIXct} vector with one value per row.}
\item{Data}{Numeric matrix with one row per record.
Without measurement columns, this matrix has zero columns.
The matrix excludes \code{Key}, \code{Time}, and \code{TZ_DST}.}

\item{Header}{Character vector with the column names for \code{Data}.
Without measurement columns, this vector is empty.}
\item{Comments}{String from the comment lines.
The result contains an empty string when the file has no comment.
The format tag and time zone declaration are not part of the comment.}
\item{Timezone}{Name of the file time zone. The default is \code{"UTC"}.}
\item{DST}{Character vector of stored time zone abbreviations, such as \code{CST} and \code{CDT}.
This vector is empty when the file has no \code{TZ_DST} column.}
}
\author{Michael Thrun (IAP-GmbH Intelligent Analytics Projects), Luca Brinkmann (IAP-GmbH Intelligent Analytics Projects)}
\seealso{\code{\link{WriteDates}}, \link{DataIO-text-formats}}
\examples{
local({
  directory <- tempfile("dataio-example-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE))
  input <- data.frame(
    Time = as.Date(c("2025-01-01", "2025-01-02")),
    Value = c(1.5, 2.5)
  )
  WriteDates("series", input, Key = c(11, 12),
             OutDirectory = directory, Comments = "Example.",
             Format = 1, Overwrite = FALSE, Verbose = FALSE)
  result <- ReadDates("series", InDirectory = directory, Verbose = FALSE)
  stopifnot(
    identical(result$Time, input$Time),
    identical(result$Key, c(11, 12)),
    identical(result$Header, "Value"),
    identical(dim(result$Data), c(2L, 1L)),
    identical(as.numeric(result$Data), input$Value),
    identical(result$Comments, "Example."),
    identical(result$Timezone, "UTC")
  )
})
}
\keyword{file}
