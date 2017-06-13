#!/usr/bin/env Rscript

# function calculation the throughput based on the ingoing or max bandwidth
#
# traffic: dataframe holding bandwidth values partitioned by links

getLinkFairness <- function(traffic) {
  # result
  fairness <- data.frame("time"=traffic[, "time"])
  traffic <- traffic[, 2:ncol(traffic)]
  traffic <- traffic / apply(traffic, 1, function(x) {return(sum(x, na.rm=TRUE))})
  
  # Jain's fairness index.
  jain <- function(x) {return(sum(x)^2 / (length(x) * sum(x^2)))}
  # Hossfelds fairness index. (F = 1 - sigma / sigma_max)
  # max standard deviation for n values ranging between 0 and 1:
  # n is even:  max sd is 0.5
  # n is odd:   max sd is sqrt(1/4 - 1/(4*n^2))
  hoss <- function(x) {
    # if x has an even length
    if (length(x) %% 2 == 0) {
      maxsd <- 0.5
    } else {
      maxsd <- sqrt(1/4 - 1/(4*length(x)^2))
    }
    return(1-(sqrt(mean(x^2)-mean(x)^2)/maxsd))
    }
  #hoss <- function(x) {return(1-(sqrt(mean(x^2)-mean(x)^2)/(max(x)-min(x))))}
  
  # calculate fairness
  fairness[["linkFairness"]] <- apply(traffic, 1, hoss)
  # return only non NAN values
  return(fairness[!is.na(fairness[["linkFairness"]]), ])
}