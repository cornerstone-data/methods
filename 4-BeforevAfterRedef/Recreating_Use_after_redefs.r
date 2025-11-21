
library(devtools)
load_all("../useeior")
library(reshape2)

before <- buildIOModel("Before2017PRO",configpath="4-BeforevAfterRedef/Before2017PRO.yml")
after <- buildIOModel("After2017PRO",configpath="4-BeforevAfterRedef/After2017PRO.yml")

# Primary production in the make table happens where industry and commodity codes match, so resort Make table to match 
# commodity order

ind <- before$Industries
com <- before$Commodities
code_match <- intersect(ind$Code, com$Code)
industries_match <- match(code_match, ind$Code)
commodities_match <- match(code_match, com$Code)


V_b <- before$V
V_a <- after$V

U_b <- before$U
U_test <- U_b
U_a <- after$U

identical(rownames(U_b),rownames(U_a))
identical(colnames(U_b),colnames(U_a))
identical(rownames(V_b),rownames(V_a))
identical(colnames(V_b),colnames(V_a))



# Check: subtracting V before from V are redefs and taking a colSum should result in a vector of 0s as all the 
# off-diagonal values in a column should be moved to the diagonal value in that same column
# Actual values in colSums(V_diff) are not 0 for all indexes; values range from 1e07 to -6e06

V_diff <- V_a - V_b 
# all.equal(as.vector(colSums(V_diff)), rep(0, dim(V_diff)[1]))

# Values in the V_diff matrix mean the following:
# For each column (commodity): 
  # where the industry row has the same column code,
    # this is primary production. Values in this cell denote the total values commodity values reallocated to primary production FOR ALL INDUSTRIES and should be >0
  # where the industry row as a different column code,
    # this is coproduction. Values in these cells denote the total value reallocated away from co-production FOR EACH INDUSTRY and are negative
# In theory the sum of values away from co-production should equal the received values of primary production but it seems this is not always the case

for(c in 1:length(colnames(V_diff))){   # for each column in V_diff
  
  cur_col <- V_diff[,c, drop=FALSE] # get current column
  primary_ind_index <- which(rownames(cur_col) %in% colnames(cur_col)) # primary production index in this column
  
  if(length(primary_ind_index) > 0){# if there is a primary production industry for this commodity
    
    ind_received_val <- cur_col[primary_ind_index] # Assign the received value from co production
    
    if(ind_received_val != 0){
      # if the industry received value is > 0 that means there was co-production reallocation for this commodoity
      print(paste0("Cur col is ", colnames(cur_col), " and row indeces are ", which(cur_col >0)))
      
      # Get indexes of industries where values are < 0 as those are the industries where the value was reallocted FROM
      co_prod_indexes <- which(cur_col < 0)
      co_prod_values <- cur_col[co_prod_indexes] * -1
      
      # Get Use table industry column (production recipe) for selected industries by dividing each column element in the
      # Use table by the column total
      if(length(co_prod_indexes) > 1){
        totals <- colSums(U_b[,co_prod_indexes])
        co_prod_input_structures <- sweep(U_b[,co_prod_indexes], 2, totals, FUN = '/')
        # Get proportional values to reallocate away from the Use table
        co_prod_cols <- sweep(co_prod_input_structures, 2, co_prod_values, FUN = '*')
        
        receiving_vals <- rowSums(co_prod_cols)
        
      } else{
        totals <- sum(U_b[,co_prod_indexes])
        co_prod_input_structures <- as.matrix(U_b[,co_prod_indexes]/totals)
        co_prod_cols <- co_prod_input_structures * co_prod_values
        
        colnames(co_prod_cols) <- colnames(U_b)[co_prod_indexes]
        receiving_vals <- co_prod_cols
      }
      
      # Remove input values from original industry
      common_cols <- intersect(colnames(U_b), colnames(co_prod_cols))
      U_test[, common_cols] <- U_test[, common_cols] - co_prod_cols[, common_cols]
      
      # Add input values to receiving industry
      U_test[, primary_ind_index] <- U_test[, primary_ind_index] + receiving_vals
      
    }else{
      # if industry received value is 0 that means there was no co-production reallocation and
      # thus we need not make changes in the use table for this pair of industries, so there should be nothing here
    }
  }  


}

print("Comparing original Use after redefinitions (U_a) and reconstructed Use after (U_test) Use tables:")

print("Comparing column sums using all.equal(colSums(U_test), colSums(U_a)): ")
all.equal(colSums(U_test), colSums(U_a))

print("Comparing total values in the matirces with sum(sum(U_a)) / sum(sum(U_t)): ")
sum(sum(U_test)) / sum(sum(U_a))


# Print to excel
U_list <- list()
U_list[["U_b"]] <- cbind(row.names(U_b),as.data.frame(U_b))
U_list[["U_a"]] <- cbind(row.names(U_a),as.data.frame(U_a))

U_a_divBy_b <- U_a/U_b
U_list[["U_a_divBy_b"]] <- cbind(row.names(U_a_divBy_b),as.data.frame(U_a_divBy_b))


U_list[["U_test"]] <- cbind(row.names(U_test),as.data.frame(U_test))


U_ratios <- U_test/U_a
U_ratios[is.na(U_ratios)] <- 0

U_list[["U_test_divBy_U_a"]] <- cbind(row.names(U_ratios),as.data.frame(U_ratios))

writexl::write_xlsx(U_list, "4-BeforevAfterRedef/U_test.xlsx", format_headers = FALSE)

