# Comparing A Matrix Before and After Scrap Adjustment

This analysis evaluates how removing scrap commodity production affects the technical coefficients matrix (A) in input-output analysis.

## Purpose

The script compares the technical coefficients matrix before and after adjusting for scrap commodity removal. This adjustment is necessary because scrap production inflates industry output totals, which affects the calculation of technical coefficients (direct input requirements per unit of output).

## Mathematical Foundation

### Core Concept

The script implements the **scrap adjustment** method described in input-output literature (see [BEA's manual page 223-226](https://www.bea.gov/sites/default/files/methodologies/IOmanual_092906.pdf#page=223)). The mathematical operations are **equivalent** to the theoretical derivation, using complementary notation.

### Key Mathematical Expressions

1. **Non-scrap output calculation:**

   ```
   non_scrap_x = x - V[:,scrap]
   ```

   Where `x` is total industry output and `V[:,scrap]` is scrap production.

2. **Non-scrap ratio (NSR):**

   ```
   nsr = non_scrap_x / x = 1 - (scrap/x)
   ```

   Ratio of non-scrap to total output for each industry.

3. **Adjusted market shares:**

   ```
   V_n_adj = diag(1/nsr) × V_n_no_scrap
   ```

   Market shares adjusted to account for scrap removal.

4. **Adjusted technical coefficients:**
   ```
   A_adj = U_n_no_scrap × V_n_adj
   ```
   Technical coefficients matrix using adjusted market shares.

### Mathematical Equivalence with PDF Derivation

The script's approach is **mathematically equivalent** to the transformation matrix method:

**PDF Derivation:**

```
W = (I - p̂)^(-1) × D
```

Where `p` is scrap ratio (`p = scrap/total`) and `D` is market share matrix.

**R Script Implementation:**

```
V_n_adj = diag(1/nsr) × V_n_no_scrap
```

Where `nsr = 1 - p` (non-scrap ratio).

**Proof of Equivalence:**
Since `nsr = 1 - p`, we have:

```
diag(1/nsr) = diag(1/(1-p)) = (I - p̂)^(-1)
```

Therefore: **V_n_adj = W** (mathematically equivalent!)

The only differences are:

- **Notation:** Uses non-scrap ratio (`nsr`) instead of scrap ratio (`p`)
- **Application:** Compares A matrices rather than deriving total requirements matrices
- **Implementation:** Explicitly removes scrap rows/columns before comparison

## What the Script Does

1. **Loads model data:** Initializes USEEIOv2.3-GHG model and builds economic matrices
2. **Calculates non-scrap ratios:** Determines what fraction of each industry's output is non-scrap
3. **Adjusts market shares:** Applies NSR adjustment to market shares matrix
4. **Computes adjusted A matrix:** Recalculates technical coefficients using adjusted market shares
5. **Compares results:** Generates comparison metrics between original and adjusted A matrices

## Outputs

The script generates two CSV files:

1. **`A_int_tot_comp.csv`**: Column-wise comparison showing:

   - Sum of intermediate requirements (original)
   - Sum of intermediate requirements (scrap-adjusted)
   - Relative difference between the two
   - Sorted by relative difference (largest differences first)

2. **`A_diff.csv`**: Element-wise difference matrix:
   ```
   A_diff = A_no_scrap - A_adj
   ```
   Shows cell-by-cell differences between original and adjusted technical coefficients.

## Usage

```r
# Run the script
source("EvalScrapAdjustment.R")
```

**Requirements:**

- `useeior` package (loaded via `devtools::load_all("../useeior")`)
- USEEIOv2.3-GHG model data

## Key Variables

- **x**: Industry output vector (total output by industry)
- **V**: Make matrix (industries × commodities) - production of commodities by industries
- **V_n**: Normalized market shares matrix
- **U**: Use matrix (commodities × industries) - intermediate consumption
- **A**: Technical coefficients matrix (A = U_n × V_n)
- **S00401/US**: Scrap commodity code

## Interpretation

- **Positive differences** in `A_int_tot_comp.csv` indicate industries where the original A matrix had higher intermediate requirements than the scrap-adjusted version
- **Large relative differences** suggest industries where scrap production significantly affects technical coefficients
- The **A_diff matrix** shows which commodity-industry pairs are most affected by the scrap adjustment
