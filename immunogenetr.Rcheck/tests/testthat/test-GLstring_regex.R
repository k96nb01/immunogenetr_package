library(testthat)
library(stringr)

test_that("GLstring_regex correctly formats HLA alleles to regex patterns", {
  expect_equal(GLstring_regex("HLA-A*02:01"), "HLA-A\\*02:01(?=(\\?|\\^|\\||\\+|\\~|/|$))")
  expect_equal(GLstring_regex("HLA-B*07:02"), "HLA-B\\*07:02(?=(\\?|\\^|\\||\\+|\\~|/|$))")
  expect_equal(GLstring_regex("HLA-DRB1*03:01"), "HLA-DRB1\\*03:01(?=(\\?|\\^|\\||\\+|\\~|/|$))")
  expect_error(GLstring_regex("A*02:01"))
  expect_error(GLstring_regex("B27"))
})
