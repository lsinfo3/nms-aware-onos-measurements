#!/usr/bin/env Rscript

# function calculating the flow based fairness
# Assumption: bandwidth equals zero -> no bandwidth requested at all
#
# traffic: dataframe holding traffic bandwidth in each row divided by connection
# req: the requested traffic bandwidth divided by connection

getFlowFairness <- function(traffic, req) {
  
  # cut measurements beginning and end containing only 0 values
  aggregateTraffic <- rowSums(traffic)
  traffic <- traffic[min( which( aggregateTraffic != 0)) : max( which( aggregateTraffic != 0)), ]
  rm(aggregateTraffic)
  
  # normalize measured bandwidth by the requested bandwidth and transpose matrix to normal shape
  traffic <- t(apply(traffic, 1, function(x) {return(x/req)}))
  # calculate quotient over sum
  traffic <- traffic / apply(traffic, 1, function(x) {return(sum(x))})
  
  # Jain's fairness index.
  jain <- function(x) {return(sum(x)^2 / (length(x) * sum(x^2)))}
  # calculate fairness (Assumption: bandwidth == 0 -> no bandwidth requested)
  fairness <- apply(traffic, 1, function(x) {return(jain(x[which(x != 0)]))})
  # return only non NAN values
  return(fairness[!is.nan(fairness)])
}