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

Make sure you're working from the current state of the repository. The default branch is `master`:

```bash
# In the terminal:
git checkout master
git pull origin master
```

### 1.3 Create or refresh the development branch

Never work directly on `master`. Use a `dev` branch.

The `dev` branch typically persists across release cycles: after each release is merged to `master` via pull request, the same `dev` branch is reused for the next round of work. So when you start a new cycle, the branch probably already exists but is behind `master`. You have two cases:

- **`dev` already exists (typical case).** Fast-forward it to `master` so you start from the latest state:
  ```bash
  git checkout dev
  git pull origin dev           # sync local dev with remote dev
  git merge master --ff-only    # advance dev to master's tip
  ```
- **`dev` does not exist yet (first cycle).** Create it from `master`:
  ```bash
  git checkout -b dev
  git push -u origin dev
  ```

Either way, confirm you're on `dev` before you start making changes:

```bash
git branch --show-current       # should print: dev
```

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

**Note on `devtools::check()` and vignettes.** Building the vignette requires `pandoc`. RStudio bundles it, so running `devtools::check()` from the RStudio Console or Terminal works out of the box. If you run `devtools::check()` from a plain R session outside RStudio (e.g. `Rscript -e "devtools::check()"` from cmd), the vignette build may fail with `Pandoc is required to build R Markdown vignettes`. Workarounds:

- Run the check from RStudio (simplest).
- Or install `pandoc` separately and make sure it's on `PATH`.
- Or skip the vignette during an interim check: `devtools::check(vignettes = FALSE)`. This is fine for iterating; you still want a full check (vignettes included) before pushing.

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
# First push of a brand-new branch (sets up remote tracking):
git push -u origin dev

# Subsequent pushes:
git push
```

**Pushing to `dev` does NOT trigger CI by itself.** The GitHub Actions workflows in `.github/workflows/` are configured to run on pushes to `master` and on pull requests — not on pushes to `dev`. If you want CI results for your branch, open the pull request (next step). Once you do, the workflows run against the PR head.

### 3.3 Create a pull request

With your changes pushed and local checks passing, open a pull request from `dev` to `master`. Opening the PR is what actually triggers CI on your work.

The fastest path is the GitHub CLI:

```bash
gh pr create --base master --head dev \
  --title "1.x.y: brief summary" \
  --body "$(cat <<'EOF'
## Summary

- Bullet points of what changed.

## Test plan

- [x] devtools::test()
- [x] devtools::check() from RStudio (0/0/0 including vignettes)
- [ ] R-CMD-check on Windows / macOS / Ubuntu (GitHub Actions)
- [ ] test-coverage run (GitHub Actions) + codecov update
EOF
)"
```

Alternatively, navigate to https://github.com/k96nb01/immunogenetr_package and click "Compare & pull request" when prompted.

Once the PR is open, two workflows run automatically against the PR head:

- **R-CMD-check.yaml** — `R CMD check` on macOS, Windows, and Ubuntu (with multiple R versions).
- **test-coverage.yaml** — `covr` run, results uploaded to Codecov, README badge updated.

Wait for both to go green before merging. The R-hub workflow (`rhub.yaml`) only runs on manual trigger (workflow_dispatch) — you can invoke it from the Actions tab if you want multi-platform checks beyond what R-CMD-check covers, but it is not required for every PR.

A pull request also gives you a chance to review the full diff of your changes before merging. If you're working with collaborators, they can review and comment on the PR before it's merged.

### 3.4 Merge the pull request

After confirming that CI checks pass on the pull request:

1. Go to the pull request on GitHub.
2. Click **"Merge pull request"** (use "Squash and merge" if you want to condense multiple commits into one clean commit on `master`).
3. Click **"Confirm merge"**.
4. Do NOT delete the remote `dev` branch — it is reused for the next release cycle (see §1.3). Leave it in place; you will fast-forward it to the new `master` tip at the start of the next cycle.

Then update your local repository:

```bash
# In the terminal:
git checkout master
git pull origin master
# (do NOT delete local 'dev' — same reason as above)
```

### 3.5 Working without a pull request (solo development)

If you prefer a simpler workflow without pull requests, you can merge locally:

```bash
# Switch back to master and merge your dev branch:
git checkout master
git pull origin master
git merge dev
git push origin master

# Leave the 'dev' branch in place for the next cycle.
```

Note: skipping the pull request also skips the CI gate. `R-CMD-check.yaml` and `test-coverage.yaml` still run on the push to `master`, but by then it is too late to catch problems before they are on the default branch. Prefer the PR path when you can.

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

## Appendix A: Setting Up the pkgdown Documentation Site (one-time)

This appendix describes the one-time procedure for launching the package documentation site at **https://immunogenetr.org**. After this is done, the site rebuilds automatically on every push to `master` and you do not need to revisit these steps. For ongoing local preview during normal development, see §A.8.

Prerequisites:

- You own `immunogenetr.org` (registered at Cloudflare).
- You have admin access to the GitHub repo.
- `master` is branch-protected, so all package changes go through `dev` → PR → `master` (per Phase 3).

### A.1 Bootstrap pkgdown from a dedicated branch

Do not bundle this work into your release-cycle `dev` branch — pkgdown setup is orthogonal infrastructure and should land in its own atomic PR, decoupled from any in-flight package changes. Create a short-lived branch off `master`:

```bash
git checkout master
git pull origin master
git checkout -b pkgdown-setup
```

Then from R in the package root:

```r
usethis::use_pkgdown_github_pages()
```

This single command will:

- Create `_pkgdown.yml` in the package root.
- Add `docs/` to `.gitignore` and `.Rbuildignore`.
- Add `.github/workflows/pkgdown.yaml` (the Action that builds and deploys the site).
- Create an empty `gh-pages` branch on the remote.
- Configure GitHub Pages to publish from `gh-pages`.

The local file changes are **not** committed for you — you'll commit and PR them in §A.4.

### A.2 Set the canonical site URL

Open the newly created `_pkgdown.yml` and set the `url` field at the top:

```yaml
url: https://immunogenetr.org

template:
  bootstrap: 5
```

The `url` value controls canonical links and the search index. Set it to the custom domain now, before DNS is wired up — you want the right URL baked into the site from the first deploy.

### A.3 Preview locally

Before pushing, build and preview the site:

```r
pkgdown::build_site()
```

This builds into `docs/` and opens the site in your browser. Confirm that the function reference, vignette, and README render correctly.

### A.4 Commit, PR, merge

Stage the new pkgdown files and open a PR as usual:

```bash
git add _pkgdown.yml .gitignore .Rbuildignore .github/workflows/pkgdown.yaml
git commit -m "Add pkgdown documentation site"
git push -u origin pkgdown-setup
gh pr create --base master --head pkgdown-setup \
  --title "Add pkgdown documentation site" \
  --body "Initial pkgdown setup; site deploys to immunogenetr.org on merge."
```

Once CI is green, merge to `master`. The `pkgdown.yaml` workflow now runs on every push to `master` and publishes to `gh-pages`. Confirm the first run completes successfully under the Actions tab. After the merge you can delete the `pkgdown-setup` branch — unlike `dev`, it is not reused.

If your release-cycle `dev` branch already has unmerged work on it (so it has diverged from `master`), bring the pkgdown changes into it after this PR lands so `dev` stays current:

```bash
git checkout dev
git pull origin dev
git merge master            # regular merge commit; not a fast-forward
git push origin dev
```

### A.5 Set the custom domain on GitHub

GitHub → repo **Settings** → **Pages**:

- **Custom domain**: `immunogenetr.org` → **Save**. This writes a `CNAME` file to the `gh-pages` branch.
- **Enforce HTTPS**: tick this once it becomes available. It is grayed out until GitHub finishes provisioning a Let's Encrypt certificate. If it stays grayed for more than ~30 minutes, recheck DNS in §A.6 (most often the cause is Cloudflare proxying still being on).

### A.6 Configure DNS at Cloudflare

In the Cloudflare dashboard for `immunogenetr.org` → **DNS** → **Records**, add four `A` records on the apex (`@`), each pointing to a GitHub Pages IP:

```
185.199.108.153
185.199.109.153
185.199.110.153
185.199.111.153
```

Critical: set proxy status on each to **DNS only** (gray cloud), not Proxied (orange cloud). With the orange cloud on, GitHub Pages cannot complete the Let's Encrypt ACME challenge and HTTPS provisioning will fail. You can switch to Proxied later if you want, but only after also setting **SSL/TLS → Overview → encryption mode** to **Full** (not Flexible — Flexible causes a redirect loop).

Optional: add a `CNAME` record `www` → `k96nb01.github.io` if you want `www.immunogenetr.org` to redirect to the apex.

DNS typically propagates in a few minutes. Verify with:

```bash
nslookup immunogenetr.org
```

Once the apex resolves to the GitHub Pages IPs, return to **Settings → Pages** and tick **Enforce HTTPS**.

### A.7 Confirm the site is live

Visit https://immunogenetr.org. You should see the pkgdown homepage. From now on, every push to `master` triggers `pkgdown.yaml` and updates the site automatically — no manual deploys needed.

### A.8 Ongoing: local preview during development

After this setup, you can preview documentation changes locally any time:

```r
pkgdown::build_site()         # full rebuild (slow)
pkgdown::build_reference()    # function reference only (fast)
pkgdown::build_articles()     # vignettes only
```

The `docs/` directory is gitignored — only the `gh-pages` branch (built by CI on push to `master`) is reflected on the live site. Use local preview to catch bad markdown or broken cross-references before they hit master.

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
| Build pkgdown site locally | `pkgdown::build_site()` |
| Build pkgdown reference only | `pkgdown::build_reference()` |
| Build pkgdown articles only | `pkgdown::build_articles()` |

---

## immunogenetr-Specific Notes

- **GitHub repo**: https://github.com/k96nb01/immunogenetr_package
- **Documentation site**: https://immunogenetr.org (custom domain owned by user, registered at Cloudflare; built by `.github/workflows/pkgdown.yaml` and served from the `gh-pages` branch). Initial setup procedure: see Appendix A.
- **Codecov**: https://app.codecov.io/gh/k96nb01/immunogenetr_package (token stored as `CODECOV_TOKEN` in GitHub secrets)
- **GitHub Actions workflows**:
  - `R-CMD-check.yaml` — multi-platform R CMD check
  - `test-coverage.yaml` — coverage reporting to Codecov
  - `rhub.yaml` — R-hub checks
  - `pkgdown.yaml` — builds and publishes the documentation site to `gh-pages` (i.e. immunogenetr.org) on every push to `master`
- **Citation**: Published in *Human Immunology* (DOI: 10.1016/j.humimm.2025.111619). Citation file at `inst/CITATION`.
- **Vignette**: `vignettes/immunogenetr.Rmd` — "Getting Started with immunogenetr"
- **README**: Generated from `README.Rmd`. Always edit the `.Rmd`, never the `.md` directly.
