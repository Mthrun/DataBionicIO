\name{WriteNAMES}
\alias{WriteNAMES}
\title{Write NAMES to file}
\description{
Save names and possibly further texts to a *.names file.
}
\usage{
WriteNAMES(FileName, Names, Key, FurtherTexts, Header,OutDirectory=getwd(),
Comments="", Overwrite=TRUE, Verbose = TRUE)
}
\arguments{
\item{FileName}{'String' , Name of the NAMES-file}
\item{Names}{[1:n] character vector. Values can start with digits and contain spaces or periods. For example, \code{"1.0.4"} is text, not a column name.}
optional:
\item{Key}{[1:n] numeric vector of unique integer values. Default is [1:n]. \code{Key} must contain finite whole numbers within \code{+/- 2^53}. If Key is omitted or empty, the writer uses 1:n and gives a warning, also with \code{Verbose=FALSE}. Invalid supplied keys are rejected before writing. Use ordinary numeric or integer vectors, not \code{bit64::integer64}.}
\item{FurtherTexts}{[1:n, 1:d], character matrix. Placed in the output file from the third column onwards.}
\item{Header}{[1:d+1] character vector of column names for Names and FurtherTexts (if given). Can also be [1:d+2] if first entry is "Key", else it will be overwritten.
Use \code{c("Version", TextHeader)} to add a separate label.
\code{paste("Version", TextHeader)} adds the prefix "Version " to each label.
If only d labels are supplied, the writer adds "Names" before them and gives a warning.}
\item{OutDirectory}{'string', in case of out directory should not be working
directory, default: \code{getwd()}}
\item{Comments}{Optional: string/character vector, these lines will be inserted at
top of file with leading #}
\item{Overwrite}{Flag indicating wheather a file with the same name should be overwritten, (Default: TRUE)}
\item{Verbose}{Flag indicating wheather additional information should be printed, (Default: TRUE)}

}
\details{
Names and FurtherTexts are text fields. Digits do not need special handling.
Empty text and the text "NA" represent missing text when the file is read.
Tabs and line breaks in text values are removed by the writer.
The writer removes spaces, tabs, commas, and semicolons from Header labels and gives a warning.
For example, "Version Currency" becomes "VersionCurrency". Header filtering does not change Names or FurtherTexts. Tabs and line breaks in text values are handled separately.
Readers also remove spaces, commas, and semicolons from header labels with a warning. Tabs in a file separate columns.
Other nonstandard labels, such as "1.0.4", are kept with a warning. This can reduce compatibility with other software.
Labels must not be empty after filtering. Line breaks and NUL characters in a header are not accepted.
The first file column must be Key. Supplied keys must be valid and unique.
Typical usages are
\preformatted{WriteNAMES('File',c('Name1','Name2','Name3','Name4','Name5'),
c(1:5))}
\code{WriteNAMES} is a function to store names and connect them with keys. Key can be named but does need to necessarily in the header.
}
\value{
creates a *.names file in the working or out directory
}
\examples{
Names=c("A","B","C")
FurtherText=cbind(c("Gen13","wdsg3","SAF"),c("sg","sdg","sdg.sd"))
Key=c(200,450,23)
WriteNAMES("Testfile1",Names,Key,FurtherText)

Header=c("a a","b","c ")
WriteNAMES("Testfile2",Names,Key,FurtherText,Header=Header)

Comment="Test"
WriteNAMES("Testfile3",Names,Key,FurtherText,Header=Header,Comment=Comment)
}

\author{Michael Thrun, Luca Brinkmann}
\seealso{\link{ReadNAMES}}
\keyword{file, Names, NAMES}
