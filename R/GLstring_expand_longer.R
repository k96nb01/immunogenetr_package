#' @title GLstring_expand_longer
#'
#' @description A function that expands a GL string into a longer, more detailed
#' format (also known as an ambiguity table) by separating the string into its
#' components resulting from its hierarchical set of operators, including gene
#' locations, loci, genotypes, haplotypes, and alleles. The function processes
#' each level of the GL string and assigns identifiers for each hierarchical
#' component. The resulting table can be assembled back into a GL string using
#' the function `ambiguity_table_to_GLstring`.
#'
#' @param GL_string A GL string that encodes HLA alleles and their potential
#' ambiguities
#'
#' @return A tibble that contains the expanded GL string with separate columns
#' for possible gene locations, loci, genotype ambiguities, genotypes, haplotypes,
#' and alleles, each with associated identifiers
#'
#' @examples
#' file <- HLA_typing_1[, -1]
#' GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())
#' result <- GLstring_expand_longer(GL_string[1])
#' print(result)
#'
#' @export
#'
#' @importFrom tibble tibble
#' @importFrom stringi stri_split_fixed

GLstring_expand_longer <- function(GL_string) {
  # Validate input exactly as before so caller-visible errors are preserved.
  check_gl_string(GL_string, "GL_string")

  # -------------------------------------------------------------------------
  # Iteration 6 rewrite: replace the 7 separate_longer_delim + 6 group-by
  # row_number() passes with a direct stri_split_fixed cascade. At each GL
  # operator level we split every parent token in one C call, record the
  # per-parent sibling count, and extend the parent ID vectors by
  # rep.int() — which is vastly cheaper than tidyr's generic unchop and
  # dplyr's grouped row_number().
  #
  # The output shape (tibble with integer index columns entry /
  # possible_gene_location / locus / genotype_ambiguity / genotype /
  # haplotype / allele and character `value`) is identical to the old
  # version, so every downstream caller (HLA_prefix_remove in the old code
  # path, tests, ambiguity_table_to_GLstring) sees the same columns.
  # -------------------------------------------------------------------------

  # split_one: apply stri_split_fixed at one GL-operator level. Returns the
  # flattened child value vector, the child sibling-index vector (1..k per
  # parent), and the replication count per parent so callers can extend
  # the other index columns via rep.int().
  split_one <- function(values, delim) {
    parts <- stringi::stri_split_fixed(values, delim)
    lens  <- lengths(parts)                 # siblings per parent
    # sibling index 1..lens[i] for each parent. sequence() is C-backed and
    # produces the concatenated counters in one call.
    child_index <- sequence(lens)
    list(
      values = unlist(parts, use.names = FALSE),
      child  = child_index,
      lens   = lens
    )
  }

  # Level 0 — one row per input GL string; `entry` starts as 1..N.
  value <- GL_string
  entry <- seq_along(GL_string)

  # Level 1 — split at "?" (possible gene location).
  s <- split_one(value, "?")
  value <- s$values
  possible_gene_location <- s$child
  entry <- rep.int(entry, s$lens)

  # Level 2 — split at "^" (locus).
  s <- split_one(value, "^")
  value <- s$values
  locus <- s$child
  entry <- rep.int(entry, s$lens)
  possible_gene_location <- rep.int(possible_gene_location, s$lens)

  # Level 3 — split at "|" (genotype ambiguity).
  s <- split_one(value, "|")
  value <- s$values
  genotype_ambiguity <- s$child
  entry <- rep.int(entry, s$lens)
  possible_gene_location <- rep.int(possible_gene_location, s$lens)
  locus <- rep.int(locus, s$lens)

  # Level 4 — split at "+" (genotype / gene copy).
  s <- split_one(value, "+")
  value <- s$values
  genotype <- s$child
  entry <- rep.int(entry, s$lens)
  possible_gene_location <- rep.int(possible_gene_location, s$lens)
  locus <- rep.int(locus, s$lens)
  genotype_ambiguity <- rep.int(genotype_ambiguity, s$lens)

  # Level 5 — split at "~" (haplotype).
  s <- split_one(value, "~")
  value <- s$values
  haplotype <- s$child
  entry <- rep.int(entry, s$lens)
  possible_gene_location <- rep.int(possible_gene_location, s$lens)
  locus <- rep.int(locus, s$lens)
  genotype_ambiguity <- rep.int(genotype_ambiguity, s$lens)
  genotype <- rep.int(genotype, s$lens)

  # Level 6 — split at "/" (allele list).
  s <- split_one(value, "/")
  value <- s$values
  allele <- s$child
  entry <- rep.int(entry, s$lens)
  possible_gene_location <- rep.int(possible_gene_location, s$lens)
  locus <- rep.int(locus, s$lens)
  genotype_ambiguity <- rep.int(genotype_ambiguity, s$lens)
  genotype <- rep.int(genotype, s$lens)
  haplotype <- rep.int(haplotype, s$lens)

  # Build the output tibble directly. tibble() with equal-length columns
  # sidesteps all of tidyr's generic column-bookkeeping.
  tibble(
    value = value,
    entry = entry,
    possible_gene_location = possible_gene_location,
    locus = locus,
    genotype_ambiguity = genotype_ambiguity,
    genotype = genotype,
    haplotype = haplotype,
    allele = allele
  )
}

globalVariables(c(
  "value", "entry", "possible_gene_location", "locus",
  "genotype_ambiguity", "genotype", "haplotype", "allele"
))
