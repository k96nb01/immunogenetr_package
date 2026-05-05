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
#' @importFrom cli cli_abort
#'

HLA_mismatch_base <- function(GL_string_recip, GL_string_donor, loci, direction, homozygous_count = 2) {
  # Validate inputs
  check_gl_string(GL_string_recip, "GL_string_recip")
  check_gl_string(GL_string_donor, "GL_string_donor")
  check_loci(loci)
  check_homozygous_count(homozygous_count)

  direction <- match.arg(direction, c("HvG", "GvH"))
  # Ensure input vectors are of the same length - each input should be a single GL string.
  if (length(GL_string_recip) != length(GL_string_donor)) {
    cli_abort("{.arg GL_string_recip} and {.arg GL_string_donor} must be of equal length.")
  }

  # Check for ambiguity
  if (any(grepl("[|/]", GL_string_recip, perl = TRUE) |
          grepl("[|/]", GL_string_donor, perl = TRUE))) {
    cli_abort("The matching/mismatching functions do not support ambiguous GL strings containing {.val |} or {.val /}. Process your GL strings to result in unambiguous genotypes before using these functions.")
  }

  # Maps the serologic naming of the DRB locus to molecular so that only one name is used
  unify_locus <- function(x) sub("^HLA-DR51/52/53$", "HLA-DRB3/4/5", x, perl = TRUE)
  # Keep original locus names for display later and normalize loci
  original_loci <- loci
  loci <- unify_locus(loci)
  # Maps internal keys back to the user's original loci inputs for display.
  # Hoisted out of the per-pair loop (used to be a linear match() inside process_pair).
  display_lookup <- stats::setNames(original_loci, loci)
  display_name <- function(name) {
    v <- display_lookup[name]
    if (is.na(v)) name else unname(v)
  }

  # Hoisted invariants: computed once per call, not per pair.
  n_loci <- length(loci)
  single_locus <- n_loci == 1L
  single_locus_prefix <- if (single_locus) paste0(original_loci, "=") else NULL

  # Precompiled regex strings (used many times inside the loop).
  # Capture the locus prefix (through the asterisk) and replace everything
  # after it, up to the trailing N, with "XXN". A lookbehind won't work here
  # because R on Linux links against PCRE1, which rejects variable-width
  # lookbehinds (PCRE2 on macOS/Windows accepts them).
  null_allele_re <- "^(HLA-[A-Za-z0-9]+\\*).+N$"
  # Fixed-string set for DRB3/4/5 classification (molecular or serologic).
  # All six tokens are 8 characters long, so `substr(x, 1, 8) %in% set`
  # gives a constant-cost lookup that avoids the regex engine entirely.
  drb345_prefixes <- c("HLA-DRB3", "HLA-DRB4", "HLA-DRB5",
                       "HLA-DR51", "HLA-DR52", "HLA-DR53")

  # Function to preprocess GL strings: handle null alleles and homozygosity
  preprocess_GL_string <- function(GL_string, homozygous_count) {
    # Split GL string into alleles
    alleles <- strsplit(GL_string, "+", fixed = TRUE)[[1L]]

    # Replace any null allele (ending with uppercase "N" expression suffix) with a
    # placeholder "XXN". The WHO nomenclature defines "N" as the null expression suffix,
    # appearing after the colon-separated allele fields (e.g. "HLA-A*01:01N").
    # The lookbehind matches the locus prefix up to the asterisk, allowing locus names
    # of any length (e.g. HLA-A, HLA-DRB1, HLA-DRB345). Short-circuit with endsWith()
    # so we only invoke the regex engine on alleles that can possibly match.
    n_idx <- which(endsWith(alleles, "N"))
    if (length(n_idx) > 0L) {
      alleles[n_idx] <- sub(null_allele_re, "\\1XXN", alleles[n_idx], perl = TRUE)
    }

    # Handle homozygosity
    la <- length(alleles)
    if (la == 1L && homozygous_count == 2) {
      alleles <- c(alleles, alleles)
    } else if (la == 2L && alleles[1L] == alleles[2L] && homozygous_count == 1) {
      alleles <- alleles[1L]
    }

    # Return processed alleles as a single GL string. Base-R paste replaces
    # str_flatten, which internally calls stri_split_boundaries and was the
    # largest self-time cost in the original profile.
    paste(alleles[!is.na(alleles)], collapse = "+")
  }

  # Function to process the alleles strings.
  process_alleles <- function(alleles_list, homozygous_count) {
    # Classify each entry as DRB3/4/5 (either molecular or serologic) via a
    # fixed-string prefix lookup — cheaper than the regex it replaced.
    is_drb345 <- substr(alleles_list, 1L, 8L) %in% drb345_prefixes
    drb345 <- alleles_list[is_drb345]
    no_drb345 <- alleles_list[!is_drb345]

    # Process DRB3/4/5 or DR51/52/53 alleles to add them to a single locus "HLA-DRB3/4/5".
    # If no DRB3/4/5 alleles are present, use a null placeholder, so that expressed
    # alleles at this locus will be output as mismatches.
    drb345_entry <- if (length(drb345) > 0L) paste(drb345, collapse = "+") else "HLA-DRB3*XX:XXN"

    # Combine lists and preprocess each allele string
    combined <- c(no_drb345, drb345_entry)
    combined <- combined[grepl("[[:graph:]]", combined, perl = TRUE)]

    processed <- vapply(combined, preprocess_GL_string, character(1L),
                        homozygous_count = homozygous_count, USE.NAMES = FALSE)

    # Filter out any NA values
    processed[!is.na(processed)]
  }

  # Helper to extract the locus name from a GL string allele entry.
  # Returns canonical names directly ("HLA-DRB3/4/5" for both molecular and
  # serologic DRB entries), so callers don't need to run unify_locus on the
  # result — that call used to dominate the per-pair profile.
  extract_locus_name <- function(allele_str) {
    n <- length(allele_str)
    if (n == 0L) return(character(0L))
    # Single substr(1, 8) classifies DRB3/4/5 in either nomenclature.
    is_drb345 <- substr(allele_str, 1L, 8L) %in% drb345_prefixes
    has_star  <- grepl("*", allele_str, fixed = TRUE)
    out <- character(n)
    out[is_drb345] <- "HLA-DRB3/4/5"
    # Remaining molecular entries: everything before the '*'. regexpr + substr
    # avoids the regex engine's backtracking machinery on this hot path.
    mol_ix <- has_star & !is_drb345
    if (any(mol_ix)) {
      star_pos <- regexpr("*", allele_str[mol_ix], fixed = TRUE)
      out[mol_ix] <- substr(allele_str[mol_ix], 1L, star_pos - 1L)
    }
    # Remaining serologic entries: leading "HLA-<letters>" prefix. This is
    # a rarely-hit path (only non-DR serologic input), so a simple sub() is fine.
    ser_ix <- !has_star & !is_drb345
    if (any(ser_ix)) {
      out[ser_ix] <- sub("^(HLA-[A-Za-z]+).*$", "\\1", allele_str[ser_ix], perl = TRUE)
    }
    out
  }

  # Function to process each pair of recipient/donor alleles
  process_pair <- function(recip_str, donor_str) {
    # Split GL strings by "^" to separate loci
    recip_alleles_list <- strsplit(recip_str, "^", fixed = TRUE)[[1L]]
    donor_alleles_list <- strsplit(donor_str, "^", fixed = TRUE)[[1L]]

    # Process recipient and donor allele strings:
    recip_alleles_list_processed <- process_alleles(recip_alleles_list, homozygous_count)
    donor_alleles_list_processed <- process_alleles(donor_alleles_list, homozygous_count)

    # extract_locus_name already returns canonical names ("HLA-DRB3/4/5" for
    # both molecular and serologic DRB entries), so no unify_locus call here.
    names(recip_alleles_list_processed) <- extract_locus_name(recip_alleles_list_processed)
    names(donor_alleles_list_processed) <- extract_locus_name(donor_alleles_list_processed)

    # Find which supplied loci are missing from recipient and donor genotypes.
    # A locus is "missing" if it's absent from either side (not both);
    # DRB3/4/5 is excluded from this check because it is optional.
    missing_from_recip <- setdiff(loci, names(recip_alleles_list_processed))
    missing_from_donor <- setdiff(loci, names(donor_alleles_list_processed))
    missing_loci <- setdiff(union(missing_from_recip, missing_from_donor), "HLA-DRB3/4/5")

    if (length(missing_loci) > 0L) {
      cli_abort("The recipient and/or donor GL strings are missing these loci: {.val {missing_loci}}.")
    }

    # Mismatch results calculation
    parts <- character(n_loci)
    for (k in seq_len(n_loci)) {
      locus_name <- loci[k]

      # Defensive guard: if either donor or recip lacks DRB3/4/5, return "=NA"
      # for that locus instead of error. Currently unreachable because
      # process_alleles() inserts a null placeholder for missing DRB3/4/5,
      # but kept as a safety net in case that logic changes.
      if (locus_name == "HLA-DRB3/4/5" &&
          (!(locus_name %in% names(recip_alleles_list_processed)) ||
           !(locus_name %in% names(donor_alleles_list_processed)))) {
        parts[k] <- paste0(display_name(locus_name), "=NA")
        next
      }

      # Pull out the allele list for each locus and split once for reuse.
      recip_alleles_str <- recip_alleles_list_processed[locus_name]
      donor_alleles_str <- donor_alleles_list_processed[locus_name]
      recip_alleles <- if (is.na(recip_alleles_str)) character(0L) else strsplit(recip_alleles_str, "+", fixed = TRUE)[[1L]]
      donor_alleles <- if (is.na(donor_alleles_str)) character(0L) else strsplit(donor_alleles_str, "+", fixed = TRUE)[[1L]]

      # Assign sides based on direction:
      # - "match_from": the side we index [1],[2] for match checking
      # - "mismatch_from": the side whose valid alleles we check for mismatches
      # GvH: matches from donor side, mismatches from recip side
      # HvG: matches from recip side, mismatches from donor side
      if (direction == "GvH") {
        match_from <- donor_alleles
        mismatch_from <- recip_alleles
      } else {
        match_from <- recip_alleles
        mismatch_from <- donor_alleles
      }

      # Calculate matches (including nulls): match_from alleles found in mismatch_from.
      # %in% on length-1 vectors is substantially faster than intersect().
      matched_alleles <- character(0L)
      m1 <- match_from[1L]; m2 <- match_from[2L]
      if (!is.na(m1) && m1 %in% mismatch_from) matched_alleles <- c(matched_alleles, m1)
      if (!is.na(m2) && m2 %in% mismatch_from) matched_alleles <- c(matched_alleles, m2)

      # Calculate mismatches (excluding nulls): mismatch_from alleles NOT in match_from
      mismatch_valid <- mismatch_from[!endsWith(mismatch_from, "N") & !endsWith(mismatch_from, "n")]
      mismatched_alleles <- character(0L)
      mv1 <- mismatch_valid[1L]; mv2 <- mismatch_valid[2L]
      if (!is.na(mv1) && !(mv1 %in% match_from)) mismatched_alleles <- c(mismatched_alleles, mv1)
      if (!is.na(mv2) && !(mv2 %in% match_from)) mismatched_alleles <- c(mismatched_alleles, mv2)

      # Count number of matches and mismatches. If total < 2 and homozygous_count == 2,
      # repeat mismatched alleles.
      total_match_mismatch <- length(matched_alleles) + length(mismatched_alleles)
      if (total_match_mismatch < 2L && homozygous_count == 2) {
        mismatched_alleles <- rep(mismatched_alleles, times = homozygous_count)
      }

      # Create a string of mismatched alleles or 'NA' if no mismatches are found.
      # Use the user's original label through the display_name function.
      if (length(mismatched_alleles) > 0L) {
        parts[k] <- paste0(display_name(locus_name), "=", paste(mismatched_alleles, collapse = "+"))
      } else {
        parts[k] <- paste0(display_name(locus_name), "=NA")
      }
    }

    result <- paste(parts, collapse = ", ")

    # If only a single locus was selected in the arguments, output without starting
    # with the locus name followed by an equal sign.
    if (single_locus) {
      result <- sub(single_locus_prefix, "", result, fixed = TRUE)
      if (identical(result, "NA")) NA_character_ else result
    } else {
      result
    }
  }

  # Return final result by applying the GL strings to the process_pair function defined above.
  vapply(
    seq_along(GL_string_recip),
    function(i) process_pair(GL_string_recip[[i]], GL_string_donor[[i]]),
    character(1L)
  )
}
