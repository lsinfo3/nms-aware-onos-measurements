#!/usr/bin/env Rscript

# function calculation the throughput based on the ingoing or max bandwidth
#
# traffic: dataframe holding timestamp and ingoing and outgoing bandwidth in kbit
# trafficLimit: defining the bandwidth limit for the network in kbit
# inName: header name of the ingoing bandwidth column for the traffic dataframe
# outName: header name of the outgoing bandwidth column for the traffic dataframe

getThroughput <- function(traffic, trafficLimit, inName, outName) {
  # bandwidth vector for results
  throughput <- vector(mode="numeric", length=length(traffic[,"time"]))
  
  for(time in traffic[, "time"]) {
    inTraffic <- traffic[traffic[["time"]] == time, inName]
    if(is.na(inTraffic)) {
      inTraffic <- 0
    }
    outTraffic <- traffic[traffic[["time"]] == time, outName]
    if(is.na(outTraffic)) {
      outTraffic <- 0
    }
    if(inTraffic == 0) {
      throughput[time] <- 1
    } else {
      throughputValue <- min( (outTraffic / min(inTraffic, trafficLimit)), 1)
      throughput[time] <- throughputValue
    }
  }
  
  return(throughput)
}