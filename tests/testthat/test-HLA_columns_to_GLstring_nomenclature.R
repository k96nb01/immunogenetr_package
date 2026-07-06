# Tests for the issue #40 work on HLA_columns_to_GLstring:
#   (1) the Cw -> C molecular locus-naming fix, and
#   (2) the new `nomenclature = "mol"/"ser"` parameter.
# Full design + rationale: Notes/issue-40-asterisk-nomenclature-notes.md
#
# This file is split into two parts:
#
#   PART A — CURRENT BEHAVIOR (regression guards). These pass against the
#            code as it exists today (dev / 1.3.0.9000) and must keep passing.
#            When `nomenclature` is absent the output must stay byte-identical,
#            so these lock the auto-detect behavior we are committed to
#            preserving (Notes §5.1, §7.4).
#
#   PART B — DESIRED BEHAVIOR (the fix + the new parameter). These describe how
#            we WANT the function to behave and are not implemented yet, so each
#            is guarded with skip(). Remove the skip() line for a block as that
#            piece is implemented to turn it from "pending" into a live test.
#
# The one exception is the issue #40 characterization test in PART A, which
# documents the CURRENT (buggy) output. When the Cw -> C fix lands it will be
# deleted and replaced by the corresponding PART B expectation.

library(testthat)
library(dplyr)

# =============================================================================
# PART A — CURRENT BEHAVIOR (must be preserved when `nomenclature` is absent)
# =============================================================================

test_that("auto-detect: serologic Cw values are emitted as HLA-Cw", {
  # Bare numbers in a Cw column (no '*', ':' or leading 0) are serologic.
  df <- data.frame(Cw1 = "7", Cw2 = "9", stringsAsFactors = FALSE)
  expect_equal(
    HLA_columns_to_GLstring(df, c(Cw1, Cw2)),
    "HLA-Cw7+HLA-Cw9"
  )
})

test_that("auto-detect: a molecular value in a C column uses the C locus", {
  # A genuinely-molecular value (colon-bearing) in a C column emits the C locus.
  df <- data.frame(C1 = "*07:01", stringsAsFactors = FALSE)
  expect_equal(HLA_columns_to_GLstring(df, c(C1)), "HLA-C*07:01")
})

test_that("auto-detect: Bw is treated as a serologic epitope, never as locus B", {
  # Bw4/Bw6 are epitopes with no molecular form. They must survive untouched
  # whether written bare or with the "Bw" token (Notes §5.5).
  df_bare <- data.frame(Bw1 = "4", Bw2 = "6", stringsAsFactors = FALSE)
  expect_equal(HLA_columns_to_GLstring(df_bare, c(Bw1, Bw2)), "HLA-Bw4+HLA-Bw6")

  df_token <- data.frame(Bw1 = "Bw4", Bw2 = "Bw6", stringsAsFactors = FALSE)
  expect_equal(HLA_columns_to_GLstring(df_token, c(Bw1, Bw2)), "HLA-Bw4+HLA-Bw6")
})

test_that("auto-detect: serologic DR and DR51/52/53 group separately", {
  # DR51/52/53 (values starting with '5' in a DR column) are split into their
  # own locus group from the other DR antigens. This is current behavior.
  df <- data.frame(
    DR1 = "7", DR2 = "6", DRw1 = "51", DRw2 = "52",
    stringsAsFactors = FALSE
  )
  expect_equal(
    HLA_columns_to_GLstring(df, c(DR1, DR2, DRw1, DRw2)),
    "HLA-DR7+HLA-DR6^HLA-DR51+HLA-DR52"
  )
})

test_that("auto-detect: serologic DQ values are emitted as HLA-DQ", {
  df <- data.frame(DQ1 = "2", DQ2 = "7", stringsAsFactors = FALSE)
  expect_equal(HLA_columns_to_GLstring(df, c(DQ1, DQ2)), "HLA-DQ2+HLA-DQ7")
})

test_that("auto-detect: DPB1/DPA1/DQA1 columns are always molecular", {
  # The is_mol_col override forces these three columns to molecular regardless
  # of value format. Locking current behavior; revisited under `nomenclature`.
  df <- data.frame(DPB1_1 = "4", stringsAsFactors = FALSE)
  expect_equal(HLA_columns_to_GLstring(df, c(DPB1_1)), "HLA-DPB1*4")
})

# NOTE: the issue #40 "characterization" test that pinned the malformed
# "HLA-Cw7+HLA-Cw*17" has been removed now that the fix is implemented. The
# corrected behavior is asserted in PART B ("DESIRED (default): issue #40 input
# restores the 1.2.0 output").

# =============================================================================
# PART B — issue #40 fix (now implemented)
# =============================================================================

# --- B1. Default mode (no `nomenclature`) = "Option Y" (Notes §3, §5.2, §5.3) -
# Option Y restores 1.2.0 behavior for the ambiguous bare-"*" case AND always
# uses a clean molecular locus name. Default classification: a value is molecular
# if it contains ":", starts with "0", contains a NON-leading "*", or sits in a
# DQA1/DPB1/DPA1 column. A bare LEADING "*" is NOT a molecular signal (this is the
# one-qualifier change from dev that restores 1.2.0). Genuinely-molecular values
# then emit the molecular locus name (Cw -> C), never the malformed "HLA-Cw*".

test_that("DESIRED (default): issue #40 input restores the 1.2.0 output", {

  # "w7" and bare "*17" are both serologic by default -> one serologic group.
  t40 <- structure(
    list(Cw1Cd.donor = "w7", Cw2Cd.donor = "*17"),
    row.names = c(NA, -1L), class = c("tbl_df", "tbl", "data.frame")
  )
  expect_equal(
    HLA_columns_to_GLstring(t40, c(Cw1Cd.donor, Cw2Cd.donor)),
    "HLA-Cw7+HLA-Cw17"
  )
})

test_that("DESIRED (default): a bare leading '*' is serologic and the '*' is stripped", {

  df <- data.frame(Cw1 = "*17", Cw2 = "*18", stringsAsFactors = FALSE)
  expect_equal(
    HLA_columns_to_GLstring(df, c(Cw1, Cw2)),
    "HLA-Cw17+HLA-Cw18"
  )
})

test_that("DESIRED (default): genuinely-molecular Cw values use the C locus name (Option Y)", {

  # Colon-bearing values are unambiguously molecular even by 1.2.0 rules; Option Y
  # cleans the locus label so they emit HLA-C* rather than the malformed HLA-Cw*.
  df <- data.frame(Cw1 = "*07:01", Cw2 = "*08:01", stringsAsFactors = FALSE)
  expect_equal(
    HLA_columns_to_GLstring(df, c(Cw1, Cw2)),
    "HLA-C*07:01+HLA-C*08:01"
  )
})

test_that("DESIRED (default): a mixed-nomenclature C locus stays one group (no '^')", {

  # Bare "*17" -> serologic HLA-Cw17; colon "*07:01" -> molecular HLA-C*07:01.
  # Same canonical locus (C), so they share one "+" group despite differing
  # nomenclatures - never split across "^".
  df <- data.frame(Cw1 = "*17", Cw2 = "*07:01", stringsAsFactors = FALSE)
  expect_equal(
    HLA_columns_to_GLstring(df, c(Cw1, Cw2)),
    "HLA-Cw17+HLA-C*07:01"
  )
})

test_that("DESIRED: a locus is never split across '^', for every locus whose nomenclatures differ", {

  # FIRM rule (applies to ALL loci, not just C): the molecular and serologic
  # spellings of a locus are the SAME locus. "^" separates *loci*; "+" joins
  # entries *within* a locus. So a serologic and a molecular entry of the same
  # locus must share one "+" group with no "^" between them.
  #
  # This invariant holds regardless of how the default renders a mixed locus
  # (that exact string is still open - see question to NB, 2026-06-19), so it
  # pins only the no-"^" property. One case per locus whose molecular and
  # serologic names DIFFER (A and B share a name and so never split; omitted).
  cases <- list(
    C    = data.frame(Cw_a = "7", C_b   = "*17",    stringsAsFactors = FALSE),
    DRB1 = data.frame(DR_a = "4", DRB1_b = "*04:01", stringsAsFactors = FALSE),
    DQB1 = data.frame(DQ_a = "2", DQB1_b = "*03:01", stringsAsFactors = FALSE)
  )
  for (locus in names(cases)) {
    out <- HLA_columns_to_GLstring(cases[[locus]], everything())
    expect_false(
      grepl("^", out, fixed = TRUE),
      info = paste0("locus ", locus, " was split across '^': ", out)
    )
  }
})

# --- B2. `nomenclature` parameter: scalar form (Notes §5.3) ------------------

test_that("DESIRED: nomenclature='ser' strips '*' and uses serologic locus names", {

  t40 <- structure(
    list(Cw1Cd.donor = "w7", Cw2Cd.donor = "*17"),
    row.names = c(NA, -1L), class = c("tbl_df", "tbl", "data.frame")
  )
  expect_equal(
    HLA_columns_to_GLstring(t40, c(Cw1Cd.donor, Cw2Cd.donor), nomenclature = "ser"),
    "HLA-Cw7+HLA-Cw17"
  )
})

test_that("DESIRED: nomenclature='mol' strips leading 'w'/'*' and uses molecular names", {

  # Improper output (HLA-C*7 from serologic "w7") is acceptable here - the
  # package does not validate; the companion helper does (Notes §5.3, §6).
  t40 <- structure(
    list(Cw1Cd.donor = "w7", Cw2Cd.donor = "*17"),
    row.names = c(NA, -1L), class = c("tbl_df", "tbl", "data.frame")
  )
  expect_equal(
    HLA_columns_to_GLstring(t40, c(Cw1Cd.donor, Cw2Cd.donor), nomenclature = "mol"),
    "HLA-C*7+HLA-C*17"
  )
})

# --- B3. `nomenclature` parameter: per-locus named-vector form (Notes §5.3) --

test_that("DESIRED: nomenclature accepts a per-locus named vector", {

  df <- data.frame(
    Cw1 = "w7", Cw2 = "*17",
    DRB1_1 = "17", DRB1_2 = "04:01",
    stringsAsFactors = FALSE
  )
  expect_equal(
    HLA_columns_to_GLstring(
      df, c(Cw1, Cw2, DRB1_1, DRB1_2),
      nomenclature = c("HLA-Cw" = "ser", "HLA-DRB1" = "mol")
    ),
    "HLA-Cw7+HLA-Cw17^HLA-DRB1*17+HLA-DRB1*04:01"
  )
})

test_that("DESIRED: nomenclature unifies a locus across its molecular- and serologic-named columns", {

  # "C1" (a molecular value) and "Cw1" (a serologic value) are the SAME locus.
  # Declaring that locus serologic must pull BOTH into one serologic group,
  # never split across "^". This is the "recognize all names for a locus" rule.
  df <- data.frame(C1 = "*17", Cw1 = "7", stringsAsFactors = FALSE)
  expect_equal(
    HLA_columns_to_GLstring(df, c(C1, Cw1), nomenclature = c("HLA-C" = "ser")),
    "HLA-Cw17+HLA-Cw7"
  )
})

test_that("DESIRED: a locus key is accepted in either nomenclature spelling", {

  # "HLA-C" and "HLA-Cw" name the same locus, so either key must behave the same.
  df <- data.frame(C1 = "*17", Cw1 = "7", stringsAsFactors = FALSE)
  out_mol_key <- HLA_columns_to_GLstring(df, c(C1, Cw1), nomenclature = c("HLA-C"  = "ser"))
  out_ser_key <- HLA_columns_to_GLstring(df, c(C1, Cw1), nomenclature = c("HLA-Cw" = "ser"))
  expect_equal(out_mol_key, out_ser_key)
  expect_equal(out_mol_key, "HLA-Cw17+HLA-Cw7")
})

# --- B4. DR under forced molecular: 51/52/53 -> DRB5/3/4 *XX (Notes §5.6) ----

test_that("DESIRED: DR forced molecular maps 51/52/53 to DRB5/3/4 with *XX", {

  # 51/52/53 carry no allele info, so the serologic number is consumed as the
  # locus indicator and the allele field becomes the XX placeholder. Every
  # other DR value maps to DRB1 and keeps its value.
  df <- data.frame(
    DR1 = "17", DR2 = "52", DR3 = "51", DR4 = "53",
    stringsAsFactors = FALSE
  )
  expect_equal(
    HLA_columns_to_GLstring(df, c(DR1, DR2, DR3, DR4), nomenclature = "mol"),
    "HLA-DRB1*17^HLA-DRB3*XX^HLA-DRB5*XX^HLA-DRB4*XX"
  )
})

test_that("DESIRED: DR forced serologic keeps HLA-DR incl. DR51/52/53", {

  df <- data.frame(DR1 = "17", DR2 = "52", stringsAsFactors = FALSE)
  expect_equal(
    HLA_columns_to_GLstring(df, c(DR1, DR2), nomenclature = "ser"),
    "HLA-DR17^HLA-DR52"
  )
})

# --- B5. Bw is never relabeled, even when forced molecular (Notes §5.5) ------

test_that("DESIRED: nomenclature='mol' leaves Bw epitopes untouched", {

  df <- data.frame(Bw1 = "4", Bw2 = "6", stringsAsFactors = FALSE)
  expect_equal(
    HLA_columns_to_GLstring(df, c(Bw1, Bw2), nomenclature = "mol"),
    "HLA-Bw4+HLA-Bw6"
  )
})

# --- B6. DPB1 serologic name is "DPB", not the legacy "DP" (Notes §5.4) ------
# NOTE: entangled with issue #33 serologic work; the allele-level semantics of
# serologic DPB are still being settled. This test pins only the locus LABEL.

test_that("DESIRED: forced-serologic DPB1 uses the HLA-DPB locus name", {

  df <- data.frame(DPB1_1 = "4", stringsAsFactors = FALSE)
  expect_equal(
    HLA_columns_to_GLstring(df, c(DPB1_1), nomenclature = "ser"),
    "HLA-DPB4"
  )
})
