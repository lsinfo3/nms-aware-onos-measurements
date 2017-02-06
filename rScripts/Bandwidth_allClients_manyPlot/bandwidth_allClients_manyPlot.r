#!/usr/bin/env Rscript

library(ggplot2)
library(reshape2)

# remove all objects in workspace
rm(list=ls())

# get commandline args
args <- commandArgs(trailingOnly = TRUE)
# resolution of the time axis
resolution <- 1
if(length(args) >= 1){
	resolution <- as.numeric(args[1])
}
rm(args)


# function calculation the bandwidth of traffic data
getBandwidth <- function(time, traffic, resolution) {
	# bandwidth vector for results
	bandwidth <- vector(mode="numeric", length=length(time))

	for(value in 2:length(time)) {
	  # length in Bit
	  bandwidth[value] <- sum(traffic[traffic$Time > (time[value-1]) & traffic$Time <= time[value], "Length"]*8)/resolution
	}

	return(bandwidth)
}


# get all captured traffic
capture <- read.csv("nms_s2eth2.csv", header=TRUE, sep=",", quote="\"", dec=".", fill=TRUE)
# only the traffic from iperf host one to two
iperfTraffic <- subset(capture, Source=="100.0.1.101" & Destination=="100.0.1.201")

# get all src/dst port pairs
portList <- list()
i <- 1
# vector of unique destination ports
uniqueDst <- unique(iperfTraffic[, "DstPort"])
for(dst in uniqueDst){
	# vector of unique source ports to specific destination port
	uniqueSrc <- unique(subset(iperfTraffic, DstPort==dst)[, "SrcPort"])
	# add src/dst port pair to list
	for(src in uniqueSrc){
		portList[[i]] <- list("src"=src, "dst"=dst)
		i <- i+1
		# print(paste(c("src=", toString(src), ", dst=", toString(dst)), collapse=''))
	}
}
# print(portList)

# latest complete second in packet capture
timeMax=floor(max(capture[,2]))
# time values to check
time <- seq(0, timeMax, by=resolution)

# calculate the bandwidths
# bandwidthData <- data.frame("time"=time, "allPorts"=getBandwidth(time, iperfTraffic, resolution))
# calculate bandwidth of each src/dst port pair
i <- 1
bandwidthData <- data.frame("time"=time)
for(portPair in portList){
	traffic <- subset(iperfTraffic, SrcPort==portPair[[1]] & DstPort==portPair[[2]])
	
	# add results to data frame as new column
	name = paste(portPair[[1]], ", ", portPair[[2]], sep="")
	bandwidthData[[name]] <- getBandwidth(time, traffic, resolution)/1024
	i <- i+1
}
rm(traffic)
rm(i)

# melt the results together
bandwidthData <- melt(bandwidthData, id="time", variable.name="tpPorts", value.name = "bandwidth")

# print the whole thing
a <- ggplot(data=bandwidthData, aes(x=time, y=bandwidth, col=tpPorts))
a <- a + geom_line()
a <- a + facet_grid(tpPorts ~ .)
a <- a + xlab("Time (s)") + ylab("Bandwidth (kBit/s)") + ggtitle("NMS Switch2 Ethernet2") + scale_color_discrete(name = "TP-Ports (src, dst)")
a
ggsave("BandwidthClassic.png", width=15, height=10)