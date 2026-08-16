#' @title GLstring_regex
#'
#' @description This function will format an HLA allele (e.g. "HLA-A*02:01") to
#' a regex pattern for searching within a GL String. The allele must carry its
#' locus designation, but the "HLA-" prefix is optional in both the allele and
#' the GL String being searched: "A*02:01" and "HLA-A*02:01" produce equivalent
#' patterns, and either matches the allele whether the GL String writes it with
#' or without the prefix (as wild-caught GL Strings often omit it). A bare field
#' value with no locus ("02:01") is rejected, since the locus cannot be inferred;
#' the `HLA_prefix_add` function is useful for repairing such values.
#'
#' The pattern matches whole alleles only, on these rules:
#'
#' * An allele supplied with fewer fields will match a higher-resolution allele
#'   in the GL String ("HLA-A*02:01" matches "HLA-A*02:01:01:01"), but partial
#'   fields never match ("HLA-A*02:14" will not match "HLA-A*02:149").
#' * An allele without an expression suffix matches regardless of expression
#'   status: "HLA-A*24:09" matches "HLA-A*24:09N". It likewise matches G and P
#'   group names, which include the allele in their name ("HLA-A*01:01:01"
#'   matches "HLA-A*01:01:01G").
#' * An allele supplied with a WHO expression suffix (N, Q, L, S, C or A) or a
#'   G/P group letter matches only alleles carrying that same letter, at the
#'   same or higher resolution: "HLA-A*01:01N" matches "HLA-A*01:01:03N" but
#'   not "HLA-A*01:01:03" or "HLA-A*01:01:03Q". Note that a G or P group query
#'   matches only the group name as written in the GL String; it does not
#'   expand to the group's member alleles ("HLA-A*01:01:01G" will not match
#'   "HLA-A*01:01:01" or "HLA-A*01:32"), since group membership is defined by
#'   the IPD-IMGT/HLA database rather than by the allele name. To find any
#'   member of a group, search the base allele name instead.
#'
#' The matched text is always the full allele name as it appears in the GL
#' String, so `stringr::str_extract` returns the allele that was found (not the
#' search string), and `stringr::str_replace` replaces the whole allele.
#'
#' @param data A string containing an HLA allele.
#'
#' @return A string with the HLA allele formatted as a regex pattern.
#'
#' @examples
#'
#' # To understand how the function works we can see how it alters the allele "HLA-A*02:01":
#'
#' GLstring_regex("HLA-A*02:01")
#'
#' # The result is the same allele with extra formatting to escape special characters found
#' # in a GL String, as well as the ability to accurately search for an allele in a GL String.
#' # For example, we would not want the allele "HLA-A*02:14" to match to "HLA-A*02:149:01",
#' # which would happen if we simply escaped the special characters:
#'
#' library(stringr)
#' str_view("HLA-A*02:149:01", str_escape("HLA-A*02:14"), match = NA)
#'
#' # Using `GLstring_regex` prevents this:
#'
#' str_view("HLA-A*02:149:01", GLstring_regex("HLA-A*02:14"), match = NA)
#'
#' # Using a longer GL String with multiple alleles and loci:
#'
#' GL_string <- "HLA-A*02:01:01+HLA-A*68:01^HLA-B*07:01+HLA-B*15:01"
#'
#' # We can match any allele accurately:
#'
#' str_view(GL_string, GLstring_regex("HLA-A*68:01"), match = NA)
#'
#' # Note that alleles supplied with fewer fields than in the GL String will also match,
#' # and that the match is the full allele as written in the GL String:
#'
#' str_view(GL_string, GLstring_regex("HLA-A*02:01"), match = NA)
#'
#' # An allele without an expression suffix matches its expression variants:
#'
#' str_view("HLA-A*24:09N+HLA-A*02:01", GLstring_regex("HLA-A*24:09"), match = NA)
#'
#' # An allele with an expression suffix matches only alleles carrying that suffix,
#' # at the same or higher resolution:
#'
#' str_view("HLA-A*01:01:03N+HLA-A*02:01", GLstring_regex("HLA-A*01:01N"), match = NA)
#' str_view("HLA-A*01:01:03Q+HLA-A*02:01", GLstring_regex("HLA-A*01:01N"), match = NA)
#'
#' # The "HLA-" prefix is optional in both the allele and the GL String, so a
#' # canonical allele finds its match in a wild-caught GL String without prefixes,
#' # and vice versa:
#'
#' str_view("A*02:01:01+A*68:01", GLstring_regex("HLA-A*02:01"), match = NA)
#' str_view("HLA-A*02:01:01+HLA-A*68:01", GLstring_regex("A*02:01"), match = NA)
#'
#' @export
#'
#' @importFrom cli cli_abort
#' @importFrom stringr str_detect
#' @importFrom stringr str_c
#' @importFrom stringr str_escape
#' @importFrom stringr str_match
#' @importFrom stringr str_replace

GLstring_regex <- function(data) {
  # Validate input
  check_gl_string(data, "data")

  # Every allele must carry a locus designation ("A*02:01", "HLA-Cw8"); a bare field value like "02:01" is rejected because the locus it belongs to cannot be inferred from the value alone. NA is treated the same way rather than being allowed to crash the check below with a raw base-R error.
  if (any(is.na(data) | !str_detect(data, "^(HLA-)?[A-Za-z]"))) {
    cli_abort("All alleles must be non-missing and include a locus designation (e.g. {.val A*02:01} or {.val HLA-A*02:01}) for {.fn GLstring_regex} to work properly. Use {.fn HLA_prefix_add} to add the locus first.")
  }

  # Canonicalize the allele by removing any "HLA-" prefix; the pattern re-adds it as optional, so an allele in either convention matches a GL String in either convention.
  base_allele <- str_replace(data, "^HLA-", "")

  # Split each allele into a base and a trailing single-letter suffix: a WHO expression suffix (N/Q/L/S/C/A) or a G/P group letter. The preceding digit requirement keeps locus letters from being read as a suffix.
  suffix_parts <- str_match(base_allele, "^(.*\\d)([NQLSCAGP])$")

  # The left boundary requires the match to begin at the start of the string or immediately after a GL String delimiter. This is what stops a prefix-less allele from matching inside a longer locus name (e.g. "A*008" inside "MICA*008").
  left_boundary <- "(?:(?<=[\\?\\^\\|\\+\\~/])|^)"

  # The right boundary lookahead holds all the delimiters in a GL String, plus the end of the string. A colon is not a boundary here: additional fields are consumed by the pattern itself, so the match is always the full allele name as it appears in the GL String.
  boundary <- "(?=(\\?|\\^|\\||\\+|\\~|/|$))"

  # An allele without a suffix matches at its resolution or higher, with or without a trailing suffix; an allele with a suffix matches only alleles carrying that same letter after the last field, however many fields intervene.
  ifelse(
    is.na(suffix_parts[, 1]),
    str_c(left_boundary, "(HLA-)?", str_escape(base_allele), "(:\\d+)*[NQLSCAGP]?", boundary),
    str_c(left_boundary, "(HLA-)?", str_escape(suffix_parts[, 2]), "(:\\d+)*", suffix_parts[, 3], boundary)
  )
}
