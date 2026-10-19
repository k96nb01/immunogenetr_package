# Contributing to immunogenetr

This guide is for collaborators with write access to `k96nb01/immunogenetr_package`. It covers the day-to-day loop of working on an issue. The maintainer's release process (CRAN prep, version bumps, merging `dev` into `master`) is in [`SOP_package_update.md`](../SOP_package_update.md); this guide points into it rather than repeating it.

## Branches and protection

| Branch | Purpose | Who can merge |
|---|---|---|
| `master` | Released code. Matches CRAN. | Maintainer only, via PR from `dev` |
| `dev` | Integration branch for the next release. | Via PR with 1 approving review |
| `<issue#>-<short-name>` | One branch per issue, cut from `dev`. | — |

Both `master` and `dev` are protected by repository rulesets: no direct pushes, no force-pushes, no deletion, and every PR needs one approving review. You cannot approve your own PR, so the maintainer reviews and merges.

`dev` is single-use: after each release it is squash-merged into `master`, deleted, and later recreated fresh from `master` (SOP §5.2, §6.2). Between a release and the next `dev` there is nowhere to merge, so hold new work until `dev` exists again. Always cut new branches from the *current* `dev`; a branch cut from a previous cycle's `dev` will carry stale history and conflict.

## The workflow

### 1. Pick up an issue

Work from an issue that is assigned to you. If you want to work on something that has no issue, open one first and describe the problem and proposed approach, so scope is agreed before code is written.

### 2. Create a branch from `dev`

```bash
git switch dev
git pull
git switch -c 48-base-pipe
```

Name the branch after the issue number and a few words. One branch per issue keeps each PR reviewable on its own.

### 3. Make the changes

Follow Phase 2 of the SOP (§2.1–2.8). In short:

- `devtools::load_all()` while developing, so you test the working tree and not the installed release.
- `devtools::document()` after any roxygen change; commit the regenerated `man/` and `NAMESPACE` files.
- Add or update tests for any behavior change.
- Add a bullet to `NEWS.md` under `# immunogenetr (development version)` that says what changed for users and references the issue, e.g. `(#48)`.
- Update the vignette or `README.Rmd` if you touched what they show; re-knit `README.md` with `devtools::build_readme()`.

### 4. Check locally

```r
devtools::check()
```

The target is 0 errors, 0 warnings, 0 notes. The `''NULL''` note on Windows is a known false positive (see `cran-comments.md`) and can be ignored. If vignette building fails with "Pandoc is required", run the check from RStudio, which bundles pandoc.

### 5. Commit

Write commit messages that say what changed and reference the issue:

```
Convert examples and vignette to the base pipe (#48)
```

Mentioning `#48` links the commit on the issue's page.

### 6. Push and open a PR into `dev`

```bash
git push -u origin 48-base-pipe
gh pr create --base dev
```

Or use the "Compare & pull request" button on GitHub, and make sure the **base** branch is `dev`, not `master`.

In the PR description:

- Link the issue: `Part of #48` (see step 8 for why not `Closes #48`).
- Summarize what changed and anything you were unsure about.
- Say how you tested it (`devtools::check()` result, any manual checks).
- If you used an AI coding tool (Claude Code, Codex, Copilot, etc.), say which and for what part of the work. That's fine to do; reviewers just read AI-assisted changes with that in mind. The AI verification pass in SOP §3.2 applies to your PR too.

CI (R-CMD-check and test coverage) runs automatically on the PR. Fix any failures by pushing more commits to the same branch.

### 7. Review

The maintainer reviews the PR and either approves it or requests changes. Respond to comments by pushing new commits to the branch; don't open a new PR. Once approved, the maintainer merges into `dev` and deletes the branch.

### 8. Closing the issue

Don't close issues yourself. GitHub's `Closes #N` keyword only fires when a PR merges into the default branch (`master`), and contributor PRs target `dev`, so the maintainer closes the issue when the PR is merged into `dev`.

After your PR is merged, update your local copy before starting the next issue:

```bash
git switch dev
git pull
git branch -d 48-base-pipe
```

## Quick checklist before opening a PR

- [ ] Branch was cut from an up-to-date `dev`
- [ ] `devtools::document()` run and regenerated files committed
- [ ] Tests added or updated for behavior changes
- [ ] `NEWS.md` bullet added with the issue number
- [ ] `devtools::check()` clean
- [ ] PR targets `dev` and links the issue
- [ ] AI tool use (if any) noted in the PR description
- [ ] No private data, PHI, or references to institutional systems in the diff (this is a public repo)
