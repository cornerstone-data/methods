devtools::load_all("../useeior")

# Use model with GHGs
modelname <- "USEEIOv2.3-GHG"

#Start building a model and build the Econ matrices
m_adj <- initializeModel(modelname)
m_adj <- loadIOData(m_adj)

drop_scrap_from_df <- function(df,axis) {
    if (axis==1) {
    df <- df[-which(rownames(df) %in% 'S00401/US'),]
    } else if (axis==2) {
    df <- df[,-which(colnames(df) %in% 'S00401/US')]        
    }
    return(df)
}
drop_scrap_items_from_vector <- function(v) {
    v <- v[-which(names(v) %in% 'S00401/US')]
    return(v)
}


#Remove scrap in adjusted model commodity-related data
#Perform update on all dfs where there is a row for comm
tmp <- list(m_adj$MultiYearCommodityOutput,
            m_adj$MultiYearCommodityCPI,
            m_adj$FinalDemand,
            m_adj$DomesticFinalDemand,
            m_adj$UseTransactions,
            m_adj$DomesticUseTransactions,
            m_adj$ImportMatrix
            )
tmp <- lapply(tmp,FUN=drop_scrap_from_df,axis=1)
m_adj$MultiYearCommodityOutput <- tmp[[1]]
m_adj$MultiYearCommodityCPI <- tmp[[2]]
m_adj$FinalDemand <- tmp[[3]]
m_adj$DomesticFinalDemand <- tmp[[4]]
m_adj$UseTransactions <- tmp[[5]]
m_adj$DomesticUseTransactions <- tmp[[6]]
m_adj$ImportMatrix <- tmp[[7]]

#Update Commodities
m_adj$Commodities <- m_adj$Commodities[-which(m_adj$Commodities$Code_Loc %in% 'S00401/US'),]

#Update Make where coms are on cols
m_adj$MakeTransactions <- drop_scrap_from_df(m_adj$MakeTransactions,axis=2)

#Update all named vectors
m_adj$CommodityOutput <- drop_scrap_items_from_vector(m_adj$CommodityOutput)
m_adj$InternationalTradeAdjustment <- drop_scrap_items_from_vector(m_adj$InternationalTradeAdjustment)

#Now continue with model building
m_adj <- loadandbuildSatelliteTables(m_adj)
m_adj <- loadandbuildIndicators(m_adj) 
m_adj <- loadDemandVectors(m_adj)
#m_adj <- constructEEIOMatrices(m_adj)

m_adj$TbS <- do.call(rbind,m_adj$SatelliteTables$totals_by_sector)
  # Set common year for flow when more than one year exists
m_adj$TbS  <- setCommonYearforFlow(m_adj$TbS)
  # Generate coefficients 
m_adj$CbS <- generateCbSfromTbSandModel(m_adj)
  


#Fully build a standard model for reference
m <- buildModel(modelname)

#Apply scrap adjustment
# Now modify marketshares for a scrap adjustment
non_scrap_x <- m$x - m$V[,'S00401/US'] 
identical(names(m$x),rownames(m$V))
x_com <- cbind(m$x,non_scrap_x)
#calculate non-scrap ratio, nsr, for each industry
nsr <- non_scrap_x/m$x
#Add it to data frame for inspecting separately
x_com <- cbind(x_com,nsr)
#Load and drop scrap column from Market shares so that nsr can be applied to it
V_n <- m$V_n
V_n_no_scrap <- m$V_n[,-which(colnames(m$V_n) %in% 'S00401/US')]
dim(V_n_adj)
#Put nsr into matrix form which is industry x industry
nsr_matrix <- diag(nsr, length(nsr),length(nsr))
#Premultiply the market shares by it to apply nsr for an industry to each row coefficient which is industries relative production of each commodity
V_n_adj <- solve(nsr_matrix) %*% V_n_no_scrap
rownames(V_n_adj) <- rownames(V_n)
#check that calculation was correct row by row for a couple industries with known non 1 nsrs
# c <- data.frame(cbind(V_n_adj["321910/US",],V_n_no_scrap["321910/US",]/nsr["321910/US"]))
# c$diff <- c[,1] - c[,2]
# sum(c$diff)
# c <- data.frame(cbind(V_n_adj["332119/US",],V_n_no_scrap["332119/US",]/nsr["332119/US"]))
# c$diff <- c[,1] - c[,2]
# sum(c$diff)


#Now apply the modified market shares to the Use table. First though remove the scrap row from the Use table
m_adj$q <- m_adj$CommodityOutput
m_adj$x <- m_adj$IndustryOutput
m_adj$U_n <- generateDirectRequirementsfromUse(m_adj, domestic = FALSE) #normalized Use
m_adj$U_d_n <- generateDirectRequirementsfromUse(m_adj, domestic = TRUE) #normalized DomesticUse 
m_adj$V_n <- V_n_adj
m_adj$A <- m_adj$U_n %*% m_adj$V_n
m_adj$A_d <- m_adj$U_d_n %*% m_adj$V_n

#Commodity mix has to be calculated outside of useeior because industry output can't be used but rather
#The calculated output as rowsums needs to be used
#normalizeIOTransactions(t(model$MakeTransactions), model$IndustryOutput)
m_adj$C_m <- normalizeIOTransactions(t(m_adj$MakeTransactions), rowSums(m_adj$MakeTransactions))
#Optional test to show tolerance is not exceeded
# industryoutputfractions <- colSums(C_m)
# tolerance <- 0.01
# for (s in industryoutputfractions) {
#   if (abs(1-s)>tolerance) {
#     stop("Error in commoditymix")
#   }
# }

# Generate model matrices
m_adj$B <- createBfromFlowDataandOutput(m_adj)
m_adj$C <- createCfromFactorsandBflows(m_adj$Indicators$factors,rownames(m_adj$B))
 # Add direct impact matrix
m_adj$D <- m_adj$C %*% m_adj$B

#Calculate L for adjusted model
I <- diag(nrow(m_adj$A))
m_adj$L <- solve(I - m_adj$A)
m_adj$L_d <- solve(I - m_adj$A_d)

m_adj$M <- m_adj$B %*% m_adj$L
m_adj$N <- m_adj$C %*% m_adj$M


## Compare the total intermediate requirements in the two A matrices
A_no_scrap_col <- m$A[,-which(colnames(m$A) %in% 'S00401/US')]
A_int_tot_comp <- data.frame(cbind(colSums(A_no_scrap_col), colSums(m_adj$A)))
A_int_tot_comp$rel_diff <- (A_int_tot_comp[,1] - A_int_tot_comp[,2])/A_int_tot_comp[,2]

colnames(A_int_tot_comp) <- c("Sum Intermediate Reqs","Sum Intermediate Reqs Scrap Adj","Rel_Diff")

A_int_tot_comp <- A_int_tot_comp[order(A_int_tot_comp$Rel_Diff, decreasing=TRUE),]
write.csv(A_int_tot_comp,"A_int_tot_comp.csv")


##Now compare them cell-wise
A_no_scrap <- m$A[-which(rownames(m$A) %in% 'S00401/US'),-which(colnames(m$A) %in% 'S00401/US')]
identical(rownames(A_no_scrap),rownames(m_adj$A))
identical(colnames(A_no_scrap),colnames(m_adj$A))

#A_adj always has great req because scrap requirement was removed causing others to increas 
A_diff <- m_adj$A - A_no_scrap 

A_diff_totals_by_com <- sort(colSums(A_diff),decreasing = TRUE) 

#Get cells with greatest 1% of changes
threshold <- quantile(A_diff, probs = 0.99)
indices_above_threshold <- which(A_diff > threshold, arr.ind = TRUE)
A_diff_changes <- data.frame(input=rownames(A_diff)[indices_above_threshold[,1]],
                             output=colnames(A_diff)[indices_above_threshold[,2]],
                             value=A_diff[indices_above_threshold]
)   

A_diff_top_changes <- A_diff_changes[order(A_diff_changes$value, decreasing=TRUE),]

write.csv(A_diff_top_changes,"A_diff_top_changes.csv")

## Visualize the A_no_scrap and A_adj matrices as x-y scatter plot, and save as PNG
png("A_comparison_plot.png", width=800, height=800)

p <- plot(as.vector(A_no_scrap), as.vector(m_adj$A),
     xlab="A_no_scrap", ylab="A_adj", main="A_no_scrap vs A_adj")
abline(0, 1, col="grey")

dev.off()


## Test to see if a model with scrap adjustment yields different results and can be validated

#Copy model object to an adjusted model and create needed objects 1 by 1

##Compare N matrices in adjusted and unadjusted models
N_no_scrap <- m$N[,-which(colnames(m$N) %in% 'S00401/US')]
N_comp <- data.frame(t(rbind(N_no_scrap,m_adj$N)))
colnames(N_comp) <- c("N","N_adj")
N_comp$N_rel_abs_change <- abs(N_comp$N_adj- N_comp$N)/N_comp$N
write.csv(N_comp,"N_comp.csv")

## Visualize the N matrices as x-y scatter plot, and save as PNG
png("N_comparison_plot.png", width=800, height=800)

p <- plot(N_comp$N,N_comp$N_adj,
     xlab="N", ylab="N_adj", main="N vs N_adj")
abline(0, 1, col="grey")

dev.off()

## Try to Validate adjusted model

# Test if adjusted model output can be recalculated
v <- compareOutputandLeontiefXDemand(m_adj, use_domestic=FALSE)
v$Failure
#      rownames variable
# 399 S00402/US       V1
# 400 S00300/US       V1

# Test if model output can be recalculated
v <- compareOutputandLeontiefXDemand(m, use_domestic=FALSE)
v$Failure
#      rownames variable
# 399 S00402/US       V1
# 400 S00300/US       V1

# Test if adjusted model domestic output can be recalculated
v <- compareOutputandLeontiefXDemand(m_adj, use_domestic=TRUE)
v$Failure
#      rownames variable
# 399 S00402/US       V1
# 400 S00300/US       V1

# Test if model domestic output can be recalculated
v <- compareOutputandLeontiefXDemand(m, use_domestic=TRUE)
v$Failure
#      rownames variable
# 399 S00402/US       V1
# 400 S00300/US       V1

# Test if adjusted model E can be recalculated
v <- compareEandLCIResult(m_adj,use_domestic=FALSE,tolerance=0.02)
v$Failure
#0
v$N_Pass
#[1] 7218
v <- compareEandLCIResult(m_adj,use_domestic=TRUE,tolerance=0.02)
v$Failure
#0
v$N_Pass
#[1] 7218

# Compare result to standard model if E can be recalculated
v <- compareEandLCIResult(m,use_domestic=FALSE,tolerance=0.02)
v$Failure
#0
v$N_Pass
#[1] 7236
v <- compareEandLCIResult(m,use_domestic=TRUE,tolerance=0.02)
v$Failure
#0
v$N_Pass
#[1] 7236

#### General inspection of Use table
U <- m$U
coms <- m$Commodities
ind <- m$Industries
uses_of_Used <- t(U['S00402/US',,drop=FALSE])
colnames(uses_of_Used) <- "Used"
colSums(uses_of_Used)

uses_of_Scrap <- t(U['S00401/US',,drop=FALSE])
colnames(uses_of_Scrap) <- "Scrap"
colSums(uses_of_Scrap)

uses_of_customs_duties <- t(U['4200ID/US',])
colSums(uses_of_customs_duties)
#Custom duties are only in the import column
#commodity output = value in imports

uses_of_non_comp <- t(U['S00300/US',])
colSums(uses_of_non_comp)
#total is close to zero because imports value (F05000) cancels out uses

uses_of_row_adj <- t(U['S00900/US',])
colSums(uses_of_row_adj)
#3.4E9

##Check out A
A_int <- sweep(U,MARGIN=2,colSums(U),FUN="/")
A_int_scrap <- t(A_int['S00401/US',])   #,decreasing=TRUE)
A_int_scrap <- merge(A_int_scrap,ind[,c("Code_Loc","Name")],by.x=0,by.y="Code_Loc")
write.csv(A_int_scrap,"A_int_scrap.csv",row.names=FALSE)

##U_met <- U[,grep("^331",colnames(U))]
##U_met_A_int <- sweep(U_met,MARGIN=2,colSums(U_met),FUN="/")

