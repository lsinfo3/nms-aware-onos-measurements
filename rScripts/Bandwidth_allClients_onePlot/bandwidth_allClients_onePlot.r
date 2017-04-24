#!/usr/bin/env Rscript

library(ggplot2)
library(reshape2)

# remove all objects in workspace
rm(list=ls())


source("/home/lorry/Masterthesis/vm/leftVm/python/rScripts/computeBandwidth.r")


# get commandline args
args <- commandArgs(trailingOnly = TRUE)

# default values
# resolution of the time axis
resolution <- 1
switchName1 <- "s1"
switchName2 <- "s3"
fileName1 <- "s2.csv"
fileName2 <- "s4.csv"
outFilePath <- "./out"

if(length(args) >= 1){
  outFilePath <- as.character(args[1])
}
if(length(args) >= 2){
  #print(as.character(args[2]))
  fileName1 <- as.character(args[2])
}
if(length(args) >= 3){
  #print(as.character(args[3]))
  fileName2 <- as.character(args[3])
}
rm(args)


# compute the bandwidth data
bandwidthData <- computeBandwidth(fileName1, resolution)
bandwidthData <- bandwidthData[,c("time","bandwidthAll")]
bandwidthData[["Switch"]] <- switchName1

# if second file is given, compute bandwidth for it
if(fileName2 != "s4.csv") {
  bandwidthDataTemp <- computeBandwidth(fileName2, resolution)
  bandwidthDataTemp <- bandwidthDataTemp[, c("time", "bandwidthAll")]
  bandwidthDataTemp[["Switch"]] <- switchName2
  # join both data frames vertically
  bandwidthData <- rbind(bandwidthData, bandwidthDataTemp)
  rm(bandwidthDataTemp)
}

# reset measurement start time to zero
timeMin <- min(bandwidthData[["time"]])
bandwidthData[["time"]] <- sapply(bandwidthData[["time"]], function (x) {x-timeMin})

# print the whole thing
figure <- ggplot(data=bandwidthData, aes(x=time, y=bandwidthAll, color=Switch)) +
  geom_line() +
  scale_color_manual(values=c("blue", "red")) +
  xlab("Time (s)") + ylab("Bandwidth (kBit/s)") +
  theme_bw() +
  theme(text = element_text(size=12))

# remove legend if only one line is plotted
if(length(unique(bandwidthData[["Switch"]])) == 1) {
  figure <- figure + theme(legend.position = "none")
}

# save cdf_plot as pdf
width <- 15.0; height <- 7.0
ggsave(paste(outFilePath, ".pdf", sep=""), plot = figure, width = width, height = height, units="cm")
