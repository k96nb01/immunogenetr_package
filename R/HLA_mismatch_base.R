#' @title HLA_mismatch_base
#'
#' @description A function to return a string of mismatches between recipient
#' and donor HLA genotypes represented as GL strings. The function finds
#' mismatches based on the direction of comparison specified in the inputs
#' and also handles homozygosity. As the name implies, this function is the base
#' for all other mismatch (and matching) functions. This function is not meant to be
#' called directly; it is better to use one of the derivative functions.
#'
#' @param GL_string_recip A GL string representing the recipient's HLA genotype.
#' @param GL_string_donor A GL string representing the donor's HLA genotype.
#' @param loci A character vector specifying the loci to be considered for
#' mismatch calculation. HLA-DRB3/4/5 (and their serologic equivalents DR51/52/53)
#' are considered once locus for this function, and should be called in this argument
#' as "HLA-DRB3/4/5" or "HLA-DR51/52/53", respectively.
#' @param direction A character string indicating the direction of mismatch.
#' Options are "HvG" (host vs. graft) or "GvH" (graft vs. host).
#' @param homozygous_count An integer specifying how to handle homozygosity.
#' Defaults to 2, where homozygous alleles are treated as duplicated for
#' mismatch calculations. Can be specified to be 1, in which case homozygous
#' alleles are treated as single occurrences without duplication.
#'
#' @return A character vector, where each element is a string summarizing the
#' mismatches for the specified loci. The strings are formatted as
#' comma-separated locus mismatch entries if multiple loci are supplied, or
#' simple GL strings if a single locus is supplied.

#'
#' @examples
#' file <- HLA_typing_1[, -1]
#' GL_string <- HLA_columns_to_GLstring(file, HLA_typing_columns = everything())
#'
#' GL_string_recip <- GL_string[1]
#' GL_string_donor <- GL_string[2]
#'
#' loci <- c("HLA-A", "HLA-DRB3/4/5", "HLA-DPB1")
#' mismatches <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, direction = "HvG")
#' print(mismatches)
#'
#' @export
#'
#' @importFrom stringr str_split
#' @importFrom stringr str_flatten
#' @importFrom stringr str_detect
#' @importFrom stringr str_replace
#' @importFrom stringr str_c
#' @importFrom purrr keep
#' @importFrom purrr discard
#' @importFrom purrr map
#' @importFrom purrr map_chr
#' @importFrom purrr map2_chr
#' @importFrom purrr modify_if
#'

HLA_mismatch_base <- function(GL_string_recip, GL_string_donor, loci, direction, homozygous_count = 2) {
  direction <- match.arg(direction, c("HvG", "GvH"))
  # Ensure input vectors are of the same length - each input should be a single GL string.
  if (length(GL_string_recip) != length(GL_string_donor)) {
    stop("Recipient and donor GL strings must be of equal length")
  }

  # Check for ambiguity
  if (any(str_detect(GL_string_recip, "[|/]") | str_detect(GL_string_donor, "[|/]"))) {
    stop("The matching/mismatching functions do not support ambiguous GL strings containing | or /. Process your GL strings to result in unambiguous genotypes before using these functions.")
  }

  unify_locus <- function(x) stringr::str_replace(x, "^HLA-DR51/52/53$", "HLA-DRB3/4/5")
  original_loci <- loci
  loci <- unify_locus(loci)
  display_name <- function(name) {
    idx <- match(name, loci)
    if (is.na(idx)) name else original_loci[[idx]]
  }

  # Function to preprocess GL strings: handle null alleles and homozygosity
  preprocess_GL_string <- function(GL_string, homozygous_count) {
    # Split GL string into alleles
    alleles <- str_split(GL_string, "\\+", simplify = TRUE)

    # Replace any allele that ends with "N" with "NullN".
    alleles <- str_replace(alleles, "(?<=HLA-[:alnum:]{1,4}\\*).+N$", "XXN")

    # Handle homozygosity
    if (length(alleles) == 1 && homozygous_count == 2) {
      alleles <- rep(alleles, times = homozygous_count)
    } else if (length(alleles) == 2 && alleles[1] == alleles[2] && homozygous_count == 1) {
      alleles <- alleles[1]
    }

    # Return processed alleles as a single GL string
    return(str_flatten(alleles, collapse = "+", na.rm = TRUE))
  }

  # Function to process each pair of recipient/donor alleles
  process_pair <- function(recip_str, donor_str) {
    # Split GL strings by "^" to separate loci
    recip_alleles_list <- unlist(strsplit(recip_str, "\\^"))
    donor_alleles_list <- unlist(strsplit(donor_str, "\\^"))

    # Function to process the alleles strings.
    process_alleles <- function(alleles_list, homozygous_count) {
      # Process DRB3/4/5 or DR51/52/53 alleles to add them to a single locus "HLA-DRB3/4/5"
      alleles_list_DRB345 <- alleles_list %>%
        keep(str_detect(., "(HLA-DRB[345])|(HLA-DR5[123])")) %>%
        paste(collapse = "+")

      # Remove DRB3/4/5 or DR51/52/53 alleles from the original list
      alleles_list_no_DRB345 <- alleles_list %>%
        keep(!str_detect(., "(HLA-DRB[345])|(HLA-DR5[123])"))

      # Combine lists and preprocess each allele string
      alleles_list_processed <- c(alleles_list_no_DRB345, alleles_list_DRB345) %>%
        keep(~ str_detect(.x, "[:graph:]")) %>%
        map_chr(preprocess_GL_string, homozygous_count)

      # Filter out any NA values
      alleles_list_processed <- alleles_list_processed[!is.na(alleles_list_processed)]

      return(alleles_list_processed)
    }

    # Process recipient and donor allele strings:
    recip_alleles_list_processed <- process_alleles(recip_alleles_list, homozygous_count)
    donor_alleles_list_processed <- process_alleles(donor_alleles_list, homozygous_count)

    # Set names for each locus
    names(recip_alleles_list_processed) <- map_chr(
      recip_alleles_list_processed,
      ~ case_when(
        # Molecular nomenclature
        str_detect(.x, "\\*") && str_detect(.x, "HLA-DRB[345]") ~ "HLA-DRB3/4/5",
        str_detect(.x, "\\*") ~ strsplit(.x, "\\*")[[1]][1],
        # Serologic nomenclature
        !str_detect(.x, "\\*") && str_detect(.x, "HLA-DR5[123]") ~ "HLA-DR51/52/53",
        !str_detect(.x, "\\*") ~ str_extract(.x, "^HLA-[A-Za-z]+")
      )
    )
    names(donor_alleles_list_processed) <- map_chr(
      donor_alleles_list_processed,
      ~ case_when(
        # Molecular nomenclature
        str_detect(.x, "\\*") && str_detect(.x, "HLA-DRB[345]") ~ "HLA-DRB3/4/5",
        str_detect(.x, "\\*") ~ strsplit(.x, "\\*")[[1]][1],
        # Serologic nomenclature
        !str_detect(.x, "\\*") && str_detect(.x, "HLA-DR5[123]") ~ "HLA-DR51/52/53",
        !str_detect(.x, "\\*") ~ str_extract(.x, "^HLA-[A-Za-z]+")
      )
    )

    names(recip_alleles_list_processed) <- unify_locus(names(recip_alleles_list_processed))
    names(donor_alleles_list_processed) <- unify_locus(names(donor_alleles_list_processed))

    # Find which supplied loci are missing from recipient and donor genotypes
    missing_loci_from_recipient <- setdiff(loci, names(recip_alleles_list_processed))
    missing_loci_from_donor <- setdiff(loci, names(donor_alleles_list_processed))
    missing_loci <- setdiff(union(missing_loci_from_recipient, missing_loci_from_donor), "HLA-DRB3/4/5")

    if (length(missing_loci) > 0) {
      stop(paste(
        "Either the recipient and/or donor GL strings are missing these loci:",
        paste(missing_loci, collapse = ", ")
      ))
    }

    # Mismatch results calculation
    mismatch_results <- map(loci, function(locus_name) {

      if (locus_name == "HLA-DRB3/4/5" &&
          (!(locus_name %in% names(recip_alleles_list_processed)) ||
           !(locus_name %in% names(donor_alleles_list_processed)))) {
        return(paste0(display_name(locus_name), "=NA"))
      }

      # Pull out the allele list for each locus.
      recip_alleles_str <- recip_alleles_list_processed[locus_name]
      donor_alleles_str <- donor_alleles_list_processed[locus_name]

      if (direction == "GvH") {
        # Calculate matches (Including nulls)
        matched_allele_1 <- intersect(unlist(strsplit(donor_alleles_str, "\\+"))[1], unlist(strsplit(recip_alleles_str, "\\+")))
        matched_allele_2 <- intersect(unlist(strsplit(donor_alleles_str, "\\+"))[2], unlist(strsplit(recip_alleles_str, "\\+")))
        matched_alleles <- discard(c(matched_allele_1, matched_allele_2), is.na)
        # Calculate mismatches (excluding nulls)
        recip_valid <- unlist(strsplit(recip_alleles_str, "\\+"))
        recip_valid <- recip_valid[!str_detect(recip_valid, "[Nn]$")]
        mismatched_allele_1 <- setdiff(recip_valid[1], unlist(strsplit(donor_alleles_str, "\\+")))
        mismatched_allele_2 <- setdiff(recip_valid[2], unlist(strsplit(donor_alleles_str, "\\+")))
        mismatched_alleles <- discard(c(mismatched_allele_1, mismatched_allele_2), is.na)
        # Count number of matches and mismatches
        total_match_mismatch <- length(matched_alleles) + length(mismatched_alleles)
        # If total matches + mismatches < 2, and homozygous_count == 2, repeat mismatched alleles.
        if (total_match_mismatch < 2 && homozygous_count == 2) {
          mismatched_alleles <- rep(mismatched_alleles, times = homozygous_count)
        }
      } else if (direction == "HvG") {
        # Calculate matches (Including nulls)
        matched_allele_1 <- intersect(unlist(strsplit(recip_alleles_str, "\\+"))[1], unlist(strsplit(donor_alleles_str, "\\+")))
        matched_allele_2 <- intersect(unlist(strsplit(recip_alleles_str, "\\+"))[2], unlist(strsplit(donor_alleles_str, "\\+")))
        matched_alleles <- discard(c(matched_allele_1, matched_allele_2), is.na)
        # Calculate mismatches (excluding nulls)
        donor_valid <- unlist(strsplit(donor_alleles_str, "\\+"))
        donor_valid <- donor_valid[!str_detect(donor_valid, "[Nn]$")]
        mismatched_allele_1 <- setdiff(donor_valid[1], unlist(strsplit(recip_alleles_str, "\\+")))
        mismatched_allele_2 <- setdiff(donor_valid[2], unlist(strsplit(recip_alleles_str, "\\+")))
        mismatched_alleles <- discard(c(mismatched_allele_1, mismatched_allele_2), is.na)
        # Count number of matches and mismatches
        total_match_mismatch <- length(matched_alleles) + length(mismatched_alleles)
        # If total matches + mismatches < 2, and homozygous_count == 2, repeat mismatched alleles.
        if (total_match_mismatch < 2 && homozygous_count == 2) {
          mismatched_alleles <- rep(mismatched_alleles, times = homozygous_count)
        }
      } else {
        stop("Direction must either be 'GvH', or 'HvG'.")
      }

      # Create a string of mismatched alleles or 'NA' if no mismatches are found.
      allele_mismatches_str <-
        if (length(mismatched_alleles) > 0) {
          paste0(display_name(locus_name), "=", paste(mismatched_alleles, collapse = "+"))
        } else {
          paste0(display_name(locus_name), "=", "NA")
        }
    })

    result <- paste(mismatch_results, collapse = ", ")

    # If only a single locus was selected in the arguments, output without starting with the locus name followed by an equal sign.
    if (length(loci) == 1) {
      result %>%
        str_replace(str_c(original_loci, "="), "") %>%
        na_if("NA")
    } else {
      return(result)
    }
  }

  # Return final result by applying the GL strings to the process_pair function defined above.
  map2_chr(GL_string_recip, GL_string_donor, process_pair)
}

globalVariables(c(".", "process_alleles"))
