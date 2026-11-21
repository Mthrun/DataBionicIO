\name{ReadLRNKey}
\alias{ReadLRNKey}
\title{Read LRN Keys as Text}
\description{
Reads the first tab-separated field from each LRN data row without numeric conversion.
}
\usage{
ReadLRNKey(FileName, InDirectory)
}
\arguments{
\item{FileName}{LRN file name. The extension is added if needed.
Use \code{NULL} to open the file chooser.}
\item{InDirectory}{Input directory. The file chooser supplies it when \code{FileName} is \code{NULL}.}
}
\details{
Lines that start with a hash or percent sign are excluded.
This reader returns text fields without the numeric key validation of \code{ReadLRN}.
}
\value{Character vector of first fields, or \code{NULL} if no data rows are present.}
\author{Quirin Stier (IAP-GmbH Intelligent Analytics Projects)}
\seealso{\code{\link{ReadLRN}}}
\keyword{file}
