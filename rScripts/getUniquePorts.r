#!/usr/bin/env Rscript

# get all src/dst port pairs
getUniquePorts <- function(iperfTraffic, tpDstPortHeaderName, tpSrcPortHeaderName) {
  # resulting port list
  portList <- list()
  # initialise counting variable
  i <- 1
  
  # vector of unique tp destination ports
  uniqueDst <- unique(iperfTraffic[, tpDstPortHeaderName])
  
  # iterate through every tp dst port and find corresponding src ports
  for(dst in uniqueDst) {
    # vector of unique source ports to specified destination port
    uniqueSrc <- unique(iperfTraffic[ iperfTraffic[[tpDstPortHeaderName]] == dst, tpSrcPortHeaderName])
    
    # add src/dst port pair to list
    for(src in uniqueSrc){
      portList[[i]] <- list("src"=src, "dst"=dst)
      i <- i+1
    }
  }
  
  return(portList)
}