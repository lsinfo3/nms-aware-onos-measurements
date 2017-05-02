#!/usr/bin/env Rscript

# function calculation the bandwidth of traffic data
getBandwidth <- function(time, traffic, resolution, base=1, timeHeaderName, lengthHeaderName) {
  # bandwidth vector for results
  bandwidth <- vector(mode="numeric", length=length(time))
  
  totalTraffic <- 0
  for(value in 2:length(time)) {
    # length in Bit
    bandwidthValue <- sum(traffic[traffic[[timeHeaderName]] > (time[value-1]) & traffic[[timeHeaderName]] <= time[value], lengthHeaderName])*8/resolution
    bandwidth[value] <- bandwidthValue
    totalTraffic <- totalTraffic + bandwidthValue
  }
  print(paste("Total traffic: ", as.character(totalTraffic), " bit", sep=""))
  
  return(bandwidth/base)
}