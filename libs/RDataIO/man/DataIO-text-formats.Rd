\name{DataIO-text-formats}
\alias{DataIO-text-formats}
\title{LRN NAMES and DATES file layouts}
\description{
The text formats store one record per data line.
Tabs separate the fields.
Comment lines start with \code{#}.
Header lines start with \code{\%}.
The writers use format 2.0.
}
\details{
\strong{LRN}

The optional format tag identifies LRN and its version.
Four header lines give the row count, column count, type codes, and column names.
The column count includes the key column.
A file with two rows and one data column can have this layout:
\preformatted{
#<?lrn version="2.0"?>
\% 2
\% 2
\% 9	1
\% Key	Value
11	1.5
12	2.5
}
Type 9 identifies the key column.
Type 0 marks columns for exclusion by software that uses the data.
This reader keeps these columns in \code{Data}.
Type 1 identifies numeric data.
Types 2 and 3 are numeric type codes for class-related data.

The reader returns the type codes in \code{DataDefined}.

\strong{NAMES}

The optional format tag identifies NAMES and its version.
Three header lines give the row count, column count, and column names.
The first column is Key.
The second column contains names.
Subsequent columns contain other text.
The reader does not require Time as a column name.

\strong{DATES}

The optional format tag identifies DATES.
Three header lines give the row count, column count, and column names.
The first two columns are Key and Time.
The optional TZ_DST column follows Time.
Other columns contain numeric measurements.
The column count includes all file columns.

A comment line can give the time zone as \code{# Timezone: Europe/Berlin}.
Without a time zone declaration, the reader uses UTC.
See \code{\link{WriteDates}} for time formats and time zone restrictions.

\strong{Missing values and read warnings}

The R readers return numeric keys in \code{[-2^53, 2^53]}.
Missing keys and keys outside this range become \code{NA} with a warning.
A numeric prefix can supply a key or numeric value.
Additional text after a numeric prefix causes a warning.

A short row receives missing values.
Additional fields do not add columns.
A row count mismatch causes a warning. The reader keeps the actual rows.

\strong{Legacy input}

LRN and NAMES files without a version tag or with version 1.0 use the legacy rules.
The LRN key column can have a different name or position.
Type 9 identifies that column.
Without a key column, the LRN reader supplies keys from 1 to the row count and gives a warning.
Legacy NAMES files can omit the column count or column names.
If both are absent, the first data row sets the number of columns.
Version 2.0 files require the current header.
The readers reject other LRN and NAMES versions.
}
\seealso{
\code{\link{ReadLRN}}, \code{\link{WriteLRN}},
\code{\link{ReadNAMES}}, \code{\link{WriteNAMES}},
\code{\link{ReadDates}}, \code{\link{WriteDates}}
}
\keyword{file}
