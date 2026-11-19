\name{WriteDates}
\alias{WriteDates}
\title{Write a DATES file}
\description{
Write time values and optional numeric data to a DATES file in format 2.0.
The writer accepts dates and timestamps.
See \link{DataIO-text-formats} for the file layout.
}
\usage{
WriteDates(FileName, TSdata, Key = NULL, OutDirectory = getwd(),
           Comments = NULL, tz = NULL, Format = NULL,
           Overwrite = TRUE, Verbose = TRUE)
}
\arguments{
\item{FileName}{Name of the output file.
The writer accepts \code{.dts} and \code{.csv} extensions.
For other extensions, the writer adds \code{.dts}.}
\item{TSdata}{Data frame or matrix with one record per row.
A column named \code{Time} supplies the time values.
Without this column name, the first column supplies the time values.
A vector of time values supplies records without measurement columns.
Time values can be strings, \code{Date} values, or \code{POSIXt} values.
The writer rejects missing time values.

Measurement columns contain numeric values.
The writer converts other measurement columns with \code{as.numeric(as.character(x))}.
This conversion uses factor labels.
Values that R cannot convert become \code{NA} with an R warning.
Prepare the input values before you call the writer.}
\item{Key}{Numeric or integer vector with one unique key per row.
Keys must be finite whole numbers in \code{[-2^53, 2^53]}.
Without supplied keys, the writer uses \code{1:n}.
The writer rejects invalid supplied keys before it opens the output file.
Use ordinary numeric or integer vectors.
Do not use \code{bit64::integer64} vectors.}
\item{OutDirectory}{Directory for the output file. The default is \code{getwd()}.}
\item{Comments}{Optional comment text.
The writer puts comment lines before the header, with \code{#} as the prefix.
The default is no comment.}
\item{tz}{Optional time zone name from \code{\link[base]{OlsonNames}}.
For POSIXt input, the writer expresses each instant in this time zone.
The conversion does not change the instant.
For dates and strings, the writer uses \code{tz} as the file time zone.

Without \code{tz}, the writer uses the input time zone attribute when it is available.
Otherwise, the writer uses \code{"UTC"}.
The writer records the time zone in the comment section.}
\item{Format}{Optional output precision:
\describe{
\item{1}{Dates in \code{YYYY-MM-DD} format.}
\item{2}{Timestamps in \code{YYYY-MM-DD hh:mm:ss} format.}
\item{3}{Timestamps in \code{YYYY-MM-DD hh:mm:ss.ms} format.}
}
The default, \code{NULL}, selects the greatest precision found in the input.
Fractional seconds have at most three decimal places.}
\item{Overwrite}{If true, the writer can replace an existing file. The default is \code{TRUE}.}
\item{Verbose}{Enable information messages. The default is \code{TRUE}.
Data warnings can occur when this argument is \code{FALSE}.}
}
\details{
String time values must use one of the formats shown for \code{Format}.
The writer also accepts slashes in the date part of a string.
It changes these slashes to hyphens.

For POSIXt input, the writer uses the time zone abbreviation for each actual timestamp.
If any timestamp uses daylight saving time (DST) or occurs in a repeated hour, the writer adds \code{TZ_DST}.
This column identifies the two occurrences of a repeated local time.
Dates and output with \code{Format = 1} do not need this column.

\strong{Time zone restriction:}
The C++ writer requires a letter as the first character of the time zone suffix.
Numeric abbreviations such as \code{+11}, \code{+1030}, and \code{-02} cause an error.
Affected zones include \code{Australia/Lord_Howe}, \code{Pacific/Chatham}, and historical DST dates in \code{America/Sao_Paulo}.
Their aliases include \code{Australia/LHI}, \code{NZ-CHAT}, and \code{Brazil/East}.
These examples do not include all affected zones.
Support depends on the abbreviation for the actual date.

For affected POSIXt input, set \code{tz = "UTC"}.
}
\author{Michael Thrun (IAP-GmbH Intelligent Analytics Projects), Luca Brinkmann (IAP-GmbH Intelligent Analytics Projects)}
\seealso{\code{\link{ReadDates}}, \link{DataIO-text-formats}}
\examples{
local({
  directory <- tempfile("dataio-write-example-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE))
  input <- data.frame(Time = as.Date("2025-01-01"), Value = 1.5)
  WriteDates("measurement", input, Key = 10, OutDirectory = directory,
             Format = 1, Overwrite = FALSE, Verbose = FALSE)
  result <- ReadDates("measurement", InDirectory = directory, Verbose = FALSE)
  stopifnot(identical(result$Key, 10), identical(as.numeric(result$Data), 1.5))
})
}
\keyword{file}
