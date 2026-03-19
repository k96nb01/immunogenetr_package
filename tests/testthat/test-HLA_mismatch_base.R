library(testthat)
library(stringr)
library(dplyr)

test_that("HLA_mismatch_base correctly identifies mismatches", {
  GL_string_recip <- "HLA-A*02:01+HLA-A*03:01^HLA-B*07:02+HLA-B*08:01^HLA-DRB1*04:01+HLA-DRB1*07:01"
  GL_string_donor <- "HLA-A*01:01+HLA-A*03:01^HLA-B*07:02+HLA-B*44:02^HLA-DRB1*04:01+HLA-DRB1*13:01"
  loci <- c("HLA-A", "HLA-B", "HLA-DRB1")

  result_HvG <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, direction = "HvG")
  expect_equal(result_HvG, "HLA-A=HLA-A*01:01, HLA-B=HLA-B*44:02, HLA-DRB1=HLA-DRB1*13:01")

  result_GvH <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, direction = "GvH")
  expect_equal(result_GvH, "HLA-A=HLA-A*02:01, HLA-B=HLA-B*08:01, HLA-DRB1=HLA-DRB1*07:01")

  result_single_locus_HvG <- HLA_mismatch_base(GL_string_recip, GL_string_donor, "HLA-A", direction = "HvG")
  expect_equal(result_single_locus_HvG, "HLA-A*01:01")

  result_single_locus_GvH <- HLA_mismatch_base(GL_string_recip, GL_string_donor, "HLA-A", direction = "GvH")
  expect_equal(result_single_locus_GvH, "HLA-A*02:01")

  result_HvG_homo1 <- HLA_mismatch_base(GL_string_recip, GL_string_donor, loci, direction = "HvG", homozygous_count = 1)
  expect_equal(result_HvG_homo1, "HLA-A=HLA-A*01:01, HLA-B=HLA-B*44:02, HLA-DRB1=HLA-DRB1*13:01")

  expect_error(
    HLA_mismatch_base(c(GL_string_recip, GL_string_recip), GL_string_donor, loci, direction = "HvG"),
    "must be of equal length"
  )
})


test_that("DRB3/4/5 and DR51/52/53 absent on both sides", {
  recip <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"
  donor <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"

  loci_mol <- c("HLA-A", "HLA-DRB3/4/5")
  out_mol <- HLA_mismatch_base(recip, donor, loci_mol, direction = "HvG")
  expect_equal(out_mol, "HLA-A=NA, HLA-DRB3/4/5=NA")

  loci_ser <- c("HLA-A", "HLA-DR51/52/53")
  out_ser <- HLA_mismatch_base(recip, donor, loci_ser, direction = "HvG")
  expect_equal(out_ser, "HLA-A=NA, HLA-DR51/52/53=NA")
})


test_that("DRB3/4/5 is in one but not in the other", {
  recip <- "HLA-A*01:01+HLA-A*02:01^HLA-DRB3*01:01^HLA-DRB4*01:01"
  donor <- "HLA-A*01:01+HLA-A*02:01^HLA-DRB1*15:01+HLA-DRB1*07:01"

  out_mol <- HLA_mismatch_base(recip, donor, c("HLA-A", "HLA-DRB3/4/5"), direction = "HvG")
  expect_equal(out_mol, "HLA-A=NA, HLA-DRB3/4/5=NA")

  out_ser <- HLA_mismatch_base(recip, donor, c("HLA-A", "HLA-DR51/52/53"), direction = "HvG")
  expect_equal(out_ser, "HLA-A=NA, HLA-DR51/52/53=NA")
})


test_that("DRB51/52/53 is in one but not in the other", {
  recip <- "HLA-A*01:01+HLA-A*02:01^HLA-DR52^HLA-DR53"
  donor <- "HLA-A*01:01+HLA-A*02:01^HLA-DRB1*15:01+HLA-DRB1*07:01"

  out_ser <- HLA_mismatch_base(recip, donor, c("HLA-A", "HLA-DR51/52/53"), direction = "HvG")
  expect_equal(out_ser, "HLA-A=NA, HLA-DR51/52/53=NA")

  out_mol <- HLA_mismatch_base(recip, donor, c("HLA-A", "HLA-DRB3/4/5"), direction = "HvG")
  expect_equal(out_mol, "HLA-A=NA, HLA-DRB3/4/5=NA")
})


test_that("DRB3/4/5 or DR51/52/53 as the only tested allele", {
  recip <- "HLA-A*01:01+HLA-A*02:01^HLA-DR52^HLA-DR53"
  donor <- "HLA-A*01:01+HLA-A*02:01^HLA-DRB1*15:01+HLA-DRB1*07:01"

  out_mol <- HLA_mismatch_base(recip, donor, "HLA-DRB3/4/5", direction = "HvG")
  expect_true(is.na(out_mol))

  out_ser <- HLA_mismatch_base(recip, donor, "HLA-DR51/52/53", direction = "HvG")
  expect_true(is.na(out_ser))
})


test_that("Matching across DRB3/4/5 (molecular) and DR51/52/53 (serologic)", {
  recip <- "HLA-A*01:01+HLA-A*02:01^HLA-DRB3*01:01^HLA-DRB4*01:01"
  donor <- "HLA-A*01:01+HLA-A*02:01^HLA-DR52^HLA-DR53"

  out_mol <- HLA_mismatch_base(recip, donor, c("HLA-A", "HLA-DRB3/4/5"), direction = "HvG")
  expect_equal(out_mol, "HLA-A=NA, HLA-DRB3/4/5=HLA-DR52+HLA-DR53")

  out_ser <- HLA_mismatch_base(recip, donor, c("HLA-A", "HLA-DR51/52/53"), direction = "HvG")
  expect_equal(out_ser, "HLA-A=NA, HLA-DR51/52/53=HLA-DR52+HLA-DR53")
})

test_that("A genotype without any DRB3/4/5 alleles compared to a genotype with will have a mismatch", {
  recip <- "HLA-DRB1*01:01^HLA-DRB3*01:01^HLA-DRB4*01:01"
  donor <- "HLA-DRB1*01:01^HLA-B*15:01"

  mismatches <- HLA_mismatch_base(recip, donor, loci = "HLA-DRB3/4/5", direction = "GvH")
  expect_equal(mismatches, "HLA-DRB3*01:01+HLA-DRB4*01:01")

  no_mismatches <- HLA_mismatch_base(recip, donor, loci = "HLA-DRB3/4/5", direction = "HvG")
  expect_equal(no_mismatches, NA_character_)

  expect_error(
    HLA_mismatch_base(recip, donor, loci = "HLA-B", direction = "HvG"),
    "missing these loci"
  )

  recip <- "HLA-DR1^HLA-DR52^HLA-DRB53"
  donor <- "HLA-DR1^HLA-B*75"

  sero_MM <- HLA_mismatch_base(recip, donor, loci = "HLA-DR51/52/53", direction = "GvH")
  expect_equal(sero_MM, "HLA-DR52+HLA-DRB53")

  sero_NA <- HLA_mismatch_base(recip, donor, loci = "HLA-DR51/52/53", direction = "HvG") # NA
  expect_equal(sero_NA, NA_character_)
})


# --- Input validation tests ---

test_that("HLA_mismatch_base rejects NULL inputs", {
  gl <- "HLA-A*01:01+HLA-A*02:01"
  expect_error(HLA_mismatch_base(NULL, gl, "HLA-A", "HvG"), "GL_string_recip")
  expect_error(HLA_mismatch_base(gl, NULL, "HLA-A", "HvG"), "GL_string_donor")
  expect_error(HLA_mismatch_base(gl, gl, NULL, "HvG"), "loci")
})

test_that("HLA_mismatch_base rejects non-character GL strings", {
  gl <- "HLA-A*01:01+HLA-A*02:01"
  expect_error(HLA_mismatch_base(123, gl, "HLA-A", "HvG"), "must be a character")
  expect_error(HLA_mismatch_base(gl, 123, "HLA-A", "HvG"), "must be a character")
})

test_that("HLA_mismatch_base rejects invalid direction", {
  gl <- "HLA-A*01:01+HLA-A*02:01"
  expect_error(HLA_mismatch_base(gl, gl, "HLA-A", "invalid"))
})

test_that("HLA_mismatch_base rejects ambiguous GL strings", {
  gl_ambig <- "HLA-A*01:01/HLA-A*01:02+HLA-A*02:01"
  gl_normal <- "HLA-A*01:01+HLA-A*02:01"
  expect_error(HLA_mismatch_base(gl_ambig, gl_normal, "HLA-A", "HvG"), "ambiguous")
})

test_that("HLA_mismatch_base works with vectorized inputs", {
  recip <- c(
    "HLA-A*01:01+HLA-A*02:01",
    "HLA-A*03:01+HLA-A*24:02"
  )
  donor <- c(
    "HLA-A*01:01+HLA-A*03:01",
    "HLA-A*03:01+HLA-A*24:02"
  )
  # Should return a vector of length 2

  result <- HLA_mismatch_base(recip, donor, "HLA-A", "HvG")
  expect_length(result, 2)
  # First pair has a mismatch, second pair is a perfect match
  expect_equal(result[1], "HLA-A*03:01")
  expect_true(is.na(result[2]))
})

test_that("HLA_mismatch_base returns NA for perfect match at single locus", {
  gl <- "HLA-A*01:01+HLA-A*02:01^HLA-B*07:02+HLA-B*08:01"
  result <- HLA_mismatch_base(gl, gl, "HLA-A", "HvG")
  expect_true(is.na(result))
})

