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
csvFiles <- ""
legendNames <- ""
outFilePath <- "./out_diff"
protocol <- "17"

if(length(args) >= 1){
  protocol <- as.character(args[1])
}
if(length(args) >= 2){
  outFilePath <- as.character(args[2])
}
if(length(args) >= 3){
  csvFiles <- strsplit(as.character(args[3]), " ")[[1]]
  #print(csvFiles)
}
if(length(args) >= 4){
  legendNames <- strsplit(as.character(args[4]), " ")[[1]]
  #print(legendNames)
}
rm(args)

#csvFiles <- c("s2.csv", "s4.csv")
#legendNames <- c("s2", "s4")

# calculate bandwidth data
bandwidthData <- mergeBandwidth(csvFiles, legendNames, resolution, protocol)


# plot the bandwidth
figure <- ggplot(data=bandwidthData, aes(x=time, y=bandwidth, color=Switch, linetype=Switch)) +
  geom_line() +
  facet_grid(dst + src ~ ., labeller=labeller(src = function(x) {paste("s:", x, sep="")}, dst = function(x) {paste("d:", x, sep="")})) +
  scale_color_manual(values=c("blue", "red")) +
  scale_linetype_manual(values=c("solid","42")) +
  scale_y_continuous(breaks=c(0,100,200)) +
  xlab("Time [s]") + ylab("Bandwidth [kbit/s]") +
  theme_bw() +
  theme(legend.position = "bottom" , text = element_text(size=12))

# remove legend if only one line is plotted
if(length(unique(bandwidthData[["Switch"]])) == 1) {
  figure <- figure + theme(legend.position = "none")
}

# save plot as pdf
width <- 15.0; height <- 20.0
ggsave(paste(outFilePath, ".pdf", sep=""), plot = figure, width = width, height = height, units="cm")
