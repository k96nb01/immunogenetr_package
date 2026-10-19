# Instructions for AI coding agents

These rules apply to any AI agent working in this repository: Claude Code, Codex, Copilot, Cursor, and others. Human contributors follow [`.github/CONTRIBUTING.md`](.github/CONTRIBUTING.md). The maintainer's release process is [`SOP_package_update.md`](SOP_package_update.md). Where this file and those disagree, those documents win; flag the disagreement to the human you are working with.

## What this repository is

`immunogenetr` is an R package on CRAN for clinical HLA informatics, built around GL Strings. The repository is **public**.

## Hard rules

1. **Independent verification at two points.** When you author or edit anything in this repo (code, tests, docs, examples), a second, independent agent with a fresh context reviews your changes, using the checklist in SOP §3.2 ("AI verification pass"):
   - **Before handing work to the human for commit:** the reviewer checks the uncommitted changes (`git status`, `git diff`, and any untracked files).
   - **Before a PR is opened:** the reviewer checks the whole branch against its base (`git fetch`, then `git diff origin/dev...HEAD` for an issue branch; the SOP's `master...dev` for a release PR).

   The reviewer must be read-only. A subagent, or a fresh CLI process started with no prior context (e.g. `codex exec`), both count. Fix what it finds and re-run it on the fixes until a pass comes back clean. Report its findings honestly to the human, including findings about work already called done. If your tool cannot start an independent reviewer, say so and ask the human to run the review in a separate session.
2. **The human reviews the diff locally before it enters history.** Leave finished work as uncommitted changes in the working tree and say it is ready for review. Commit, push, or open a PR only when the human explicitly asks. Approval of a plan is not approval to commit.
3. **Ask before writing to GitHub.** Show the human the exact text of any issue, comment, or PR description and get a yes before posting it. Never merge PRs, approve PRs, or change repository settings, rulesets, or secrets unless the human asks for that specific action.
4. **No private data.** This repo is public. Never add patient data, PHI, real identifiers, references to private repositories, or institutional system names, including in `Notes/`.

## Working conventions

- Branch from an up-to-date `dev`, one branch per issue (`48-base-pipe`); PRs target `dev`, never `master`. See CONTRIBUTING.md.
- Use `devtools::load_all()` to test the working tree; a plain R session uses the installed release.
- After any roxygen change run `devtools::document()` and include the regenerated `man/` and `NAMESPACE`.
- Every user-facing change gets a `NEWS.md` bullet under the development heading, citing the issue (`(#48)`).
- `devtools::check()` should be 0 errors, 0 warnings, 0 notes. The `''NULL''` note on Windows is a known false positive (`cran-comments.md`). If vignettes fail with "Pandoc is required", run the check from RStudio, or set the `RSTUDIO_PANDOC` environment variable to the folder holding RStudio's bundled pandoc.
- Verify behavior by running code, not by reading it. Exercise exported functions with a single value, a vector, and `NA`.
- Code that splits or matches GL Strings must handle the full delimiter set: `^`, `|`, `+`, `~`, `/`, `?`.
- Style for new or edited code: base pipe `|>`; pass functions directly to `across()` where possible (`across(A1:B2, HLA_prefix_add)`), and use `\(x)` lambdas when extra arguments are needed. Existing `~ f(.)` lambdas are being converted under their own issue (#55); don't convert them as a side effect of unrelated work.
- In the PR description, say which AI tool was used and for what.
