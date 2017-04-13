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
fileName <- "./temp.csv"
outFilePath <- "./out.png"

if(length(args) >= 1){
  resolution <- as.numeric(args[1])
}
if(length(args) >= 2){
  print(as.character(args[2]))
  fileName <- as.character(args[2])
}
if(length(args) >= 3){
  outFilePath <- as.character(args[3])
}
rm(args)


# compute the bandwidth data
bandwidthData <- computeBandwidth(fileName, resolution)

# remove "bandwidthAll" column
bandwidthData[["bandwidthAll"]] <- NULL

# melt the results together
bandwidthData <- melt(bandwidthData, id="time", variable.name="tpPorts", value.name = "bandwidth")

# add factor for variable order
bandwidthData$tpPorts <- factor(bandwidthData$tpPorts, levels=sort(levels(bandwidthData$tpPorts)))
bandwidthData[["src"]] <- strsplit(as.character(bandwidthData[["tpPorts"]]), ", ")
bandwidthData[["src"]] <- sapply(bandwidthData[["src"]], function (x) x[2])
bandwidthData[["dst"]] <- strsplit(as.character(bandwidthData[["tpPorts"]]), ", ")
bandwidthData[["dst"]] <- sapply(bandwidthData[["dst"]], function (x) x[1])

lineColor <- colorRampPalette(c("blue", "red"))(length(unique(bandwidthData[, "tpPorts"])))
fillColor <- colorRampPalette(c("lightblue4", "lightcoral"))(length(unique(bandwidthData[, "tpPorts"])))

# print the whole thing
a <- ggplot(data=bandwidthData, aes(x=time, y=bandwidth, color=tpPorts, fill=tpPorts, facets=tpPorts)) +
  geom_area() +
  facet_wrap(~ tpPorts, ncol=3) +
#  scale_color_discrete(name = "TP-Ports (src, dst)") +
  scale_color_manual(values=lineColor, name = "TP-Ports (src, dst)") +
  scale_fill_manual(values=fillColor, name="TP-Ports (src, dst)") +
  xlab("Time (s)") + ylab("Bandwidth (kBit/s)")
#  ggtitle(basename(outFilePath))

# save plot as png
#width <- 5.9; height <- 3.5
width <- 14; height <- 10
#width <- 2.9; height <- 2.0
ggsave(outFilePath, plot = a, width = width, height = height)