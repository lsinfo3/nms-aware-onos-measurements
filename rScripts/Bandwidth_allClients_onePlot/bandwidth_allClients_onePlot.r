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
bandwidthData <- bandwidthData[,c("time","bandwidthAll")]
# melt the results together
#bandwidthData2 <- melt(bandwidthData, id="time", variable.name="tpPorts", value.name = "bandwidth")

# set measurement start time to zero
timeMin <- min(bandwidthData[["time"]])
bandwidthData[["time"]] <- sapply(bandwidthData[["time"]], function (x) {x-timeMin})

#lineColor <- c("black", colorRampPalette(c("blue", "red"))(length(unique(bandwidthData[, "tpPorts"]))))

# print the whole thing
a <- ggplot(data=bandwidthData, aes(x=time, y=bandwidthAll)) +
  geom_line() +
# scale_color_gradient(low="coral", high="steelblue", name = "TP-Ports (src, dst)") +
# scale_color_brewer(palette="Dark2") +
# scale_color_manual(values=lineColor, name = "TP-Ports (src, dst)") +
  xlab("Time (s)") + ylab("Bandwidth (kBit/s)") +
  theme_bw() +
  theme(text = element_text(size=12))
# ggtitle(basename(outFilePath))
#print(a)

# save cdf_plot as pdf
#width <- 5.9; height <- 3.5
#width <- 7.9; height <- 3.5
width <- 15.0; height <- 7.0
#width <- 2.9; height <- 2.0
#plot <- plot + theme(plot.margin = grid::unit(c(0,0,0,0), "mm"))
ggsave(outFilePath, plot = a, width = width, height = height, units="cm")
