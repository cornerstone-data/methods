## Evaluate the impacts of waste disaggregation N matrix for GHGs
# Compare the N matrix with and without waste disaggregation

# requires >= v1.8
devtools::load_all("../useeior")

# Build supply chain factors model v1.4 w/ waste disaggregation
modelname <- "USEEIOv2.6.0-phoebe-23"
modelconfigfile <- c(paste0("../supply-chain-factors/model-specs/", modelname, ".yml"))
m1 <- buildModel(modelname, configpaths=modelconfigfile)

# Rebuild model without waste disaggregation
m2 <- initializeModel(modelname, modelconfigfile)
m2$specs$DisaggregationSpecs <- NULL
m2$specs$Model <- "USEEIOv2.6.0-phoebe-23_no_waste_disagg"
m2 <- loadIOData(m2, modelconfigfile)
m2 <- loadandbuildSatelliteTables(m2)
m2 <- loadandbuildIndicators(m2)
m2 <- loadDemandVectors(m2)
m2 <- constructEEIOMatrices(m2, modelconfigfile)


# Compare N values
df1 <- t(as.data.frame(m1$N))
df2 <- t(as.data.frame(m2$N))

# Highlight sectors of greater than 1% +/- difference
merged_df <- merge(df1, df2, by = 0, all = TRUE, suffixes = c("_with_disagg", "_without_disagg"))
merged_df['comp'] <- round(merged_df[,2] / merged_df[,3],3)
merged_df <- merged_df[merged_df$comp > 1.01 | merged_df$comp < 0.99, ]
merged_df <- merged_df[!is.na(merged_df$comp), ]

# Waste sectors not included
write.csv(merged_df, '49-waste_disagg/waste_disagg_N_comparison.csv', row.names=FALSE)
