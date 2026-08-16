library(testthat)
library(stringr)

test_that("HLA_validate correctly validates and cleans HLA alleles", {
  expect_equal(HLA_validate("HLA-A2"), "HLA-A2")
  expect_equal(HLA_validate("A*02:01:01:01N"), "A*02:01:01:01N")
  expect_equal(HLA_validate("A*02:01:01N"), "A*02:01:01N")
  expect_equal(HLA_validate("HLA-DRB1*02:03novel"), "HLA-DRB1*02:03")
  expect_equal(HLA_validate("HLA-DQB1*03:01v"), "HLA-DQB1*03:01")
  expect_equal(HLA_validate("HLA-DRB1*02:03P"), "HLA-DRB1*02:03P")
  expect_equal(HLA_validate("HLA-DPB1*04:01:01G"), "HLA-DPB1*04:01:01G")
  expect_equal(HLA_validate("2"), "2")
  expect_equal(HLA_validate(2), "2")
  expect_equal(HLA_validate("B27"), "B27")
  expect_equal(HLA_validate("A*010101"), "A*010101")
  expect_equal(HLA_validate("-"), NA_character_)
  expect_equal(HLA_validate("blank"), NA_character_)
})

test_that("HLA_validate handles multi-allele values per take_first_allele", {
  # The function cleans one allele per value. The default preserves the
  # historical behavior — a GL String is silently reduced to its first
  # allele — while take_first_allele = FALSE catches malformed multi-allele
  # input with an error instead of truncating it.
  expect_silent(out <- HLA_validate("HLA-A*01:01+HLA-A*02:01"))
  expect_equal(out, "HLA-A*01:01")
  expect_equal(HLA_validate("HLA-A*01:01/HLA-A*01:02"), "HLA-A*01:01")
  expect_error(
    HLA_validate("HLA-A*01:01+HLA-A*02:01", take_first_allele = FALSE),
    "GL String delimiters"
  )
  expect_error(
    HLA_validate("HLA-A*01:01/HLA-A*01:02", take_first_allele = FALSE),
    "GL String delimiters"
  )
  # Single-allele values, including NA, pass the strict check.
  expect_silent(HLA_validate(c("A*02:01", "B27", NA), take_first_allele = FALSE))
  expect_error(HLA_validate("A*02:01", take_first_allele = "yes"), "TRUE.*or.*FALSE")
})

test_that("HLA_validate is vectorized and pins NA, empty, and field-limit behavior", {
  expect_equal(
    HLA_validate(c("A*02:01", NA, "", "blank")),
    c("A*02:01", NA, NA, NA)
  )
  # Fields beyond the four-field WHO maximum are dropped.
  expect_equal(HLA_validate("HLA-A*01:01:01:01:01"), "HLA-A*01:01:01:01")
})
