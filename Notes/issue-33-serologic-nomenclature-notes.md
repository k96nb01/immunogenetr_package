# Working notes — Issue #33: serologic nomenclature for DQA1/DPA1/DPB1 (and beyond)

**Date:** 2026-06-10 (updated 2026-06-20)
**Package:** immunogenetr (dev branch, version 1.3.0.9000)
**Issue:** https://github.com/k96nb01/immunogenetr_package/issues/33
**Status:** Design / scoping. No issue-#33 code written yet. **Key approach decided 2026-06-20: encode nomenclature PATTERNS, not reference tables (see §5.4).** Realistic dev data now available (`HLA_typing_synthetic_LIS`, see §6). The issue-#40 work already landed the structural locus-identity backbone this builds on.

---

## 1. The trigger

The WHO 2026-04 update introduced serologic nomenclature for **HLA-DQA1, HLA-DPA1, and HLA-DPB1**, three loci that previously had no serologic equivalents. The package contains a hard-coded shortcut — "any value in a DQA1/DPA1/DPB1 column is molecular" — that was safe before the update and is now wrong.

The deeper we looked, the broader the problem became. It is no longer just about three loci. The 2026 nomenclature also reshaped **associated antigens**, which collide with legacy molecular notation across the classical loci (A/B/C/DR) too.

---

## 2. How `HLA_columns_to_GLstring` works today

The function converts HLA typing spread across columns into a GL string. For each cell it decides **molecular vs. serologic**, then emits the appropriate form.

Classification-relevant steps:

1. **Locus from column name** — a prefix cascade maps each column to a molecular locus (`A1` → `HLA-A`, `DQA1` → `HLA-DQA1`, `DPB1` → `HLA-DPB1`, etc.).
2. **Serologic name map** — each molecular locus also has a serologic name. This map already encodes the "drop the trailing 1" rule:
   - `HLA-DQA1` → `HLA-DQA`
   - `HLA-DPA1` → `HLA-DPA`
   - `HLA-DPB1` → `HLA-DP`  ⚠ **outdated** — the formalized serologic name is `HLA-DPB`, not `HLA-DP` (`DP` predates formalization). Fix to `DPB`. See [issue-40-asterisk-nomenclature-notes.md](issue-40-asterisk-nomenclature-notes.md) §5.4.
   - `HLA-DQB1` → `HLA-DQ`
   - `HLA-DRB1` → `HLA-DR`
3. **Per-cell molecular test** (the heart of the issue):
   ```r
   is_mol_col <- grepl("DQA1|DPB1|DPA1", col2mod)   # column-name override
   molecular_cell <- has_colon | has_leading_zero | has_asterisk | is_mol_col[col_idx]
   ```
   A value is molecular if it contains `:`, starts with `0`, contains `*`, **or sits in a DQA1/DPA1/DPB1 column**. That last clause is unconditional — it is the bug.
4. **Emit** — molecular → `"<locus>*<allele>"`; serologic → `"<serologic_name><allele>"`.

**Key insight:** the serologic *naming* machinery is already correct. A value `01` classified as serologic in a `DQA1` column would emit `HLA-DQA` + `01` = `HLA-DQA01` — exactly the WHO form. **Only the classification gate is broken.** The `is_mol_col` clause forces molecular, so the serologic branch is never reached for these three loci.

---

## 3. Scope: what else is affected

Traced every function that distinguishes the two nomenclatures. **Only `HLA_columns_to_GLstring` carries the "always molecular" assumption.** All other functions key off the presence of `*` (molecular always has it; serologic never does), which is robust and unaffected:

| Function | Mechanism | Affected? |
|----------|-----------|-----------|
| `HLA_mismatch_base` | locus = text before `*`; serologic = `HLA-<letters>` prefix | No |
| `HLA_truncate` | splits on `*`; bare serologic left untouched | No |
| `check_molecular_gl_string` (utils-validation) | flags any allele lacking `*` as serologic | No |
| `HLA_validate` | locus-agnostic regex | No |

Conclusion: once a value is correctly **labeled** at the point of entry (`HLA_columns_to_GLstring`), the rest of the package already does the right thing. The fix is concentrated, but the *decision logic* it needs is hard.

---

## 4. The complications, in order of severity

### 4.1 Leading-zero collision (DQA/DPA/DPB)

Serologic forms for the new loci carry leading zeros: `DQA01`–`DQA06`, `DPA01`/`DPA02`, `DPB01`, `DPB0201`, etc. So `has_leading_zero` is no longer a clean molecular signal **for these loci**. A bare `01` in a DQA1 column is genuinely ambiguous: molecular `DQA1*01` vs. serologic `DQA01`.

### 4.2 Column-name drift

The natural disambiguator is the column name: `DQA1` (with the `1`) = molecular, `DQA` (no `1`) = serologic. But this convention is brand new.

- **Pre-2026:** both `DQA1` and `DQA` columns held molecular data (no serology existed).
- **Going forward (ideal):** `DQA1` = molecular, `DQA` = serologic.
- **Reality:** legacy tables will not be updated, so a `DQA` column may contain **either** nomenclature.

So the column name is a *hint*, not a guarantee.

### 4.3 Associated-antigen collision (all classical loci)

This is the hardest one, and it broadens the problem well beyond issue #33.

Worked example — allele A\*02:01:
- Current molecular: `A*02:01`
- Associated antigen (one resolution level of serology): `A0201`
- **Legacy molecular** (older 2-field, no colon): `A*0201`

The asterisk is frequently omitted in stored typing tables. With it dropped:
- Legacy molecular `A*0201` → `0201`
- Associated antigen `A0201` → (locus letter dropped) `0201`

A column `A` with value `0201` is therefore **unresolvable at the value level** — the string is a valid member of *both* nomenclatures. No regex, leading-zero rule, or dictionary lookup can separate them. This pushes the ambiguity onto A/B/C/DR, not just DQA/DPA/DPB.

### 4.4 Cross-era renaming of associated antigens

The 2026 update also **renamed** existing associated antigens. Example: the older `A203` became `A0203`. So if a function is told it is consuming serologic data and sees `203`, it should normalize it to `0203`. This requires **translation tables between nomenclature eras**, not just a single current-era reference.

- The **HLAtools** package already provides translation between different eras of HLA nomenclature. Worth investigating whether we can depend on it or borrow its approach/data rather than rebuilding era-translation from scratch.

### 4.5 Asterisk is unreliable in input

Real-world tables routinely omit the `*` (e.g. `0201` rather than `A*0201`). So the presence of `*`, while a *positive* signal for molecular when present, cannot be relied on as a *negative* signal — its absence does not imply serologic.

---

## 5. Design direction (current thinking)

### 5.1 Rejected: interactive prompting

Considered making the function prompt the user to decide molecular vs. serologic. **Rejected.** Reasons:

- Breaks every non-interactive use: `mutate()` pipelines, Quarto/Rmd renders, Shiny, plumber APIs (e.g. matching_api), scheduled jobs, `testthat`. A blocking prompt hangs all of them.
- Does not scale: a 500-row table with an ambiguous value in each would prompt 500 times.
- Makes the function impure and untestable — output would depend on console input, not just arguments.

### 5.2 Preferred: caller-declared nomenclature, at the column level

The saving grace: **real lab tables are internally consistent** — a given column is essentially all-molecular or all-serologic. The decision belongs at the column/table level, made once, not per cell.

Proposed shape:

- A default assumption (e.g. `nomenclature = "molecular"`) that preserves today's behavior and backward compatibility.
- An explicit override — e.g. a tidyselect argument naming the serologic columns (`serologic_columns = c(DQA, DP)`), or a per-locus mapping.
- `:` and `*` still force molecular unambiguously (unchanged).
- For any value that is **ambiguous** under the declared assumption, **emit a warning** listing the offending cells. A misclassification must never be silent.

### 5.3 Optional companion: opt-in interactive helper

For exploratory work, a **separate** function could scan a table, report the ambiguous cells, and return a column→nomenclature mapping the user then passes into `HLA_columns_to_GLstring`. This keeps the core transformation pure and reproducible while still offering a guided console workflow when wanted.

### 5.4 Approach: encode PATTERNS, not reference tables — DECIDED 2026-06-20

**NB decision (2026-06-20):** do **not** bake a full serologic-nomenclature reference table into this package, and do **not** translate between nomenclature eras. Other packages (notably **HLAtools**) already maintain authoritative antigen lists and era translation; replicating that here is out of scope and would saddle the package with a constantly-maintained reference.

Instead, **encode the structural patterns (the grammar) of valid serologic nomenclature.** Classify/validate a value by whether it **conforms to the pattern** for its locus, not by membership in a fixed antigen list. Consequences:

- A value that matches a locus's serologic pattern is handled **even if that specific antigen does not (yet) exist** in the published nomenclature.
- **Forward-compatible:** the WHO adds new antigens on an ongoing basis; pattern-based handling keeps working with no package data update.
- Keeps the package lean — no maintenance-burden reference table, no era tables.
- The interactive helper (§5.3) validates the **same way**: it flags values that do not conform to *any* locus's serologic grammar, rather than checking against a master antigen list.

What "patterns" means (to be specified precisely at implementation): the per-locus token grammar — e.g. serologic C is `Cw` + digits; DQA is `DQA` + digits; DP is `DPB`/`DPA` + digits; broads/splits/associated antigens are digit strings (optionally with `(split)` notation like `A24(9)`); and the structural "drop/keep the 1" molecular↔serologic locus relationship. The **canonical locus-identity + naming tables already added for issue #40** (`HLA_columns_to_GLstring`, see [issue-40 notes §5.4](issue-40-asterisk-nomenclature-notes.md)) are the structural backbone; issue #33 extends this with per-value pattern checks.

**Out of scope (defer to HLAtools or the caller):** era translation of renamed antigens (e.g. `A203` ↔ `A0203`), and any authoritative "does this exact antigen exist?" lookup. The IPD-IMGT/HLA `rel_dna_ser.txt` and hla.alleles.org antigen pages remain references *if a pattern ever needs validating against reality*, but we are explicitly not depending on them at runtime.

---

## 6. Cross-cutting requirements (regardless of approach)

- **Realistic dev/test data now available (2026-06-20):** `HLA_typing_synthetic_LIS` — a 63-row synthetic LIS "Patient" table added to the package (`data/`, documented, with a test). **Key property (NB):** its molecular (`m…`) columns contain a **mix of true molecular (`31:01`) and serologic (`w6`) values**, because the source lab historically stored serologic typing in the molecular columns. That mixed-nomenclature-within-a-molecular-column case is exactly the wild-caught input the classifier must handle, so this is the **primary fixture** for issue #33. View with `data(HLA_typing_synthetic_LIS)` after reinstalling the dev build.
- **Hand-built edge-case fixture** still useful, covering per locus: hi-res molecular, low-res molecular (`01`, `01:01`), `locus*field`, serologic (`DQA01`, `A2`, `A24(9)`), bare ambiguous (`1`, `0201`), and both column-name conventions (`DQA1` vs `DQA`). (Era-specific cases like legacy `A203` are out of scope per §5.4.)
- **Conflict-signaling decision:** silent default vs. warning vs. an argument forcing an explicit declaration. (Leaning: default + warning.)
- **Regression guard:** A/B/C/DR/DQ output must be byte-identical before and after the change.

---

## 7. Open questions for colleagues / next actions

**For colleagues (domain):**

1. In real wild-caught lab tables, how are serologic DQA/DPA/DP values actually written — bare number, prefixed token (`DQA1`, `DPw4`), or leading-zero form?
2. Do labs actually *store* associated antigens (the `A0201` level) in these tables, or is that level rare enough that we can default ambiguous 4-digit values to molecular and treat serologic as an explicit, declared case?
3. Is the `DQA1` (molecular) vs. `DQA` (serologic) column convention something we can expect going forward, or will it stay inconsistent?

**On our side:**

- [x] Gather real-world example tables — done: `HLA_typing_synthetic_LIS` (§6).
- [ ] **Specify the per-locus serologic grammar** (the "patterns" of §5.4): write down, per locus, the exact token + digit rules that define a conforming serologic value (incl. broad/split/associated forms and `A24(9)`-style splits).
- [ ] Implement pattern-based classification/validation, reusing the issue-#40 canonical locus backbone; add the warning path and regression guard.
- [ ] Build the interactive helper to flag non-conforming values (pattern-based, no master list).
- ~~Confirm formats against `rel_dna_ser.txt` / investigate HLAtools era-translation~~ — dropped per the §5.4 patterns-not-tables decision (era translation is out of scope).

---

## 8. Decisions locked in so far

- **Patterns, not tables (2026-06-20):** encode the *grammar* of valid serologic nomenclature; do **not** bake in a full antigen reference table, and do **not** translate between nomenclature eras. A value is handled if it conforms to its locus's pattern, even if it isn't (yet) a published antigen — forward-compatible as the nomenclature grows. Era translation and authoritative existence checks are out of scope (defer to HLAtools). (§5.4)
- The core function will **not** become interactive.
- Nomenclature will be **caller-declared at the column level**, defaulting to molecular for backward compatibility. *(Note: the issue-#40 work implemented the `nomenclature` parameter on `HLA_columns_to_GLstring` with this column-level model — issue #33 builds on it.)*
- Ambiguous cells will trigger a **warning**, never a silent guess.
- The fix is scoped to `HLA_columns_to_GLstring`; downstream functions already handle correctly-labeled input.
