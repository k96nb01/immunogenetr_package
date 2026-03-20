#' @keywords internal
"_PACKAGE"

#' @section GL string functions:
#' Functions for working with genotype list (GL) strings:
#' \itemize{
#'   \item \code{\link{HLA_columns_to_GLstring}}: Convert tabular HLA data to GL strings
#'   \item \code{\link{GLstring_genes}}: Split a GL string into locus columns
#'   \item \code{\link{GLstring_genes_expanded}}: Split a GL string into one allele per row
#'   \item \code{\link{GLstring_expand_longer}}: Expand a GL string into an ambiguity table
#'   \item \code{\link{ambiguity_table_to_GLstring}}: Collapse an ambiguity table back to a GL string
#'   \item \code{\link{GLstring_genotype_ambiguity}}: Extract genotype ambiguity from GL strings
#'   \item \code{\link{GLstring_gene_copies_combine}}: Combine gene copies in a GL string
#'   \item \code{\link{GLstring_regex}}: Create regex patterns for accurate GL string searching
#' }
#'
#' @section Matching and mismatching:
#' Functions for calculating HLA matching between recipient and donor:
#' \itemize{
#'   \item \code{\link{HLA_mismatch_base}}: Core mismatch engine (used internally by other functions)
#'   \item \code{\link{HLA_mismatch_logical}}: Is there a mismatch? (TRUE/FALSE)
#'   \item \code{\link{HLA_mismatch_number}}: How many mismatches?
#'   \item \code{\link{HLA_mismatched_alleles}}: Which alleles are mismatched?
#'   \item \code{\link{HLA_match_number}}: How many matches?
#'   \item \code{\link{HLA_match_summary_HCT}}: Standard match grades for hematopoietic cell transplantation
#' }
#'
#' @section Allele name utilities:
#' Functions for manipulating HLA allele names:
#' \itemize{
#'   \item \code{\link{HLA_truncate}}: Truncate alleles to a specified number of fields
#'   \item \code{\link{HLA_prefix_add}}: Add HLA and locus prefixes
#'   \item \code{\link{HLA_prefix_remove}}: Remove HLA and locus prefixes
#'   \item \code{\link{HLA_validate}}: Validate and clean HLA allele names
#'   \item \code{\link{HLA_column_repair}}: Convert column names between WHO and tidyverse formats
#' }
#'
#' @section File I/O:
#' \itemize{
#'   \item \code{\link{read_HML}}: Read GL strings from HML (HLA Markup Language) files
#' }
#'
#' @section Datasets:
#' \itemize{
#'   \item \code{\link{HLA_typing_1}}: Synthetic HLA typing for 10 individuals
#'   \item \code{\link{HLA_typing_LIS}}: Synthetic LIS-formatted HLA typing
#'   \item \code{\link{HLA_dictionary}}: HLA allele dictionary (2008)
#'   \item \code{\link{Haplotype_frequencies}}: HLA haplotype frequencies
#'   \item \code{\link{mismatch_table_2010}}: Consensus mismatch reference table (2010)
#'   \item \code{\link{mismatch_table_2016}}: Consensus mismatch reference table (2016)
#' }
NULL
