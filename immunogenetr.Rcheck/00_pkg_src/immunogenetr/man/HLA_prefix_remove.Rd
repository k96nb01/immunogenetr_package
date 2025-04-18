% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/HLA_prefix_remove.R
\name{HLA_prefix_remove}
\alias{HLA_prefix_remove}
\title{HLA_prefix_remove}
\usage{
HLA_prefix_remove(data)
}
\arguments{
\item{data}{A string with a single HLA allele.}
}
\value{
A string modified to remove HLA and locus prefixes.
}
\description{
This function removes HLA and locus prefixes from a string of HLA typing:
"HLA-A2" changes to "2".
}
\examples{
df <- data.frame(
  A1 = c("HLA-A2", "A2", "A*11:01", "A66", "HLA-DRB3*15:01"),
  A2 = c("HLA-A1", "A1", "A*02:01", "A68", "HLA-DRB4*14:01"),
  stringsAsFactors = FALSE
)

df <- HLA_prefix_remove(df)

}
