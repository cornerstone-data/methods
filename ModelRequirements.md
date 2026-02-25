# Model Requirements

All models should include, after model build, all the following matrices and vectors (as defined by [useeior model objects](https://github.com/cornerstone-data/useeior/blob/1565a70b7da2e50ff7ab5fc344fc0ba95f307a8a/format_specs/Model.md)): **A, B, C, D, M, N, U, V, Y, Rho, Phi, Tau, x, q**, for each commodity and region, along with metadata capturing input data, assumptions, and code version used to build the model.

## Cornerstone v1 Global EEIO

### US National Component

>[!IMPORTANT]
> US model will be derived using current methods from USEEIO v2 and/or CEDA 2026 without major methodological or data source nuance

- \>= 400 commodities, using the BEA schema with some reclassifications
- 2012-2023 time series

> [!NOTE]
> Plan to use 2017 Benchmark tables from the BEA as the input as these are still expected to be the most recent available in 2026

- Homogenous production functions (input structure) for commodities except when co-production using different industry processes is valid
- GHG extension with at least as many sectors as the model itself, unique for each model year
- Enable converting model results into PUR price
- Enable supply chain and emission factor decomposition by scopes and supply chain tiers
- Include full and partial (e.g.) consumption vectors
- Achieve [flow total by commodity recalculation validation](https://www.nature.com/articles/s41597-022-01293-7#Equ28) except for understood exceptions
- Calculate CO2e using IPCC AR6 GWPs
- Be useable with import emission factors that are consistent in scope (classification, year, boundaries) and separate clearly domestic and imported requirements in impact calculations

### US State Models

- State-based two region models for 50 states (and potentially D.C.)
- ~70 commodities, using the BEA summary schema with some reclassifications
- 2012 - 2023 time series
- Derived from national BEA summary tables
- GHG extension with at least as many sectors as the model itself, unique for each model year
- Calculate CO2e using IPCC AR6 GWPs
