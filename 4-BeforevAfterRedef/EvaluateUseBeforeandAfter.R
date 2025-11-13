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
  U_ratios <- U_b/U_a
  
  # Replace all NaN (0/0) with 1 to indicate that the values are equivalent between matrices
  U_ratios[is.na(U_ratios)] <- 1
  
  # Re-order the matrix, descending from left to right, by the values in the totals tow
  total_row_index <- which(rownames(U_ratios) %in% tot_row)
  U_ratios <- U_ratios[,order(U_ratios[total_row_index,], decreasing = TRUE)]
  
  # The first column should now be where the max value is for the totals row
  # Now order the matrix such that the rows are in descending order for that column
  
  U_ratios <- U_ratios[order(U_ratios[,1], decreasing = TRUE),]
  
  # Move totals row to the top
  total_row_index <- which(rownames(U_ratios) %in% tot_row) # This index will have changed during the last line
  other_rows <- seq(1:nrow(U_ratios))[!(seq(1:nrow(U_ratios)) %in% total_row_index)]
  U_ratios <- U_ratios[c(total_row_index, other_rows),]

  # For printing to excel, cbind rownames to dataframe
  U_ratios <- cbind(rownames(U_ratios), U_ratios)
  colnames(U_ratios)[1] <- "Com_Code"
    
  # Save sorted ratios matrix to list

  return(as.data.frame(U_ratios))
}


# START OF MAIN PART OF SCRIPT
# There are no summary use tables in purchaser prices saved as of useeior v.1.8
U_tables <- c("Detail_Use_2017_PRO","Detail_Use_2017_PUR","Summary_Use_2017_PRO","Summary_Use_2018_PRO","Summary_Use_2019_PRO",
      "Summary_Use_2020_PRO","Summary_Use_2021_PRO","Summary_Use_2022_PRO")

results_by_table <- list()
top_diffs <- data.frame()
top_diffs_num <- 10

for(u in U_tables) {
  
  U_ratios <- calculateUseIndustriesBeforeandAfter(u)
  results_by_table [[u]] <- U_ratios
  df <- U_ratios[1:top_diffs_num,1:2]
  colnames(df) <- paste(u,"_",colnames(df), sep = "")

  if(length(top_diffs) == 0){
    top_diffs <- df
  }
  top_diffs <- cbind(top_diffs, df) # Append first ten rows and first 2 cols of every Use table
  

}

# Print tables
# Writing results_by_table to excel because we are writing multiple sheets to one file 

writexl::write_xlsx(results_by_table, "4-BeforevAfterRedef/BvA_Full_Use_Tables.xlsx", format_headers = FALSE)
write.csv(top_diffs,"4-BeforevAfterRedef/TopDiffIndustriesByYear.csv", row.names = FALSE)



