% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/au.tests.r
\name{au.tests}
\alias{au.tests}
\title{AU testing}
\usage{
au.tests(m0, m1, r0, r1, lowthresh = 1e-12)
}
\arguments{
\item{m0}{Number of control subjects}

\item{m1}{Number of case subjects}

\item{r0}{Number of control subjects exposed}

\item{r1}{Number of case subjects exposed}

\item{lowthresh}{A threshold for probabilities below to be considered as zero. Defaults to 1e-12.}
}
\value{
A vector of AU p-values, computed under score, likelihood ratio, and Wald tests.
}
\description{
Calculates approximate unconditional p-values for testing independence in 2x2 case-control tables.
}
\examples{
au.tests(15000, 5000, 30, 25)
au.tests(10000, 10000, 30, 25)
}

