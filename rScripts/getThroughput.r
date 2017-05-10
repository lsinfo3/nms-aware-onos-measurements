#!/usr/bin/env Rscript

# function calculation the throughput based on the ingoing or max bandwidth
#
# traffic: dataframe holding in- and outgoing bandwidth in kbit
# trafficLimit: defining the bandwidth limit for the network in kbit
# inName: header name of the ingoing bandwidth column for the traffic dataframe
# outName: header name of the outgoing bandwidth column for the traffic dataframe

getThroughput <- function(traffic, trafficLimit, inName, outName) {
  
  # remove zeros at the beginning and end
  traffic <- traffic[min( which( traffic[, inName] != 0)) : max( which( traffic[, inName] != 0)), ]
  # restrict in going traffic to bandwidth limit
  traffic[traffic[[inName]] > trafficLimit, inName] <- trafficLimit
  
  # get quotient
  throughput <- traffic[[outName]]/traffic[[inName]]
  # filter out values higher than 1
  throughput[throughput > 1.0] <- 1
  
  return(throughput)
}