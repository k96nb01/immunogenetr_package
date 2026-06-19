# Working notes — Issue #40: asterisk handling, Cw/C naming, and a `nomenclature` parameter

**Date:** 2026-06-18
**Package:** immunogenetr (dev branch, version 1.3.0.9000)
**Issue:** https://github.com/k96nb01/immunogenetr_package/issues/40
**Status:** Diagnosis complete; design agreed. **No code written yet** — deferred by request to capture the plan first.
**Related:** [issue-33-serologic-nomenclature-notes.md](issue-33-serologic-nomenclature-notes.md) — same nomenclature problem space; share the locus maps and the interactive-helper idea.

---

## 1. The report

A donor GL string produced by `HLA_columns_to_GLstring` caused `HLA_mismatch_number` to error.

Reproduction from the issue:

```r
# Source table
table <- structure(
  list(Cw1Cd.donor = "w7", Cw2Cd.donor = "*17"),
  row.names = c(NA, -1L), class = c("tbl_df", "tbl", "data.frame")
)
HLA_columns_to_GLstring(table, c(Cw1Cd.donor, Cw2Cd.donor))
# dev/1.3.0 output: "HLA-Cw7+HLA-Cw*17"   <-- malformed

# Downstream mismatch call
recip <- "HLA-Cw10+HLA-Cw6"
donor <- "HLA-Cw7+HLA-Cw*17"
HLA_mismatch_number(recip, donor, "HLA-Cw", direction = "SOT", homozygous_count = 1)
# Error: "The recipient and/or donor GL strings are missing these loci: 'HLA-Cw'."

# Removing the "*" makes the mismatch call work:
HLA_mismatch_number(recip, "HLA-Cw7+HLA-Cw17", "HLA-Cw", direction = "SOT", homozygous_count = 1)
# [1] 2
```

The issue itself proposed "probably two bugs": (1) `HLA_mismatch_x` should accept a serologic allele with an asterisk; (2) `HLA_columns_to_GLstring` should handle entries with asterisks.

---

## 2. Empirical version history (tested, not assumed)

Tested the exact reproduction against three source trees by loading each with `pkgload::load_all`:
v1.2.0 (tag), v1.3.0 (tag), and dev (1.3.0.9000). R 4.6.0.

| | `Cw` col `w7`+`*17` | `Cw` col `*07:01` (colon) | mismatch on `HLA-Cw*17` | mismatch on `HLA-Cw17` |
|---|---|---|---|---|
| **1.2.0** | `HLA-Cw7+HLA-Cw17` ✅ | `HLA-Cw*07:01` ❌ | ERROR (missing locus) | `2` ✅ |
| **1.3.0** | `HLA-Cw7+HLA-Cw*17` ❌ | `HLA-Cw*07:01` ❌ | ERROR (missing locus) | `2` ✅ |
| **dev**   | `HLA-Cw7+HLA-Cw*17` ❌ | `HLA-Cw*07:01` ❌ | ERROR (missing locus) | `2` ✅ |

**Conclusion — the bug has two halves, and Half 1 is narrower than first thought:**

- **Half 1 — the malformed `HLA-Cw*…` output. The `Cw` locus-naming defect is mostly PRE-EXISTING** (1.2.0 emits `HLA-Cw*07:01` too — see the colon column). It surfaces for *any* molecular value the `Cw` column classifies as molecular (colon / leading-zero). **Only the bare-`*` case is a true 1.3.0 regression:** `*17` (no colon, no leading zero) was serologic `HLA-Cw17` in 1.2.0 but became molecular `HLA-Cw*17` in 1.3.0, via the new `has_asterisk` rule. So "go back to the 1.2.0 default" means specifically *restore the bare-`*` = serologic behavior*; it does **not** by itself fix the colon case (which was always malformed).
- **Half 2 — mismatch functions choking on an asterisk in a serologic-style allele — is fully pre-existing.** All three versions error identically. It was simply never *reached* in 1.2.0 because nothing produced that malformed string.

---

## 3. Root cause — Half 1 (two distinct sub-issues)

### 3a. Classification (the bare-`*` regression)

The 1.3.0 "Iteration 6" rewrite of `HLA_columns_to_GLstring` (merge of `immunogenetr_fast`, commit `d46b11c`) added a new molecular-classification clause that did not exist in 1.2.0:

```r
has_asterisk   <- !is.na(raw) & grepl("*", raw, fixed = TRUE)
molecular_cell <- has_colon | has_leading_zero | has_asterisk | is_mol_col[col_idx]
```

The `has_asterisk` clause was added (correctly) to rescue low-resolution molecular alleles like `A*01` / `B*07` (no colon, no leading zero) that 1.2.0 misclassified as serologic (`HLA-A01`) — the PIRCHE / Hilary Mehler bug, which has a regression test. But it is **too broad**: it also captures a **bare leading `*`** like `*17`, which 1.2.0 treated as serologic (`HLA-Cw17`).

**Fix (Option Y, decided 2026-06-19):** narrow the rule so a `*` signals molecular **only when it is not the first character** — i.e. `has '*' AND does not start with '*'`. This keeps `A*01` molecular (preserves the PIRCHE fix) while restoring `*17` to serologic (matches 1.2.0). Verified against all probed cases; breaks no existing test (every PIRCHE/DRB test has a token before the `*`).

### 3b. Emit-side locus naming (pre-existing, fixed by default under Option Y)

This defect is **not** new in 1.3.0 — 1.2.0 emits `HLA-Cw*07:01` for a colon-bearing molecular value in a `Cw` column too. The defect is on the **emit** side, not the classify side:

```r
final_type <- ifelse(
  molecular_cell,
  paste0(molecular_locus, "*", allele_clean),   # <-- molecular_locus is "HLA-Cw" for a Cw column
  paste0(serologic_name_c, allele_clean)
)
```

`molecular_locus` comes from the column-name cascade, which returns the **serologic** label `HLA-Cw` for a `Cw…` column. So a molecular value in a `Cw` column emits `HLA-Cw` + `*` + `17` = `HLA-Cw*17`. That string is neither valid molecular (`HLA-C*17`) nor valid serologic (`HLA-Cw17`).

**Fix:** the molecular branch must emit a **molecular** locus name. `Cw → C`. See §5 for the full map.

### Domain context (why `*17` exists in a `Cw` column at all)

For a long time HLA-C\*17 alleles had **no serologic equivalent**, so labs could not write `Cw17`. They recorded `*17` in the `Cw` column alongside genuine serologic Cw antigens (e.g. `Cw9`). So `*17` in a `Cw` column is *molecular by intent* — the `*`=molecular rule is correct. The only error is the output locus label.

---

## 4. Root cause — Half 2 (pre-existing mismatch fragility)

In `HLA_mismatch_base`, `extract_locus_name` does **not** parse a locus per allele. By the time it runs, all alleles for one locus group are already rejoined with `+`, so it receives the whole group string (`"HLA-Cw7+HLA-Cw*17"`). Its molecular rule is a slice — "everything before the first `*`":

```r
has_star  <- grepl("*", allele_str, fixed = TRUE)
star_pos  <- regexpr("*", allele_str[mol_ix], fixed = TRUE)
out[mol_ix] <- substr(allele_str[mol_ix], 1L, star_pos - 1L)
```

That slice only lands on the right locus when the **first** allele in the group is molecular. In `HLA-Cw7+HLA-Cw*17` the first allele is serologic (no `*`), so the slice runs past the `+` and yields `HLA-Cw7+HLA-Cw`, which matches no requested locus → "missing locus" error.

Confirmed by experiment (dev): asterisk-allele **second** errors; asterisk-allele **first** (`HLA-Cw*17+HLA-Cw7`) returns `2`. For a clean single `HLA-Cw*17` it would extract `HLA-Cw` correctly. The failure is specifically a **mixed-nomenclature group** (serologic + molecular under one locus) hitting the "first asterisk" heuristic.

**✅ Fixed (2026-06-19).** `extract_locus_name` now parses the locus from the **first allele** of each `+`-joined group (the group is one locus, so the first allele's locus is the group's locus) instead of slicing the whole rejoined string before the first `*`. Robust regardless of allele order or how the GL string was produced. Verified: the exact issue #40 call `HLA_mismatch_number("HLA-Cw10+HLA-Cw6", "HLA-Cw7+HLA-Cw*17", "HLA-Cw", direction = "SOT", homozygous_count = 1)` now returns `2` (was a "missing locus" error). Regression tests added to `test-HLA_mismatch_base.R` (asterisk-first and asterisk-second). Full suite green (494 pass).

---

## 5. Agreed design — `HLA_columns_to_GLstring`

> **Status (2026-06-19): both halves of issue #40 IMPLEMENTED.** §5 (`HLA_columns_to_GLstring`: Option Y default + `nomenclature` parameter + canonical-locus grouping + DR `"mol"` lookup + Bw guard + `DPB` label) and §4 (`extract_locus_name` first-allele parse in `HLA_mismatch_base`) are done. Full suite green (494 pass, 0 fail). Original workflow resolves end-to-end, and the exact reported `HLA_mismatch_number` call returns `2`. **Still deferred:** the companion interactive helper (§6) and reconciling DPB allele-level semantics with issue #33.

### 5.1 Auto-detection (default) — refined per Option Y

A cell is molecular if it contains `:`, starts with `0`, contains a **non-leading** `*`, or is a DQA1/DPB1/DPA1 column. The change from dev: a **bare leading `*`** is no longer a molecular signal (§3a). This is the default when `nomenclature` is not supplied, and the full default behavior is specified in §5.3 ("Default behavior — Option Y").

### 5.2 Standalone naming fix (the Half-1 emit defect)

On the molecular branch, emit molecular locus names. **Only `Cw → C` is affected** in the auto-detect path. Under Option Y this applies **by default** (not just under `nomenclature = "mol"`), so a genuinely-molecular `Cw` value emits `HLA-C*…`. `Bw` is special — see §5.5.

### 5.3 New `nomenclature` parameter — naive relabel only

Declares the **output** nomenclature per locus. Performs **structural relabeling only** — no era/translation tables in this package (see §6).

Two accepted forms:

```r
# Scalar: one nomenclature for every selected locus
HLA_columns_to_GLstring(data, HLA_typing_columns, nomenclature = "mol",
                        prefix_to_remove = "", suffix_to_remove = "")

# Named vector: per-locus, keyed by molecular locus name (tidyselect-style)
HLA_columns_to_GLstring(data, HLA_typing_columns,
  nomenclature = c("HLA-Cw" = "ser", "HLA-DRB1" = "mol"),
  prefix_to_remove = "", suffix_to_remove = "")
```

Values: `"mol"` (molecular) / `"ser"` (serologic). Default (absent): current auto-detect.

**The parameter is locus-wide, and a locus is a single entity regardless of nomenclature spelling.** This is firm (NB, 2026-06-19):

- `C`, `Cw`, and `C*…` are all the **same locus**. The function must recognize every spelling as one locus when grouping. Likewise `DR`/`DRB1`, `DQ`/`DQB1`, etc.
- **A locus is never split across `^`.** `^` separates *loci*; `+` joins entries *within* a locus. So `HLA-Cw7^HLA-C*17` is **forbidden output** — those are the same locus and must share one `+`-joined group. (My earlier "split" idea was wrong.)
- When `nomenclature` declares a locus `"mol"` or `"ser"`, **every** entry at that locus is converted to the chosen spelling, then grouped together.
- The named-vector **key may be given in either spelling** — `c("HLA-Cw" = "ser")` and `c("HLA-C" = "ser")` are equivalent (both name the C locus). Internally normalize the key to a canonical locus identity.

**✅ Default behavior (RESOLVED — Option Y, NB 2026-06-19).** With no `nomenclature` argument the function does **per-cell auto-detect**, restoring 1.2.0 behavior for the ambiguous bare-`*` case *and* always using clean molecular locus names:

- Classification: molecular if it contains `:`, starts with `0`, contains a **non-leading** `*`, or is a DQA1/DPB1/DPA1 column (§3a). A **bare leading `*` is serologic** (the `*` is stripped) → `*17` ⇒ `HLA-Cw17`.
- Naming: a genuinely-molecular `Cw` value emits the **molecular** locus name → `*07:01` ⇒ `HLA-C*07:01` (not the malformed `HLA-Cw*07:01`). This is the "always-clean" half of Option Y; it goes beyond literal 1.2.0 (which emitted the malformed form).
- Grouping uses the **canonical locus identity** (§5.4), so a mixed-nomenclature locus stays one `+` group, never `^`-split. Worked example: `Cw` column `*17` + `*07:01` ⇒ `HLA-Cw17+HLA-C*07:01` (one C group, mixed spelling — honest, since the two values genuinely differ in nomenclature and we don't translate).
- Net: issue #40 default ⇒ `HLA-Cw7+HLA-Cw17` (= 1.2.0). The `nomenclature` parameter is the way to force a single nomenclature across the locus.

(Option X — strict literal 1.2.0, leaving `HLA-Cw*07:01` malformed by default — was rejected.)

Relabel rules:

- **`"mol"`** — strip a leading `w` and any `*`, then emit `<molecular-locus>*<allele>`.
  - `*17` / `w17` → `HLA-C*17`.
  - **Improper output is acceptable.** `w9 → HLA-C*9` is not valid nomenclature, but the package does not validate it — that is the companion helper's job (§6).
- **`"ser"`** — strip any `*`, then emit `<serologic-locus><allele>`.
  - `*17` → `HLA-Cw17`.

### 5.4 Canonical locus-identity table (labels only — never translate the allele itself)

This table defines **which spellings are the same locus**. It serves two jobs: (a) grouping — all spellings of a locus collapse to one canonical identity so the locus is never `^`-split; (b) relabeling — the chosen output nomenclature picks the column to emit. The named-vector key may be supplied in **either** column and is normalized to the canonical locus.

| canonical locus | molecular spelling | serologic spelling |
|---|---|---|
| A | A | A *(same)* |
| B | B | B *(same)* |
| C | C | Cw |
| DRB1 | DRB1 | DR |
| DRB3 | DRB3 | DR51 *(see §5.6)* |
| DRB4 | DRB4 | DR53 *(see §5.6)* |
| DRB5 | DRB5 | DR52 *(see §5.6)* |
| DQB1 | DQB1 | DQ |
| DQA1 | DQA1 | DQA |
| DPB1 | DPB1 | **DPB** |
| DPA1 | DPA1 | DPA |
| **Bw** | *(none — epitope)* | Bw *(never relabeled; see §5.5)* |

Only loci whose molecular and serologic names **differ** (C, DR/DRB·, DQ, DQA, DP·) can be `^`-split by the *current* code, because A/B already share one label. The unification work must make every row above collapse to one group.

**⚠ Fix the existing `serologic_map`:** it currently maps `HLA-DPB1 → HLA-DP`. `DP` was the pre-formalization label; the formalized serologic name is **`DPB`**. Update `DP → DPB`. This must stay in sync with the issue-33 serologic work.

> Note on DR51/52/53 ↔ DRB5/3/4: the serologic→molecular mapping is **not** numeric-sequential (51→DRB**5**, 52→DRB**3**, 53→DRB**4**). See §5.6.

### 5.5 Bw is an epitope — never relabel

`Bw` is an epitope, only ever `Bw4` / `Bw6`, with **no molecular form**. There is **no `Bw → B` mapping**. Never force a `Bw` column molecular; never turn `Bw4` into `B*4`. Leave `HLA-Bw` untouched in all branches.

### 5.6 DR under `"mol"` — uses a fixed lookup

DR51/52/53 are broad serologic specificities indicating *presence* of a DRB3/4/5 gene; they carry **no allele information**. So the serologic number is consumed as the **locus indicator** and the allele field becomes the `XX` unknown-placeholder (DR52 ≠ DRB3\*52):

| serologic | molecular |
|---|---|
| 51 | `HLA-DRB5*XX` |
| 52 | `HLA-DRB3*XX` |
| 53 | `HLA-DRB4*XX` |
| anything else | `HLA-DRB1*<value>` (e.g. `17` → `HLA-DRB1*17`) |

(Format confirmed as `*XX`, the package's standard unknown-allele placeholder.)

### 5.7 DQ under `"mol"`

Nothing special: `DQ → DQB1`, value carried as-is (`7` → `HLA-DQB1*7`).

---

## 6. Companion interactive helper (separate function)

A separate, opt-in function for exploratory work:

- Scans a table and reports cells that would produce **non-existent antigens** (e.g. the `HLA-C*9` from a `w9` forced to molecular).
- Holds the **era/translation tables** (e.g. the serologic↔molecular renames, `A203 → A0203`).
- Keeps the core `HLA_columns_to_GLstring` pure, reproducible, and non-interactive.

Translation (especially serologic → molecular, which is one-to-many) is **out of scope** for the core function and stays behind this helper. See issue-33 notes §5.3 for the broader interactive-helper discussion.

---

## 7. Decisions locked in (2026-06-18, updated 2026-06-19)

1. `*`=molecular, but **refined** (Option Y, 2026-06-19): a `*` signals molecular only when **not the first character**. A bare leading `*` (e.g. `*17`) is serologic — restores 1.2.0 while keeping the PIRCHE `A*01` fix (§3a).
2. Half-1 has two parts: (a) the bare-`*` classification regression (1.3.0-only, §3a); (b) the emitted-locus-label defect `Cw → C` (mostly pre-existing, §3b). Both fixed **by default** under Option Y.
3. **Default mode = Option Y** (§5.3): restore 1.2.0 for the bare-`*` case **and** always emit clean molecular locus names. Issue #40 default ⇒ `HLA-Cw7+HLA-Cw17`. Option X (strict 1.2.0, leaving `HLA-Cw*07:01` malformed) was rejected.
4. A locus is one entity across nomenclatures; **never `^`-split** it. Group on canonical locus identity (§5.4).
5. `Bw` is an epitope: never relabeled, never forced molecular.
6. New `nomenclature` parameter: tidyselect-style, `"mol"`/`"ser"`, scalar **or** per-locus named vector (key accepted in either spelling); default = Option-Y auto-detect.
7. Relabeling is **naive/structural only**. No era-translation in this package. Improper outputs (`HLA-C*9`) are allowed; the helper validates.
8. `serologic_map`: change `DPB1: DP → DPB`; keep in sync with issue #33.
9. The mismatch `extract_locus_name` fragility is real and pre-existing — **defer the fix**, but record it.
10. **Tests written first (2026-06-19):** `tests/testthat/test-HLA_columns_to_GLstring_nomenclature.R` — Part A locks current behavior; Part B is the `skip()`-guarded spec (un-skip per piece as implemented). Function code itself **not yet modified**.

---

## 8. TODO / where to pick up

> **▶ Resume here (next session).** Issue #40 is **functionally complete** — both halves fixed, committed, and pushed to `dev` (commits `8d9b502`, `1a3d647`); working tree clean; full suite 494 pass. Nothing on issue #40 is blocking. Remaining work is **optional/follow-on**, in rough priority order:
> 1. **Companion interactive helper** (§6) — the next substantive build. Scans a table, warns on would-be non-existent antigens, holds era-translation tables. Decide first: own function vs. depend on HLAtools (issue-33 §4.4).
> 2. **`nomenclature` arg position** — currently last (back-compat). Decide whether to move it earlier before any release/version bump.
> 3. **DPB allele-level serologic semantics** — only the *label* (`DPB`) is settled; the value rules belong to **issue #33** (see [issue-33 notes](issue-33-serologic-nomenclature-notes.md)).
> 4. Separate threads in §9 (HLA- prefix tolerance; colleague PDF/txt for issue #33).
>
> No version bump / NEWS entry was made (still `1.3.0.9000`); add one if/when these changes go toward a release per the package-update SOP.

- [x] **Test fixtures** (2026-06-19): `tests/testthat/test-HLA_columns_to_GLstring_nomenclature.R`. Part A (8 tests, passing) locks current behavior; Part B (14 tests, `skip()`-guarded) is the Option-Y spec — issue-40 default, bare-`*` serologic, Option-Y clean naming, never-`^`-split invariant, `mol`/`ser` scalar + named-vector forms, cross-spelling key, DR 51/52/53→DRB·, Bw untouched, DPB label.
- [x] **`HLA_columns_to_GLstring`** — implemented §5 (2026-06-19): Option-Y classification (bare-`*` serologic), canonical-locus grouping + Cw→C clean naming, `nomenclature` scalar + named-vector (cross-spelling keys), DR `"mol"` 51/52/53→DRB·*XX lookup, Bw guard, `DPB` label. `man/` regenerated.
- [x] `serologic_map`: `DPB1: DP → DPB` done (§5.4). *Still reconcile the allele-level DPB semantics with issue #33.*
- [x] **Regression guard:** full suite green — 492 pass, 0 fail (incl. the PIRCHE low-res test and `test_sero`).
- [x] **Characterization test deleted** and replaced by Part B "DESIRED (default)". §2 dev row is now effectively `HLA-Cw7+HLA-Cw17`.
- [x] **`extract_locus_name`** (`HLA_mismatch_base.R`) — done (2026-06-19): parses the locus from the first allele of each group. Both halves of issue #40 now resolved; even a hand-written/legacy `HLA-Cw*17` no longer errors in the mismatch functions.
- [ ] Build the companion interactive helper (§6); decide where era-translation lives (own function vs. HLAtools dependency — see issue-33 §4.4).
- [ ] Decide whether to keep `nomenclature` as the last argument (chosen for back-compat) or move it earlier before a release.

---

## 9. Not addressed today (separate threads from the same 2026-06-18 message)

- **`HLA-` prefix tolerance** — make all functions accept `A*02:01` as readily as `HLA-A*02:01`, including inside GL strings (`A*02:01+A*03:01` ≡ `HLA-A*02:01+HLA-A*03:01`). Separate task.
- **Colleague replies** — `Responses from Eric and Loren.pdf` and the accompanying txt in this folder; feed into the issue-33 serologic design.
