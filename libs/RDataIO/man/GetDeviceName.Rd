\name{GetDeviceName}
\alias{GetDeviceName}
\title{Get Name of Flowcytometer Device}
\description{
Extracts the name of the flowcytometer device from flowcytometer data.
This data must be given as object of \code{flowFrame} class from \pkg{flowCore}.
This data can stem from a FCS or a LMD file.
}
\usage{
GetDeviceName(flowFrame)
}
\arguments{
\item{flowFrame}{Object of \code{flowFrame} class from \pkg{flowCore}.}
}
\value{
List of
\item{DeviceName}{String name of flowcytometer device.}
}
\author{
Quirin Stier (IAP-GmbH Intelligent Analytics Projects)
}
%\examples{
%}
\keyword{FCS}