#!/usr/bin/env Rscript

#!/usr/bin/env Rscript

library(ggplot2)
library(reshape2)

# remove all objects in workspace
rm(list=ls())


# get commandline args
args <- commandArgs(trailingOnly = TRUE)

# default values
# resolution of the time axis
resolution <- 1
csvFiles <- ""
legendNames <- ""
outFilePath <- "./out"
protocol <- "17"

csvFilesMod <- c("mod/s1.csv", "mod/s2.csv", "mod/s3.csv", "mod/s4.csv")
csvFilesNms <- c("nms/s1.csv", "nms/s2.csv", "nms/s3.csv", "nms/s4.csv")
legendNamesMod <- c("MOD/NMS_S1", "MOD_S2", "MOD_S3", "MOD_S4")
legendNamesNms <- c("NMS_S1", "NMS_S2", "NMS_S3", "NMS_S4")

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

shapeBandwidth <- function(csvFiles, resolution, protocol, legendNames) {
  
  source("/home/lorry/Masterthesis/vm/leftVm/python/rScripts/computeBandwidth.r")
  
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
  rm(i)
  
  # reset measurement start time to zero
  timeMin <- min(bandwidthData[["time"]])
  bandwidthData[["time"]] <- sapply(bandwidthData[["time"]], function (x) {x-timeMin})
  rm(timeMin)
  
  return(bandwidthData)
}

bandwidthDataMod <- shapeBandwidth(csvFilesMod, resolution, protocol, legendNamesMod)
bandwidthDataNms <- shapeBandwidth(csvFilesNms, resolution, protocol, legendNamesNms)

# join nms and mod data vertically
bandwidthData <- rbind(bandwidthDataMod, bandwidthDataNms)

# print the whole thing
figure <- ggplot(data=bandwidthData[bandwidthData[["Switch"]] != "NMS_S1",], aes(x=time, y=bandwidthAll, color=Switch, linetype=Switch)) +
  geom_line() +
  scale_color_manual(values=c("blue", "#FF0000", "#FF0000", "#FF0000", "#00FF00", "#00FF00", "#00FF00")
  ) +
  xlab("Time [s]") + ylab("Bandwidth [kbit/s]") +
  theme_bw() +
  theme(text = element_text(size=12)) +
  scale_linetype_manual(values=c("solid","dashed","solid","dashed","dashed","solid","dashed"))
# remove legend if only one line is plotted
if(length(unique(bandwidthData[["Switch"]])) == 1) {
  figure <- figure + theme(legend.position = "none")
}
# save as rdata
save(figure, file="./out_aggr.RData")
# save as pdf
width <- 15.0; height <- 7.0
#ggsave(paste(outFilePath, "_aggr_", strftime(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".pdf", sep=""), plot = figure, width = width, height = height, units="cm")
ggsave(paste(outFilePath, "_aggr", ".pdf", sep=""), plot = figure, width = width, height = height, units="cm")

rm(width, height, bandwidthData, computeBandwidth)