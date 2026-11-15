\name{ReadTXT2DATA}
\alias{ReadTXT2DATA}
\title{Read a tab-separated text table}
\usage{
ReadTXT2DATA(TxtFilename, TxtDirectory = getwd(), NamesInd = -1,
             DataDefined = c(), SkipLines = 0)
}
\arguments{
\item{TxtFilename}{name of .txt file. Including file extension '*.txt'}
\item{TxtDirectory}{Directory where *.txt file is (default ==  getwd() )}
\item{NamesInd}{Column index for record names. The default, -1, selects no names column.}
\item{DataDefined}{Column type information for the legacy interface.}
\item{SkipLines}{integer, the number of lines of the data file to skip before beginning to read data}
}
\value{An unnamed list with seven elements in this order:
numeric data, header, key selection, column types, names, descriptions, and other text data.
Use \code{result[[1]]} to get the numeric data matrix.}
\description{
Read a text table with \code{\link[utils]{read.table}}.
Tabs separate fields. The first line contains column names.
The function uses the default comment character, \code{#}. }
\author{
Sabine Puels 3/2015}
