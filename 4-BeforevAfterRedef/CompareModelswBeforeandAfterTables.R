
library(devtools)
load_all("../useeior")

before <- buildIOModel("Before2017PRO",configpath="4-BeforevAfterRedef/Before2017PRO.yml")
after <- buildIOModel("After2017PRO",configpath="4-BeforevAfterRedef/After2017PRO.yml")

ind <- before$Industries

V_b <- before$V
V_a <- after$V

U_b <- before$U
U_a <- after$U

identical(rownames(U_b),rownames(U_a))
identical(colnames(U_b),colnames(U_a))
identical(rownames(V_b),rownames(V_a))
identical(colnames(V_b),colnames(V_a))

library(reshape2)


getCoProdDF <- function(V) {
    df <- melt(V)
    colnames(df) <- c("I","C","value")
    df$C <- as.character(df$C)
    df$I <- as.character(df$I)
    df <- subset(df,df$value > 0)
    #Drop non-coproduction
    df <- df[df$C != df$I,]
    return(df)
}

co_b <- getCoProdDF(V_b)
co_a <- getCoProdDF(V_a)
co <- merge(co_b,co_a,by=c('C','I'),all.x=TRUE)
co[is.na(co)] <- 0
#keep only values with no change
co <- co[co$value.x != co$value.y,]
colnames(co) <- c('C','I','value.b','value.a')

co_c_by_ind <- co[,c('C','I')]
co_c_by_ind <- merge(co_c_by_ind,before$Commodities[,c("Code_Loc","Name")],by.x="C",by.y="Code_Loc",all.x=TRUE)


library(dplyr)
co_c_by_ind <- co_c_by_ind %>%
               group_by(C,Name)  %>%
               summarise(inds = paste(I, collapse = ", "))


write.csv(co_c_by_ind,"co_c_by_ind_DET_PRO_2017.csv",row.names=FALSE)


source('4-BeforevAfterRedef/Functions.R')

V_b_off <- getOffDiagonalMake(V_b)
V_a_off <- getOffDiagonalMake(V_a)

identical(rownames(V_b_off),rownames(V_a_off))
identical(colnames(V_b_off),colnames(V_a_off))

# Movement of co-production is diff with V_b_off and V_a_off
V_delta <- V_b_off - V_a_off

#Normalize V_delta



x_b <- data.frame(before$x)

x_b <- x_b[rownames(V_delta),,drop=FALSE]

identical(rownames(x_b),rownames(V_delta))

#Estimate ration like using commodity mix calculation
#Result is commodityxindustry format
x_movement_ratios <- useeior:::normalizeIOTransactions(t(V_delta),x_b)

#industry output would need to be transformed by calculating these values from industry output

x_movement_total_fractions <- sort(colSums(x_movement_ratios),decreasing=TRUE)

names(x_movement_total_fractions[which(x_movement_total_fractions > 0.10)])

