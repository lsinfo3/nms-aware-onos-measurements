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
outFilePath <- "./out"

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

# get extra source and destination port columns
bandwidthData[["src"]] <- strsplit(as.character(bandwidthData[["tpPorts"]]), ", ")
bandwidthData[["src"]] <- sapply(bandwidthData[["src"]], function (x) x[2])
bandwidthData[["dst"]] <- strsplit(as.character(bandwidthData[["tpPorts"]]), ", ")
bandwidthData[["dst"]] <- sapply(bandwidthData[["dst"]], function (x) x[1])

lineColor <- colorRampPalette(c("blue", "red"))(length(unique(bandwidthData[, "tpPorts"])))
fillColor <- colorRampPalette(c("lightblue4", "lightcoral"))(length(unique(bandwidthData[, "tpPorts"])))

for(destinationPort in unique(bandwidthData[, "dst"])) {
  
  # print the whole thing
  figure <- ggplot(data=bandwidthData[bandwidthData$dst==destinationPort,],
                   aes(x=time, y=bandwidth, color=tpPorts, fill=tpPorts)) +
    geom_area(size=0.3) +
    facet_grid(dst + src ~ ., labeller=labeller(src = function(x) {paste("src=", x, sep="")}, dst = function(x) {paste("dst=", x, sep="")})) +
  #  scale_color_discrete(name = "TP-Ports (src, dst)") +
    scale_color_manual(values=lineColor, name = "TP-Ports (src, dst)") +
  #  scale_color_gradient(low="blue", high="red") +
    scale_fill_manual(values=fillColor, name="TP-Ports (src, dst)") +
    xlab("Time (s)") + ylab("Bandwidth (kBit/s)") +
    theme(legend.position = "none")
  #  ggtitle(basename(outFilePath))
  
  # save plot as png
  #width <- 7.9; height <- 3.5
  #width <- 2.9; height <- 2.0
  width <- 5.9; height <- 2.0 * length(unique(bandwidthData[bandwidthData[["dst"]]==destinationPort, "src"]))
  ggsave(paste(outFilePath, as.character(destinationPort), ".png", sep=""), plot = figure, width = width, height = height)
  
  # update color values to use for next figure
  srcNum <- length(unique(bandwidthData[bandwidthData[["dst"]]==destinationPort, "src"]))
  lineColor <- tail(lineColor, -srcNum)
  fillColor <- tail(fillColor, -srcNum)
}