# Compare changes in the Use table in Before vs. After Redefinition. 
# The changes in the Use table after redefinitions are a result of reallocations across industries (Use table columns) based on the 
# secondary product redefitions made in the Make table

library(devtools)
load_all("../useeior")


# Calculate ratio of Use table industries before and after redifitions
calculateUseIndustriesBeforeandAfter <- function(m) {
  l <- list()
  
  U_b <- as.matrix(get(paste0(m,"_BeforeRedef_17sch")))
  U_a <- as.matrix(get(paste0(m,"_AfterRedef_17sch")))
  
  if(startsWith(m,"Detail")) {
    tot_col <- "T007"
    tot_row <- "T008"
    
    # Code below needed because Detail_use before redefinitions does not have the proper name for the last 2 columns
    lastCol <- length(colnames(U_b))
    colnames(U_b)[(lastCol-1):lastCol] <- c("T004", tot_col)
    

  } else {
    tot_col <- "Total Commodity Output"
    tot_row <- "Total Industry Output"
    tot_intermediate <- "Total_Intermediate"
  }


  # # For U_b
  # 
  # # Remove total columns and rows
  # U_b_col_names_to_keep <- colnames(U_b)[grep("^T", colnames(U_b), invert = TRUE)]
  # U_b_row_names_to_keep <- rownames(U_b)[grep("^T", rownames(U_b), invert = TRUE)]
  # U_b_minusTs <- U_b[U_b_row_names_to_keep, U_b_col_names_to_keep]
  # 
  # # Find FD and VA start indexes
  # FD_Col_start <- grep("^F01",colnames(U_b_minusTs))
  # VA_Row_start <- grep("^V001", rownames(U_b_minusTs))
  # U_b_no_FD <- U_b_minusTs[, 1:(FD_Col_start-1), drop = FALSE]
  # U_b_only_FD <- as.matrix(U_b_minusTs[, -(1:(FD_Col_start-1))])
  # 
  # # For U_a
  # # Remove total columns and rows
  # U_a_col_names_to_keep <- colnames(U_a)[grep("^T", colnames(U_a), invert = TRUE)]
  # U_a_row_names_to_keep <- rownames(U_a)[grep("^T", rownames(U_a), invert = TRUE)]
  # U_a_minusTs <- U_a[U_a_row_names_to_keep, U_a_col_names_to_keep]
  # 
  # # Find FD and VA start indexes
  # FD_Col_start <- grep("^F01",colnames(U_a_minusTs))
  # VA_Row_start <- grep("^V001", rownames(U_a_minusTs))
  # U_a_no_FD <- U_a_minusTs[, 1:(FD_Col_start-1), drop = FALSE]
  # U_a_only_FD <- as.matrix(U_a_minusTs[, -(1:(FD_Col_start-1))])
  
  
  ## Compare U_b and U
  # Get ratios before:after
  U_ratio <- U_b/U_a
  
  # Replace all NaN (0/0) with 1 to indicate that the values are equivalent between matrices
  U_ratio[is.na(U_ratio)] <- 1
  
  # Re-order the matrix, descring from left to right, by the values in the totals tow
  total_row_index <- which(rownames(U_ratio) %in% tot_row)
  U_ratio <- U_ratio[,order(U_ratio[total_row_index,], decreasing = TRUE)]
  
  # Move totals row to the top
  other_rows <- seq(1:nrow(U_ratio))[!(seq(1:nrow(U_ratio)) %in% total_row_index)]
  U_ratio <- U_ratio[c(total_row_index, other_rows),]
  
  # Save sorted ratios matrix to list
  
  l[["U_ratios"]] <- as.data.frame(U_ratio)
  
  
  #TODO: Perform additional analysis on top 10 most changed values in the sorted matrix

  return(l)
}

# There are no summary use tables in purchaser prices saved as of useeior v.1.8
U_tables <- c("Detail_Use_2017_PRO","Detail_Use_2017_PUR","Summary_Use_2017_PRO","Summary_Use_2018_PRO","Summary_Use_2019_PRO",
      "Summary_Use_2020_PRO","Summary_Use_2021_PRO","Summary_Use_2022_PRO")

PRO_or_PUR <- c("_PRO", "_PUR")

results_by_table <- list()
for(u in U_tables) {
  
    result_list <- calculateUseIndustriesBeforeandAfter(u)
    results_by_table[[u]] <- result_list[["U_ratios"]]
    
}


