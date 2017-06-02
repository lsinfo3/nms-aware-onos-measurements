#!/usr/bin/env Rscript

# function calculation the throughput based on the ingoing or max bandwidth
#
# traffic: dataframe holding bandwidth values partitioned by links

getLinkFairness <- function(traffic) {
  
  traffic <- traffic / apply(traffic, 1, function(x) {return(sum(x, na.rm=TRUE))})
  
  # Jain's fairness index.
  jain <- function(x) {return(sum(x)^2 / (length(x) * sum(x^2)))}
  # Hossfelds fairness index. (F = 1 - sigma / sigma_max)
  # sqrt(0.25) is the max standard deviation for n values ranging between 0 and 1
  hoss <- function(x) {return(1-(sqrt(mean(x^2)-mean(x)^2)/sqrt(0.25)))}
  
  # calculate fairness
  fairness <- apply(traffic, 1, hoss)
  # return only non NAN values
  return(fairness[!is.na(fairness)])
}