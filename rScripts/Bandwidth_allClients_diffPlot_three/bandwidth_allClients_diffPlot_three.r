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
fileName1 <- "./s2.csv"
fileName2 <- "./s4.csv"
outFilePath <- "./out"

if(length(args) >= 1){
  resolution <- as.numeric(args[1])
}
if(length(args) >= 2){
  print(as.character(args[2]))
  fileName1 <- as.character(args[2])
}
if(length(args) >= 3){
  print(as.character(args[3]))
  fileName2 <- as.character(args[3])
}
if(length(args) >= 4){
  outFilePath <- as.character(args[4])
}
rm(args)


# compute the bandwidth data
bandwidthData1 <- computeBandwidth(fileName1, resolution)
bandwidthData2 <- computeBandwidth(fileName2, resolution)

# remove "bandwidthAll" column
bandwidthData1[["bandwidthAll"]] <- NULL
bandwidthData2[["bandwidthAll"]] <- NULL

# melt the results together
bandwidthData1 <- melt(bandwidthData1, id="time", variable.name="tpPorts", value.name = "bandwidth")
bandwidthData2 <- melt(bandwidthData2, id="time", variable.name="tpPorts", value.name = "bandwidth")

# add factor for variable order
bandwidthData1$tpPorts <- factor(bandwidthData1$tpPorts, levels=sort(levels(bandwidthData1$tpPorts)))
bandwidthData2$tpPorts <- factor(bandwidthData2$tpPorts, levels=sort(levels(bandwidthData2$tpPorts)))

# extract source and destination port as columns
bandwidthData1[["src"]] <- strsplit(as.character(bandwidthData1[["tpPorts"]]), ", ")
bandwidthData1[["src"]] <- sapply(bandwidthData1[["src"]], function (x) x[2])
bandwidthData1[["dst"]] <- strsplit(as.character(bandwidthData1[["tpPorts"]]), ", ")
bandwidthData1[["dst"]] <- sapply(bandwidthData1[["dst"]], function (x) x[1])

bandwidthData2[["src"]] <- strsplit(as.character(bandwidthData2[["tpPorts"]]), ", ")
bandwidthData2[["src"]] <- sapply(bandwidthData2[["src"]], function (x) x[2])
bandwidthData2[["dst"]] <- strsplit(as.character(bandwidthData2[["tpPorts"]]), ", ")
bandwidthData2[["dst"]] <- sapply(bandwidthData2[["dst"]], function (x) x[1])

# combine both frames
bandwidthData1[["Switch"]] <- "s2"
bandwidthData2[["Switch"]] <- "s4"
bandwidthData <- rbind(bandwidthData1, bandwidthData2)
# set measurement start time to zero
timeMin <- min(bandwidthData[["time"]])
bandwidthData[["time"]] <- sapply(bandwidthData[["time"]], function (x) {x-timeMin})
rm(timeMin)

# simplify source port number
i <- 1
destinationPorts <- unique(bandwidthData[, "dst"])
for(dst in sort(as.integer(destinationPorts))) {
  sourcePorts <- unique(bandwidthData[bandwidthData[["dst"]]==dst, "src"])
  for(src in sourcePorts) {
    bandwidthData[bandwidthData[["dst"]]==dst & bandwidthData[["src"]]==src, "src"] <- sapply(bandwidthData[bandwidthData[["dst"]]==dst & bandwidthData[["src"]]==src, "src"], function (x) {as.character(i)})
    i <- i+1
  }
}
rm(i, src, dst, destinationPorts, sourcePorts)

# define factor order
bandwidthData$src <- factor(bandwidthData$src, levels=sort(as.integer(unique(bandwidthData$src))))

for(destinationPort in unique(bandwidthData[, "dst"])) {
  
  # print the whole thing
  figure <- ggplot(data=bandwidthData[bandwidthData$dst==destinationPort,],
                   aes(x=time, y=bandwidth, color=Switch, linetype=Switch)) +
    geom_line() +
    facet_grid(src ~ ., labeller=labeller(src = function(x) {paste("src:", x, sep="")})) +
    scale_color_manual(values=c("blue", "red")) +
    scale_linetype_manual(values=c("solid","42")) +
    scale_y_continuous(breaks=c(0,100,200)) +
    xlab("Time (s)") + ylab("Bandwidth (kBit/s)") +
    theme_bw() +
    theme(legend.position = "bottom" , text = element_text(size=12))
  
  # save plot as png
  width <- 7.4; height <- 1.0 + 1.8 * length(unique(bandwidthData[bandwidthData[["dst"]]==destinationPort, "src"]))
  ggsave(paste(outFilePath, as.character(destinationPort), ".pdf", sep=""), plot = figure, width = width, height = height, units="cm")
  
}
rm(destinationPort)