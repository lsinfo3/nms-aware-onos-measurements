#!/usr/bin/env Rscript

# function calculating the flow based fairness
# Assumption: bandwidth equals zero -> no bandwidth requested at all
#
# traffic: dataframe holding traffic bandwidth in each row partitioned by connection
# req: the requested traffic bandwidth partitioned by connection

getFlowFairness <- function(traffic, req) {
  
  # cut measurements beginning and end containing only 0 values
  aggregateTraffic <- rowSums(traffic[, 2:ncol(traffic)])
  traffic <- traffic[min( which( aggregateTraffic != 0)) : max( which( aggregateTraffic != 0)), ]
  rm(aggregateTraffic)
  
  # result
  fairness <- data.frame("time"=traffic[, "time"])
  traffic <- traffic[, 2:ncol(traffic)]
  
  # normalize measured bandwidth by the requested bandwidth and transpose matrix to normal shape
  traffic <- t(apply(traffic, 1, function(x) {return(x/req)}))
  # calculate quotient over sum
  traffic <- traffic / apply(traffic, 1, function(x) {return(sum(x))})
  
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
  
  # calculate fairness (Assumption: bandwidth == 0 -> no bandwidth requested)
  fairness[["flowFairness"]] <- apply(traffic, 1, function(x) {return(hoss(x[which(x != 0)]))})
  # return only non NAN values
  return(fairness[!is.nan(fairness[["flowFairness"]]), ])
}