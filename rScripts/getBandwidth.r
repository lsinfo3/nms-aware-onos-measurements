#!/usr/bin/env Rscript

# function calculation the bandwidth of traffic data
#
# time: vector with time values the bandwidth should be calculated for
# traffic: data frame holding packet length and arrival time
# base: bandwidth base for output
getBandwidth <- function(time, traffic, base=1) {
  
  # round off time values
  traffic[, 1] <- floor(traffic[, 1])
  # aggregate the bandwidth over the time values
  bandwidth <- aggregate(x=traffic[, 2], by=list(traffic[, 1]), FUN=sum)
  # rename columns
  names(bandwidth)[names(bandwidth)=="Group.1"] <- "time"
  names(bandwidth)[names(bandwidth)=="x"] <- "bandwidth"
  
  # create dataframe to merge bandwidth with
  timeFrame <- data.frame("time"=time)
  bandwidth <- merge(bandwidth, timeFrame, by="time", all=TRUE)
  # remove time column
  bandwidth <- bandwidth[, "bandwidth"]
  # replace NA values with 0
  bandwidth[is.na(bandwidth)] <- 0
  
  #print(paste("Total traffic: ", as.character(sum(bandwidth)*8), " bit", sep=""))
  
  # convert from byte to bit and then to predefined base
  bandwidth <- (bandwidth*8)/base
  
  return(bandwidth)
}