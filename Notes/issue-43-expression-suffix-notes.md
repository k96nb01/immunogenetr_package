# Working notes: Issue #43, expression suffixes in `GLstring_regex`

**Date:** 2026-07-31
**Package:** immunogenetr (dev branch, version 1.4.0.9000, clean tree in sync with origin/dev)
**Issue:** https://github.com/k96nb01/immunogenetr_package/issues/43
**Status:** Implemented, reviewed by NB, committed and pushed to `dev` 2026-08-14. **See §10 for
the resume state — the next step is the SOP §3.2 AI verification pass, then the PR.**

---

## 1. The question as posed

`GLstring_regex()` builds its boundary from GL String delimiters, a colon, and end-of-string:

```r
str_c(str_escape(alleles), "(?=(\\?|\\^|\\||\\+|\\~|/|:|$))")
```

WHO expression suffixes (N, Q, L, S, C, A) are absent from that set, so an allele ending in a
suffix is invisible to a search for its base name.

Nick sketched an `exclude_expression_variants` parameter and worked through four cases against
two test strings:

```r
G1 <- "HLA-A*01:01/HLA-A*01:01:02/HLA-A*01:01:03N"
G2 <- "HLA-A*01:01/HLA-A*01:01:02/HLA-A*01:01N"
```

He then talked himself out of the parameter, leaning toward putting the suffixes into the regex
itself, documenting that an unsuffixed query matches suffixed alleles, and adding a way to filter
non-expressed alleles out of a GL String beforehand.

**Supporting argument for dropping the parameter:** the fourth quadrant is not merely awkward, it
is incoherent. `GLstring_regex("HLA-A*01:01N", exclude_expression_variants = TRUE)` asks the
caller to say "exclude suffixed alleles" while the query itself is a suffixed allele. A parameter
with an undefined quadrant should not ship.

---

## 2. Blast radius (checked, not assumed)

`GLstring_regex()` has **no internal callers**. Grepping `R/`, `tests/`, and `vignettes/` finds
only:

- `tests/testthat/test-GLstring_regex.R`, three assertions pinning the literal regex string
  (lines 6, 7, 9), plus behavioral tests
- `vignettes/immunogenetr.Rmd` lines 244 to 255
- `R/immunogenetr-package.R` line 14, the overview list

So a semantics change is contained. Confirmed the dev tree emits the same pattern as installed
1.4.0, so the results below apply to dev.

---

## 3. The obvious fix is only half a fix

Two candidate patterns were tested:

- **Option A, suffix as a boundary character:** `(?=[NQLSCA]?(\?|\^|\||\+|\~|/|:|$))`
- **Option B, floating suffix:** if the query ends in a suffix, emit
  `HLA\-A\*01\:01(:\d+)*N(?=boundary)`; otherwise use Option A's pattern.

| GL String | query | current | Option A | Option B |
|---|---|---|---|---|
| `HLA-A*01:01:03N` | `HLA-A*01:01` | TRUE | TRUE | TRUE |
| `HLA-A*01:01N` | `HLA-A*01:01` | FALSE | TRUE | TRUE |
| `HLA-A*01:01:03N` | `HLA-A*01:01N` | FALSE | **FALSE** | TRUE |
| `HLA-A*01:01N` | `HLA-A*01:01N` | TRUE | TRUE | TRUE |
| `HLA-A*01:01:03` | `HLA-A*01:01N` | FALSE | FALSE | FALSE |
| `HLA-A*01:010:01` | `HLA-A*01:01` | FALSE | FALSE | FALSE |
| `HLA-A*01:01:03Q` | `HLA-A*01:01N` | FALSE | FALSE | FALSE |

**Row 3 is the finding.** `HLA_truncate("HLA-A*01:01:03N", 2)` returns `HLA-A*01:01N`, and under
Option A that truncated name still does not match the allele it came from. That is the same
truncate-then-search pipeline issue #43 is about, mirrored onto the suffixed side. Option A leaves
it broken.

The suffix is not really a boundary character; it is a component that sits after the last field
regardless of how many fields intervene. Option B is the only variant passing all seven rows,
including the three negative controls (an expressed allele must not answer a null query, a longer
field must not over-match, and `Q` must not answer `N`).

---

## 4. Replacement hazard

The suffix sits inside a lookahead, so it is not consumed and the match text equals the query
rather than the allele found. Harmless for `str_detect`. Not harmless for replacement:

```r
str_replace("HLA-A*01:01N+HLA-A*02:01", GLstring_regex("HLA-A*01:01"), "XXX")
# after the fix: "XXXN+HLA-A*02:01"      <-- dangling suffix
# today:         "HLA-A*01:01N+HLA-A*02:01"  (silent no-op)
```

So the fix trades a silent non-match for a silent corruption. Consuming the suffix into the match
only half solves it, because the extra-fields case (`HLA-A*01:01` matching `HLA-A*01:01:02`) still
returns the query rather than what was found.

**Recommendation:** keep the lookahead, preserving the existing invariant that the match text
equals the query string, and document plus test the replacement hazard.

---

## 5. G and P groups have the identical gap

```r
HLA_truncate("HLA-A*01:01:01G", 2, keep_G_P_group = TRUE)   # "HLA-A*01:01G"
str_detect("HLA-A*01:01:01G", GLstring_regex("HLA-A*01:01G"))  # FALSE
```

Same class of bug, same `HLA_truncate` contradiction. Worth deciding in the same issue so the two
do not drift apart. Suggested resolution: fix only the floating-position half for G and P, and do
**not** make a bare `HLA-A*01:01` match `HLA-A*01:01G`, since a G group is a set of alleles rather
than an allele.

---

## 6. Open decision

Whether to adopt Option B (floating suffix) or Option A (boundary character only). Everything else
above follows either way. Nick is weighing this; nothing should be implemented until he calls it.

## 6a. Decisions made (NB, 2026-08-14)

All open questions above were settled; probe scripts `probe-issue-43-*.R` in this directory hold
the verified matrices behind each call.

1. **Option B (floating suffix), in its "consuming" form.** Both the intervening fields and the
   suffix are consumed rather than held in a lookahead, for bare queries too:
   - bare query: `escaped_query(:\d+)*[NQLSCAGP]?(?=boundary)`
   - suffixed query: `escaped_base(:\d+)*SUFFIX(?=boundary)`
   The match text is therefore always **the full allele name as it appears in the GL String**.
   Rationale (NB): echoing the query back made `str_extract` act like `HLA_truncate` on the found
   allele. Consequences: `str_detect` semantics identical to the lookahead form (verified on all
   16 matrix rows); `str_replace` now replaces the whole allele cleanly, which also fixes the
   pre-existing 1.4.0 corruption where a bare query left dangling fields (`XXX:02`); the §4
   replacement-hazard section is obsolete — the hazard is eliminated, not documented around.
   `str_extract` output changes vs 1.4.0 for bare queries against deeper alleles (full allele
   found instead of the query) — gets its own NEWS sentence.
2. **G/P groups are included, and bare queries match them.** Revised from §5: since a G group
   contains the allele in its name (`A*01:01:01G` contains `A*01:01:01`), a bare query matches
   G/P names (`[NQLSCAGP]?` in the bare arm). A G/P **query** still requires the G/P in the
   target: loosening that would make a G query match any fields-extension of its base, and "G"
   in the query would stop meaning anything. Callers wanting set-coverage search the base name.
3. **`GLstring_drop_non_expressed()` ships in the same release as a standalone feature**, not as
   a safety valve — the coupling argument in §8 was withdrawn after concluding the regex change
   is neutral-or-corrective for known downstream use (bead panels carry no null alleles, so bare
   queries against bead alleles are unaffected, and a bare query newly matching a kept L/Q/A
   allele is the desired behavior).

---

## 7. The filter function: build it, it is nearly free

Nothing in the 22 exports removes alleles from a GL String. `HLA_truncate(keep_suffix = FALSE)`
does the opposite, stripping the letter and turning a null allele into its expressed name.

But the machinery already composes, and the hard structural cases were verified working:

```r
GLstring_expand_longer(GL) |>
  dplyr::filter(!stringr::str_detect(value, "[NSC]$")) |>
  ambiguity_table_to_GLstring()
```

| input | output |
|---|---|
| `HLA-A*01:01N+HLA-A*02:01^HLA-B*07:02/HLA-B*07:02N+HLA-B*08:01^HLA-C*01:02N+HLA-C*03:04N` | `HLA-A*02:01^HLA-B*07:02+HLA-B*08:01` |
| `HLA-A*01:01N+HLA-A*02:01N^HLA-B*07:02+HLA-B*08:01` | `HLA-B*07:02+HLA-B*08:01` |
| `HLA-A*01:01N` | **errors:** ``​`data` must have at least one row`` |

An emptied allele-ambiguity list narrows, an emptied gene copy collapses, and an all-null locus
disappears along with its `^`, with no dangling delimiters. So this is a thin wrapper, not new
machinery. It needs to add:

- a **`suffixes` argument**, because "non-expressed" is a clinical judgement rather than a fact.
  A reasonable clinical default drops N, S, and C while deliberately keeping L, Q, and A. Default to
  `c("N", "S", "C")` and let callers narrow to `"N"`.
- **`NA_character_`** when everything is dropped, instead of the zero-row error above.
- **vectorization** over a character vector, which the round trip gives free via the `entry` column.

A version of `GLstring_drop_non_expressed()` already exists in a downstream clinical report and is
the obvious thing to promote. Note that local copy only splits on `^`, `+`, and `/`, so it would
mangle a GL String carrying `?`, `|`, or `~`. The package version gets those three levels free.

**Naming:** suggested exporting the specific `GLstring_drop_non_expressed()` rather than a general
`GLstring_filter_alleles()`, at least initially. The specific name carries the clinical meaning,
and a general pattern argument invites regexes that break the full-allele-name contract
`GLstring_regex()` exists to enforce.

---

## 8. Sequencing

Ship the regex fix and the filter function in the **same release**. The regex fix is what removes
the accidental protection downstream users may be relying on, so the replacement must land with
it. NEWS should say so explicitly rather than leaving it to be discovered.

---

## 9. Reproducing this

Environment gotcha: `Rscript.exe -e` fails on Windows when the expression contains a `|`, with
"The system cannot find the path specified", from both PowerShell and Git Bash. GL String regexes
are full of `|`, so **write a script file** and run `Rscript file.R`.

```r
# probe.R
suppressMessages({library(stringr); library(dplyr)})
devtools::load_all(".", quiet = TRUE)

boundary <- "(\\?|\\^|\\||\\+|\\~|/|:|$)"
optA <- function(a) str_c(str_escape(a), "(?=[NQLSCA]?", boundary, ")")
optB <- function(a) {
  m <- str_match(a, "^(.*?)([NQLSCA])$")
  ifelse(is.na(m[, 1]),
    str_c(str_escape(a), "(?=[NQLSCA]?", boundary, ")"),
    str_c(str_escape(m[, 2]), "(:\\d+)*", m[, 3], "(?=", boundary, ")"))
}

cases <- list(
  c("HLA-A*01:01:03N", "HLA-A*01:01"), c("HLA-A*01:01N",    "HLA-A*01:01"),
  c("HLA-A*01:01:03N", "HLA-A*01:01N"), c("HLA-A*01:01N",    "HLA-A*01:01N"),
  c("HLA-A*01:01:03",  "HLA-A*01:01N"), c("HLA-A*01:010:01", "HLA-A*01:01"),
  c("HLA-A*01:01:03Q", "HLA-A*01:01N")
)
for (cs in cases) {
  cat(sprintf("%-18s ~ %-14s current=%-5s A=%-5s B=%-5s\n", cs[1], cs[2],
      str_detect(cs[1], GLstring_regex(cs[2])),
      str_detect(cs[1], optA(cs[2])), str_detect(cs[1], optB(cs[2]))))
}

# Round trip
GL <- "HLA-A*01:01N+HLA-A*02:01^HLA-B*07:02/HLA-B*07:02N+HLA-B*08:01^HLA-C*01:02N+HLA-C*03:04N"
GLstring_expand_longer(GL) |>
  filter(!str_detect(value, "[NSC]$")) |>
  ambiguity_table_to_GLstring() |>
  cat("\n")
```

---

## 10. When work resumes

> **▶ Resume here.** Everything in this file plus §6a is **implemented, NB-reviewed, and
> pushed to `dev`** (2026-08-14, commits `f7f6cf1` notes, `5ce1e23` package changes,
> `3d27455` SOP/.Rcheck cleanup; version still 1.4.0.9000). 602 tests pass;
> `devtools::check()` gave 0 errors / 0 warnings plus one spurious `''NULL''` NOTE that is an
> artifact of running check via Rscript on Windows — re-confirm 0/0/0 from RStudio.
>
> Scope grew beyond §6a during implementation, all NB-approved:
> - **Optional `HLA-` prefix** (NB request): the query is canonicalized by stripping any
>   `HLA-`, the pattern re-adds it as optional, and a **left boundary** (start-of-string or GL
>   delimiter, via lookbehind) replaces the old mandatory-prefix rule as the protection
>   against matching inside longer locus names (`A*008:01` must not match in `MICA*008:01`).
>   Locus-less queries (`02:01`) still error. Tests cover MICA/MICB/KIR.
> - `GLstring_regex(NA)` now fails with a clean `cli_abort` instead of a raw base error.
> - SOP: new §3.2 "AI verification pass"; `immunogenetr.Rcheck` untracked and gitignored.
>
> **Next steps, in order:**
> 1. **Run the SOP §3.2 AI verification pass** over `git diff master...dev`. This is
>    *required*, not optional: a first pass ran mid-development (no functional findings), but
>    the optional-prefix work, MICA/KIR tests, NA polish, and SOP/housekeeping commits all
>    landed *after* it and have had no independent cold read.
> 2. Fix any findings (NB reviews before every commit), then open the PR into `master` per
>    SOP Phase 3 and let CI go green. The release would be 1.5.0 (new exported function).
> 3. Parked questions, none blocking: should a G/P query also match its bare base allele in a
>    GL String (kept strict: the target must carry the G/P letter)? Should the hypothetical
>    `HLA-MICA*...` form matching a MICA query be pinned or excluded (currently unpinned)?
>    Should old-literature MICA STR names (`A5.1`-style) get explicit test coverage?
