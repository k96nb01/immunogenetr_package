library(testthat)
library(dplyr)
library(stringr)
library(xml2)
library(tibble)
library(purrr)
library(tidyr)

test_that("read_HML correctly extracts GL Strings from HML_1.hml", {
  # Load the first test HML file bundled with the package.
  HML_1 <- system.file("extdata", "HML_1.hml", package = "immunogenetr")

  if (file.exists(HML_1)) {
    result <- read_HML(HML_1)

    # Should return a tibble.
    expect_s3_class(result, "tbl_df")
    # Should have the expected columns.
    expect_true("sampleID" %in% colnames(result))
    expect_true("GL_string" %in% colnames(result))
    # Should extract rows.
    expect_gt(nrow(result), 0)
    # All GL Strings should contain "HLA-" prefix.
    expect_true(all(str_detect(result$GL_string, "HLA-")))
    # HML_1 has 5 samples.
    expect_equal(nrow(result), 5)
    # Sample IDs should be present and non-NA.
    expect_false(any(is.na(result$sampleID)))
  } else {
    skip("HML_1.hml test file does not exist.")
  }
})

test_that("read_HML correctly extracts GL Strings from hml_2.hml", {
  # Load the second test HML file with a slightly different format.
  HML_2 <- system.file("extdata", "hml_2.hml", package = "immunogenetr")

  if (file.exists(HML_2)) {
    result <- read_HML(HML_2)

    # Should return a tibble with the same structure.
    expect_s3_class(result, "tbl_df")
    expect_true(all(c("sampleID", "GL_string") %in% colnames(result)))
    expect_gt(nrow(result), 0)
    # hml_2 also has 5 samples.
    expect_equal(nrow(result), 5)
    # All GL Strings should contain "HLA-".
    expect_true(all(str_detect(result$GL_string, "HLA-")))
  } else {
    skip("hml_2.hml test file does not exist.")
  }
})

test_that("read_HML produces valid GL Strings with locus separators", {
  # Verify that the output GL Strings have proper "^" locus separators.
  HML_1 <- system.file("extdata", "HML_1.hml", package = "immunogenetr")

  if (file.exists(HML_1)) {
    result <- read_HML(HML_1)

    # Each GL String should contain "^" separating loci.
    expect_true(all(str_detect(result$GL_string, "\\^")))
    # Each GL String should contain "+" separating gene copies.
    expect_true(all(str_detect(result$GL_string, "\\+")))
  } else {
    skip("HML_1.hml test file does not exist.")
  }
})

test_that("read_HML results are consistent between both HML files", {
  # Both HML files represent the same 5 samples; GL Strings should align.
  HML_1 <- system.file("extdata", "HML_1.hml", package = "immunogenetr")
  HML_2 <- system.file("extdata", "hml_2.hml", package = "immunogenetr")

  if (file.exists(HML_1) && file.exists(HML_2)) {
    result_1 <- read_HML(HML_1)
    result_2 <- read_HML(HML_2)

    # Both should have the same number of samples.
    expect_equal(nrow(result_1), nrow(result_2))
  } else {
    skip("HML test files do not exist.")
  }
})

test_that("read_HML errors on non-existent file", {
  # Should produce an error for a file that doesn't exist.
  expect_error(read_HML("nonexistent_file.hml"))
})

test_that("read_HML errors on invalid XML", {
  # Create a temporary file with invalid XML content.
  bad_file <- tempfile(fileext = ".hml")
  writeLines("This is not valid XML content <><>", bad_file)

  expect_error(read_HML(bad_file))
  # Clean up.
  unlink(bad_file)
})

test_that("read_HML handles HML files without XML namespace", {
  # Create a minimal HML file with no namespace declaration,
  # which exercises the else branch for unqualified XPath queries.
  no_ns_file <- tempfile(fileext = ".hml")
  writeLines(c(
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<hml>',
    '  <sample id="DONOR001">',
    '    <typing gene-family="HLA" gene="HLA-A" allele-db="IMGT/HLA" allele-version="3.25.0">',
    '      <allele-assignment allele-db="IMGT/HLA" allele-version="3.25.0">',
    '        <glstring>HLA-A*01:01+HLA-A*02:01</glstring>',
    '      </allele-assignment>',
    '    </typing>',
    '    <typing gene-family="HLA" gene="HLA-B" allele-db="IMGT/HLA" allele-version="3.25.0">',
    '      <allele-assignment allele-db="IMGT/HLA" allele-version="3.25.0">',
    '        <glstring>HLA-B*07:02+HLA-B*08:01</glstring>',
    '      </allele-assignment>',
    '    </typing>',
    '  </sample>',
    '</hml>'
  ), no_ns_file)

  result <- read_HML(no_ns_file)

  # Should return a tibble with the expected structure.
  expect_s3_class(result, "tbl_df")
  expect_true(all(c("sampleID", "GL_string") %in% colnames(result)))
  # Should find 1 sample.
  expect_equal(nrow(result), 1)
  # GL String should contain both loci joined by "^".
  expect_true(str_detect(result$GL_string, "HLA-A"))
  expect_true(str_detect(result$GL_string, "HLA-B"))
  expect_true(str_detect(result$GL_string, "\\^"))
  # Sample ID should match.
  expect_equal(result$sampleID, "DONOR001")

  # Clean up.
  unlink(no_ns_file)
})

test_that("read_HML validates input", {
  # NULL input should error.
  expect_error(read_HML(NULL))
  # Numeric input should error.
  expect_error(read_HML(123))
})

test_that("read_HML extracts exact GL String content from hml_2.hml", {
  # Pins the exact output for one known sample (verified against the file's own
  # <glstring> nodes) so a rewrite of the XML traversal or locus-combining logic
  # cannot silently reorder loci or alter allele content.
  HML_2 <- system.file("extdata", "hml_2.hml", package = "immunogenetr")

  if (file.exists(HML_2)) {
    result <- read_HML(HML_2)

    # Sample IDs come out in document order.
    expect_equal(
      result$sampleID,
      c("22-03848", "22-03849", "22-03850", "22-03851", "22-03852")
    )
    # Sample 22-03848: each source <glstring> node in document order, joined
    # with "^". Includes a genotype ambiguity ("|") at HLA-DPA1 that must pass
    # through unaltered.
    expect_equal(
      result$GL_string[result$sampleID == "22-03848"],
      "HLA-A*33:03:01+HLA-A*34:02:01^HLA-B*14:01:01+HLA-B*44:03:02^HLA-C*07:06:01+HLA-C*08:02:01^HLA-DPA1*01:03:01+HLA-DPA1*03:05:01Q|HLA-DPA1*01:87Q+HLA-DPA1*03:01:01^HLA-DPB1*104:01:01+HLA-DPB1*584:01:02^HLA-DQA1*01:02:01+HLA-DQA1*04:01:02^HLA-DQB1*03:19:01+HLA-DQB1*06:09:01^HLA-DRB1*08:04:01+HLA-DRB1*13:02:01^HLA-DRB3*03:01:01+HLA-DRB3*03:01:01^HLA-E*01:01:01+HLA-E*01:03:01^HLA-F*01:01:02+HLA-F*01:02:01^HLA-G*01:01:09+HLA-G*01:04:01^HLA-H*02:08:01+HLA-H*02:11:01^MICA*004:01+MICA*008:04^MICB*002:01+MICB*005:02"
    )
  } else {
    skip("hml_2.hml test file does not exist.")
  }
})

test_that("read_HML extracts exact sample IDs from HML_1.hml", {
  # Pins the sample IDs (in document order) so ID extraction from the "id"
  # attribute can't silently change.
  HML_1 <- system.file("extdata", "HML_1.hml", package = "immunogenetr")

  if (file.exists(HML_1)) {
    result <- read_HML(HML_1)
    expect_equal(
      result$sampleID,
      c(
        "22-03848-HLA-031722-AB-AlloSeq-EP", "22-03849-HLA-031722-AB-AlloSeq-EP",
        "22-03850-HLA-031722-AB-AlloSeq-EP", "22-03851-HLA-031722-AB-AlloSeq-EP",
        "22-03852-HLA-031722-AB-AlloSeq-EP"
      )
    )
  } else {
    skip("HML_1.hml test file does not exist.")
  }
})

test_that("read_HML combines same-locus glstring nodes with '+'", {
  # HML_duplicate_locus.hml puts each HLA-A allele in its own <glstring> node,
  # as some HML implementations do; the duplicate-locus logic must join
  # same-locus nodes with "+" into one gene-copy pair, while a node carrying a
  # "/" allele ambiguity passes through intact. Pins the combined output exactly.
  dup_file <- test_path("HML_duplicate_locus.hml")

  result <- read_HML(dup_file)

  expect_equal(result$sampleID, "DUP-LOCUS-001")
  expect_equal(
    result$GL_string,
    "HLA-A*01:01:01:01+HLA-A*02:01:01:01^HLA-B*07:02:01:01/HLA-B*07:02:01:03+HLA-B*08:01:01:01"
  )
})
