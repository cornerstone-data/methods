# Get a Make table with just off diagonal values
getOffDiagonalMake <- function(Make) {
  #Resort to index rows and columns by commodities so the the diagonal means the primary production
  #Set that to zero and add the remainder of production
  
  comswithprimaryindustries <- colnames(Make)[which(colnames(Make) %in% rownames(Make))]
  indwithnoprimarycom <- rownames(Make)[-which(rownames(Make) %in% c(colnames(Make),"T007", "Total Commodity Output"))]
  
  Make <- Make[c(comswithprimaryindustries,indwithnoprimarycom), comswithprimaryindustries]
  
  #Can run this check but it will fail at this point because we added indwithnoprimarycom back to rows
  #useeior:::checkNamesandOrdering(colnames(Make),rownames(Make),"")
  
  #set diagonal to 0
  diag(Make) <- 0
  
  #return sum all values
  return(Make)
}