\name{TrimHeader}
\alias{TrimHeader}
\title{Trim Header Labels and Replace Underscores}
\description{
Removes trailing whitespace from header labels, then replaces each underscore with the specified text.
}
\usage{
TrimHeader(Header, UnderlineReplacement = " ")
}
\arguments{
\item{Header}{Character vector of header labels.}
\item{UnderlineReplacement}{Replacement text for underscores. The default is one space.}
}
\details{
Trailing spaces, tabs, carriage returns and newlines are removed with \code{trimws}.
Leading and internal whitespace is preserved. Underscore replacement follows \code{gsub} rules.
Missing values remain missing.
}
\value{Character vector of modified header labels.}
\author{Michael Thrun (IAP-GmbH Intelligent Analytics Projects)}
\examples{
TrimHeader(c("Sample_A  ", " Sample_B"))
TrimHeader("Sample_A", UnderlineReplacement = "-")
}
\keyword{character}
