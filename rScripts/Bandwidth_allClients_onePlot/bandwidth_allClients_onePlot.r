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
csvFiles <- ""
legendNames <- ""
outFilePath <- "./out"
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

csvFiles <- c("s1.csv", "s3.csv")
legendNames <- c("s1", "s3")

for(i in 1:length(csvFiles)) {
  # compute the bandwidth data
  bandwidthDataTemp <- computeBandwidth(csvFiles[i], resolution, protocol)
  bandwidthDataTemp <- bandwidthDataTemp[,c("time","bandwidthAll")]
  bandwidthDataTemp[["Switch"]] <- legendNames[i]
  
  if(exists("bandwidthData")) {
    # join both data frames vertically
    bandwidthData <- rbind(bandwidthData, bandwidthDataTemp)
  } else {
    bandwidthData <- bandwidthDataTemp
  }
  rm(bandwidthDataTemp)
}

# reset measurement start time to zero
timeMin <- min(bandwidthData[["time"]])
bandwidthData[["time"]] <- sapply(bandwidthData[["time"]], function (x) {x-timeMin})

source("/home/lorry/Masterthesis/vm/leftVm/python/rScripts/getThroughput.r")
throughPutData <- dcast(bandwidthData, time ~ Switch, value.var="bandwidthAll")
throughPut <- getThroughput(throughPutData, 2000, "s1", "s3")

# print the whole thing
figure <- ggplot(data=bandwidthData, aes(x=time, y=bandwidthAll, color=Switch)) +
  geom_line() +
  scale_color_manual(values=c("blue", "#E69F00", "red", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")
) +
  xlab("Time [s]") + ylab("Bandwidth [kbit/s]") +
  theme_bw() +
  theme(text = element_text(size=12))

# remove legend if only one line is plotted
if(length(unique(bandwidthData[["Switch"]])) == 1) {
  figure <- figure + theme(legend.position = "none")
}

# save cdf_plot as pdf
width <- 15.0; height <- 7.0
ggsave(paste(outFilePath, ".pdf", sep=""), plot = figure, width = width, height = height, units="cm")
