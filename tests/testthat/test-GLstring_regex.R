library(testthat)
library(stringr)

test_that("GLstring_regex correctly formats HLA alleles to regex patterns", {
  # Basic two-field alleles: left boundary, optional prefix, escaped base, optional
  # consumed fields and suffix, right boundary lookahead.
  left <- "(?:(?<=[\\?\\^\\|\\+\\~/])|^)(HLA-)?"
  right <- "(?=(\\?|\\^|\\||\\+|\\~|/|$))"
  expect_equal(GLstring_regex("HLA-A*02:01"), paste0(left, "A\\*02:01(:\\d+)*[NQLSCAGP]?", right))
  expect_equal(GLstring_regex("HLA-B*07:02"), paste0(left, "B\\*07:02(:\\d+)*[NQLSCAGP]?", right))
  # Multi-character locus name.
  expect_equal(GLstring_regex("HLA-DRB1*03:01"), paste0(left, "DRB1\\*03:01(:\\d+)*[NQLSCAGP]?", right))
  # An allele carrying an expression suffix: the suffix floats after any number of additional fields.
  expect_equal(GLstring_regex("HLA-A*01:01N"), paste0(left, "A\\*01:01(:\\d+)*N", right))
  # A G group name gets the same floating treatment.
  expect_equal(GLstring_regex("HLA-A*01:01G"), paste0(left, "A\\*01:01(:\\d+)*G", right))
  # An allele without the "HLA-" prefix produces the identical pattern.
  expect_equal(GLstring_regex("A*02:01"), GLstring_regex("HLA-A*02:01"))
})

test_that("GLstring_regex errors without a locus designation", {
  # A bare field value carries no locus, so it cannot be searched safely.
  expect_error(GLstring_regex("02:01"))
  expect_error(GLstring_regex("*02:01"))
})

test_that("GLstring_regex handles vector input", {
  # Should accept and process a vector of alleles, including a mix of bare and suffixed queries.
  alleles <- c("HLA-A*02:01", "HLA-B*07:02", "HLA-C*04:01N", "HLA-A*01:01G")
  result <- GLstring_regex(alleles)

  # Should return a vector of the same length.
  expect_length(result, 4)
  # Each element should be a valid regex string.
  expect_true(all(grepl("\\(\\?=", result)))
  # Suffixed queries take the floating-suffix arm; bare queries take the optional-suffix arm.
  expect_true(grepl("\\[NQLSCAGP\\]\\?", result[1], fixed = FALSE))
  expect_true(grepl("(:\\d+)*N", result[3], fixed = TRUE))
  expect_true(grepl("(:\\d+)*G", result[4], fixed = TRUE))
})

test_that("GLstring_regex produces patterns that match correctly in GL Strings", {
  # Set up a GL String with multiple alleles.
  gl <- "HLA-A*02:01:01+HLA-A*68:01^HLA-B*07:01+HLA-B*15:01"

  # Two-field allele should match the four-field allele (fewer fields match more).
  pattern_a <- GLstring_regex("HLA-A*02:01")
  expect_true(str_detect(gl, pattern_a))

  # Full three-field allele should also match.
  pattern_a3 <- GLstring_regex("HLA-A*02:01:01")
  expect_true(str_detect(gl, pattern_a3))

  # A non-present allele should not match.
  pattern_missing <- GLstring_regex("HLA-A*03:01")
  expect_false(str_detect(gl, pattern_missing))
})

test_that("GLstring_regex prevents partial field matching", {
  # The regex should NOT match "HLA-A*02:149:01" when searching for "HLA-A*02:14".
  gl_with_long_allele <- "HLA-A*02:149:01"
  pattern <- GLstring_regex("HLA-A*02:14")
  expect_false(str_detect(gl_with_long_allele, pattern))

  # But "HLA-A*02:14" should match itself at end of string.
  expect_true(str_detect("HLA-A*02:14", pattern))

  # Partial fields never match, whether or not a suffix is involved.
  expect_false(str_detect("HLA-A*01:010:01", GLstring_regex("HLA-A*01:01")))
  expect_false(str_detect("HLA-A*01:010G", GLstring_regex("HLA-A*01:01")))
  expect_false(str_detect("HLA-A*01:010:01G", GLstring_regex("HLA-A*01:01G")))
})

test_that("GLstring_regex matches alleles at GL String boundaries", {
  # Allele at the end of a GL String (followed by $).
  gl <- "HLA-A*01:01+HLA-A*02:01"
  pattern <- GLstring_regex("HLA-A*02:01")
  expect_true(str_detect(gl, pattern))

  # Allele before a "^" locus separator.
  gl2 <- "HLA-A*02:01^HLA-B*07:02"
  expect_true(str_detect(gl2, pattern))

  # Allele before a "+" gene copy separator.
  gl3 <- "HLA-A*02:01+HLA-A*03:01"
  expect_true(str_detect(gl3, pattern))

  # Allele before a "/" allele ambiguity separator.
  gl4 <- "HLA-A*02:01/HLA-A*02:06"
  expect_true(str_detect(gl4, pattern))

  # Allele before a "|" genotype ambiguity separator.
  gl5 <- "HLA-A*02:01|HLA-A*02:01+HLA-A*03:01"
  expect_true(str_detect(gl5, pattern))
})

test_that("GLstring_regex handles high-resolution and rare loci", {
  # Four-field allele should match itself in a GL String context.
  result_4f <- GLstring_regex("HLA-A*02:01:01:01")
  expect_true(str_detect("HLA-A*02:01:01:01+HLA-A*03:01", result_4f))

  # DQA1 locus.
  result_dqa <- GLstring_regex("HLA-DQA1*05:01")
  expect_true(str_detect("HLA-DQA1*05:01+HLA-DQA1*01:02", result_dqa))

  # DPB1 locus.
  result_dpb <- GLstring_regex("HLA-DPB1*04:01")
  expect_true(str_detect("HLA-DPB1*04:01+HLA-DPB1*02:01", result_dpb))
})

test_that("bare queries match alleles carrying expression suffixes (#43)", {
  # An unsuffixed query matches the allele regardless of expression status.
  expect_true(str_detect("HLA-A*01:01:03N", GLstring_regex("HLA-A*01:01")))
  expect_true(str_detect("HLA-A*01:01N", GLstring_regex("HLA-A*01:01")))
  for (suffix in c("N", "Q", "L", "S", "C", "A")) {
    expect_true(str_detect(str_c("HLA-A*24:09", suffix), GLstring_regex("HLA-A*24:09")))
  }

  # Mid-string, not just at the end.
  expect_true(str_detect("HLA-A*01:01N+HLA-A*02:01", GLstring_regex("HLA-A*01:01")))
  expect_true(str_detect("HLA-A*01:01N/HLA-A*01:02", GLstring_regex("HLA-A*01:01")))
})

test_that("suffixed queries match only that suffix, at the same or higher resolution (#43)", {
  pattern_n <- GLstring_regex("HLA-A*01:01N")

  # Exact match and higher-resolution match: HLA_truncate("HLA-A*01:01:03N", 2) gives
  # "HLA-A*01:01N", and that truncated name must find the allele it came from.
  expect_true(str_detect("HLA-A*01:01N", pattern_n))
  expect_true(str_detect("HLA-A*01:01:03N", pattern_n))
  expect_true(str_detect("HLA-A*01:01:02N+HLA-A*02:01", pattern_n))

  # An expressed allele must not answer a null query.
  expect_false(str_detect("HLA-A*01:01:03", pattern_n))
  # One suffix must not answer a query for another.
  expect_false(str_detect("HLA-A*01:01:03Q", pattern_n))
})

test_that("bare queries match G and P group names; G/P queries require the letter (#43)", {
  # A G group contains the allele in its name, so the allele finds the group.
  expect_true(str_detect("HLA-A*01:01:01G", GLstring_regex("HLA-A*01:01:01")))
  expect_true(str_detect("HLA-A*01:01:01G", GLstring_regex("HLA-A*01:01")))
  expect_true(str_detect("HLA-A*01:01G", GLstring_regex("HLA-A*01:01")))
  expect_true(str_detect("HLA-A*24:02P", GLstring_regex("HLA-A*24:02")))

  # A truncated G group name finds its source: HLA_truncate("HLA-A*01:01:01G", 2,
  # keep_G_P_group = TRUE) gives "HLA-A*01:01G".
  expect_true(str_detect("HLA-A*01:01:01G", GLstring_regex("HLA-A*01:01G")))
  expect_true(str_detect("HLA-A*01:01:01G+HLA-A*02:01", GLstring_regex("HLA-A*01:01G")))

  # A G/P query requires the G/P in the GL String: a group query is not answered by a
  # bare allele, and G and P never answer each other.
  expect_false(str_detect("HLA-A*01:01:01", GLstring_regex("HLA-A*01:01:01G")))
  expect_false(str_detect("HLA-A*24:02", GLstring_regex("HLA-A*24:02P")))
  expect_false(str_detect("HLA-A*01:01:01G", GLstring_regex("HLA-A*01:01P")))
})

test_that("the match is the full allele as it appears in the GL String (#43)", {
  gl <- "HLA-A*01:01:01+HLA-A*02:02:02N"

  # A lower-resolution query extracts the full allele found, not the query.
  expect_equal(str_extract(gl, GLstring_regex("HLA-A*01:01")), "HLA-A*01:01:01")
  expect_equal(str_extract(gl, GLstring_regex("HLA-A*02:02N")), "HLA-A*02:02:02N")
  expect_equal(str_extract(gl, GLstring_regex("HLA-A*02:02")), "HLA-A*02:02:02N")
  expect_equal(
    str_extract("HLA-A*01:01:01G+HLA-B*07:02", GLstring_regex("HLA-A*01:01")),
    "HLA-A*01:01:01G"
  )

  # An exact-name query extracts itself.
  expect_equal(str_extract("HLA-A*01:01", GLstring_regex("HLA-A*01:01")), "HLA-A*01:01")

  # Because the whole allele is consumed, replacement replaces the whole allele —
  # no dangling fields or suffixes.
  expect_equal(
    str_replace("HLA-A*01:01N+HLA-A*02:01", GLstring_regex("HLA-A*01:01"), "XXX"),
    "XXX+HLA-A*02:01"
  )
  expect_equal(
    str_replace("HLA-A*01:01:02+HLA-A*02:01", GLstring_regex("HLA-A*01:01"), "XXX"),
    "XXX+HLA-A*02:01"
  )
  expect_equal(
    str_replace("HLA-A*01:01:02N+HLA-A*02:01", GLstring_regex("HLA-A*01:01N"), "XXX"),
    "XXX+HLA-A*02:01"
  )
  expect_equal(
    str_replace("HLA-A*01:01:01G+HLA-A*02:01", GLstring_regex("HLA-A*01:01G"), "XXX"),
    "XXX+HLA-A*02:01"
  )
})

test_that("serologic queries are unaffected by suffix handling", {
  # A serologic name ends in a digit, so it takes the bare arm and matches itself only.
  pattern <- GLstring_regex("HLA-A2")
  expect_true(str_detect("HLA-A2^HLA-B7", pattern))
  expect_false(str_detect("HLA-A24^HLA-B7", pattern))
})

test_that("GLstring_regex handles non-HLA loci such as MICA, MICB and KIR", {
  # MICA alleles carry no "HLA-" prefix; the prefix handling must be a no-op.
  expect_true(str_detect("MICA*008:01", GLstring_regex("MICA*008:01")))
  expect_true(str_detect("MICA*008:01:01", GLstring_regex("MICA*008:01")))
  expect_true(str_detect("MICA*008", GLstring_regex("MICA*008")))

  # In a mixed GL String alongside prefixed HLA alleles.
  gl_mixed <- "HLA-A*02:01+HLA-A*68:01^MICA*008:01:01+MICA*002:01"
  expect_true(str_detect(gl_mixed, GLstring_regex("MICA*008:01")))
  expect_true(str_detect(gl_mixed, GLstring_regex("HLA-A*02:01")))
  expect_false(str_detect(gl_mixed, GLstring_regex("MICA*004")))

  # The match is the full MICA allele as written.
  expect_equal(str_extract(gl_mixed, GLstring_regex("MICA*008")), "MICA*008:01:01")

  # Field boundaries hold for MICA exactly as for HLA loci.
  expect_false(str_detect("MICA*088:01", GLstring_regex("MICA*008")))
  expect_false(str_detect("MICA*008:011", GLstring_regex("MICA*008:01")))

  # An HLA-A query must not match inside a MICA name, and a MICA query must not
  # be answered by an HLA-A allele with the same field values.
  expect_false(str_detect("MICA*008:01+MICA*002:01", GLstring_regex("A*008:01")))
  expect_false(str_detect("HLA-A*008:01", GLstring_regex("MICA*008:01")))

  # Expression suffix logic carries over: the A inside "MICA" is never read as
  # a suffix (a suffix requires a digit immediately before it), and a suffixed
  # MICA query matches only its own suffix at the same or higher resolution.
  expect_true(str_detect("MICA*012:01:02N", GLstring_regex("MICA*012:01N")))
  expect_false(str_detect("MICA*012:01:02", GLstring_regex("MICA*012:01N")))
  expect_true(str_detect("MICA*012:01:02N", GLstring_regex("MICA*012:01")))

  # KIR locus names can themselves end in a letter (KIR2DL5A); trailing digits
  # in the allele keep the suffix detector from misfiring on the locus name.
  expect_true(str_detect("KIR2DL5A*0010101+KIR2DL5B*0020101", GLstring_regex("KIR2DL5A*0010101")))
  expect_false(str_detect("KIR2DL5B*0010101", GLstring_regex("KIR2DL5A*0010101")))
})

test_that("GLstring_regex validates inputs", {
  # NA should still work through check_gl_string (allows NA).
  # But should error because no locus is detected in NA.
  expect_error(GLstring_regex(NA))
  # Empty string should error (no locus designation).
  expect_error(GLstring_regex(""))
  # Mixed valid/invalid should error.
  expect_error(GLstring_regex(c("HLA-A*02:01", "02:01")))
})

test_that("the HLA- prefix is optional in both the allele and the GL String", {
  # All four convention combinations match.
  expect_true(str_detect("HLA-A*02:01:01+HLA-A*68:01", GLstring_regex("HLA-A*02:01")))
  expect_true(str_detect("A*02:01:01+A*68:01", GLstring_regex("HLA-A*02:01")))
  expect_true(str_detect("HLA-A*02:01:01+HLA-A*68:01", GLstring_regex("A*02:01")))
  expect_true(str_detect("A*02:01:01+A*68:01", GLstring_regex("A*02:01")))

  # Serologic names work in both conventions too.
  expect_true(str_detect("A2^B27", GLstring_regex("A2")))
  expect_true(str_detect("HLA-A2^HLA-B27", GLstring_regex("A2")))
  expect_false(str_detect("A24^B27", GLstring_regex("A2")))

  # The left boundary stops a prefix-less allele from matching inside a longer
  # locus name that happens to end with the same letters.
  expect_false(str_detect("MICA*008:01+MICA*002:01", GLstring_regex("A*008:01")))
  expect_false(str_detect("MICB*005:02", GLstring_regex("B*005:02")))
  expect_false(str_detect("HLA-DQA1*01:01", GLstring_regex("A1*01:01")))

  # Mid-string, every delimiter satisfies the left boundary.
  expect_true(str_detect("B*07:02/A*02:01", GLstring_regex("A*02:01")))
  expect_true(str_detect("B*07:02|A*02:01~C*01:02", GLstring_regex("A*02:01")))
  expect_true(str_detect("B*07:02^A*02:01+A*68:01", GLstring_regex("A*02:01")))

  # The match is still the allele as written in the GL String, in either
  # convention, so extraction and replacement behave.
  expect_equal(str_extract("HLA-A*02:01:01+HLA-A*68:01", GLstring_regex("A*02:01")), "HLA-A*02:01:01")
  expect_equal(str_extract("A*02:01:01+A*68:01", GLstring_regex("HLA-A*02:01")), "A*02:01:01")
  expect_equal(
    str_replace("A*02:01:01+A*68:01", GLstring_regex("HLA-A*02:01"), "XXX"),
    "XXX+A*68:01"
  )

  # Suffix and G/P behavior carries over to prefix-less queries.
  expect_true(str_detect("A*01:01:03N", GLstring_regex("A*01:01N")))
  expect_false(str_detect("A*01:01:03", GLstring_regex("A*01:01N")))
  expect_true(str_detect("A*01:01:01G", GLstring_regex("A*01:01G")))
  expect_true(str_detect("A*24:09N+A*02:01", GLstring_regex("A*24:09")))
})
