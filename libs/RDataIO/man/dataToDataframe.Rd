\name{dataToDataframe}
\alias{dataToDataframe}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{ load a *.data file into a data.frame }
\description{
  Converts the outputted List from \code{ReadData} into a data.frame.
}
\usage{
dataToDataframe(V)
}
\arguments{
  \item{V}{ list from \code{ReadData} call}
}
\value{
  \item{data.frame}{Data columns with optional Names and Description columns.
  Row names follow \code{data.frame(V$Data)}; \code{V$Key} is not assigned as row names.}
}
\author{Tim Schneider}
\seealso{ \code{addext}, \code{WriteData},\code{ReadData} }
\examples{
	#needs a *.data file "test.data" in current directory (getwd())
	#dataToDataFrame( ReadData("test.data") )
}
\keyword{dataToDataframe,file}
