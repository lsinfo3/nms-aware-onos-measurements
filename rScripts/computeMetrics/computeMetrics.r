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

#csvFiles <- c("s1.csv", "s2.csv", "s3.csv", "s4.csv")
#legendNames <- c("s1", "s2", "s3", "s4")

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

resultHeader <- c("time", "throughput", "linkFairness", "flowFairness", "reallocations")
result <- c(strftime(Sys.time(), "%Y-%m-%d_%H-%M-%S"))

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
# save as pdf
width <- 15.0; height <- 7.0
ggsave(paste(outFilePath, "_aggr_", strftime(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".pdf", sep=""), plot = figure, width = width, height = height, units="cm")
rm(width, height)


#TODO: Do not depend on legend names!
# calculate the percentage of the throughput
source("/home/lorry/Masterthesis/vm/leftVm/python/rScripts/metrics/getThroughput.r")
throughputData <- dcast(bandwidthData, time ~ Switch, value.var="bandwidthAll")
throughput <- getThroughput(throughputData[, c("time", "s1", "s3")], 2000, "s1", "s3")
#rm(throughputData, getThroughput)

print(paste("Mean of throughput: ", mean(throughput[,"throughput"]), sep=""))
result <- c(result, mean(throughput[,"throughput"]))
resultDetail <- melt(throughput, id.vars="time")
#rm(throughput)


# calculate the link fairness
source("/home/lorry/Masterthesis/vm/leftVm/python/rScripts/metrics/getLinkFairness.r")
linkFairnessData <- dcast(bandwidthData, time ~ Switch, value.var="bandwidthAll")
linkFairness <- getLinkFairness(linkFairnessData[, c("time", "s2", "s4")])
rm(linkFairnessData, getLinkFairness)
print(paste("Mean of link fairness: ", mean(linkFairness[, "linkFairness"]), sep=""))
result <- c(result, mean(linkFairness[, "linkFairness"]))
resultDetail <- rbind(resultDetail, melt(linkFairness, id.vars="time"))
rm(linkFairness)

rm(bandwidthData)



source("/home/lorry/Masterthesis/vm/leftVm/python/rScripts/mergeBandwidth.r")
# calculate bandwidth data
bandwidthData <- mergeBandwidth(csvFiles[c(2,4)], legendNames[c(2,4)], resolution, protocol)
rm(mergeBandwidth, computeBandwidth)

# plot the bandwidth
figure <- ggplot(data=bandwidthData, aes(x=time, y=bandwidth, color=Switch, linetype=Switch)) +
  geom_line() +
  facet_grid(dst + src ~ ., labeller=labeller(src = function(x) {paste("s:", x, sep="")}, dst = function(x) {paste("d:", x, sep="")})) +
  scale_color_manual(values=c("blue", "red")) +
  scale_linetype_manual(values=c("solid","42")) +
  # scale_y_continuous(breaks=c(0,100,200)) +
  xlab("Time [s]") + ylab("Bandwidth [kbit/s]") +
  theme_bw() +
  theme(legend.position = "bottom" , text = element_text(size=12))

# remove legend if only one line is plotted
if(length(unique(bandwidthData[["Switch"]])) == 1) {
  figure <- figure + theme(legend.position = "none")
}

# save plot as pdf
width <- 15.0; height <- 20.0
ggsave(paste(outFilePath, "_diff_", strftime(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".pdf", sep=""), plot = figure, width = width, height = height, units="cm")

rm(width, height)


# calculate the flow fairness
# TODO: Adapt requested bandwidth!
source("/home/lorry/Masterthesis/vm/leftVm/python/rScripts/metrics/getFlowFairness.r")
flowFairnessData <- dcast(bandwidthData, time ~ src, value.var="bandwidth", fun.aggregate=sum)
flowFairness <- getFlowFairness(flowFairnessData, rep(200, ncol(flowFairnessData)-1))
rm(flowFairnessData, getFlowFairness)

print(paste("Mean of flow fairness: ", mean(flowFairness[, "flowFairness"]), sep=""))
result <- c(result, mean(flowFairness[, "flowFairness"]))
resultDetail <- rbind(resultDetail, melt(flowFairness, id.vars="time"))
rm(flowFairness)


# calculate the flow reallocation
source("/home/lorry/Masterthesis/vm/leftVm/python/rScripts/metrics/getReallocation.r")
reallocations <- getReallocation(bandwidthData[, c("time", "bandwidth", "src", "Switch")])
print(paste("Flow reallocations: ", sum(reallocations), sep=""))
result <- c(result, sum(reallocations))
rm(getReallocation, reallocations)

rm(bandwidthData)


# write results to output file
csvFileName <- paste(outFilePath, ".csv", sep="")
if(!file.exists(csvFileName)) {
  write.table(t(resultHeader), file=csvFileName, row.names=FALSE, col.names=FALSE, na="", sep=",", append=FALSE)
}
write.table(t(result), file=csvFileName, row.names=FALSE, col.names=FALSE, na="", sep=",", append=TRUE)

# write detail results to output file
csvFileName <- paste(outFilePath, "_detail.csv", sep="")
resultDetail <- dcast(resultDetail, time ~ variable, fill=0)
write.table(resultDetail, file=csvFileName, row.names=FALSE, na="", sep=",", append=FALSE)