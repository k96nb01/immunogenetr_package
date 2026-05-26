# Internal validation helper functions for immunogenetr
# These are not exported; they provide consistent input checking across the package.

#' @importFrom cli cli_abort
#' @importFrom rlang caller_env

# Validate that a GL string argument is a non-empty character vector.
# Allows NA values within the vector (handled downstream), but rejects
# NULL, non-character types, and zero-length input.
check_gl_string <- function(x, arg_name = "data", call = caller_env()) {
  # NULL check
  if (is.null(x)) {
    cli_abort("{.arg {arg_name}} must be a character vector, not {.cls NULL}.", call = call)
  }
  # Allow bare NA (logical) by treating it as NA_character_; a scalar NA or

  # vector of all NA is a valid "no data" input that downstream code handles.
  if (is.logical(x) && all(is.na(x))) {
    return(invisible(x))
  }
  # Type check
  if (!is.character(x)) {
    cli_abort("{.arg {arg_name}} must be a character vector, not {.cls {class(x)}}.", call = call)
  }
  # Length check
  if (length(x) == 0) {
    cli_abort("{.arg {arg_name}} must have length >= 1, not 0.", call = call)
  }
  invisible(x)
}

# Validate that a data argument is a non-empty data frame.
check_data_frame <- function(x, arg_name = "data", call = caller_env()) {
  # NULL check
  if (is.null(x)) {
    cli_abort("{.arg {arg_name}} must be a data frame, not {.cls NULL}.", call = call)
  }
  # Type check
  if (!is.data.frame(x)) {
    cli_abort("{.arg {arg_name}} must be a data frame, not {.cls {class(x)}}.", call = call)
  }
  # Row check
  if (nrow(x) == 0) {
    cli_abort("{.arg {arg_name}} must have at least one row.", call = call)
  }
  invisible(x)
}

# Validate that a loci argument is a non-empty character vector of locus names.
check_loci <- function(x, arg_name = "loci", call = caller_env()) {
  # NULL check
  if (is.null(x)) {
    cli_abort("{.arg {arg_name}} must be a character vector of locus names, not {.cls NULL}.", call = call)
  }
  # Type check
  if (!is.character(x)) {
    cli_abort("{.arg {arg_name}} must be a character vector, not {.cls {class(x)}}.", call = call)
  }
  # Length check
  if (length(x) == 0) {
    cli_abort("{.arg {arg_name}} must have length >= 1, not 0.", call = call)
  }
  invisible(x)
}

# Validate that a scalar logical argument is TRUE or FALSE (not NA, NULL, or non-logical).
check_logical_flag <- function(x, arg_name, call = caller_env()) {
  if (is.null(x) || !is.logical(x) || length(x) != 1 || is.na(x)) {
    cli_abort("{.arg {arg_name}} must be {.val TRUE} or {.val FALSE}.", call = call)
  }
  invisible(x)
}

# Validate that homozygous_count is 1 or 2.
check_homozygous_count <- function(x, call = caller_env()) {
  if (is.null(x) || length(x) != 1 || !x %in% c(1, 2)) {
    cli_abort("{.arg homozygous_count} must be {.val 1} or {.val 2}.", call = call)
  }
  invisible(x)
}

# Validate that fields is an integer between 1 and 4.
check_fields <- function(x, call = caller_env()) {
  if (is.null(x) || length(x) != 1 || !x %in% 1:4) {
    cli_abort("{.arg fields} must be an integer between 1 and 4.", call = call)
  }
  invisible(x)
}

# Validate that every allele in a GL string uses molecular nomenclature
# (i.e. contains "*"). This is intended for callers that want to enforce
# a molecular-only input — for example, an API layer that refuses to mix
# serologic and molecular allele names. Serologic inputs like "HLA-DR52"
# or "HLA-A1" are rejected with a message naming the offending tokens.
#
# Accepts the same special cases as check_gl_string(): a bare NA or a
# character vector of all-NA is treated as "no data" and passes.
check_molecular_gl_string <- function(x, arg_name = "data", call = caller_env()) {
  check_gl_string(x, arg_name = arg_name, call = call)
  if (is.logical(x) && all(is.na(x))) return(invisible(x))

  # Split each GL string on any of the GL delimiters (^, +, |, /) and
  # check that every non-empty, non-NA token contains "*".
  for (i in seq_along(x)) {
    if (is.na(x[[i]])) next
    tokens <- strsplit(x[[i]], "[\\^+|/]", perl = TRUE)[[1L]]
    tokens <- tokens[nzchar(tokens)]
    if (length(tokens) == 0L) next
    bad <- tokens[!grepl("*", tokens, fixed = TRUE)]
    if (length(bad) > 0L) {
      cli_abort(
        c(
          "{.arg {arg_name}} must use molecular HLA nomenclature (alleles containing {.val *}), not serologic.",
          "x" = "Element {i} contains serologic allele{?s}: {.val {bad}}."
        ),
        call = call
      )
    }
  }
  invisible(x)
}
