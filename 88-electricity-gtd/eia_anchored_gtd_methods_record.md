---
name: Elec CF production
overview: Methods record for EIA-anchored G/T/D in production. D0–D15 settled. Discussion
todos:
  - id: d0-identity
    content: "Settle D0: how purchaser generation / T&D dollars and MWh are built"
    status: completed
  - id: d1-d9-methods
    content: D0–D9 settled. D8 keeps each purchaser's electricity $; leftover is the residual after generation $ (EIA prices do not reassign leftover $ across classes)
    status: completed
  - id: export-gh-discussion
    content: "Discussion #88 posted (opening principles + D0–D15 + Phi comments): https://github.com/cornerstone-data/methods/discussions/88"
    status: completed
  - id: p0-baseline-snapshot
    content: Record current production (old 3-way + old mixed units) under electricity_disagg_eia/ before replacing code; commit the freeze so old vs new can be compared in one checkout
    status: pending
  - id: p1-flag
    content: Replace 3-way-split (and mixed-units conversion) in place; no new flags; reallocation flag unchanged
    status: pending
  - id: p2-purchaser-gtd
    content: Build purchaser generation / T&D from EIA end-use shares × (eGRID − 2.14 exports), F04000 = Table 2.14, and dollar weights within class; keep each purchaser's electricity $; leftover is bill minus generation $
    status: pending
  - id: p3-make-int-va
    content: Implement Make table, Use 3×3, and value added per settled D1–D3
    status: pending
  - id: p4-mixed-units
    content: Convert generation to MWh with D4 option 2 (c_col = eGRID/q_$; c_row = 1/p); keep T&D in dollars
    status: pending
  - id: p5-year-scale
    content: Year scaling keeps 1a as an intermediate; after D0 re-apply at the model year, re-run Make-last so published q follows EIA MWh mix
    status: pending
  - id: p6-tests-diag
    content: Tests, waterfall configs, diagnostics vs frozen current-production snapshot and vs the CF report
    status: pending
  - id: later-td-buyers
    content: "D10 settled: keep the whole U[221100,221100] cell; U[G,G] from D1; remainder on U[T,T] and U[D,D]; off-diagonals 0"
    status: completed
  - id: later-imports-egrid
    content: "D11 settled: domestic Use+Y MWh = eGRID; extra import MWh = |F05000|/p (no UGO share on imports)"
    status: completed
  - id: later-2017-egrid-proxy
    content: "D12 settled: 2017-chain eGRID = eGRID_2016 x (EIA 3.1_2017 / EIA 3.1_2016) = 4,039 TWh"
    status: completed
  - id: later-negative-cells
    content: "D13 settled: clip to 0 for class dollar shares only; F05000 out of D0 classes; live cells unchanged"
    status: completed
  - id: later-ugo-td-year
    content: "D14 settled: freeze 2017 UGO T/(T+D) (~5.92%/94.08%) on the 2017 chain and after D6; p numerator stays the 2017 UGO generation share"
    status: completed
  - id: open-exports-d0-class
    content: "D15 settled: F04000 is its own D0 class (Table 2.14 MWh); four Table 2.2 classes share (eGRID − export MWh); F04000 bill unchanged, leftover via D8"
    status: completed
  - id: sef-phi-electricity-children
    content: "Settled: Phi = 1 on 221110/221121/221122 (PRO=PUR, same as Phoebe 221100); other commodities keep their Phi"
    status: completed
  - id: later-table-22-promote
    content: "Implementation (P2), not a methods decision: promote Table 2.2 and Table 2.14 loaders from diagnostics/extract into production"
    status: pending
  - id: later-coupled-tests
    content: "Implementation (P6, same PR): rewrite production w_row / Table 8.3 / mixed-units tests + cache lists; retarget or delete production-match test; analysis d_85 stays historical"
    status: pending
  - id: write-code-impl-plan
    content: "Write a separate code implementation plan that cites this methods record and Discussion #88 (D0–D15); P0 freeze is the first implementation step"
    status: pending
isProject: false
---

# EIA-anchored generation / T&D markup — methods record

Put the diagnostics counterfactual ([write-up](bedrock/analysis/electricity_disagg_diagnostics/output/alternate_eia_anchored_split/eia_anchored_td_markup_counterfactual.md)) into the live Cornerstone electricity path. **Within each end-use class, MWh still follow post-reallocation electricity-purchase dollars.** Using MECS (manufacturing kWh survey) shares inside Industrial is a later add-on.

This file is the **methods record**. It is not the code implementation plan. **D0–D15 are settled.** GitHub discussion: [#88](https://github.com/cornerstone-data/methods/discussions/88) (done). Next: a separate code implementation plan, then **P0** (freeze today’s production) before replacing 3-way code.

## How to read this file

1. **Settled design** — the production method. Use this as the source of truth.
2. **Implementation after methods** — files, P0–P6, tests. Not started.
3. **Methods discussion log** — why each decision was made, including options not chosen. Historical CF numbers (2018 eGRID as a 2017 proxy) stay in the log where they were used; they do not override D12.
4. **Open questions** — none remaining for this replacement. D15 (exports as a D0 class) is settled.

## Glossary

**Sectors and data**

- **Generation / transmission / distribution (G / T / D):** the three electricity industries and commodities after the split (`221110`, `221121`, `221122`). The BEA aggregate they come from is **electric power** (`221100`).
- **Use table:** who buys which commodities (intermediate purchases). **Make table:** who produces which commodities. **Y:** final demand (households, investment, government, exports). **Use+Y** for a commodity is total use of that commodity.
- **Value added (VA):** the residual that makes an industry’s inputs plus VA equal its gross output.
- **BEA GO / UGO305:** BEA gross-output by G / T / D. **2017 UGO mix** is about **34.2% / 3.9% / 61.9%**. This design does **not** use UGO for Make or industry columns (D2 Make-last; D3 with Make-last weights). Two UGO **shares** are still used, both frozen at **2017**:
  - **Generation-dollar share** (~34% of `221100` Use+Y) — the `p` numerator (D0), including at the model year.
  - **T/(T+D)** (~5.92% / 94.08%) — leftover transmission vs distribution (D8, D10, D14).
- **eGRID:** EPA plant-level inventory; the generation **output** target is US **plant net generation** (`us_total_net_generation_mwh`). GGL interconnect-loss helpers exist but are **not** added to this cap. Stewi has no 2017 inventory. **2017-chain** eGRID is the D12 estimate (**4,039 TWh**, plant-net 2016 × EIA 3.1). **Model year** uses that year’s real plant-net eGRID.
- **EIA Table 2.2:** sales MWh to ultimate customers by class (Residential, Commercial, Industrial, Transportation), plus **Direct Use** (on-site generation never sold on the grid) and **Total End Use** (sales + Direct Use).
- **EIA Table 2.4:** average retail ¢/kWh by class. **Not used** for leftover dollars (D8) or mixed units (D4).
- **EIA Table 8.3:** utility expense statistics. Today’s 3-way uses Purchased Power + T/D shares on the Use-table electricity-buys-electricity cell. **Drops out** of the 3×3 under D1/D10. Production / (Production+T+D) is **not** a `p` numerator if UGO is missing.
- **EIA Table 3.1:** all-sector net generation. Used only to trend eGRID 2016 → 2017 (D12).
- **EIA Table 2.14:** Canada/Mexico electricity trade (MWh). **Production input for exports (D15):** `F04000` generation MWh = Canada + Mexico exports. **Check** for D11 import MWh (`|F05000| / p`). Not a production input for imports.

**Matrices (EEIO)**

- **A:** direct requirements (inputs per unit of output). **L:** total requirements, `(I − A)⁻¹`.
- **E:** emissions by industry. **B:** emissions intensity of commodities. **D:** direct emission factor (column sums of B). **N:** total emission factor including supply chain (column sums of B × L).
- **q:** commodity output. After mixed units, generation `q` is in MWh.
- **p:** uniform generation price in $/MWh. **Production definition:** (generation-dollar share × domestic `221100` Use+Y $) / eGRID. Equivalent to generation Use+Y $ / eGRID once D0 has written those dollars.
- **U[G,G]:** Use-table cell “generation commodity bought by the generation industry” (generation self-use).
- **Leftover:** a purchaser’s electricity **bill** (old `221100` cell) minus that purchaser’s **generation $**. Split T vs D with 2017 UGO T/(T+D). Not EIA Table 2.4.
- **Phi:** producer value / purchaser value. Purchaser-price `N` = producer-price `N` × Phi. **Phi = 1** means the two prices are the same. On G/T/D children, Phi is 1 (same as USEEIO Phoebe on `221100`). Other commodities keep their usual Phi.

**Years**

- **2017 chain:** 3-way split on 2017 detail tables, before year scaling.
- **Model year:** published Cornerstone year (e.g. 2024). D6 re-applies D0 here, then Make-last.

**Model steps (today’s electricity path)**

- **Co-production cleanup:** move odd Make-table off-diagonals on aggregate `221100` onto the diagonal, with matching Use/VA transfers. **Unchanged.**
- **3-way split:** turn aggregate `221100` into G / T / D. Today: split Make diagonal; split the Use 3×3; split other inputs and VA in the electricity **columns**; split electricity **commodity rows** and Y. This work **replaces** that split in place.
- **Compensating row weights (`w_row`):** extra weights so G/T/D **dollar** row totals still match the BEA GO split after a Table 8.3 3×3. **Dropped** when the 3-way-split flag is on.
- **Year scaling:** inflate 2017 detail tables toward the model year. After summary-sector growth, production applies a **per-child GO-growth correction** (code Decision 7: G/T/D grow at different UGO rates). That is **not** D7 in this log (D7 is emissions). D6 keeps that correction as an **intermediate**, then overwrites electricity `q` and purchaser rows.
- **Mixed units:** convert **generation** to MWh; leave T&D in dollars. Today’s class-varying `c_row ∝ 1 / Table 2.4` is replaced (D4).

**This project**

- **Counterfactual (CF):** the diagnostics design in the write-up above. Used 2018 eGRID as a 2017 proxy and absolute EIA **sales** MWh. Production replaces both (four-class shares × (eGRID − 2.14 exports); D12 on the 2017 chain; D15 on `F04000`).
- **D0, D1, … D15:** methods decisions in the log below.
- **Off-diagonal 3×3:** generation industry buying transmission or distribution (or the reverse). **Kept at zero** so T/D total EFs do not inherit generation combustion through L.

Names **not** used in this file: “Fork 1 / 2 / 3.” Those were temporary labels for three production-balance rules that now live in D8, D6, and D0.

## Settled design

### Guiding principles

1. MWh values in the IO model follow EIA's sales of electricity to ultimate customers by class (for example, Residential > Industrial + Direct Use in Table 2.2). We follow that class mix, not the published sales totals as-is. Those four classes share **(eGRID − Table 2.14 export MWh)**. Physical exports are their own class on `F04000` (Table 2.14), not Commercial. Inside each class, MWh still follow who already buys electricity in the IO table.
2. Total generation in the model equals national eGRID net generation. EIA class shares only divide that total among industries and final demand. There is no 2017 eGRID, so the 2017 tables use an estimate (~4,039 TWh). The published 2024 model uses 2024 eGRID. Current production mixed units already call `us_total_net_generation_mwh(model_base_year)` — so **2024 eGRID**, not a 2017 or 2018 proxy. The 2017 3-way today is monetary and does not use eGRID. If `model_base_year` were 2017, D12 would apply there too.
3. We keep each industry's and household's 2017 electricity bill in dollars. Splitting electricity into generation, transmission, and distribution only divides that existing bill; it does not change who pays how much.
4. US generation equals domestic use of generation. Imported electricity is extra. For 2017, that extra is close to EIA's reported imports (~0.96×). Intermediate `Uimp` is inside `F05000`, not additional.
5. When the generation industry uses generation, that use is counted in Industrial + Direct Use. Generation, transmission, and distribution do not buy each other's electricity products. Remainder of the old self-use cell sits on transmission and distribution diagonals (D10).
6. Whatever is left of a purchaser's electricity bill after generation is transmission and distribution. We do not move that leftover using EIA retail prices. If generation would cost more than the bill, water-fill the clipped generation $ onto others in the same class so leftover is not negative and class MWh still hit D0. Nibble that class (and eGRID) only if the class's total bills cannot cover `p × class MWh`.
7. How large generation dollars are, relative to leftover T&D, follows BEA's 2017 generation share of the electric power sector (~34%), including in the published later year. EIA decides who gets generation MWh; BEA decides only that overall dollar split.
8. Of leftover T&D dollars, transmission versus distribution stays the 2017 BEA mix (~6% / 94%), including after we scale to a later year. That split does not change the generation price.

The eGRID − EIA Total End Use gap is **spread across classes** via identity 2. It is not a leftover parked on one cell, and it is not EIA delivered consumption.

**CF illustration (not the 2017-chain cap):** with 2018 eGRID **4,168 TWh** as a 2017 proxy, four-class MWh **before D15** were Residential **1,487** / Commercial **1,459** / Industrial+Direct Use **1,214** / Transportation **8.1** TWh. Production 2017-chain uses the same four-class **shares** times **(D12 4,039 TWh − Table 2.14 2017 exports)**; `F04000` holds 2.14 (D15). The remaining gap vs Total End Use is smeared on those four classes, not onto exports.

**$100 toy** (used below): electricity Use+Y **$100**; Steel **$40**, shop **$30**, households **$30**; generation-dollar share **34%** → generation **$34**, leftover **$66**.

### Decision index (D0–D15)

- **D0 — Purchaser rows:** four Table 2.2 classes get shares of Total End Use × **(eGRID − Table 2.14 export MWh)**; Industrial includes Direct Use; `F04000` is D15; `p` numerator = **2017 UGO generation-dollar share** of (inflated) `221100` Use+Y, including at the model year.
- **D1 — Use 3×3:** `U[G,G]` is the generation industry’s slice of Industrial+Direct Use; off-diagonals 0; do not stack Table 8.3 generation $ on top of those MWh.
- **D2 — Make:** Make-last. Make diagonal shares follow Use+Y G/T/D totals. No BEA GO on Make.
- **D3 — Columns + VA:** option 1 with Make-last weights. Fuels 100% → generation. If `VA_G` would go negative, spill other non-fuel to T/D until `VA_G = 0`; else warn and keep negative VA.
- **D4 — Mixed units:** `c_col = eGRID / q_$`; `c_row = 1/p` (flat). Table 2.4 out of conversion. T&D stay dollars. Domestic Use+Y MWh = eGRID except a class-level nibble if that class’s bills cannot cover `p × class MWh`.
- **D5 — eGRID minus EIA end use:** no extra Use-row cell. The remaining gap is eGRID − export MWh − Total End Use, smeared across the four Table 2.2 classes. `F04000` holds Table 2.14 only (D15). Leftover **dollars** are D8.
- **D6 — Year scaling:** keep per-child GO-growth (1a) as an intermediate after summary `"22"` inflation. Then re-apply D0 at the model year and **re-run Make-last** so published `q` follows that year’s EIA MWh mix, not BEA gen GO growth. 1a does not last on electricity `q` or purchaser rows.
- **D7 — E and B:** keep production placement. Combustion on generation, SF₆ on transmission, distribution ~0, `B_gen /= c_col`, x from Make-last V.
- **D8 — Leftover T&D $:** keep each purchaser’s electricity $ (old `221100` cell). Generation $ from D0; leftover = bill − generation $. If gen $ would exceed a bill, water-fill within class (not a silent nibble). Do not reassign leftover $ using EIA Table 2.4. T vs D of leftover is D14.
- **D9 — Flags:** no new flags. Reallocation unchanged. Existing 3-way-split and mixed-units flags run this method. P0 freeze under `electricity_disagg_eia/` is the old-vs-new comparison.
- **D10 — Self-use 3×3:** keep the whole `U[221100, 221100]` cell. `U[G,G]` from D1; remainder on `U[T,T]` and `U[D,D]` with 2017 UGO T/(T+D); off-diagonals 0. T/D diagonals are dollars, not extra generation MWh.
- **D11 — Imports vs eGRID:** domestic generation Use+Y MWh = eGRID = `q`. Extra import MWh = `|Y[221100, F05000]| / p`. Imported `221100` is generation (no leftover split). Intermediate `Uimp` is inside `F05000`, not additional.
- **D12 — 2017 eGRID proxy:** 2017-chain eGRID = eGRID 2016 × (EIA Table 3.1 2017 / EIA Table 3.1 2016) = **4,039 TWh**. After D6, real eGRID at `model_base_year` (canonical **2024**). Current production mixed units already do that; they do not estimate 2017 eGRID.
- **D13 — Negative Use/Y cells:** clip to 0 only when forming within-class dollar shares. Do not zero live Use/Y cells. `F05000` is D11; `F04000` is D15. Neither is a Commercial class weight. On a negative bill, generation $ = 0 and leftover may be negative on that cell only.
- **D14 — Leftover T vs D year:** freeze 2017 UGO T/(T+D) (~**5.92% / 94.08%**) on the 2017 chain and after D6. Same ratio for D8 leftover and D10 self-use remainder. Does not enter `p`.
- **D15 — Exports as a D0 class:** `F04000` generation MWh = EIA Table 2.14 Canada + Mexico exports. Four Table 2.2 classes share (eGRID − that MWh). Keep the `F04000` dollar bill; leftover via D8. Do not put `F04000` 100% on generation.
- **Phi on electricity children (post-#88):** `221110` / `221121` / `221122` have **Phi = 1** (producer price = purchaser price), same as USEEIO Phoebe on aggregate `221100`. Other commodities keep their usual Phi. Leftover T&D is D8, not a Phi haircut.

### Production-balance rules

These three rules keep a balanced Use table. They were discussed as implementation “forks”; they are now D8, D6, and D0.

1. **Keep purchaser bills (D8).** Each purchaser’s electricity $ stays the old `221100` cell. Industry columns stay balanced without moving VA. Generation $ = class MWh × `p` (within class ∝ $). Leftover = bill − generation $. If generation $ would exceed a bill, water-fill the clipped $ onto others in the same class. Electricity 3×3: no leftover on the generation **column** (D1); self-use remainder is D10.

   On the $100 toy: bills stay **$40 / $30 / $30**; generation ≈ **$10 / $12 / $12**; leftover ≈ **$30 / $18 / $18**. Changing bills to follow EIA retail-price gaps (~**$19 / $36 / $45**) was not chosen (would require a VA repair on Steel).

2. **Make-last after model-year D0 (D6).** Prefer that year’s EIA MWh mix over BEA dollar growth on published output. After D0 re-apply, Make-last so published `q` follows the new Use+Y mix. Rebuild electricity columns/VA to the new Make `x`. Per-child GO growth (1a) still runs, then is overwritten.

   Toy: 2017 Use+Y and `q` both **$100** (generation **$34**). Summary `"22"` **1.43×** → **$143**. 1a (2017→2022 illustration) would make `q` about **$55 gen / $5 T / $83 D**. D0 re-apply might land generation Use+Y at **$50**; Make-last sets generation `q` to **$50**, not **$55**.

3. **2017 generation-dollar share (D0).** `p` numerator = 2017 UGO generation share × `221100` Use+Y $ (~**$156.6 B**, ~34% of **$458.3 B** in 2017). Apply the **same 2017 share** to the inflated electricity Use+Y total at the model year. EIA MWh set **who** gets generation; BEA sets only the gen-vs-T&D **dollar level**. Not the model-year UGO generation share (2024 ≈ 30.6%).

   On the $100 toy: generation $ = **$34**, leftover pool **$66**. There is no EIA series in the current extract that is “generation GO $”; UGO is required. Missing UGO is an error. Table 8.3 Production share (~87% gen) is **not** a `p` backup (fuel-heavy opex, not GO).

### Leftover T vs D and `p`

`p` = (2017 generation-dollar share × `221100` Use+Y $) / eGRID. **T/(T+D) is not in that formula.** It only splits leftover among T and D.

D6 does **not** keep the 2024 UGO generation share. 1a would temporarily change gen’s share of `q`; D0 re-apply and Make-last overwrite it. Published gen vs leftover **dollars** stay the 2017 ~34% / ~66% idea, grown in total.

D14 freezes 2017 T/(T+D) so leftover T vs D uses the same 2017 UGO **structure** as the generation-dollar share. Using 2024 T/(T+D) would not change `p` either; it would only mix UGO years on the leftover split. 2024 T/(T+D) is 6.03% / 93.97% vs 2017 5.92% / 94.08%. On leftover **$66**: T **$3.91**, D **$62.09**.

### Intended production sequence

```text
Co-production cleanup (unchanged)
  → 3-way split, commodity rows + final demand first (Make-last needs Use+Y totals):
        export MWh = EIA Table 2.14 Canada+Mexico (same year as eGRID; D15)
        four Table 2.2 classes: shares of Total End Use × (eGRID − export MWh)
        F04000 holds Table 2.14 only (not Commercial; D8 leftover on that bill)
        (2017 chain: eGRID = eGRID_2016 × EIA_3.1_2017/EIA_3.1_2016)
        (Industrial pool = Industrial sales + Direct Use; includes generation industry)
        within-class $ weights clip negatives to 0 (live cells unchanged;
         F05000 and F04000 not in Table 2.2 class pools)
        generation $ = MWh × p
        leftover T&D $ = that purchaser's 221100 $ − generation $
        (if gen $ would exceed a bill, water-fill within class;
         nibble the class only if class bills < p × class MWh)
        leftover T vs D = 2017 UGO T/(T+D) (~5.92%/94.08%), also after D6
        generation industry column: generation only (no T&D leftover)
        imported 221100 is generation (no leftover); extra MWh = |F05000|/p
  → 3-way split, Use 3×3: U[G,G] from Industrial+Direct Use MWh × p;
        remainder of U[221100,221100] on U[T,T] and U[D,D]
        (2017 UGO T/(T+D), also after D6);
        off-diagonals 0
  → 3-way split, Make: diagonal shares = Use+Y G/T/D shares (no UGO on Make)
  → 3-way split, industry columns + VA: option 1 (Make-last weights);
        if VA_G would be < 0, spill other non-fuel to T/D until VA_G = 0;
        if still < 0, warn and keep negative VA (no further guardrails)
  → year scaling: same summary inflation as flag-off, then production per-child
        GO-growth correction (1a); re-apply D0 at model year (EIA 2.2 shares ×
        (eGRID − 2.14 exports); F04000 = that year’s 2.14; p numerator still
        2017 generation-dollar share × inflated 221100);
        re-run Make-last (and electricity columns/VA) so q follows that Use+Y mix
  → mixed units: generation only; T&D stay dollars;
        c_col = eGRID / q_$; c_row = 1/p (flat); Table 2.4 not in conversion;
        domestic generation Use+Y MWh = eGRID; import MWh extra
  → any leftover eGRID vs EIA (already in the D0 scale-up)
  → emissions: combustion on generation, SF6 on transmission; B_gen /= c_col
```

### Implementation notes (wiring, not methods)

- Purchaser `Y` is split in a separate cached path (`derive_disagg_Ytot_with_trade` / `disaggregate_electricity_commodity_row_in_y`), not inside `disaggregate_electricity_make_use_va`. D0/D8 must write both Use rows and Y.
- A small GO identity residual is absorbed into aggregate VA before today’s column split.
- The end-use map stays the live class assignment. In P2, change `END_USE_MAPPING_REVIEW_STATUS` from DRAFT to adopted for EIA-anchored G/T/D. Hard constraints: `F05000` out of D0 class pools (D11); electricity children → Industrial; `F04000` is the **Exports** class (D15), not Commercial. A broader NAICS/FD mapping review is out of this replacement.
- Promote Table 2.14 export MWh (`epa_02_14`) into the purchaser builder — **P2** (D15). If EPA lags `model_base_year`, use the latest 2.14 year and log it.
- Table 8.3 is hardcoded to 2017 and drops out of the 3×3 under D1.
- Today’s step order is Make → Use 3×3 → columns/VA → commodity rows/`Y`. Make-last **reverses** Make vs rows: commodity rows + Y first, then Make.
- Promote Table 2.2 (Direct Use / Total End Use) from diagnostics into production — **P2**.
- Rewrite production `w_row` / Table 8.3 / mixed-units `c_row` tests **in the same PR** as the replacement — **P6**. Drop `get_electricity_commodity_row_weights` from `cache_reset.py` and inflation/disagg test cache lists. Retarget or delete `test_production_matches_compensated_scenario` as a production identity (P0 freeze comparison or drop). Analysis d_85 stays historical; do not skip/xfail production tests to land the replacement.

## Implementation after methods

**P0 first**, on today’s code, before replacing the 3-way. Then P1–P6. No code until an explicit go-ahead.

Files to change:

- [`electricity_disaggregation.py`](bedrock/transform/eeio/electricity_disaggregation.py) — four-class targets = EIA Total End Use shares × (eGRID − Table 2.14 exports); `F04000` = 2.14 (D15); Industrial+Direct Use includes Direct Use and the generation column; write `U[G,G]` from that allocation; off-diagonals 0. Split Make **after** Use+Y using those row-total shares (not UGO).
- [`cornerstone_disagg_pipeline.py`](bedrock/transform/eeio/cornerstone_disagg_pipeline.py) / [`electricity_disaggregation.py`](bedrock/transform/eeio/electricity_disaggregation.py) — mixed units: `c_col = eGRID / q_$`; `c_row = 1/p` for every purchaser (drop Table 2.4 from `electricity_class_row_factors`).
- [`electricity_end_use_mapping.py`](bedrock/transform/eeio/electricity_end_use_mapping.py) — still maps IO sectors to EIA classes for dollar weights.
- [`usa_config.py`](bedrock/utils/config/usa_config.py) — **no new flags.** Keep `implement_electricity_reallocation` as today. Point `implement_electricity_disaggregation` at this 3-way-split method. Update `implement_electricity_mixed_units` conversion in place. Existing YAML configs keep the same flag names.
- [`derive_PRO_to_PUR_ratio.py`](bedrock/transform/iot/derive_PRO_to_PUR_ratio.py) — when the 3-way flag is on, set Phi = 1 on `221110` / `221121` / `221122` explicitly (do not only rely on `reindex` fill).
- Tests: [`test_electricity_mixed_units.py`](bedrock/transform/eeio/__tests__/test_electricity_mixed_units.py) and 3-way-split balance tests.
- New analysis package [`bedrock/analysis/electricity_disagg_eia/`](bedrock/analysis/electricity_disagg_eia/) — freeze of **today’s** production (old 3-way + old mixed units) plus later old-vs-new comparison. Not a fourth flag.

### Phases

- **P0 — Freeze current production (do this first, on today’s code).** New package [`bedrock/analysis/electricity_disagg_eia/`](bedrock/analysis/electricity_disagg_eia/). Run the live model on the existing waterfall configs that will change (`2025_usa_cornerstone_v0_3_electricity_disaggregation` and `…_electricity_mixed_units`) and write a committed snapshot under `electricity_disagg_eia/output/baseline_current_production/`. Include git SHA, config names, and date in metadata. After the 3-way code is replaced, one checkout still has old numbers on disk vs new live output. Do **not** start P1 until this freeze is written and committed.
- **P1 — Wire existing flags; no new ones.** Reallocation unchanged. 3-way-split flag runs the new purchaser rows / 3×3. Mixed-units flag runs the new generation conversion. Tests: flags off and reallocation-only still match today; 3-way-split and mixed-units tests are rewritten for the new identities.
- **P2 — Purchaser generation / T&D builder** (four classes: 2.2 shares × (eGRID − 2.14 exports); `F04000` = Table 2.14; dollars within class; keep each purchaser’s electricity $; leftover = bill − gen $; water-fill within class; Industrial includes Direct Use).
- **P3 — 3×3 / Make / VA** per D1–D3.
- **P4 — Mixed units:** generation in MWh; T&D in dollars; conversion factors per D4–D5.
- **P5 — Year scaling** per D6; re-read EIA 2.2 at the model year; re-apply D0 then Make-last so `q` follows EIA MWh mix. `p` numerator still the 2017 generation-dollar share.
- **P6 — Tests + diagnostics (same PR as the replacement):** rewrite production CI (`w_row` / Table 8.3 / mixed-units `c_row` / cache lists). Retarget or delete `test_production_matches_compensated_scenario`. Analysis d_85 stays historical. Live new production vs the P0 freeze (old 3-way) and vs the existing CF report. Assert Phi = 1 on electricity children when margins are on. Methods post exported from this log.

### P0 snapshot contents

Package lives next to [`electricity_disagg_diagnostics`](bedrock/analysis/electricity_disagg_diagnostics/), not inside it:

```text
bedrock/analysis/electricity_disagg_eia/
  README.md
  paths.py
  snapshot_current_production.py   # P0: run on today's code only
  compare_to_baseline.py           # P6: live new vs frozen old
  output/
    baseline_current_production/   # committed freeze; do not overwrite after P1
    new_vs_baseline/               # generated after the new method lands
```

Snapshot enough to reconstruct old vs new without re-running the old 3-way:

- **Metadata:** git SHA, datetime, config names, flag values.
- **IO scalars** per config: `q` / `x` for G/T/D, generation Use+Y $, `U[G,G]`, household `F01000` generation, `p`, mixed-units `c_col` / `c_row` if present.
- **Electricity Use 3×3** and electricity **commodity rows + Y** (purchaser-level; needed for class MWh and HH).
- **EF vectors** `E`, `D`, `N` (all sectors, not only G/T/D) and BLy so later N/D plots do not need a second production flag.
- **Class generation MWh** under mixed units (Residential / Commercial / Industrial / Transportation / Exports / HH). Commercial excludes `F04000`.

Footing and reallocation configs are **not** part of the freeze; those paths stay bit-identical and are covered by existing tests.

### Testing

- Electricity flags **off** (canonical v0.3): unchanged (no 3-way split).
- Reallocation **on**, 3-way split **off**: unchanged co-production cleanup.
- 3-way split **on**: this method, not today’s compensating-row-weight split. Compare to the P0 freeze, not to a second flag.
- Mixed units **on**: new generation conversion (flat `1/p`; T&D leftover already in dollars), not today’s Table 2.4-varying `c_row`. Same: live vs P0 freeze.
- Balance tests rewritten for the identities we **choose** to keep (not “row totals still match BEA GO”).
- Waterfall configs keep the same names: footing → co-production cleanup → 3-way split (**this method**) → mixed units (**this conversion**). No extra “eia-anchored” config or flag.

### Out of scope

- MECS / Census ASM physical shares inside Industrial.
- Changing co-production cleanup.
- Folding the 407-sector electricity taxonomy into the canonical 405-sector model (still behind the existing electricity flag).

---

# Methods discussion log

Living draft. After each settled answer, this section is updated the same turn. Copy into a methods discussion as: opening post (preamble + summary) then one comment per D0–D15 plus Phi.

**Title:** Modeling decisions for EIA-anchored electricity G / T / D (production)

**Preamble (opening post):** This discussion lists the modeling decisions for putting the EIA-anchored generation / transmission / distribution path into production (replacement of today’s 3-way split and mixed-units conversion; co-production cleanup unchanged). There are 16 decision points (**D0–D15**). Please comment in that order; earlier decisions constrain later ones.

Guiding MWh totals: **eGRID** for generation output (2017 chain: D12 estimate **4,039 TWh**; model year: that year’s real eGRID); **EIA Table 2.2 shares of Total End Use × (eGRID − Table 2.14 export MWh)** for generation Use+Y by ultimate-customer class (Residential, Commercial, Industrial + Direct Use, Transportation); **Table 2.14** for `F04000` (D15). Within class, MWh follow electricity-purchase dollars. MECS physical shares are deferred. Each purchaser keeps their current electricity **dollar** bill; leftover T&D is that bill minus generation $. `p` numerator is the **2017 UGO generation-dollar share** of `221100` Use+Y, including at the model year. Leftover T vs D is **2017 UGO T/(T+D)**. No new config flags.

This is the intended production method, not a diagnostics overlay. Code is not in this discussion; a separate implementation plan will cite these decisions.

**Summary:** see [Decision index](#decision-index-d0d15) above.

### D0 — Purchaser generation / T&D package (SETTLED)

**Why this matters:** In the current 3-way split, compensating row weights (derived so remaining row dollars, after the Table 8.3 3×3, restore the BEA GO mix) make generation / T / D **dollar** Use+Y totals follow BEA GO even though the intersection uses different percentages. Mixed units then put class retail gaps into generation-row conversion factors (`∝ 1 / Table 2.4`). Class generation MWh therefore does not match EIA (households ~38% of Residential; Transportation ~11×). The diagnostics CF rebuilt purchaser G / T / D from EIA **sales** MWh × one generation price, with Table 2.4 leftover in T&D. Those identities cannot all hold at once. D0 says which purchaser-row package we will not break. Later decisions only place holes that package accepts.

**Discussion path:** Forcing BEA GO **row dollar** totals and EIA class MWh and one national `p` at once is inconsistent. We dropped BEA GO as a Use-row constraint. Class-specific generation prices were rejected in favor of one national `p`. The published CF then used **absolute EIA sales** MWh; that left gen Use+Y dollars below current generation Use+Y by eGRID minus sales, times `p`.

**Original CF resolution (superseded for class totals):** EIA sales MWh by class; dollars within class; `p` = generation Use+Y dollars / eGRID; T&D leftover to Table 2.4 class bills; drop compensating row weights.

**Amendment — EIA shares × (eGRID − exports) (2026-08-20, D15 2026-08-22):** Class targets for the four Table 2.2 classes are **not** EIA sales as published, and **not** shares × full eGRID. They are EIA Table 2.2 **shares of Total End Use** (Residential, Commercial, **Industrial + Direct Use**, Transportation) times **(eGRID − Table 2.14 export MWh)**. `F04000` is its own class (D15). Within each Table 2.2 class, still ∝ electricity-purchase dollars. Households get the scaled Residential total. The generation industry stays in the Industrial+Direct Use dollar pool.

**CF working table** (2018 eGRID **4,168 TWh** as 2017 proxy, **before D15**): Residential **1,487** / Commercial **1,459** / Industrial+Direct Use **1,214** / Transportation **8.1** TWh. Sum = that eGRID. Production **2017-chain** uses the same four-class **shares** times **(D12 eGRID − Table 2.14 2017 exports)** plus `F04000` = 2.14 (D15). Model year uses that year’s EIA 2.2 shares × (that year’s eGRID − that year’s 2.14).

`p` numerator is the **2017 UGO generation-dollar share** of `221100` Use+Y (not a live `221110` row, and not the model-year UGO generation share). Allocated MWh (four classes + `F04000`) sum to eGRID, so generation Use+Y dollars = **p × eGRID** = that UGO slice. The old “sales only” dollar shortfall **closes**. The eGRID − export MWh − Total End Use gap is spread over the **four Table 2.2 classes**, not onto `F04000`.

Table 2.4 leftover: D8 keeps each purchaser’s electricity **bill**. Leftover is that bill minus generation $. EIA retail prices do **not** reassign leftover $ across classes. Compensating row weights stay off. Make-table “last” shares stay report-only until D2.

**Rejected as `p` numerators** (already in [`EIA_ElectricPowerAnnual.yaml`](bedrock/extract/eia/EIA_ElectricPowerAnnual.yaml)). None is generation commodity output $ comparable to UGO GO. **Do not implement an automatic fallback.** Missing UGO305 names or year stays an error, as in live `build_electricity_disagg_go_weights()`.

- **Table 8.3 `expenses: Production` / (Production+T+D) × `221100` Use+Y.** 2017 mock opex: Production **$98.7 B**, T **$10.8 B**, D **$4.4 B** → ~**87%** gen share vs UGO **34%**. Fuel-heavy IOU plant opex, not GO. Auto-applying it would nearly triple generation $ and collapse leftover. Not a `p` backup.
- **Table 8.3 `expenses: Production` absolute $.** IOU plant opex only (~**$99 B** in 2017). Incomplete vs IO GO. Order-of-magnitude check, not a numerator.
- **Table 2.3 revenue from sales to ultimate customers.** Retail (gen+T&D bundled), ~**$390 B** in 2017 vs IO **$458 B**. Too large as gen $. Sanity: gen $ should stay below Table 2.3 total.
- **Table 2.4 × eGRID** or **Table 2.2 × 2.4.** Withdrawn as leftover (D8). Not a gen $ numerator.

**Why this answer:** You required generation output = eGRID, generation use = that same total, and EIA only for **mix** (including Direct Use in Industrial). One national generation price is unchanged. The 2017 generation-dollar share keeps `p` from jumping with model-year UGO gen mix (2024 ≈ 30.6%).

**What we give up:** EIA Table 2.2 **sales** MWh by class as the IO numbers (households will exceed published Residential sales). Table 2.4 as a joint identity with those sales. Treating the eGRID − end-use scale-up as delivered consumption (it is not EIA end use). Model-year UGO generation share as the `p` numerator. Putting exports inside Commercial (`F04000 / p` is not EIA exports).

**Implementation:** Port the CF purchaser-row builder, but replace class MWh targets with shares × (eGRID − 2.14 exports), fold Direct Use into Industrial, and assign `F04000` from Table 2.14 (D15). `p` numerator = 2017 UGO generation share of `221100` Use+Y (same share on the inflated total at the model year). Missing UGO is an error; do not fall back to Table 8.3. Do not bring back compensating row weights when the 3-way-split flag is on.

**Resolution:** Four Table 2.2 class MWh = EIA Total End Use shares × (eGRID − Table 2.14 export MWh); Industrial includes Direct Use; `F04000` is D15; `p` numerator = 2017 UGO generation share of `221100` Use+Y, including at the model year. Drop `w_row`.

### D1 — Use 3×3 and generation self-use (SETTLED, revised)

**Why this matters:** The 3×3 of “electricity industries buying electricity commodities” decides (1) whether T/D total EFs pick up generation emissions (off-diagonal purchases) and (2) whether extra generation MWh sit **outside** the class buckets. With class targets already summing to eGRID, extra `U[G,G]` on top of Industrial+Direct Use would make use > output.

**Discussion path:** Not putting generation emissions into T/D EFs is the more important EF choice → off-diagonals stay 0. Direct Use is not a separate cell: it is **inside the Industrial+Direct Use share** (29.1% of eGRID in 2017). `U[G,G]` is the generation industry’s dollar-weight slice of that bucket. Stacking Table 8.3 generation dollars on top was rejected because it would exceed eGRID.

**Resolution:**

1. Off-diagonals = 0. The generation industry buys generation only (no Table 2.4 leftover on that column).
2. Industrial+Direct Use MWh (that class’s share of (eGRID − export MWh)) includes the generation industry. That slice × `p` is **`U[G,G]`**.
3. Do not add Table 8.3 generation dollars on top of those MWh.
4. T/D diagonal cells take the rest of the self-use cell (`T − U[G,G]`), in dollars, and do not add generation MWh (D10).

**Why this answer:** Output = use at eGRID, class mix follows EIA end-use shares, self-use stays in Industrial+Direct Use without breaking the cap. T/D still do not buy generation, so their total EFs do not inherit generation’s direct intensity through this block.

**What we give up:** `U[G,G]` MWh is **not** EIA Direct Use (141 TWh) and **not** Table 8.3 / `p`. It is (electricity industry dollars / Industrial+Direct Use dollars) × Industrial+Direct Use MWh. Direct Use is only in the **class total**; most of it lands on non-utility Industrial columns via dollar weights.

**Implementation:** Same purchaser-row builder; four-class targets = shares × (eGRID − 2.14 exports); Direct Use in the Industrial pool; write `U[G,G]` from the generation column; put `T − U[G,G]` on `U[T,T]` and `U[D,D]` (D10); keep off-diagonals at zero.

**Alternative considered — Direct Use as `U[G,G]` only (not chosen):** 141 TWh on generation self-use, Industrial at sales only, and a separate rule for the rest of eGRID minus end use. You instead folded Direct Use into Industrial’s **share** of eGRID.

**Other alternatives not chosen:** Extra Table 8.3 generation dollars (use > eGRID). Absolute EIA sales as class MWh (then use ≠ eGRID output unless output leaves eGRID).

### D2 — Make table (SETTLED)

**Why this matters:** After co-production cleanup, electricity Make is a **diagonal** 3×3, so commodity output `q` and industry gross output `x` share one mix. Today that mix is BEA GO (UGO305). D0/D1/D15 set Use+Y from EIA class MWh plus leftover T&D, not from BEA GO. If Make stayed UGO, T/D use would not match `q`.

**Resolution:** **Make-last.** Make **inherits the Use+Y G/T/D split**. Do **not** use BEA GO shares for Make at all.

Concretely: after D0/D1 (and leftover) produce generation / T / D **commodity-row totals** (intermediate Use **plus** Y), set the three Make **diagonal** cells so each child’s share of aggregate `221100` Make equals that child’s share of Use+Y. Off-diagonals stay 0. Then `q` follows use (up to imports). Because Make is diagonal, industry `x` gets the same mix.

This is **not** copying the Use 3×3 into Make. `U[G,G]` is generation self-use (a slice of Industrial). `V[G,G]` is the generation industry’s entire output of the generation commodity — almost all of `q_G`. Make-last copies **row totals**, not that self-use cell.

**Why this answer:** Use+Y is already the EIA/retail story; output should follow that story. BEA GO is no longer a Make constraint.

**What we give up:** BEA’s 34.2 / 3.9 / 61.9 as who produces G/T/D. The published CF Make-last percentages (35.8 / 3.8 / 60.4) were sales-only gen dollars and are **not** the production mix. Leftover (D8) still moves T+D shares.

**Implementation:** Today Make is split **before** Use rows because UGO does not depend on Use. Make-last reverses that: build commodity rows + Y (and the Use 3×3) first, then split Make from those totals. `disaggregate_make_intersection` takes Use+Y shares instead of `build_electricity_disagg_go_weights()`. Year scaling (D6) re-runs Make-last after model-year D0.

### D3 — Industry columns + value added (SETTLED)

**Why this matters:** Make-last sets how large each G/T/D **industry** is (`x_k`). Each industry column still has to buy non-electricity inputs and have value added so that **inputs + VA = `x_k`**. D1 already settled electricity **purchases** in those columns (generation buys generation only; T/D do not buy generation). D3 is everything else in the column: fuels, other intermediates, VA.

**Resolution:**

1. **Default = option 1.** Same recipe as production, Make-last weights instead of BEA GO. Fuels → generation (100%). Other non-electricity rows ∝ Make-last shares. `x_k` from Make-last. VA residual. Column still balances: `inputs + VA = x`.
2. **Backup if default `VA_G < 0`:** spill **other non-fuel intermediates** off generation onto T/D (∝ Make-last T/D shares) until `VA_G = 0`. Fuels stay 100% on generation. `U[G,G]` is not spilled.
3. **If the backup is not enough** (`fuels + U[G,G] > x_G` even with other non-fuel on generation at 0): **warn and write the negative VA**, same as today’s production. No further guardrails: do not reduce fuels on generation, do not raise `x_G`, do not shrink `U[G,G]`.

**Why this answer:** Columns follow the same split as Make (D2). Fuels stay on the industry that burns them. The only repair is moving non-fuel intermediates, which does not leak fuel-chain EFs onto T/D. If that cannot produce non-negative generation VA, we keep the existing warning rather than fighting D1/D2.

**What we give up:** T&D-as-markup columns; reducing fuels on generation; raising generation GO; shrinking `U[G,G]`. Negative generation VA remains possible in the pathological case.

**Implementation:** `disaggregate_use_industry_columns` takes Make-last `w` instead of `w_go`. After computing `VA_G`, if negative, rescale generation’s non-fuel, non-electricity Use rows down (remainder to T/D by Make-last T/D shares) until residual is 0; if other rows hit 0 and residual is still negative, `warnings.warn` and keep the negative VA.

### D4 — Mixed units (SETTLED)

**Why this matters:** Mixed units convert **generation** from dollars to MWh and leave T&D in dollars. Today’s class-varying `c_row ∝ 1 / Table 2.4` would undo D0 class MWh. If Make-last `q_$` ≠ generation Use+Y dollars, a single factor (`c_row = c_col`) makes output = eGRID but Use+Y MWh ≠ eGRID.

**Resolution:** **Option 2.** eGRID is a constraint on generation **commodity and industry output** (Make `q`/`x`) **and** on generation **Use+Y** (Use table + Y).

- `c_col = eGRID / q_221110_$` so Make output (and the generation industry column) becomes eGRID.
- `c_row[j] = 1/p` for every purchaser, with `p` = generation Use+Y dollars / eGRID, so Use+Y MWh = eGRID and class mix from D0 is preserved, except a class-level nibble if that class's bills cannot cover `p × class MWh`.
- Table 2.4 does **not** enter mixed units. T&D stay dollars. `B` generation is still divided by `c_col`. If `q_$` ≠ Use+Y `$`, the self-use A cell is scaled by `c_row / c_col` ≠ 1. Imports use the same generation-row conversion as domestic.
- **`y_nab` units:** keep today’s two getters. `derive_cornerstone_y_nab()` (from `derive_cornerstone_Aq_scaled`) stays **dollars**, including generation — that is the published / snapshot series. `derive_cornerstone_y_nab_mixed_units()` (from mixed A/q) is **hybrid**: generation in MWh because `y = q − A q` must match mixed-units A/q. Do not force mixed-units `y_nab[221110]` to dollars.

**Why this answer:** You required eGRID on both tables, not only on Make output. Option 1 would miss that when leftover makes Make and Use+Y dollar totals disagree.

**What we give up:** One shared conversion factor; a self-use A twist when `q_$` ≠ Use+Y `$`.

**Implementation:** Replace `electricity_class_row_factors` (Table 2.4 / `λ`) with a constant `1/p`. Keep `electricity_output_factor` as `eGRID / q_$`. Rewrite mixed-units tests that currently assert Industrial `c_row` > Residential `c_row`. eGRID year: D12 on the 2017 chain, D6 at the model year. E placement is D7. Leave `derive_cornerstone_y_nab` monetary and `derive_cornerstone_y_nab_mixed_units` hybrid; mixed-units BLy diagnostics already consume the hybrid series.

### D5 — eGRID minus EIA end use (SETTLED)

**Why this matters:** eGRID exceeds EIA Total End Use. That gap is generation that is not EIA end use (losses, plant use, and the part of trade not peeled off as D15 exports). The published CF left the gap off the Use row. D0 already smears **eGRID − export MWh − Total End Use** across the four Table 2.2 classes. `F04000` holds Table 2.14 only (D15). D4 then makes Make output and Use+Y both eGRID in MWh, so there is no MWh hole left to park. Leftover **dollars** for T&D are D8.

**CF illustration:** 2018 eGRID **4,168 TWh** minus EIA Total End Use ~**3,864 TWh** ≈ **304 TWh**. **2017-chain production** uses D12 **4,039 TWh**, so the gap vs 2017 Total End Use is smaller. The placement rule does not change.

**Resolution:** **Option 1.** No extra Use-row cell. The remaining gap exists only as D0 scale-up on the four Table 2.2 classes. Scaled class MWh are not EIA delivered consumption. Direct Use stays inside Industrial’s share. Exports are D15 (`F04000` = Table 2.14), not a parked residual.

**Why this answer:** D0, D1, and D4 already force generation Use+Y and Make output to eGRID. A parked residual would reopen those identities.

**What we give up:** An explicit losses / plant-use generation cell. Exports are on `F04000` via D15, not this cell.

### D6 — Year scaling (SETTLED)

**Why this matters:** The 3-way split is built on **2017** detail tables. The published model is a later year (e.g. 2024). Two different “year” stories are in play:

1. **Dollar scaling (today):** after disaggregation, all 407 sectors get BEA summary-sector growth. Electricity children sit in Utilities `"22"`, so they would all get the **same** ratio. Production then applies a **per-child GO-growth correction** (code Decision 7, not this log’s D7): rescale G / T / D using UGO305 **detail GO growth** (2017→2022 illustration: generation ~1.62×, transmission ~1.29×, distribution ~1.33× vs Utilities ~1.43×). That is BEA GO **dynamics**, not the 2017 GO **levels** we dropped on Make (D2).
2. **Physical re-anchor (CF):** mixed units already read **model-year eGRID**. The CF rebuilt class MWh at the model year with that year’s EIA Table 2.2 and scaled post-reallocation `221100` $ as within-class weights. The CF used 2018 eGRID as a 2017 proxy; production 2017-chain uses D12 instead. D6 still uses **real** eGRID at the model year.

If we only inflate 2017 D0 dollars, 2024 class MWh is the **2017 EIA mix** grown, not the 2024 Residential/Industrial mix. D0 as a model-year identity wants EIA 2.2 **shares × (eGRID − 2.14 exports) at the model year**, plus that year’s Table 2.14 on `F04000`. Child GO growth on `q` after Make-last can also pull G/T/D dollar mix away from leftover Use+Y before D4 converts generation to eGRID.

**Ruled out (2026-08-21):** Option 3 (split last) — 2017 3-way must still go through the same summary inflation as flag-off, so the inflation mechanism does not change when disaggregation is on. Option 2 (scale only, no EIA re-anchor) — D0 must be re-applied at the model year (EIA 2.2 shares × that year’s eGRID).

**Remaining: 1a vs 1b** (keep vs drop the per-child GO-growth correction after summary `"22"` scaling).

**Investigation — does 1a vs 1b touch non-electricity money?** The correction (`rescale_electricity_children_to_detail_GO_growth_A` / `_q`) **only writes** the three electricity **commodity rows** of A and the three electricity **`q`**. It does not rewrite other A rows or other `q`.

Spillovers still exist:

- Every industry’s **electricity purchase mix and total electricity coefficient** change (A[G/T/D, j] for non-elec j). That is still the electricity rows.
- Electricity **industry output** `q_G`/`q_T`/`q_D` change, so those columns buy more/less of **every** input (fuels, steel, …): `U[i, G] = A[i, G] × q_G`. Non-electricity `q` is unchanged; non-electricity **Y** can move because `y = q − A q` and electricity `q` changed.
- **1a vs flag-off:** when the flag is off, aggregate `221100` keeps the Utilities `"22"` ratio. 1b keeps all three children on that same ratio (sum grows like flag-off `221100`). 1a multiplies children by (detail GO growth / `"22"`), so **total** G+T+D `q` need not match flag-off `221100` growth (weighted average of 1.62 / 1.29 / 1.33 vs 1.43).

Re-applying D0 at the model year **overwrites electricity Use+Y rows**, so the A-row part of 1a may be largely replaced for purchaser G/T/D. The `q` part still matters until Make-last is re-run; electricity-column purchases of non-elec commodities still follow `q_G/T/D`.

**Options left:**

- **1a.** Keep today’s per-child GO growth, then re-anchor D0 rows at the model year.
- **1b.** Drop that correction; children stay on Utilities `"22"`, then re-anchor. Closer to flag-off inflation of the electricity **total**.

**Resolution:** **1a**, then D0 re-apply, then **Make-last again.** Keep production’s per-child GO-growth correction in the inflation path (same mechanism as flag-off `"22"`, then today’s G/T/D GO-growth rescale). Then re-apply D0 at the model year (EIA Table 2.2 shares × that year’s eGRID; within-class $ from scaled purchaser bills, D8; `p` numerator still the **2017 generation-dollar share** × inflated `221100`). Then re-run Make-last (and electricity columns/VA) so published `q` and generation industry size follow that Use+Y mix. Mixed units `c_col` / `p` use model-year eGRID.

**Amendment (2026-08-21):** Re-run Make-last after D0 re-apply. Prefer the latest EIA MWh mix over BEA dollar growth on published output. 1a does not last on electricity `q` or purchaser rows. Leaving 1a `q` in place was not chosen.

**Does D6 use the 2024 generation share?** No. 1a would temporarily change gen’s share of electricity `q`. Then D0 and Make-last overwrite it. What lasts: (1) **who** gets generation MWh — that year’s EIA 2.2 shares × that year’s eGRID; (2) **how large generation $ are vs leftover** — 2017 generation-dollar share × inflated `221100`. Not 2024 UGO’s ~30.6% gen share.

**Why this answer:** You wanted the inflation mechanism unchanged when the electricity flag is on (no split-last), EIA identities at the published year (re-anchor), and output to follow that EIA use mix rather than BEA gen GO growth.

**What we give up:** Lasting per-child BEA GO growth on generation `q` (the 1.62× vs 1.29×/1.33× split). 1a still runs, then is overwritten. D4’s `q_$` ≠ Use+Y `$` case is mostly imports at the model year.

**Implementation:** Leave `rescale_electricity_children_to_detail_GO_growth_A` / `_q` as they are. After year scaling, rebuild purchaser G/T/D from model-year EIA 2.2 × (eGRID − 2.14 exports) and `F04000` = that year’s Table 2.14 (D15; D8 leftover; D14 T vs D; D0 `p` numerator still the 2017 generation-dollar share × inflated `221100`). D8 bills at the model year are the **pre-1a** electricity-row sum (after summary `"22"`, before per-child GO growth), inflated with commodity PI — not post-1a `Adom ⊙ q`. Re-run Make-last from those Use+Y totals; rebuild electricity columns/VA to the new `x`. Then D4. EIA 2.2 / 2.14 year is the model year (if EPA lags, latest 2.14 year and log it). There is no model-year Y matrix: non-import, **non-export** FD bills use 2017 Y column shares × pre-1a electricity `y` total (then PI); **do not** spread `F04000` from those shares — assign D15 MWh on that column; D11 extra import MWh uses the scaled `imports` vector (sum of G+T+D) / `p`, not a 2017 `F05000` share of `y_nab`.

### D7 — Emissions E and B (SETTLED)

**Why this matters:** Direct emissions **E** are an industry fact (who combusts). Intensities **B** = E / x (then mixed units divide generation B by `c_col`, kg/$ → kg/MWh). **D** is column sums of B. **N** is D through the supply chain (B L). D0/D1 already decided T/D do **not** buy generation, so T/D total EFs do not pick up generation combustion through the electricity 3×3. Who *does* inherit generation’s D is whoever buys generation MWh (EIA class mix).

Today (eGRID FBS; missing inventory is an error, not a gas-type fallback):

- Plant combustion (non-SF₆) → generation `221110`
- SF₆ → transmission `221121`
- Distribution `221122` ≈ 0 direct E
- Fuels in the Use table go to the generation **column** (D3), so fuel-chain EFs sit on generation too
- When B uses E-year GO, aggregate `221100` x is expanded with **Make V row shares** — after D2 that is Make-last, not BEA GO
- Mixed units: `B[:, 221110] /= c_col`

Leftover T&D can be a **large $** industry. Putting combustion E there would make T/D look carbon-intensive because they are a markup, not because they burn fuel. That fights D1’s EF architecture.

**Options considered:**

1. **Keep production E/B placement.** Combustion on generation, SF₆ on transmission, distribution ~0, `B_gen /= c_col`. x from Make-last V. D0 only changes **purchaser** N (who buys gen MWh). T/D D stay near zero except SF₆ on T.
2. **Spread combustion E onto T/D** in proportion to leftover dollars. Physically wrong; T/D N would inherit plant CO₂ as if markup were generation.
3. **Keep E on generation but compute B with BEA-GO x.** Fights D2 Make-last (denominator would not match industry size).

Leftover dollars (D8) can change generation `x` and thus D_gen dilution. E inventory year vs model year is mostly already eGRID-at-E-year.

**Resolution:** **Option 1.** Keep production E/B placement. Plant combustion on generation; SF₆ on transmission; distribution ~0 direct E; `B_gen /= c_col`; x from Make-last V. D0 only changes who inherits generation D (purchaser N). Do not put combustion on leftover T&D.

**Why this answer:** Combustion is a plant fact. T&D leftover is a dollar markup. D1 already blocked generation E from entering T/D through the 3×3.

**What we give up:** Spreading plant CO₂ onto T/D; a BEA-GO denominator for B.

**Implementation:** Leave eGRID FBS mapping and `apply_electricity_unit_conversion_to_B` as they are. Do **not** overwrite 2017 `V`. When splitting GHG-year parent `221100` GO across G/T/D for B (`distribute_electricity_aggregate_x_using_v_row_shares`), use **P5 published `q` shares** from `derive_cornerstone_Aq_scaled().scaled_q`, not 2017 V row shares. D7’s “x follows Make-last” is the published Make-last (model-year D0), not the 2017-chain V. Vnorm stays on 2017 V (identity on the electricity diagonal). Dollar-year mismatch between BEA GO series and inflated `q` is unchanged from today.

### D8 — Leftover dollars / clip / imports / map / Y (SETTLED, amended)

**Why this matters:** Generation dollars are already set (class MWh × one generation price). What remains is leftover T&D on each purchaser, and whether that changes that purchaser’s electricity bill. Changing bills to follow EIA retail-price gaps would move $ off industries onto households and force a VA repair (or break `x = inputs + VA`).

**Discussion path:** Guiding aims were keep IO tables balanced and still differentiate by end-use class. Option 3 (leave industry bills alone, put the leftover pattern only in Y) was ruled out — it would not model industry electricity use more accurately. Option 2 (change bills, VA absorbs) hits the EIA leftover-dollar pattern but rewrites sector VA; when $ move onto households, national industry VA rises. Option 1 keeps each purchaser’s electricity $; class mix still differs because D0’s EIA MWh shares are not the IO dollar mix.

**2017 illustration** (option 1). Each purchaser still pays their current `221100` dollars. Generation $ = MWh × `p`. Leftover = that bill minus generation $. Class leftover ¢/kWh is **not** Table 2.4 minus `p`; it is (class IO $ − class gen $) / class MWh. The withdrawn rule would have scaled EIA leftover gaps to a **$301.7 B** pool (~1.10×) and changed industry bills.

**Dollar toy** (same $100 toy as the settled-design section). Steel currently pays **$40**, a shop **$30**, households **$30**. Generation $ stay **$34**. EIA shares put about 29% / 35% / 36% of generation on Steel / shop / HH, so generation $ ≈ **$10 / $12 / $12**.

- **Option 1 (chosen):** bills stay **$40 / $30 / $30**. Leftover = bill − gen ≈ **$30 / $18 / $18**. Steel’s other inputs and VA do not move. `x` still equals inputs + VA.
- **Option 2 (not chosen):** EIA leftover-dollar pattern might assign leftover **$9 / $24 / $33**, so all-in bills become **$19 / $36 / $45**. Steel’s electricity bill falls **$21**; households’ rises **$15**. Steel `x` is unchanged, so unless VA rises $21 the column does not balance. National industry VA would rise because households have no VA to cut.

**Resolution (amendment):** Keep each purchaser’s electricity dollar total (the old `221100` cell). Generation dollars stay class MWh × generation price, allocated within class by electricity-purchase dollars. Leftover T&D on that purchaser is the rest of their bill. Do **not** spread leftover using EIA retail-price gaps. Do not split leftover in proportion to MWh alone nationally — leftover follows the IO bills after generation $ are taken out.

If generation $ would exceed that purchaser's bill, water-fill the clipped $ onto others in the same class (each purchaser `min(proportional gen $, bill)`; remainder to remaining slack). Do not cut generation $ to match an EIA retail bill. Nibble that class's MWh only if class bills < `p × class MWh`. On 2017 live IO this does not bind (Industrial bills/needed ≈ 1.7×; first-pass clips = 0).

Of leftover, split transmission vs distribution with **2017 UGO T/(T+D)** (~5.92% / 94.08%), including after D6 (D14) — not the full generation/T/D mix, and not model-year UGO T/(T+D). No leftover on the generation industry column (D1).

Keep today’s end-use map (households = Residential; electricity children = Industrial; within-class dollar weights). In P2, set `END_USE_MAPPING_REVIEW_STATUS` to adopted for EIA-anchored G/T/D (no longer DRAFT). `F05000` stays out of D0 class pools even though the dict labels it Commercial. `F04000` is the **Exports** class (D15), not Commercial. Imports are D11 (generation only; extra MWh = `|F05000| / p`). Published `y_nab` stays dollars; mixed-units `y_nab` is hybrid (D4). No extra margin table (Phi on G/T/D is identity — see post-#88 Phi decision). Table 2.4 is not used for leftover dollars (and already not used in mixed units).

**Why this answer:** Industry columns stay balanced without moving VA. End-use classes still differ in generation vs leftover mix via D0. The EIA leftover-dollar pattern is what would have changed bills.

**What we give up:** Leftover dollars by class will not follow EIA Table 2.4 price gaps. All-in ¢/kWh will not equal Table 2.4. T&D dollars will not equal published EIA retail bills. A class-level nibble of D0/eGRID MWh remains possible if that class's bills cannot cover `p × class MWh` (not observed on 2017 IO).

**Implementation:** For each non-electricity purchaser, domestic bill = `Udom` + Y cell of `221100` (**except** `F05000`). Do **not** include `Uimp` in the D8 bill. Assign gen $ by water-filling within class so `gen ≤ bill` and class totals hit D0 when class bills allow. `F04000` is a one-purchaser Exports class (D15): gen $ = `p` × Table 2.14 MWh; leftover = bill − gen; nibble that class only (do not raid Commercial). `td = bill − gen`. Split `td` with **2017** UGO T/(T+D) (D14). Write all `Uimp` `221100` onto the generation row with no leftover (D11). Electricity 3×3: D1 `U[G,G]` plus D10 remainder of self-use on `U[T,T]` / `U[D,D]`. Then Make-last. Drop compensating `w_row`.

### D9 — Config flags (SETTLED)

**Why this matters:** Today there are three electricity switches: reallocation, 3-way split, mixed units. A fourth switch would keep the old 3-way split around for comparison but adds config surface and waterfall states.

**Resolution:** **Do not add flags.** `implement_electricity_reallocation` stays as it is (co-production cleanup unchanged). `implement_electricity_disaggregation` **is** this new 3-way split (purchaser rows, 3×3, columns as settled). `implement_electricity_mixed_units` **is** the new generation conversion (T&D leftover already in dollars; generation conversion factors no longer pack Table 2.4 into the generation row). Existing YAML files keep the same flag names; only the code behind them changes.

**What we give up:** No second production flag that still runs the old 3-way. Old vs new in one checkout is a **committed freeze** of today’s production (P0), not a live dual path.

**Implementation:** **P0 first:** run today’s 3-way and mixed-units configs and write artifacts under [`bedrock/analysis/electricity_disagg_eia/output/baseline_current_production/`](bedrock/analysis/electricity_disagg_eia/output/baseline_current_production/). Commit that freeze. Then rewrite the 3-way-split and mixed-units functions in place. Canonical v0.3 (all electricity flags off) is unchanged. Reallocation-only configs are unchanged. Production 3-way-split and mixed-units tests are rewritten in the **same PR** (not skipped). `test_production_matches_compensated_scenario` is retargeted to the P0 freeze or deleted. Analysis d_85 stays historical. P6 also compares live new output to the freeze.

### D10 — Electricity self-use 3×3 (SETTLED)

**Aims (user, 2026-08-22):** (1) do not lose dollars of old `U[221100, 221100]`; (2) do not lose dollars of `221100` `x` or `q`; (3) model generation MWh = eGRID; (4) no Use 3×3 off-diagonals.

**Where leftover is not this cell:** D8 leftover is retail bill minus generation $ for Steel / shop / HH. Self-use is an intersection cell. Do not unbundle it with leftover language. Just place the cell on the diagonal.

**Check of the two recipes:**

- **D1 only (`U[G,G]`, T/T = D/D = 0).** (3) and (4) hold. (1) fails: remainder of the cell is dropped. (2) fails: Use+Y G+T+D $ falls, Make-last total `q`/`x` falls.
- **Plain diagonal split `U[k,k] = w_k × T`.** (1), (2), and (4) hold. (3) fails: `U[G,G] = w_G × T` is not D1’s purchaser slice, so generation Use+Y $ ≠ `p × eGRID` unless D0 is reopened and other purchasers’ generation $ are cut.

**Neither of those two hits all four.** The construction that does:

- `T = U[221100, 221100]` (domestic + imported self-use $).
- `U[G,G] = min(D1 purchaser slice, T)` — generation commodity, inside eGRID.
- Remainder `T − U[G,G]` on **`U[T,T]` and `U[D,D]`** with **2017** UGO T/(T+D) (D14). Those cells stay **dollars** (D4 does not convert T/D to MWh), so they do not add eGRID MWh.
- Off-diagonals 0.

Then (1) sum of diagonals = `T`; (2) Use+Y total $ unchanged, Make-last total `q`/`x` unchanged; (3) generation $ still `p × eGRID`; (4) no off-diagonals. D1 already allowed T/D diagonal cells “if any”; this is that remainder.

**Dollar toy:** Use+Y **$100**, self-use **$8**, D1 `U[G,G]` ≈ **$2**. Write **$2 / $0.4 / $5.6** on G/T/D diagonals (T vs D ≈ 6/94). Steel / shop / HH bills unchanged. Generation $ still **$34**. After mixed units, generation Use+Y MWh = eGRID; T/T and D/D stay $.

**If D1 `U[G,G]` would exceed `T`:** clip to `T` (same as D8 clip to the bill). Remainder 0. To keep (3), put the clipped generation $ on other Industrial purchasers in that class (class MWh still sums to the D0 target).

**Why this answer:** It is the only placement that keeps the intersection, keeps `q`/`x`, keeps eGRID, and stays diagonal. Circular T/T and D/D self-use is ordinary IO; it does not put generation emissions on T/D through this block.

**What we give up:** T and D industries buy their own commodities. `U[G,G]` is still D1’s Industrial slice, not `w_G × T`.

**Implementation:** After D0 writes `U[G,G]`, set `U[T,T]` and `U[D,D]` from `T − U[G,G]` with **2017** UGO T/(T+D) (D14). Do not write off-diagonals. Same ratio after D6.

### D11 — Imports vs the eGRID cap (SETTLED)

**Why this matters:** eGRID is **US plant** net generation (domestic output). BEA also has **imported** electricity. D0/D4 said generation Use+Y MWh = eGRID = `q`. If “Use+Y” includes imports, imported MWh are taken **out of** the eGRID cap. If “Use+Y” is domestic only, then `q` = domestic use = eGRID and import MWh sit **on top**. You cannot have all three of: `q` = eGRID, total (domestic+import) use = eGRID, and import MWh extra.

Today’s mixed units already pick the domestic identity. `electricity_class_row_factors` preserves **domestic** row MWh = eGRID (`adom` + `y`), then the same `c_row` is applied to `Aimp`. D4’s “Use+Y = eGRID” wording did not say that. D5’s eGRID − end-use gap is EIA losses / plant use / trade smeared into class MWh; it is **not** the BEA import row.

**Options considered:** (1) domestic Use+Y = eGRID, import MWh extra; (2) imports inside the cap; (3) raise `q` by import MWh. Do not leave the import generation row in dollars while domestic is MWh.

**Resolution:** **Option 1.** Domestic generation Use+Y MWh = eGRID = `q`. Guiding identity 3 is **output = domestic use**. D0 class MWh and `p` use **domestic** electricity $ (`Udom` + Y with `F05000` left as the import column). Extra import MWh = `|Y[221100, F05000]| / p`.

Imported `221100` is the generation commodity (wholesale), not a US bundled retail bill. Do **not** apply the UGO generation-dollar share or D8 leftover to imports. Intermediate `Uimp` is the industry slice of `F05000`, not additional. Same `c_row = 1/p` as domestic.

**Investigation — eGRID has no trade; EIA Table 2.14 does (2026-08-22):**

- **A, corrected.** Bedrock eGRID on this path is stewi **plant net generation only** (`us_total_net_generation_mwh`). GGL interconnect-loss helpers exist (`load_egrid_ggl`) but are **not** added to the cap. No national import or export MWh series.
- **B is correct.** EIA Electric Power Annual **Table 2.14** is already extracted (`epa_02_14`): Canada/Mexico imports and exports, MWh, by year. Parser skips the “U.S. total” block; national = Canada + Mexico.

Figures below used the **CF 2018 eGRID proxy** on 2017 IO dollars. D12 replaces that proxy on the 2017 chain (see knock-on there).

- eGRID 2018 = **4,168 TWh**. UGO gen share **34.17%**. `q_221100` = **$455.8 B**. `p` = **$37.36 / MWh**. `|F05000|` = **$2.431 B**. `Uimp` = **$1.488 B**.
- Option 1 extra MWh = `|F05000| / p` = **65.1 TWh**. (`Uimp / p` = 39.8 TWh would miss FD imports. `s × |F05000| / p` = 22.2 TWh is far too low.)
- EIA Table 2.14 **2018** imports = **58.3 TWh** (Canada 51.5 + Mexico 6.8). Option 1 / EIA 2018 = **1.12**.
- EIA Table 2.14 **2017** imports = **65.7 TWh** (Canada 59.9 + Mexico 5.8). Option 1 / EIA 2017 = **0.99**.

The 2018 gap is mostly **year**: IO $ are 2017, EIA 2018 imports were lower than 2017. Same-year (2017) dollars vs EIA MWh match. Exports do **not** use this import recipe (`F04000 / p` ≈ 73 TWh vs EIA 2018 exports **13.8 TWh**). **D15** assigns Table 2.14 export MWh to `F04000` inside eGRID instead.

**Why this answer:** eGRID is production; imports are extra supply; domestic Make–Use clears; extra MWh line up with EIA Table 2.14 when the dollar year matches.

**What we give up:** “output = all use” in MWh. Four-class MWh shares × (eGRID − exports) describe **domestic ultimate-customer** use of US generation. Export MWh are D15.

**Implementation:** D0/D8 eGRID allocation on domestic bills only. Place import `221100` entirely on the generation row (`Uimp` and the `F05000` generation cell). Convert at `1/p`. National check: import generation MWh ≈ `|F05000| / p`.

### D12 — 2017 eGRID proxy (SETTLED)

**Why this matters:** D0/D4/D11 use eGRID MWh as domestic generation output. The 3-way split is built on **2017** detail tables. Stewi eGRID inventories in bedrock are **2014, 2016, 2018–2024** — **no 2017**. D6 already re-applies D0 at the **model year** with that year’s real eGRID, so this proxy does not set published `q`. D12 is the **2017-chain** cap: class MWh = 2017 EIA shares × this MWh, and `p` = domestic gen $ / this MWh.

**Resolution:** **Option 4.** Estimate 2017 eGRID from the EIA 2016→2017 trend:

`eGRID_2017 = eGRID_2016 × (EIA Table 3.1 2017 / EIA Table 3.1 2016)`

Table 3.1 is all-sector net generation (3.1.A fossil/nuclear/pumped storage + 3.1.B renewables, including estimated small-scale solar). Assumption: the eGRID/EIA coverage ratio is stable from 2016 to 2017.

**Calculation (bedrock, 2026-08-22):**

- EIA 3.1 2016 = 3,468.129 + 628.258 = **4,096.387 TWh**
- EIA 3.1 2017 = 3,348.860 + 710.573 = **4,059.433 TWh**
- EIA 2016→2017 ratio = 4,059.433 / 4,096.387 = **0.990979** (**−0.90%**, a dip, not an increase)
- eGRID 2016 = **4,075.323 TWh**
- eGRID/EIA 2016 = 4,075.323 / 4,096.387 = **0.99486**
- **eGRID_2017 = 4,075.323 × 0.990979 = 4,038.559 TWh** (report **4,039 TWh**)
- That estimate / EIA 2017 = **0.99486** (same coverage gap as 2016; **0.5%** below EIA 2017)

Not chosen:

- Raw eGRID 2018 **4,168.370 TWh** (EIA 3.1 2018 = **4,210.526 TWh**; eGRID/EIA 2018 = 0.990). **2.7%** above EIA 2017. CF/year-alignment proxy.
- Raw eGRID 2016 **4,075 TWh** (**0.4%** above EIA 2017). Misses the 2016→2017 dip.
- EIA 3.1 2017 raw **4,059 TWh**. Same-year but not eGRID coverage.
- 2018-backward twin `eGRID_2018 × (EIA_2017 / EIA_2018)` = 4,168.370 × (4,059.433 / 4,210.526) = **4,018.790 TWh**. Differs because the coverage ratio is not identical in 2016 and 2018. Interpolating eGRID 2016 and 2018 would miss the 2017 dip.

**Knock-on for D11 on the 2017 chain:** `p` = (UGO gen share × `q_221100`) / 4,038.559 TWh ≈ **$38.56 / MWh** (was $37.36 with 2018 eGRID). `|F05000| / p` ≈ **63.0 TWh** vs EIA Table 2.14 2017 imports **65.7 TWh** (0.96). Model year still uses that year’s eGRID and that year’s Table 2.14 as a check.

**Why this answer:** Keeps eGRID plant coverage and moves it with EIA’s 2016→2017 change. D6 still overwrites at the model year.

**What we give up:** Bit-match to the published CF’s 2018 proxy on the 2017 chain. A made-up 2017 inventory (documented, reproducible from on-disk EIA 3.1 + eGRID 2016).

**Implementation:** Helper `egrid_mwh_for_io_year(2017)` = `us_total_net_generation_mwh(2016) * eia_table_3_1_total_mwh(2017) / eia_table_3_1_total_mwh(2016)`. Other years: real eGRID. D0/D4/D11 on the 2017 chain use this. After D6, `us_total_net_generation_mwh(model_base_year)`.

### D13 — Negative Use/Y cells (SETTLED)

**Why this matters:** D0 splits each class’s MWh among purchasers in proportion to their electricity **dollars**. A negative dollar cell then wants **negative MWh**. That is a different clip from D8 (cut generation $ so leftover is not negative on a *positive* bill).

**What is actually negative (2017 BEA detail `221100`):** industry Use has **no** negative cells. The only negative Y cell is **`F05000` = −$2.431 B**. After expansion or year scaling, small inventory/scrap negatives can still appear.

**Resolution:** **CF default — clip to 0 only when forming within-class dollar shares.** No purchaser gets negative MWh. Do **not** rewrite live Use/Y cells to 0. Exclude `F05000` from D0 class pools (it is D11 extra import MWh, not Commercial). Exclude `F04000` from Commercial (it is D15 Exports, inside eGRID). On a rare negative industry bill: generation $ = 0, leftover stays that negative cell (D8 leftover ≥ 0 does not bind there). `F05000` is not a D8 purchaser. `F04000` **is** a D8 purchaser (one-purchaser Exports class).

**Why this answer:** Matches the CF weight clip. Keeps `q = Utot + Y`. Does not double-count D11.

**What we give up:** Leftover may be negative on quirk cells. D8’s leftover ≥ 0 is only for positive bills.

**Implementation:** `clip(lower=0)` on the dollar series used for within-class shares (same as CF). Drop `F05000` and `F04000` from Table 2.2 class weights in `build_end_use_map`. Map `F04000` to Exports (D15). Leave Use/Y values unchanged.

### D14 — Leftover T vs D year (SETTLED)

**Why this matters:** D8 leftover on each (positive) purchaser is bill minus generation $. That leftover pool is split **transmission vs distribution** with UGO T/(T+D), not the full G/T/D mix. D10 uses the same T/(T+D) for the self-use remainder on `U[T,T]` and `U[D,D]`. D0 already froze the **generation-dollar share** at the **2017** UGO ratio even after year scaling. D14 is whether T/(T+D) is also frozen at 2017, or updated to the model year when D6 re-applies D0.

UGO305 has GO for every year 1997–2024. Production’s current `build_electricity_disagg_go_weights()` reads `usa_base_io_data_year` (2017). The CF also uses the IO-year UGO column. D6 1a uses **per-child GO growth** (gen vs T vs D grow at different rates), then Make-last overwrites `q`. T vs D of leftover is a small split (~6% / 94%).

**UGO T/(T+D) by year (bedrock, 2026-08-22):**

- 2017: **5.92% / 94.08%**
- 2018: 6.00% / 94.00%
- 2022: 5.76% / 94.24%
- 2023: 5.99% / 94.01%
- 2024: 6.03% / 93.97%

The leftover T vs D mix barely moves. Generation’s share of G+T+D **does** move in UGO (2017 **34.2%** → 2022 **38.8%** → 2024 **30.6%**). That is **not** the published D6 mix (see D6: 1a does not last).

Using 2024 T/(T+D) for leftover would **not** match D6 (D6 does not keep 2024 gen share). It would mix UGO years: 2017 for gen-vs-leftover, 2024 for leftover T vs D. Using 2024 UGO for **generation share as well** would reopen D0 and change `p`. That is a bigger change than D14.

**`p` and T/(T+D):** `p` = (2017 generation-dollar share × `221100` Use+Y $) / eGRID. T/(T+D) only splits leftover among T and D. It is **not** in the `p` formula. Model-year T/(T+D) would also leave `p` unchanged. What would change `p` is using the model-year generation share of `221100`, which D0 already ruled out.

**Options considered:**

1. **Freeze 2017 UGO T/(T+D)** (~5.92% / 94.08%) on the 2017 chain **and** after D6 re-apply. Same 2017 UGO structure as the generation-dollar share.
2. **2017 on the 2017 chain; model-year UGO T/(T+D) when D6 re-applies D0.** Slightly more “up to date.” 2024 would be 6.03% / 93.97% vs 5.92% / 94.08%.
3. **Make-last T vs D after the fact.** Circular: leftover writes T/D Use+Y, Make-last copies those totals.

**Resolution:** **Option 1.** Freeze 2017 UGO T/(T+D) (~**5.92% / 94.08%**) on the 2017 chain and after D6. Same ratio for D8 leftover and D10 self-use remainder. Leftover T vs D stays on 2017 UGO structure with D0; `p` stays on the 2017 generation-dollar share.

**Why this answer:** Pairs leftover T vs D with the frozen 2017 gen-vs-leftover split. D6 does not require a 2024 T/(T+D). The year-to-year T/(T+D) gap is ~0.1–0.3 percentage points.

**What we give up:** Model-year UGO T vs D (2024 would be 6.03% / 93.97%).

**Implementation:** `build_electricity_disagg_go_weights()` T/(T+D) from **2017** UGO, including after D6 re-apply. Do not read `model_base_year` UGO for this split.

**Toy:** leftover **$66**. 2017 split → T **$3.91**, D **$62.09**. 2024 split (not used) → T **$3.98**, D **$62.02**. Generation $ still **$34**; `p` unchanged.

### D15 — Exports as a D0 class (SETTLED)

**Why this matters:** Default D0 put `F04000` in Commercial. Generation MWh on that column were `bill / p` (~**73 TWh**), which is not EIA Table 2.14 exports (2018 **13.8 TWh**). That both overstates export MWh and pollutes Commercial with non-ultimate-customer use. Direct Use was already folded into Industrial rather than parked as a dummy Use-row cell (D5). Exports get the same treatment: a physical EIA series on a real IO column.

**Resolution:** Treat physical exports as their own D0 class, sole member `F04000`.

1. Export MWh = EIA Table 2.14 Canada + Mexico exports, same year as the eGRID in force (D12 on the 2017 chain; model year after D6). If Electric Power Annual lags `model_base_year`, use the latest 2.14 year and log it.
2. Four Table 2.2 classes get shares of Total End Use × **(eGRID − export MWh)**. Relative Res / Com / Ind+DU / Trans mix unchanged. Remaining D5 gap = eGRID − export MWh − Total End Use, still smeared across those four classes. `F04000` holds **Table 2.14 only**, not the rest of the gap. No dummy losses/plant-use cell (D5).
3. `F04000` is out of Commercial (D13 twin of `F05000`, opposite reason: `F05000` is extra import MWh; `F04000` is inside eGRID).
4. D8 on that column: gen $ = `p` × export MWh; leftover = bill − gen; T vs D from D14. Do not reassign leftover with Table 2.4. One-purchaser class: if the bill cannot cover `p` × exports, nibble that class only (do not raid Commercial, and do not raid exports to save Commercial). 2017 bills look slack (`F04000 / p` ≫ 2.14).
5. `q` = eGRID = domestic generation Use+Y still (four classes + `F04000`). `p` still (2017 UGO gen share × `221100` $) / eGRID. D11 imports stay extra on top. No new flag. Do not change the `F04000` dollar bill. Do not put `F04000` 100% on generation.

**Not chosen:** putting the whole D5 gap on `F04000`; scaling classes by (eGRID − X) but leaving `F04000` inside Commercial; giving `F04000` both a 2.14 target and a Commercial $ share; using `F04000 / p` as EIA exports.

**Why this answer:** Aligns Commercial with Table 2.2 ultimate-customer sales (GP1), keeps total generation = eGRID (GP2), keeps the export dollar bill (GP3), and treats exports as US generation used abroad (GP4). Leftover T&D on `F04000` is D8 uniformity, not a physical claim that exported kWh travel US distribution.

**What we give up:** `F04000 / p` as a descriptive export MWh. Leftover T&D dollars on the export column.

**Implementation:** Table 2.14 loader (`epa_02_14`, already extracted). Purchaser builder: fifth class `Exports` with one column `F04000`. End-use map: `F04000` → Exports, not Commercial. P5: do not spread `F04000` from 2017 Y column shares; assign 2.14 MWh on that column. P6: generation-row `F04000` MWh ≈ Table 2.14; Commercial class excludes `F04000`. D11 import check unchanged.

### Phi on disaggregated electricity (SETTLED, post-#88 review)

**Why this matters:** D8 leftover T&D is a producer-price split of each purchaser’s old `221100` bill. `cornerstone_industry_avg_margins` applies a different conversion: Phi (producer value / purchaser value) so purchaser-price `N` = producer-price `N` × Phi. Canonical v0.3 has margins on and electricity off. The electricity waterfall has margins off. `2025_usa_cornerstone_full_model_electricity_disaggregation` already has **both** flags on. The question was whether leftover T&D plus Phi would double-count a markup on electricity.

**USEEIO Phoebe (justification, 2026-08-22):** [USEEIOv2.6.0-phoebe-23](https://zenodo.org/records/17457336/files/USEEIOv2.6.0-phoebe-23.xlsx?download=1) `Phi` tab. Bedrock uses the same definition (`apply_phi_to_ef_vector`: `N_pur = N_pro × Phi`).

- **Phi = 1 is the identity** (producer price = purchaser price). **Phi = 0 is not “no margins”**; it would zero the purchaser factor. Bedrock already replaces inf/nan Phi with 1.0. When margins are inactive, `phi_for_sectors` is all ones — the same identity.
- Phoebe `221100/US` is **exactly 1.0 for every year 1997–2024**. Purchaser-price `N` equals producer-price `N` for aggregate electric power. `221200` and `221300` are also all-ones in that workbook (many utilities). About 152 sectors are all-ones; most goods are not (e.g. crops ~0.4–0.8).
- That means USEEIO does **not** put electric T&D into Phi on `221100`. BEA wholesale / retail / transport margins on that commodity are zero in that model, so PUR = PRO.
- After a 3-way split, `221110` / `221121` / `221122` are not in Phoebe or in BEA margins. Bedrock builds Phi on the 405-sector list (`COMMODITIES`, including `221100` only), then `reindex(..., fill_value=1.0)` onto `N`. The children are missing from that list, so they **already** get Phi = 1 via fill. Relying on that accident is not enough; set it explicitly.
- Mixed units: generation `N` is **per MWh**. A dollar-margin Phi ≠ 1 on `221110` would be the wrong units.
- Phi is per commodity. Steel can have Phi ≠ 1 while electricity has Phi = 1. Those do not conflict. Other sectors keep their usual purchaser-price conversion. Electricity leftover T&D stays in the producer-price Use table (D8); Phi = 1 on G/T/D does not add a second markup on electricity’s own `N`.
- The published SEF CSV still drops aggregate `221100` (`finalize_cornerstone_ef_table`). That filter does not automatically drop the three children; this decision is Phi identity, not the SEF row list.

**Resolution:** When the 3-way flag is on, **Phi = 1** on `221110`, `221121`, and `221122` (producer price = purchaser price), matching Phoebe on `221100`. Do not invent child-specific trade margins. Do not treat leftover T&D as a Phi haircut. Other commodities keep `derive_phi_cornerstone_usa_at_year`. No new flag. Do not error if 3-way and margins are both on.

**Implementation:** In `phi_for_sectors` (or immediately after reindex), if `implement_electricity_disaggregation`, set the three child codes to 1.0. P6: with a margins-on + 3-way config (or a unit test of `phi_for_sectors` on a 407 index), assert those three Phis are 1. Waterfall configs stay margins-off; `full_model_electricity_disaggregation` may keep both flags.
