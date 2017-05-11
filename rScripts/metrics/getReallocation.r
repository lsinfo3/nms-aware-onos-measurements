#!/usr/bin/env Rscript

# function calculating the flow reallocations
#
# traffic: dataframe holding the time, bandwidth, src and Switch data

getReallocation <- function(traffic) {
  
  reallocations <- c()
  # calculate reallocation for every connection
  for(port in unique(traffic[,"src"])) {
    
    # filter traffic for specific switch
    portTraffic <- traffic[traffic[["src"]]==port, ]
    # dcast by switch name
    portTraffic <- dcast(portTraffic, time ~ Switch, value.var="bandwidth", fun.aggregate=sum)
    # time column is irrelevant
    portTraffic <- portTraffic[, 2:ncol(portTraffic)]
    
    # if no data or only on one switch data was captured
    if(class(portTraffic) != "data.frame") {
      reallocations <- c(reallocations, 0)
    } else {
      # remove rows where no traffic was send (zero values)
      sumTraffic <- rowSums(portTraffic)
      portTraffic <- portTraffic[which(sumTraffic != 0), ]
      rm(sumTraffic)
    
      # calculate the sign of the difference between both switches
      diffTraffic <- apply(portTraffic, 1, function(x) {return(sign(x[1]-x[2]))})
      rm(portTraffic)
    
      # remove zero values, as traffic is divided evenly for them
      diffTraffic <- diffTraffic[which(diffTraffic != 0)]
    
      # use run length encoding for the reallocation counting
      reallocations <- c(reallocations, length(rle(diffTraffic)$values)-1)
    }
  }
  
  return(reallocations)
}