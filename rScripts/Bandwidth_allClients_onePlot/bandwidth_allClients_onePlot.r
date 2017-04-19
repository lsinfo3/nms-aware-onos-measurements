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
fileName <- "temp.csv"
outFilePath <- "./out.pdf"

if(length(args) >= 1){
  outFilePath <- as.character(args[1])
}
if(length(args) >= 2){
  print(as.character(args[2]))
  fileName <- as.character(args[2])
}
rm(args)


# compute the bandwidth data
bandwidthData <- computeBandwidth(fileName, resolution)
bandwidthData <- bandwidthData[,c("time","bandwidthAll")]

# reset measurement start time to zero
timeMin <- min(bandwidthData[["time"]])
bandwidthData[["time"]] <- sapply(bandwidthData[["time"]], function (x) {x-timeMin})

# print the whole thing
a <- ggplot(data=bandwidthData, aes(x=time, y=bandwidthAll)) +
  geom_line(color="blue") +
  xlab("Time (s)") + ylab("Bandwidth (kBit/s)") +
  theme_bw() +
  theme(text = element_text(size=12))

# save cdf_plot as pdf
width <- 15.0; height <- 7.0
ggsave(outFilePath, plot = a, width = width, height = height, units="cm")
