devtools::load_all("../useeior")

# Use model with GHGs
modelname <- "USEEIOv2.3-GHG"

#Start building a model and build the Econ matrices
m <- initializeModel(modelname)
m <- loadIOData(m)
m <- useeior:::buildEconomicMatrices(m)
m <- loadandbuildSatelliteTables(m)
m <- loadandbuildIndicators(m) 


# Now modify marketshares
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
c <- data.frame(cbind(V_n_adj["321910/US",],V_n_no_scrap["321910/US",]/nsr["321910/US"]))
c$diff <- c[,1] - c[,2]
sum(c$diff)

c <- data.frame(cbind(V_n_adj["332119/US",],V_n_no_scrap["332119/US",]/nsr["332119/US"]))
c$diff <- c[,1] - c[,2]
sum(c$diff)

#Now apply the modified market shares to the Use table. First though remove the scrap row from the Use table
U_no_scrap <- m$UseTransactions[-which(rownames(m$UseTransactions) %in% 'S00401/US'),]
U_n_no_scrap <- useeior:::normalizeIOTransactions(U_no_scrap,m$x)
A_adj <- U_n_no_scrap %*% V_n_adj

## Compare the total intermediate requirements in the two A matrices
A_no_scrap_col <- m$A[,-which(colnames(m$A) %in% 'S00401/US')]
A_int_tot_comp <- data.frame(cbind(colSums(A_no_scrap_col), colSums(A_adj)))
A_int_tot_comp$rel_diff <- (A_int_tot_comp[,1] - A_int_tot_comp[,2])/A_int_tot_comp[,2]

colnames(A_int_tot_comp) <- c("Sum Intermediate Reqs","Sum Intermediate Reqs Scrap Adj","Rel_Diff")

A_int_tot_comp <- A_int_tot_comp[order(A_int_tot_comp$Rel_Diff, decreasing=TRUE),]
write.csv(A_int_tot_comp,"A_int_tot_comp.csv")


##Now compare them cell-wise
A_no_scrap <- m$A[-which(rownames(m$A) %in% 'S00401/US'),-which(colnames(m$A) %in% 'S00401/US')]
identical(rownames(A_no_scrap),rownames(A_adj))
identical(colnames(A_no_scrap),colnames(A_adj))

#A_adj always has great req because scrap requirement was removed causing others to increas 
A_diff <- A_adj - A_no_scrap 

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

p <- plot(as.vector(A_no_scrap), as.vector(A_adj),
     xlab="A_no_scrap", ylab="A_adj", main="A_no_scrap vs A_adj")
abline(0, 1, col="grey")

dev.off()


## Test to see if a model with scrap adjustment yields different results and can be validated

#Copy model object to an adjusted model and create needed objects 1 by 1
m_adj <- m
m_adj$Commodities <- m_adj$Commodities[-which(m_adj$Commodities$Code_Loc %in% 'S00401/US'),]
m_adj$V_n <- V_n_adj
m_adj$A <- A_adj
m_adj$q <- m$q[-which(names(m$q) %in% 'S00401/US')]

m_adj$TbS <- do.call(rbind,m_adj$SatelliteTables$totals_by_sector)
# Set common year for flow when more than one year exists
m_adj$TbS <- setCommonYearforFlow(m_adj$TbS)
# Generate coefficients 
m_adj$CbS <- generateCbSfromTbSandModel(m_adj)
m_adj$B <- createBfromFlowDataandOutput(m_adj)
m_adj$C <- createCfromFactorsandBflows(m_adj$Indicators$factors,rownames(m_adj$B))
 # Add direct impact matrix
m_adj$D <- m_adj$C %*% m_adj$B

m_adj$M <- m_adj$B %*% m_adj$L
m_adj$N <- m_adj$C %*% m_adj$M

I <- diag(nrow(m_adj$A))
m_adj$L <- solve(I - m_adj$A)

#Now update m to add EEIO matrices
m <- constructEEIOMatrices(m)

##Compare N matrices in adjusted and unadjusted models
N_no_scrap <- m$N[,-which(colnames(m$N) %in% 'S00401/US')]
N_comp <- data.frame(t(rbind(N_no_scrap,m_adj$N)))
colnames(N_comp) <- c("N","N_adj")
N_comp$N_rel_abs_change <- abs(N_comp$N_adj- N_comp$N)/N_comp$N

## Visualize the N matrices as x-y scatter plot, and save as PNG
png("N_comparison_plot.png", width=800, height=800)

p <- plot(N_comp$N,N_comp$N_adj,
     xlab="N", ylab="N_adj", main="N vs N_adj")
abline(0, 1, col="grey")

dev.off()


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

