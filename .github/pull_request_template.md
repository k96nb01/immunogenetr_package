## Summary

<!-- What changed and why, in a few sentences. -->

Part of #

<!-- Use "Part of #N", not "Closes #N": PRs into dev don't auto-close issues. The maintainer closes the issue on merge. -->

## Testing

<!-- devtools::check() result, plus any manual checks or new tests. -->

## AI use

<!-- Which AI tool(s) you used (Claude Code, Codex, Copilot, ...) and for what. Write "None" if none. -->

## Verification pass

<!-- Required if an AI tool wrote or edited any of this PR (AGENTS.md rule 1, SOP §3.2). -->

- Reviewer: <!-- e.g. Claude Code subagent, `codex exec` in a fresh context, or "N/A (no AI-written changes)" -->
- Rounds: <!-- how many passes until clean -->
- Findings and fixes: <!-- one line each, or "No findings" -->

## Checklist

- [ ] Branch cut from an up-to-date `dev`; PR targets `dev` (release PRs: `dev` → `master`)
- [ ] `devtools::document()` run and regenerated files committed
- [ ] Tests added or updated for behavior changes
- [ ] `NEWS.md` bullet added with the issue number
- [ ] `devtools::check()` clean
- [ ] No private data, PHI, or references to institutional systems
