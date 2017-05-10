#!/usr/bin/env Rscript

# function calculation the throughput based on the ingoing or max bandwidth
#
# traffic: dataframe holding divided traffic bandwidth in each row

getLinkFairness <- function(traffic) {
  
  traffic <- traffic / apply(traffic, 1, function(x) {return(sum(x))})
  
  # Jain's fairness index.
  jain <- function(x) {return(sum(x)^2 / (length(x) * sum(x^2)))}
  
  # calculate fairness
  fairness <- apply(traffic, 1, jain)
  # return only non NAN values
  return(fairness[!is.na(fairness)])
}