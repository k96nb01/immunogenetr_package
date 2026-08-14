library(testthat)

test_that("GLstring_drop_non_expressed removes alleles at every structural level", {
  # An allele ambiguity list narrows, a gene copy with no expressed alleles collapses,
  # and a locus with no expressed alleles disappears along with its "^".
  gl <- "HLA-A*01:01N+HLA-A*02:01^HLA-B*07:02/HLA-B*07:02N+HLA-B*08:01^HLA-C*01:02N+HLA-C*03:04N"
  expect_equal(
    GLstring_drop_non_expressed(gl),
    "HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"
  )

  # A locus vanishing from the front of the GL String leaves no dangling delimiter.
  expect_equal(
    GLstring_drop_non_expressed("HLA-A*01:01N+HLA-A*02:01N^HLA-B*07:02+HLA-B*08:01"),
    "HLA-B*07:02+HLA-B*08:01"
  )

  # A GL String with nothing to remove passes through unchanged.
  expect_equal(
    GLstring_drop_non_expressed("HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"),
    "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"
  )
})

test_that("GLstring_drop_non_expressed handles the full GL String delimiter set", {
  # Genotype ambiguity ("|"): a haplotype member is removed within one alternative.
  expect_equal(
    GLstring_drop_non_expressed("HLA-A*01:01N~HLA-B*07:02|HLA-A*02:01~HLA-B*08:01"),
    "HLA-B*07:02|HLA-A*02:01~HLA-B*08:01"
  )

  # Possible gene location ("?").
  expect_equal(
    GLstring_drop_non_expressed("HLA-DRB3*01:01N?HLA-DRB4*01:03"),
    "HLA-DRB4*01:03"
  )
})

test_that("GLstring_drop_non_expressed returns NA when nothing survives", {
  expect_equal(GLstring_drop_non_expressed("HLA-A*01:01N"), NA_character_)
  expect_equal(GLstring_drop_non_expressed("HLA-A*01:01N+HLA-A*02:01N"), NA_character_)
})

test_that("GLstring_drop_non_expressed is vectorized and preserves NA input", {
  input <- c(
    "HLA-A*01:01N+HLA-A*02:01",
    "HLA-A*01:01N",
    NA,
    "HLA-B*07:02+HLA-B*08:01"
  )
  expect_equal(
    GLstring_drop_non_expressed(input),
    c("HLA-A*02:01", NA, NA, "HLA-B*07:02+HLA-B*08:01")
  )
})

test_that("the suffixes argument controls which expression variants are removed", {
  # Default keeps L, Q and A.
  expect_equal(
    GLstring_drop_non_expressed("HLA-A*24:02Q+HLA-A*01:01"),
    "HLA-A*24:02Q+HLA-A*01:01"
  )
  expect_equal(
    GLstring_drop_non_expressed("HLA-A*30:14L+HLA-A*01:01"),
    "HLA-A*30:14L+HLA-A*01:01"
  )

  # Default removes N, S and C.
  expect_equal(
    GLstring_drop_non_expressed("HLA-A*01:01N+HLA-A*23:38S/HLA-A*02:01"),
    "HLA-A*02:01"
  )

  # Narrowed to "N" only, an S allele survives.
  expect_equal(
    GLstring_drop_non_expressed("HLA-A*01:01N+HLA-A*23:38S", suffixes = "N"),
    "HLA-A*23:38S"
  )

  # Widened to include Q.
  expect_equal(
    GLstring_drop_non_expressed("HLA-A*24:02Q+HLA-A*01:01", suffixes = c("N", "Q")),
    "HLA-A*01:01"
  )
})

test_that("GLstring_drop_non_expressed does not remove G/P group names or bare alleles", {
  # G and P are groups, not expression variants; names ending in those letters stay.
  expect_equal(
    GLstring_drop_non_expressed("HLA-A*01:01:01G+HLA-A*24:02P"),
    "HLA-A*01:01:01G+HLA-A*24:02P"
  )
})

test_that("GLstring_drop_non_expressed validates the suffixes argument", {
  # G and P are rejected: they are allele groups, not expression variants.
  expect_error(GLstring_drop_non_expressed("HLA-A*01:01N", suffixes = "G"))
  expect_error(GLstring_drop_non_expressed("HLA-A*01:01N", suffixes = "P"))
  # Unknown letters, empty selections, and non-character input are rejected.
  expect_error(GLstring_drop_non_expressed("HLA-A*01:01N", suffixes = "X"))
  expect_error(GLstring_drop_non_expressed("HLA-A*01:01N", suffixes = character(0)))
  expect_error(GLstring_drop_non_expressed("HLA-A*01:01N", suffixes = 1))
  expect_error(GLstring_drop_non_expressed("HLA-A*01:01N", suffixes = c("N", NA)))
})
