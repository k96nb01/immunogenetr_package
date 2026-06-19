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

| | `HLA_columns_to_GLstring("*17")` | mismatch on `HLA-Cw*17` | mismatch on `HLA-Cw17` |
|---|---|---|---|
| **1.2.0** | `HLA-Cw7+HLA-Cw17` ✅ | ERROR (missing locus) | `2` ✅ |
| **1.3.0** | `HLA-Cw7+HLA-Cw*17` ❌ | ERROR (missing locus) | `2` ✅ |
| **dev**   | `HLA-Cw7+HLA-Cw*17` ❌ | ERROR (missing locus) | `2` ✅ |

**Conclusion — the bug has two halves with different histories:**

- **Half 1 (`HLA_columns_to_GLstring` emitting `HLA-Cw*17`) is a 1.3.0 regression.** 1.2.0 produced the clean `HLA-Cw17` for the same input.
- **Half 2 (mismatch functions choking on an asterisk in a serologic-style allele) is pre-existing.** All three versions error identically. It was simply never *reached* in 1.2.0 because nothing produced that malformed string.

---

## 3. Root cause — Half 1 (the 1.3.0 regression)

The 1.3.0 "Iteration 6" rewrite of `HLA_columns_to_GLstring` (merge of `immunogenetr_fast`, commit `d46b11c`) added a new molecular-classification clause that did not exist in 1.2.0:

```r
has_asterisk   <- !is.na(raw) & grepl("*", raw, fixed = TRUE)
molecular_cell <- has_colon | has_leading_zero | has_asterisk | is_mol_col[col_idx]
```

This `has_asterisk` clause is **working as intended** and we are **keeping it**. A `*` is a correct molecular signal; it was added to rescue low-resolution molecular alleles like `A*01` / `B*07` (no colon, no leading zero) that 1.2.0 misclassified as serologic.

The actual defect is on the **emit** side, not the classify side:

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

**Fix (deferred, recorded):** make `extract_locus_name` parse each allele's locus individually rather than slicing the rejoined group. Robust regardless of how the GL string was produced. **Decision: leave for later** — once `HLA_columns_to_GLstring` emits a single consistent nomenclature per locus, the mismatch path stops seeing mixed groups in practice. Come back and harden it anyway.

---

## 5. Agreed design — `HLA_columns_to_GLstring`

> **Status: deferred.** Per 2026-06-18 decision, do **not** modify `HLA_columns_to_GLstring` yet (not even the standalone `Cw → C` fix). Capture here; implement later.

### 5.1 Auto-detection — unchanged

A cell is molecular if it contains `*`, `:`, or a leading `0`. Keep exactly as-is. This stays the **default** behavior when `nomenclature` is not supplied (backward compatible).

### 5.2 Standalone naming fix (the Half-1 bug)

On the molecular branch, emit molecular locus names. **Only `Cw → C` is affected** in the auto-detect path. `Bw` is special — see §5.5.

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

Relabel rules:

- **`"mol"`** — strip a leading `w` and any `*`, then emit `<molecular-locus>*<allele>`.
  - `*17` / `w17` → `HLA-C*17`.
  - **Improper output is acceptable.** `w9 → HLA-C*9` is not valid nomenclature, but the package does not validate it — that is the companion helper's job (§6).
- **`"ser"`** — strip any `*`, then emit `<serologic-locus><allele>`.
  - `*17` → `HLA-Cw17`.

### 5.4 Locus-label maps (labels only — never translate the allele itself)

| molecular | serologic |
|---|---|
| C | Cw |
| DRB1 / DRB3 / DRB4 / DRB5 | DR |
| DQB1 | DQ |
| DQA1 | DQA |
| DPB1 | **DPB** |
| DPA1 | DPA |

**⚠ Fix the existing `serologic_map`:** it currently maps `HLA-DPB1 → HLA-DP`. `DP` was the pre-formalization label; the formalized serologic name is **`DPB`**. Update `DP → DPB`. This must stay in sync with the issue-33 serologic work.

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

## 7. Decisions locked in (2026-06-18)

1. Keep the `*`=molecular auto-detection rule. It works as intended.
2. The Half-1 defect is the **emitted locus label** (`Cw → C` on the molecular branch), not classification.
3. `Bw` is an epitope: never relabeled, never forced molecular.
4. New `nomenclature` parameter: tidyselect-style, `"mol"`/`"ser"`, scalar **or** per-locus named vector; default = current auto-detect.
5. Relabeling is **naive/structural only**. No era-translation in this package. Improper outputs (`HLA-C*9`) are allowed; the helper validates.
6. `serologic_map`: change `DPB1: DP → DPB`; keep in sync with issue #33.
7. The mismatch `extract_locus_name` fragility is real and pre-existing — **defer the fix**, but record it.
8. **Do not modify `HLA_columns_to_GLstring` yet** — capture the plan first (this note), implement later.

---

## 8. TODO / where to pick up

- [ ] **`HLA_columns_to_GLstring`** — implement §5: the `Cw → C` molecular-naming fix **plus** the `nomenclature` parameter together (one design pass over the locus-naming logic).
- [ ] Fix `serologic_map`: `DPB1: DP → DPB` (§5.4) — reconcile with issue #33.
- [ ] **`extract_locus_name`** (`HLA_mismatch_base.R`) — parse locus per-allele instead of slicing before the first `*` (§4).
- [ ] **Test fixtures:** the exact issue-40 reproduction; `mol`/`ser` scalar and named-vector forms; the DR 51/52/53→DRB5/3/4 lookup; `Bw4`/`Bw6` left untouched; mixed-nomenclature mismatch groups (asterisk-first and asterisk-second).
- [ ] **Regression guard:** A/B/C/DR/DQ output for existing inputs must be byte-identical when `nomenclature` is not supplied.
- [ ] Build the companion interactive helper (§6); decide where era-translation lives (own function vs. HLAtools dependency — see issue-33 §4.4).
- [ ] Sanity-check the empirical version table (§2) survives once fixes land.

---

## 9. Not addressed today (separate threads from the same 2026-06-18 message)

- **`HLA-` prefix tolerance** — make all functions accept `A*02:01` as readily as `HLA-A*02:01`, including inside GL strings (`A*02:01+A*03:01` ≡ `HLA-A*02:01+HLA-A*03:01`). Separate task.
- **Colleague replies** — `Responses from Eric and Loren.pdf` and the accompanying txt in this folder; feed into the issue-33 serologic design.
