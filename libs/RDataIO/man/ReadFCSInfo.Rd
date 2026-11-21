\name{ReadFCSInfo}
\alias{ReadFCSInfo}
\title{Read FCS Parameter Metadata}
\description{
Reads parameter descriptions, the cytometer name and annotation keywords from an FCS file.
}
\usage{
ReadFCSInfo(FileName, FilePath = "", truncate_max_range = FALSE)
}
\arguments{
\item{FileName}{Input file name. The FCS extension is added if no extension is present.}
\item{FilePath}{Input directory. An empty string selects the current directory.}
\item{truncate_max_range}{Logical value passed to \code{flowCore::read.FCS}.}
}
\value{
A list with these elements:
\item{Variables}{Character matrix with \code{Name}, \code{Description} and \code{Scale} columns.
For multiple datasets, a list of these matrices is returned.
Absent fields contain the string \code{"NA"}.}
\item{DeviceType}{Cytometer name from the \code{CYT} keyword, or \code{NULL} if absent.}
\item{Keywords}{Annotation keyword list. Leading \code{@} and dollar signs are removed from names.
Keywords from multiple datasets are concatenated.}
}
\details{
The function requires \pkg{flowCore}. It reads each linked dataset.
The parameter scan stops at the first absent parameter, with a limit of 1000 parameters.
}
\author{Michael Thrun (IAP-GmbH Intelligent Analytics Projects)}
\seealso{\code{\link{ReadFCS}}, \code{\link{GetDeviceName}}}
\keyword{file}
