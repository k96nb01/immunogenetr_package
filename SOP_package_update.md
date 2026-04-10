# Standard Operating Procedure: Updating the immunogenetr Package

This document describes the full lifecycle for making changes to the `immunogenetr` R package, from initial development through CRAN submission. It is specific to the immunogenetr package and its GitHub repository at `k96nb01/immunogenetr_package`.

## Prerequisites

Make sure you have the following packages installed:

```r
install.packages(c("devtools", "usethis", "roxygen2", "testthat", "covr", "knitr", "rmarkdown"))
```

You should also have a GitHub Personal Access Token configured for `usethis` to interact with GitHub:

```r
usethis::create_github_token()   # opens browser to create a token
gitcreds::gitcreds_set()          # store the token locally
```

---

## Phase 1: Setting Up a Development Session

### 1.1 Open the project

Open `immunogenetr.Rproj` in RStudio. This ensures your working directory and build tools are configured correctly.

### 1.2 Pull the latest changes

Make sure you're working from the current state of the repository:

```bash
# In the terminal:
git checkout main
git pull origin main
```

### 1.3 Create a development branch

Never work directly on `main`. Create a `dev` branch on the GitHub website.

Switch to the `dev` branch in RStudio and pull from github to get up to date.

### 1.4 Load the package for interactive development

```r
devtools::load_all()
```

This simulates installing the package so you can test functions interactively without a full install. Run this any time you change code and want to test it.

### 1.5 Prepare for continued development

Bump to a development version so that subsequent work is clearly distinguished from the released version:

```r
usethis::use_dev_version()
```

This changes the version in `DESCRIPTION` to something like `1.2.0.9000`, signaling that this is a development version.

### 1.6 Add a new NEWS.md heading

`use_dev_version()` will also add a new heading to `NEWS.md` for the development version. Start logging changes under this heading.

---

## Phase 2: Making Changes

### 2.1 Write or modify code

All package functions live in `R/`. Follow these conventions for immunogenetr:

- Use tidyverse principles and functions whenever possible.
- Annotate code extensively, with a comment on each line or functional section.
- Use `if/else` over `switch()`.
- Use `$` for column access over `[[]]`.
- Use explicit `if/else` rather than early-return patterns.

### 2.2 Update documentation

If you've changed or added any roxygen2 comments (the `#'` blocks above functions), regenerate the documentation:

```r
devtools::document()
```

This updates the `man/` directory, the `NAMESPACE` file, and any collation directives.

### 2.3 Write or update tests

All tests live in `tests/testthat/`. Each test file corresponds to a source file (e.g., `test-HLA_truncate.R` tests `R/HLA_truncate.R`).

To run tests interactively during development:

```r
devtools::test()
```

To run a single test file:

```r
testthat::test_file("tests/testthat/test-HLA_truncate.R")
```

### 2.4 Update NEWS.md

Every user-facing change should be documented in `NEWS.md` under the current development version heading. Group entries by type:

- **New features** for new functionality.
- **Bug fixes** for corrections to existing behavior.
- **Improvements** for performance or usability enhancements.
- **Documentation** for vignette, help page, or README changes.
- **Tests** for new or expanded test coverage.

### 2.5 Run R CMD check locally

This is the single most important quality gate. Run it frequently:

```r
devtools::check()
```

Your target is always **0 errors, 0 warnings, 0 notes**. Fix any issues before proceeding.

### 2.6 Check code coverage

After adding or modifying tests, check coverage:

```r
covr::package_coverage()   # summary by file
covr::report()             # interactive HTML report with line-by-line detail
```

Use the report to identify uncovered lines and decide whether to add tests or mark unreachable code with `# nocov start` / `# nocov end`.

### 2.7 Update the vignette (if applicable)

If your changes affect the user-facing workflow, update `vignettes/immunogenetr.Rmd`. Build and preview it with:

```r
devtools::build_vignettes()
```

### 2.8 Update the README (if applicable)

The README is generated from `README.Rmd`. If you change it, re-knit:

```r
devtools::build_readme()
```

This regenerates `README.md`. Do not edit `README.md` directly.

---

## Phase 3: Committing, Pushing, and Merging

### 3.1 Stage and commit changes

Commit frequently as you work on the branch, with descriptive messages:

```bash
# In the terminal:
git add <specific files>
git commit -m "Brief description of changes"
```

Avoid committing files that contain secrets (e.g., `.Renviron`, API keys). Stage specific files rather than using `git add .` or `git add -A`.

### 3.2 Push the branch to GitHub

```bash
# First push (sets up remote tracking):
git push -u origin feature/my-new-feature

# Subsequent pushes:
git push
```

After pushing, the GitHub Actions workflows will run automatically on your branch:

- **R-CMD-check.yaml** runs `R CMD check` on macOS, Windows, and Ubuntu (with multiple R versions).
- **test-coverage.yaml** runs `covr` and uploads results to Codecov, updating the badge on your README.

### 3.3 Create a pull request

Once your changes are complete and passing CI, create a pull request on GitHub to merge your branch into `main`. You can do this from the GitHub website or from the command line:

```bash
# Using the GitHub CLI:
gh pr create --title "Brief description" --body "Details about the changes"
```

Or navigate to https://github.com/k96nb01/immunogenetr_package and click "Compare & pull request" when prompted.

A pull request gives you a chance to review the full diff of your changes before merging. If you're working with collaborators, they can review and comment on the PR before it's merged.

### 3.4 Merge the pull request

After confirming that CI checks pass on the pull request:

1. Go to the pull request on GitHub.
2. Click **"Merge pull request"** (use "Squash and merge" if you want to condense multiple commits into one clean commit on `main`).
3. Click **"Confirm merge"**.
4. Optionally click **"Delete branch"** to clean up the remote branch.

Then update your local repository:

```bash
# In the terminal:
git checkout main
git pull origin main
git branch -d feature/my-new-feature   # delete the local branch
```

### 3.5 Working without a pull request (solo development)

If you prefer a simpler workflow without pull requests, you can merge locally:

```bash
# Switch back to main and merge your branch:
git checkout main
git pull origin main
git merge feature/my-new-feature
git push origin main

# Clean up the branch:
git branch -d feature/my-new-feature
git push origin --delete feature/my-new-feature
```

This is faster for solo work but skips the review step that pull requests provide.

Check the Actions tab on GitHub (https://github.com/k96nb01/immunogenetr_package/actions) to confirm everything passes.

---

## Phase 4: Preparing a CRAN Release

### 4.1 Create a release checklist

When you're ready to release a new version to CRAN, create a structured checklist as a GitHub issue:

```r
usethis::use_release_issue()
```

This opens a GitHub issue with a tailored checklist based on whether this is a patch, minor, or major release. The checklist includes items like:

- Checking your current CRAN status and any existing NOTEs.
- Running `urlchecker::url_check()` to verify URLs.
- Running `devtools::check()` with various configurations.
- Checking on R-hub.
- Updating `cran-comments.md`.
- Submitting to CRAN.

Work through the checklist items in order, checking them off as you go.

### 4.2 Bump the version number

Use `usethis::use_version()` to increment the version in `DESCRIPTION`:

```r
usethis::use_version("patch")   # e.g., 1.1.0 -> 1.1.1
usethis::use_version("minor")   # e.g., 1.1.0 -> 1.2.0
usethis::use_version("major")   # e.g., 1.1.0 -> 2.0.0
```

This also updates the `NEWS.md` heading to reflect the new version number.

### 4.3 Run comprehensive checks

Run the full check suite before submitting:

```r
# Standard check
devtools::check()

# Check for CRAN-specific issues
devtools::check(remote = TRUE, manual = TRUE)

# Check URLs in documentation
urlchecker::url_check()

# Check on R-hub for additional platforms
rhub::rhub_check()
```

### 4.4 Update cran-comments.md

Edit `cran-comments.md` in the package root to document your test results for the CRAN reviewers. A typical format:

```
## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments
- local macOS (R 4.x.x)
- GitHub Actions: macOS-latest (release), windows-latest (release), ubuntu-latest (devel, release, oldrel-1)
- R-hub

## Downstream dependencies
There are currently no downstream dependencies for this package.
```

### 4.5 Submit to CRAN

```r
devtools::submit_cran()
```

This builds the package, submits it to CRAN, and creates a `CRAN-SUBMISSION` file that records the submission details. You will receive a confirmation email from CRAN that you need to respond to.

---

## Phase 5: After CRAN Acceptance

### 5.1 Create a GitHub release

Once CRAN has accepted the package:

```r
usethis::use_github_release()
```

This creates a Git tag and a corresponding GitHub release, using information from `CRAN-SUBMISSION` to populate the release notes. It also deletes the `CRAN-SUBMISSION` file.



---

## Quick Reference

| Task | Command |
|---|---|
| Load package for development | `devtools::load_all()` |
| Regenerate documentation | `devtools::document()` |
| Run tests | `devtools::test()` |
| Run R CMD check | `devtools::check()` |
| Check code coverage | `covr::package_coverage()` |
| Interactive coverage report | `covr::report()` |
| Build vignettes | `devtools::build_vignettes()` |
| Knit README | `devtools::build_readme()` |
| Create release checklist | `usethis::use_release_issue()` |
| Bump version | `usethis::use_version("patch")` |
| Check URLs | `urlchecker::url_check()` |
| Submit to CRAN | `devtools::submit_cran()` |
| Create GitHub release | `usethis::use_github_release()` |
| Bump to dev version | `usethis::use_dev_version()` |

---

## immunogenetr-Specific Notes

- **GitHub repo**: https://github.com/k96nb01/immunogenetr_package
- **Codecov**: https://app.codecov.io/gh/k96nb01/immunogenetr_package (token stored as `CODECOV_TOKEN` in GitHub secrets)
- **GitHub Actions workflows**:
  - `R-CMD-check.yaml` — multi-platform R CMD check
  - `test-coverage.yaml` — coverage reporting to Codecov
  - `rhub.yaml` — R-hub checks
- **Citation**: Published in *Human Immunology* (DOI: 10.1016/j.humimm.2025.111619). Citation file at `inst/CITATION`.
- **Vignette**: `vignettes/immunogenetr.Rmd` — "Getting Started with immunogenetr"
- **README**: Generated from `README.Rmd`. Always edit the `.Rmd`, never the `.md` directly.
