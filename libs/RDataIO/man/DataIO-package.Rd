\name{DataIO-package}
\alias{DataIO-package}
\alias{DataIO}
\docType{package}
\title{
DataBionicIO for R
}
\description{
Functions for writing and reading data are being provided in the cdbt.DataIO package of DataBionicIO, which specializes on [n,k] matrices and data frames. The file format with the extension *.data enables the user to import data to Microsoft Excel and Mathworks Matlab. Furthermore it allows for inspecting and editing data with any text editor. To prevent failure which for example might occur during unintentional alteration of the *.data file in Excel or an editor, the files are verified by a checksum for each column of data.

See the vignettes for more examples of how to use the functions for writing and reading *.data files.

}
\details{

\tabular{ll}{
*.data: \tab files with this extension are used to store \code{[n,k]} matrices of numbers and strings. \cr
}

\tabular{ll}{
Package: \tab cdbt.DataIO\cr
Type: \tab Package\cr
Version: \tab 1.0.0\cr
Date: \tab 2026-11-17\cr
License: \tab AGPL-3 + file LICENSE\cr
}
}
\author{Michael Thrun (IAP-GmbH Intelligent Analytics Projects), Tim Schneider, Alfred Ultsch}
\references{
	\url{www.uni-marburg.de/fb12/datenbionik}
	\email{mthrun@mathematik.uni-marburg.de}
}
\keyword{ package }
\seealso{ \code{WriteData}}
\examples{
	#Writing a *.data file
	#mat = matrix( 
    #  c(1,0,0,0,1,0,0,0,1), 
   #   nrow=3, 
    #  ncol=3) 

	#WriteData(FileName = "test.data",Data = mat)
		
	#Read again
	#ReadData("test.data")
}
