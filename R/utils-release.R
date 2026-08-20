# Internal release infrastructure for immunogenetr.
# Not exported. usethis::use_release_issue() automatically detects
# release_bullets() and appends each returned string as an extra checklist
# item in the generated release issue. Add reminders here as we discover
# immunogenetr-specific things that are easy to forget during a release.

# Return a character vector of package-specific release-checklist reminders.
release_bullets <- function() {
  c(
    # rhub.yaml is workflow_dispatch only -- it does NOT run on push or PR,
    # so it's easy to skip. Trigger it by hand and check it against the
    # release branch before submitting.
    paste(
      "Manually trigger the `rhub.yaml` workflow",
      "(Actions tab -> R-hub -> Run workflow -> Branch: `dev`);",
      "confirm the only ERROR is the expected `nosuggests` vignette one",
      "disclosed in `cran-comments.md`"
    ),

    # pkgdown renders README.md / the vignette through a different pandoc
    # invocation than GitHub does, so GL Strings can look correct on the repo
    # page but break on immunogenetr.org (the '^'/'*' superscript regression
    # that hit v1.3.0; see SOP section A.3). Preview locally before merge.
    paste(
      "Run `pkgdown::build_home()` and eyeball GL String rendering",
      "(no stray superscripts/italics from `^`/`*`) before merging"
    ),

    # Link rot: the CITATION DOI is easy to leave stale across releases.
    "Confirm the DOI in `inst/CITATION` still resolves",

    # Reference datasets track external nomenclature/frequency sources that
    # update on their own cadence, independent of code changes.
    paste(
      "Check `Haplotype_frequencies` and `HLA_dictionary` nomenclature",
      "against the latest WHO/IPD-IMGT/HLA release"
    ),

    # check(manual = TRUE) already exercises this, but the PDF manual build
    # silently needs a TeX distribution (TinyTeX) on PATH -- worth an explicit
    # confirmation so a missing/broken TeX setup is caught before submit.
    "Confirm the PDF manual builds (TinyTeX present and on PATH)",

    # The moving CRAN tag is not part of the standard usethis checklist, so
    # it was missed for the 1.2.0-1.4.0 releases. It marks the commit
    # currently on CRAN.
    paste(
      "After acceptance, move the `CRAN` tag to the accepted commit:",
      "`git tag -f CRAN master && git push --force origin CRAN`",
      "(SOP section 6.1a)"
    )
  )
}
