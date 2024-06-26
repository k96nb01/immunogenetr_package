% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/HLA_prefix_remove.R
\name{HLA_prefix_remove}
\alias{HLA_prefix_remove}
\title{HLA_prefix_remove}
\usage{
HLA_prefix_remove(.data, columns)
}
\arguments{
\item{.data}{A data frame}

\item{columns}{Names of columns in .data containing HLA typing results}
}
\value{
A data frame object with specified columns modified to remove HLA
and locus prefixes.
}
\description{
This function removes HLA and locus prefixes from typing
results in specified columns of a data frame. For example, a column with
values `c("HLA-A2", "A2", "A*11:01", "A66", "HLA-DRB3*15:01")` changes to
`c("2", "2", "11:01", "66", "15:01")`
}
\examples{
data(toydata)
output <- toydata \%>\% HLA_prefix_remove(A.2_recipient)

}
