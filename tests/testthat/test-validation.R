library(testthat)

# ===========================================================================
# Tests for check_gl_string
# ===========================================================================

test_that("check_gl_string accepts valid character vectors", {
  # Single GL string
  expect_invisible(check_gl_string("HLA-A*01:01+HLA-A*02:01"))
  # Vector of GL strings

  expect_invisible(check_gl_string(c("HLA-A*01:01", "HLA-B*07:02")))
  # Character vector with an embedded NA (valid; downstream handles NAs)
  expect_invisible(check_gl_string(c("HLA-A*01:01", NA_character_)))
  # Bare NA (logical) is allowed as a special case
  expect_invisible(check_gl_string(NA))
})

test_that("check_gl_string rejects NULL", {
  expect_error(check_gl_string(NULL), "must be a character vector, not.*NULL")
})

test_that("check_gl_string rejects non-character types", {
  # Numeric input
  expect_error(check_gl_string(123), "must be a character vector, not.*numeric")
  # Logical TRUE/FALSE (not bare NA)
  expect_error(check_gl_string(TRUE), "must be a character vector, not.*logical")
  # List input
  expect_error(check_gl_string(list("HLA-A*01:01")), "must be a character vector, not.*list")
  # Data frame input
  expect_error(check_gl_string(data.frame(x = "a")), "must be a character vector")
})

test_that("check_gl_string rejects zero-length character vector", {
  expect_error(check_gl_string(character(0)), "must have length >= 1, not 0")
})

test_that("check_gl_string reports the correct argument name", {
  # Default argument name
  expect_error(check_gl_string(NULL), "data")
  # Custom argument name
  expect_error(check_gl_string(NULL, arg_name = "GL_string_recip"), "GL_string_recip")
})

# ===========================================================================
# Tests for check_data_frame
# ===========================================================================

test_that("check_data_frame accepts valid data frames", {
  # Standard data frame
  expect_invisible(check_data_frame(data.frame(x = 1, y = 2)))
  # Tibble
  expect_invisible(check_data_frame(tibble::tibble(x = 1, y = 2)))
})

test_that("check_data_frame rejects NULL", {
  expect_error(check_data_frame(NULL), "must be a data frame, not.*NULL")
})

test_that("check_data_frame rejects non-data-frame types", {
  # Character vector
  expect_error(check_data_frame("not a dataframe"), "must be a data frame, not.*character")
  # Numeric vector
  expect_error(check_data_frame(c(1, 2, 3)), "must be a data frame, not.*numeric")
  # List (not a data frame)
  expect_error(check_data_frame(list(x = 1)), "must be a data frame, not.*list")
  # Matrix
  expect_error(check_data_frame(matrix(1:4, 2, 2)), "must be a data frame, not.*matrix")
})

test_that("check_data_frame rejects empty data frames (0 rows)", {
  expect_error(check_data_frame(data.frame(x = character(0))), "must have at least one row")
})

test_that("check_data_frame reports the correct argument name", {
  expect_error(check_data_frame(NULL), "data")
  expect_error(check_data_frame(NULL, arg_name = "my_table"), "my_table")
})

# ===========================================================================
# Tests for check_loci
# ===========================================================================

test_that("check_loci accepts valid locus vectors", {
  # Single locus
  expect_invisible(check_loci("HLA-A"))
  # Multiple loci
  expect_invisible(check_loci(c("HLA-A", "HLA-B", "HLA-DRB1")))
  # DRB3/4/5 combined locus
  expect_invisible(check_loci("HLA-DRB3/4/5"))
})

test_that("check_loci rejects NULL", {
  expect_error(check_loci(NULL), "must be a character vector of locus names, not.*NULL")
})

test_that("check_loci rejects non-character types", {
  # Numeric input
  expect_error(check_loci(1), "must be a character vector, not.*numeric")
  # Logical input
  expect_error(check_loci(TRUE), "must be a character vector, not.*logical")
})

test_that("check_loci rejects zero-length character vector", {
  expect_error(check_loci(character(0)), "must have length >= 1, not 0")
})

# ===========================================================================
# Tests for check_logical_flag
# ===========================================================================

test_that("check_logical_flag accepts TRUE and FALSE", {
  expect_invisible(check_logical_flag(TRUE, "my_flag"))
  expect_invisible(check_logical_flag(FALSE, "my_flag"))
})

test_that("check_logical_flag rejects NULL", {
  expect_error(check_logical_flag(NULL, "my_flag"), "must be.*TRUE.*or.*FALSE")
})

test_that("check_logical_flag rejects NA", {
  expect_error(check_logical_flag(NA, "my_flag"), "must be.*TRUE.*or.*FALSE")
})

test_that("check_logical_flag rejects non-logical types", {
  # String "TRUE"
  expect_error(check_logical_flag("TRUE", "my_flag"), "must be.*TRUE.*or.*FALSE")
  # Numeric 1
  expect_error(check_logical_flag(1, "my_flag"), "must be.*TRUE.*or.*FALSE")
})

test_that("check_logical_flag rejects logical vectors of length > 1", {
  expect_error(check_logical_flag(c(TRUE, FALSE), "my_flag"), "must be.*TRUE.*or.*FALSE")
})

test_that("check_logical_flag reports the correct argument name", {
  expect_error(check_logical_flag(NULL, "keep_suffix"), "keep_suffix")
})

# ===========================================================================
# Tests for check_homozygous_count
# ===========================================================================

test_that("check_homozygous_count accepts 1 and 2", {
  expect_invisible(check_homozygous_count(1))
  expect_invisible(check_homozygous_count(2))
})

test_that("check_homozygous_count rejects NULL", {
  expect_error(check_homozygous_count(NULL), "must be.*1.*or.*2")
})

test_that("check_homozygous_count rejects invalid values", {
  # Zero
  expect_error(check_homozygous_count(0), "must be.*1.*or.*2")
  # Three
  expect_error(check_homozygous_count(3), "must be.*1.*or.*2")
  # Negative
  expect_error(check_homozygous_count(-1), "must be.*1.*or.*2")
})

test_that("check_homozygous_count rejects vectors of length > 1", {
  expect_error(check_homozygous_count(c(1, 2)), "must be.*1.*or.*2")
})

# ===========================================================================
# Tests for check_fields
# ===========================================================================

test_that("check_fields accepts integers 1 through 4", {
  expect_invisible(check_fields(1))
  expect_invisible(check_fields(2))
  expect_invisible(check_fields(3))
  expect_invisible(check_fields(4))
})

test_that("check_fields rejects NULL", {
  expect_error(check_fields(NULL), "must be an integer between 1 and 4")
})

test_that("check_fields rejects out-of-range values", {
  # Zero
  expect_error(check_fields(0), "must be an integer between 1 and 4")
  # Five
  expect_error(check_fields(5), "must be an integer between 1 and 4")
  # Negative
  expect_error(check_fields(-1), "must be an integer between 1 and 4")
})

test_that("check_fields rejects non-numeric types", {
  # String that doesn't coerce to a valid value
  expect_error(check_fields("abc"), "must be an integer between 1 and 4")
})

test_that("check_fields rejects vectors of length > 1", {
  expect_error(check_fields(c(1, 2)), "must be an integer between 1 and 4")
})

# ===========================================================================
# Tests for check_molecular_gl_string
# ===========================================================================

test_that("check_molecular_gl_string accepts valid molecular GL strings", {
  expect_invisible(check_molecular_gl_string("HLA-A*01:01+HLA-A*02:01"))
  expect_invisible(check_molecular_gl_string("HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"))
  expect_invisible(check_molecular_gl_string(c(
    "HLA-A*01:01+HLA-A*02:01",
    "HLA-A*03:01+HLA-A*24:02"
  )))
  # Null-suffix alleles still contain '*'
  expect_invisible(check_molecular_gl_string("HLA-A*01:01:02N+HLA-A*02:01"))
  # Embedded NA is allowed (handled downstream)
  expect_invisible(check_molecular_gl_string(c("HLA-A*01:01", NA_character_)))
  # Bare NA is allowed
  expect_invisible(check_molecular_gl_string(NA))
})

test_that("check_molecular_gl_string rejects serologic GL strings", {
  expect_error(
    check_molecular_gl_string("HLA-A1+HLA-A2"),
    "must use molecular"
  )
  expect_error(
    check_molecular_gl_string("HLA-DR52"),
    "must use molecular"
  )
  # Mixed molecular + serologic inside one GL string is also rejected
  expect_error(
    check_molecular_gl_string("HLA-A*01:01+HLA-A*02:01^HLA-DR52"),
    "HLA-DR52"
  )
})

test_that("check_molecular_gl_string reports the offending element index and token", {
  gl <- c("HLA-A*01:01+HLA-A*02:01", "HLA-A*03:01+HLA-DR52")
  expect_error(
    check_molecular_gl_string(gl),
    "Element 2.*HLA-DR52"
  )
})

test_that("check_molecular_gl_string inherits base gl_string checks", {
  # NULL and non-character inputs are still rejected via check_gl_string()
  expect_error(check_molecular_gl_string(NULL), "must be a character vector, not.*NULL")
  expect_error(check_molecular_gl_string(123), "must be a character vector, not.*numeric")
  expect_error(check_molecular_gl_string(character(0)), "must have length >= 1")
})
