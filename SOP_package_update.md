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

- **`dev` already exists (typical case).** Advance it to the latest `master` so you start from the post-release state:
  ```bash
  git checkout dev
  git pull origin dev           # sync local dev with remote dev
  git reset --hard master       # advance dev to master's tip (see note below)
  git push --force-with-lease   # update remote dev
  ```

  **Why `reset --hard` rather than `merge --ff-only`?** If the previous release PR was merged with "Squash and merge" (recommended in §5.1), `master` now has one squashed commit while `dev` still has the original N individual commits — the branches have *diverged*, so `merge --ff-only` will fail with `Not possible to fast-forward, aborting`. The squashed commit on `master` contains the same content as the N commits on `dev`, just collapsed, so it's safe to discard `dev`'s old history by resetting. The force-push is needed because remote `dev` still has the pre-squash history; `--force-with-lease` protects against overwriting any new work pushed by someone else.

  If the previous PR was merged with a regular merge commit (not squash), `merge --ff-only` works and the force-push is unneeded — but squash is the SOP-recommended path.
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

### 1.5 Bump to a development version

```r
usethis::use_dev_version()
```

This does two things in one shot: it changes the version in `DESCRIPTION` to something like `1.2.0.9000` (signaling a development version that's clearly distinguished from any released version), and adds a new heading to `NEWS.md` for the development cycle. Start logging changes under that new heading as you work.

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

If your changes affect the user-facing workflow, update `vignettes/immunogenetr.Rmd`. Preview it with:

```r
pkgdown::build_article("immunogenetr")
```

(`devtools::build_vignettes()` is deprecated as of devtools 2.5.0 — it left build artifacts in the development directory. `pkgdown::build_article()` renders a single article into the pkgdown site for local preview.)

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

## Phase 3: Committing, Pushing, and Opening the PR

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

Leave the PR open through Phase 4. Merging happens in Phase 5.

---

## Phase 4: Preparing a CRAN Release

With your PR open from Phase 3 and CI green, work through these steps on `dev`. Every change you make here updates the PR for another CI pass. The PR does not merge yet — Phase 5 handles the merge.

### 4.1 Create a release checklist

**Do this before §4.4 (bumping the version).** `use_release_issue()` reads `DESCRIPTION` and assumes the current version is the released one. If you've already bumped, the version it offers for the new release will be wrong.

Create a structured checklist as a GitHub issue:

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

### 4.2 Run comprehensive checks

Run the full check suite before submitting. Each item here is non-redundant — they catch different things.

```r
# CRAN-flavored check: builds PDF manual, validates URLs against the live web,
# enables the same env vars CRAN's incoming check uses. Strict superset of
# devtools::check() — don't run both, just this one.
devtools::check(remote = TRUE, manual = TRUE)

# Explicit URL audit across DESCRIPTION/README/vignette/man.
# Faster and more thorough than the URL pass inside check(remote = TRUE).
urlchecker::url_check()

# Submit to win-builder for an R-devel check on Windows. CRAN's submission
# pipeline mirrors this; a clean win-builder result is the strongest
# pre-submission signal. Results are emailed (no local output) within
# ~30-90 min on weekdays. Required even on a Windows host — your local
# R is R-release, not R-devel.
devtools::check_win_devel()
```

For R-hub multi-platform checks, **don't install rhub locally** — modern `rhub` v2 runs on GitHub Actions runners anyway, so the local invocation is just a remote queue. Instead, trigger the existing `rhub.yaml` workflow from the Actions tab (https://github.com/k96nb01/immunogenetr_package/actions/workflows/rhub.yaml) with **workflow_dispatch**. For the `config` input, the platforms that add coverage beyond the existing `R-CMD-check.yaml` GHA matrix are:

- `donttest` — runs `\donttest{}` examples (CRAN does this; the standard `R-CMD-check.yaml` skips them).
- `nosuggests` — package check with Suggests packages absent (CRAN does this).
- `gcc16` — closest to CRAN's `r-devel-linux-x86_64-fedora-gcc` reference build.

The `[VM]` platforms (`linux`, `windows`, `macos`) just delegate to GHA runners — running them adds nothing on top of `R-CMD-check.yaml`. Sanitizer/valgrind/rchk containers target memory bugs in compiled code and don't apply to pure-R packages like this one.

#### Reverse dependency check

If immunogenetr ever gains reverse dependencies (other CRAN packages that depend on it), run `revdepcheck::revdep_check(num_workers = 4)` and disclose the result in `cran-comments.md`. Skip this step while there are none — the `use_release_issue()` checklist also only includes it conditionally. You can sanity-check from R with `devtools::revdep()` (returns the current list) or by visiting `https://cran.r-project.org/web/packages/immunogenetr/index.html` and looking at the "Reverse dependencies" section.

#### Reading `devtools::check()` output

**The summary box at the bottom of `devtools::check()` output can silently drop ERRORs.** Always check the `Status: N ERROR, M WARNING, K NOTE` line in the *middle* of the output (before the summary box), not just the `0 errors / 1 warning / 1 note`-style summary at the very bottom. If there's a mismatch, trust the middle line — that's R CMD check's verdict; the bottom is devtools post-processing.

#### TinyTeX / PDF manual troubleshooting

`devtools::check(manual = TRUE)` builds the PDF manual via TinyTeX. Three failure modes recur:

- **`Cannot find pcrr8t.mf` (or similar missing font metric).** Your local TinyTeX is on an older TeX Live year than the current CTAN — TeX Live's yearly release cycle disallows cross-year installs from the same `tlmgr`. Fix with `tinytex::reinstall_tinytex()` (downloads ~100 MB, takes a few minutes). After reinstall, install the base 35 PostScript font packages explicitly:
  ```r
  tinytex::tlmgr_install(c("psnfss", "courier", "helvetic"))
  ```
  **Do not** try to install `urw-base35` — it is not present in Yihui's TLNet mirror (the rhub.yaml-and-tinytex default). The individual font packages above are the right install.

- **`checking PDF version of manual ... WARNING` with `LaTeX errors found:` followed by nothing, plus a NOTE about a leftover `immunogenetr-manual.tex` in the check directory.** Both messages have the same root cause: `makeindex` is missing from PATH, so the with-index PDF build can't generate the `.ind` file and texi2pdf leaves intermediate artifacts behind. Fix:
  ```r
  tinytex::tlmgr_install("makeindex")
  ```

After any TinyTeX change, **wipe the check directory before re-running** — its `.Rcheck` lingers between runs and can make the leftover-`.tex` NOTE persist even after the underlying issue is fixed:

```r
unlink("../immunogenetr.Rcheck", recursive = TRUE)
devtools::check(remote = TRUE, manual = TRUE)
```

Side note: `devtools::check()` may also print a `Warning in system2("quarto", "-V", ...)` about Quarto receiving `TMPDIR=...` as a positional argument. This is a Quarto CLI parsing bug on Windows, harmless, and unrelated to your package.

### 4.3 Update cran-comments.md

Edit `cran-comments.md` in the package root to document your test results for the CRAN reviewers. Use your actual local platform/R version (not the literal text below — replace with your environment):

```
## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments
- local <your OS> (R <your R version>)
- win-builder R-devel
- GitHub Actions: macOS-latest (release), windows-latest (release), ubuntu-latest (devel, release, oldrel-1)
- R-hub: donttest, nosuggests, gcc16

## Downstream dependencies
There are currently no downstream dependencies for this package.
```

#### Disclosing the R-hub `nosuggests` vignette error

The `nosuggests` platform will report an ERROR for vignette re-building if your vignette uses the `rmarkdown` engine (which immunogenetr's does):

```
Error: processing vignette 'immunogenetr.Rmd' failed with diagnostics:
there is no package called 'rmarkdown'
```

This is **not a real CRAN blocker** — CRAN's own incoming check runs with `_R_CHECK_FORCE_SUGGESTS_=false`, which downgrades this exact case to a NOTE. The R-hub `nosuggests` platform doesn't set that env var, so it surfaces as ERROR. Disclose it explicitly in `cran-comments.md` so reviewers know you ran the check and understand the discrepancy:

```
## R-hub notes

The `nosuggests` platform reports an ERROR at "checking re-building of vignette outputs":

    Error: processing vignette 'immunogenetr.Rmd' failed with diagnostics:
    there is no package called 'rmarkdown'

This is the standard interaction between R-hub's `nosuggests` platform and vignettes built with the `rmarkdown` engine. CRAN's own incoming check runs with `_R_CHECK_FORCE_SUGGESTS_=false`, which downgrades this case to a NOTE. The `gcc16` and `donttest` platforms pass cleanly.
```

### 4.4 Bump the version number

This is the last step before merging. By bumping at the end of Phase 4 — after the comprehensive checks and `cran-comments.md` are settled — you avoid having to rebump if a check turns up something that requires reworking. This ordering matches the `use_release_issue()` checklist, which places `use_version()` under "Submit to CRAN," not "Prepare for release."

Use `usethis::use_version()` to increment the version in `DESCRIPTION`:

```r
usethis::use_version("patch")   # e.g., 1.3.0 -> 1.3.1
usethis::use_version("minor")   # e.g., 1.3.0 -> 1.4.0
usethis::use_version("major")   # e.g., 1.3.0 -> 2.0.0
```

This also updates the `NEWS.md` heading to reflect the new version number. Push the version-bump commit so it shows up on the PR; once CI is green on that final push, you're ready for Phase 5.

---

## Phase 5: Merge and Submit

With Phase 4 complete and CI green, this phase moves the release from `dev` onto `master` and submits it to CRAN. After Phase 5, `master` reflects exactly what was submitted to CRAN — no extra commits.

### 5.1 Merge the PR

1. Go to the pull request on GitHub.
2. Click the **Squash and merge** dropdown → "Squash and merge". Squash keeps `master`'s history one-commit-per-release; the individual development commits are preserved in the PR record.
3. Click **Confirm squash and merge**.
4. **Do NOT delete the remote `dev` branch** — it is reused for the next release cycle (per §1.3 and §6.2).

### 5.2 Sync local master

Update your local repository so the next step works from the post-merge state:

```bash
git checkout master
git pull origin master
```

Don't delete local `dev` either — same reason as above.

### 5.3 Submit to CRAN

From R, in the package root (you should now be on `master`, synced with origin):

```r
devtools::submit_cran()
```

What this actually does, step by step:

1. Builds a source tarball (`immunogenetr_<version>.tar.gz`) from the current package directory.
2. Uploads the tarball to CRAN's submission endpoint.
3. Writes a `CRAN-SUBMISSION` file in the package root recording the submission details (commit SHA, date, version). This file persists locally until §6.1 cleans it up.
4. Triggers CRAN to email the maintainer address from `DESCRIPTION` with a confirmation link.

**Critical: clicking the confirmation link is what actually submits the package.** Until you click, the package is queued but not in CRAN's incoming review. If you don't click within ~24 hours the submission is dropped silently. The email typically arrives within a few minutes; if you don't see it, check spam.

After confirmation, expect a sequence of automated emails over the next 24–72 hours:

- **"Submission acknowledged"** — confirms CRAN received the click. Submission is now in the incoming queue.
- **Pretest results** (sometimes) — CRAN runs `R CMD check --as-cran` on a few platforms. If anything fails, you'll get an email naming the issue. Common pretest failures: URLs that respond differently from CRAN's IP, missing copyright entries in `inst/COPYRIGHTS`, NEWS.md formatting.
- **Human review** — a CRAN reviewer eyeballs the submission for policy compliance. Most submissions pass without comment.
- **Acceptance** — `"package immunogenetr <version> has been published on CRAN"`. The package goes live on CRAN's package index within a few hours of this email.

If CRAN flags an issue and requires changes, do not resubmit the same version number — CRAN rejects duplicates. Fix the issue, run `usethis::use_version("patch")` to bump to the next patch (e.g., 1.3.0 → 1.3.1), update `cran-comments.md`, and resubmit (returning to §5.3).

---

## Phase 6: After CRAN Acceptance

### 6.1 Create a GitHub release

Once CRAN has accepted the package:

```r
usethis::use_github_release()
```

This creates a Git tag and a corresponding GitHub release, using information from `CRAN-SUBMISSION` to populate the release notes. It also deletes the `CRAN-SUBMISSION` file.

### 6.2 Begin the next release cycle

To start work on the next release, return to Phase 1. The `dev` branch is reused across cycles — fast-forward (or, after a squash merge, reset) it to the new `master` tip per §1.3, reload the package per §1.4, and bump to a new dev version per §1.5. Any open issues or features you want to address fit into Phase 2 from there.

This is the "loop close" of the SOP: every accepted release ends with the next one beginning on a refreshed `dev`.

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

**Rendering gotchas encountered during initial setup** (worth knowing because GitHub renders the same source files differently than pkgdown does, so README/vignette content that looks right on the GitHub repo page can break on the pkgdown site — and vice versa):

- **`^` in HLA GL strings rendering as superscript.** pkgdown renders Markdown through pandoc, which has a `superscript` extension enabled by default. Pandoc interprets `^…^` as `<sup>…</sup>`, which mangles every GL string (and the `*` characters between caret pairs become `<em>` italics for the same reason). Two strategies are in use:
  - **README.Rmd:** the YAML sets `md_extensions: -superscript-subscript` so the rendered `README.md` keeps `\^` and `\*` escapes as literals, and a `kable_hla()` helper escapes `*` and `^` per cell before calling `knitr::kable()`. This means tables are regenerated live from the package on every knit instead of being hand-pasted, so they don't go stale when functions change.
  - **vignettes/immunogenetr.Rmd:** a `knit_print.data.frame` S3 method in the setup chunk wraps `knitr::kable(x, format = "html")` output in a pandoc raw-HTML block (```` ```{=html} ```` ... ```` ``` ````). The raw block tells pandoc to pass the HTML through verbatim, bypassing its `markdown_in_html_blocks` extension that would otherwise re-parse cell contents and re-trigger the superscript problem.
- **Hex sticker rendering at full image size.** The default pattern of `<img src='...' height="139" />` in the README header isn't honored consistently by pkgdown's CSS. Add an explicit `width` plus an inline `style` attribute (`style="height:139px; width:auto; max-width:120px;"`) to force the size — inline style beats Bootstrap's container rules.
- **Vignette outputs appearing as code blocks instead of tables.** The default `html_vignette` output prints data frames as monospace `#>`-prefixed text. Setting `df_print: kable` in the YAML works for direct `rmarkdown::render()` but pkgdown's article rendering path doesn't always honor it — use the `knit_print` method described above to be reliable across both paths.
- **DESCRIPTION `URL:` field must include the pkgdown site URL.** `pkgdown::build_site()` warns if the canonical site URL in `_pkgdown.yml` isn't also listed in DESCRIPTION's `URL:` field. Add it as the first entry.

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

Recommended: also add four `AAAA` records on the apex (`@`) for IPv6 reachability, again all set to **DNS only**:

```
2606:50c0:8000::153
2606:50c0:8001::153
2606:50c0:8002::153
2606:50c0:8003::153
```

Optional: add a `CNAME` record `www` → `k96nb01.github.io` (DNS only) if you want `www.immunogenetr.org` to redirect to the apex.

Cloudflare will display an orange banner reading "Proxying is required for most security and performance features." **Ignore it.** That advice is for typical web origin servers, not for GitHub Pages with Let's Encrypt. Leave every record DNS-only.

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
pkgdown::build_site()                       # full rebuild (slow)
pkgdown::build_reference()                  # function reference only (fast)
pkgdown::build_article("immunogenetr")      # single named article (fastest)
pkgdown::build_articles()                   # all articles
```

`pkgdown::build_article()` is the recommended replacement for the deprecated `devtools::build_vignettes()` when you just want to preview a single vignette during development.

The `docs/` directory is gitignored — only the `gh-pages` branch (built by CI on push to `master`) is reflected on the live site. Use local preview to catch bad markdown or broken cross-references before they hit master.

### A.9 Ongoing maintenance: what (not) to do for routine updates

Once §A.1–A.8 are done, the site is fully self-maintaining for normal development. **You do not need to revisit any of those steps for routine package work.** Specifically:

| Concern | Status | Action needed |
|---|---|---|
| Site rebuild on README/vignette/code change | Automatic on every push to `master` (via `.github/workflows/pkgdown.yaml`) | None |
| Adding a new vignette | Drop `vignettes/foo.Rmd` in, push to `master` | None beyond the normal package PR |
| Adding a new exported function | Auto-discovered from `NAMESPACE`; reference page generated | None beyond `devtools::document()` |
| DNS records at Cloudflare | Persist indefinitely | None unless changing host or domain |
| Custom domain in GitHub Pages settings | Persists | None unless changing domain |
| Let's Encrypt TLS certificate | Auto-renewed by GitHub Pages backend (90-day rotation) | None |
| Workflow Actions runner version | Pinned to `r-lib/actions` versions in the workflow file | Update only when intentionally moving to a newer Action |

**When you actually need to touch pkgdown infrastructure:**

- **You change the package's hosted URL** (e.g. moving off `immunogenetr.org`): update `_pkgdown.yml` `url:`, the `URL:` field in `DESCRIPTION`, the `Custom domain` box in GitHub Pages settings, and DNS records at the registrar. All four must agree.
- **The pkgdown site stops building** after a push: check the latest `pkgdown.yaml` run under the Actions tab. Most failures are R/dependency drift on the runner — usually resolved by bumping `r-lib/actions/setup-r-dependencies@v2` or pinning a stable R version in the workflow.
- **The site builds but the custom domain stops resolving:** check that the four `A` records (and four `AAAA` records, if added) at Cloudflare are still set to **DNS only** (grey cloud). Cloudflare occasionally re-prompts to enable proxying — don't.
- **HTTPS shows a cert error:** the Let's Encrypt cert renewal occasionally fails if DNS proxying was inadvertently turned on. Toggle the custom domain off and back on in GitHub Pages settings to force a re-issuance.
- **You upgrade pkgdown** (`install.packages("pkgdown")`): run `pkgdown::build_site()` locally and skim the output before pushing — major pkgdown versions occasionally change the default template or CSS.

---

## Quick Reference

| Task | Command |
|---|---|
| Load package for development | `devtools::load_all()` |
| Regenerate documentation | `devtools::document()` |
| Run tests | `devtools::test()` |
| Run R CMD check (CRAN-flavored) | `devtools::check(remote = TRUE, manual = TRUE)` |
| Submit to win-builder R-devel | `devtools::check_win_devel()` |
| Check URLs | `urlchecker::url_check()` |
| Trigger R-hub multi-platform | (workflow_dispatch on `rhub.yaml` from Actions tab) |
| Check code coverage | `covr::package_coverage()` |
| Interactive coverage report | `covr::report()` |
| Preview a vignette | `pkgdown::build_article("immunogenetr")` |
| Knit README | `devtools::build_readme()` |
| Create release checklist | `usethis::use_release_issue()` |
| Bump version | `usethis::use_version("patch")` |
| Bump to dev version | `usethis::use_dev_version()` |
| Submit to CRAN | `devtools::submit_cran()` |
| Create GitHub release | `usethis::use_github_release()` |
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
