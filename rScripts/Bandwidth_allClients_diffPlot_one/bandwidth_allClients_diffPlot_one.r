#!/usr/bin/env Rscript

library(ggplot2)
library(reshape2)

# remove all objects in workspace
rm(list=ls())


source("/home/lorry/Masterthesis/vm/leftVm/python/rScripts/computeBandwidth.r")
source("/home/lorry/Masterthesis/vm/leftVm/python/rScripts/mergeBandwidth.r")


# get commandline args
args <- commandArgs(trailingOnly = TRUE)

# default values
# resolution of the time axis
resolution <- 1
fileName1 <- "./s2.csv"
fileName2 <- "./s4.csv"
outFilePath <- "./out_diff"

if(length(args) >= 1){
  outFilePath <- as.character(args[1])
}
if(length(args) >= 2){
  print(as.character(args[2]))
  fileName1 <- as.character(args[2])
}
if(length(args) >= 3){
  print(as.character(args[3]))
  fileName2 <- as.character(args[3])
}
rm(args)

# check if second string is set
if(fileName2=="./s4.csv") {
  bandwidthData <- mergeBandwidth(c(fileName1), resolution)
} else {
  bandwidthData <- mergeBandwidth(c(fileName1, fileName2), resolution)
}


# check if the data frame contains the bandwidth of only one switch
if("Switch" %in% colnames(bandwidthData)) {
  figure <- ggplot(data=bandwidthData, aes(x=time, y=bandwidth, color=Switch, linetype=Switch)) +
    geom_line() +
    facet_grid(dst + src ~ ., labeller=labeller(src = function(x) {paste("s:", x, sep="")}, dst = function(x) {paste("d:", x, sep="")})) +
    scale_color_manual(values=c("blue", "red")) +
    scale_linetype_manual(values=c("solid","42")) +
    scale_y_continuous(breaks=c(0,100,200)) +
    xlab("Time (s)") + ylab("Bandwidth (kBit/s)") +
    theme_bw() +
    theme(legend.position = "bottom" , text = element_text(size=12))
} else {
  figure <- ggplot(data=bandwidthData, aes(x=time, y=bandwidth)) +
    geom_line(color="blue") +
    facet_grid(dst + src ~ ., labeller=labeller(src = function(x) {paste("s:", x, sep="")}, dst = function(x) {paste("d:", x, sep="")})) +
    scale_y_continuous(breaks=c(0,100,200)) +
    xlab("Time (s)") + ylab("Bandwidth (kBit/s)") +
    theme_bw() +
    theme(legend.position = "bottom" , text = element_text(size=12))
}

# save plot as png
width <- 15.0; height <- 20.0
ggsave(paste(outFilePath, ".pdf", sep=""), plot = figure, width = width, height = height, units="cm")
