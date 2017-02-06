#!/usr/bin/env Rscript


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
allBandwidth <- getBandwidth(time, iperfTraffic, resolution)
# calculate bandwidth of each src/dst port pair
i <- 1
bandwidthList <- list()
for(portPair in portList){
	traffic <- subset(iperfTraffic, SrcPort==portPair[[1]] & DstPort==portPair[[2]])
	bandwidthList[[i]] <- getBandwidth(time, traffic, resolution)
	i <- i+1
}

# print the whole thing
xrange <- range(time)
yrange <- range(allBandwidth)
colors <- rainbow(length(bandwidthList)+1)

#print(xrange)
#print(yrange)

plot(xrange, yrange, type="n", xlab="Time (s)", ylab="Bandwidth (Bit/s)")
#opar <- par()
#par(pin=c(50,10))

lines(time, allBandwidth, type="l", col="black")
for(item in 1:length(portList)){
	lines(time, bandwidthList[[item]], type="l", col=colors[item])
}


title(main="NMS Switch2 Ethernet2", col.main="red", font.main=3)
legend(xrange[2]-85, yrange[2], c("all traffic", portList), cex=0.8, col=c("black", colors), lty=as.vector(array(1, c(1,length(bandwidthList)+1))), title="line")

# par(opar)

