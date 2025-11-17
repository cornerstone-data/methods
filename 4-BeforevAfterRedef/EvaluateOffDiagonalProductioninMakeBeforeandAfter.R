#Compare co-production defined as off-diagonal output in Make table from Make Before and After redefinitions to see how much output is moved to the diagonal.

library(devtools)
load_all("../useeior")

source('4-BeforevAfterRedef/Functions.R')


calculateOffDiagonalCommodityProductioninMakeBeforeandAfter <- function(m) {
  l <- list()

  
  l[["v_b_off"]] <- V_b_off
  l[["v_a_off"]] <- V_a_off
  
  #Percent of off-diagonal before
  q_b_off_percent <- (sum(V_b_off)/q)*100
  
  #Percent of off-diagonal after
  q_a_off_percent <- (sum(V_a_off))/q*100
  
  l[["per_off_diag_output"]] <- c("Before"=q_b_off_percent,"After"=q_a_off_percent)
  
  return(l)
}

vs <- c("Detail_Make_2017","Summary_Make_2017","Summary_Make_2018","Summary_Make_2019",
      "Summary_Make_2020","Summary_Make_2021","Summary_Make_2022")

q_off_diag_percent <- list()
for(v in vs) {

  if(startsWith(v,"Detail")) {
    tot_row <- "T007"
    tot_col <- "T008"
  } else {
    tot_row <- "Total Commodity Output"
    tot_col <- "Total Industry Output"
  }
  
  V_b <- as.matrix(get(paste0(m,"_BeforeRedef_17sch")))
  q <- V_b[tot_row,tot_col]
  
  V_b_off <- getOffDiagonalMake(V_b)
  V_a <- as.matrix(get(paste0(m,"_AfterRedef_17sch")))
  V_a_off <- getOffDiagonalMake(V_a)


  result_list <- calculateOffDiagonalCommodityProductioninMakeBeforeandAfter(v)
  q_off_diag_percent[[v]] <- result_list[["per_off_diag_output"]]
}

#Prepare tables for summary states

df <- t(data.frame(q_off_diag_percent))
write.csv(df,"PercentofOffDiagonalMakeinBeforeandAfterRedef_2017-2022.csv")

#Now get a diff of before and after make off diagonal to compare for a given year 
#sum_make_2017_result <- compareMakeBeforeandAfter("Detail_Make_2017")

#sum_make_2017_beforeafter_diff <- sum_make_2017_result[["v_b_off"]] - sum_make_2017_result[["v_a_off"]]

#write.csv(sum_make_2017_beforeafter_diff,"sum_make_2017_beforeafter_diff.csv")
