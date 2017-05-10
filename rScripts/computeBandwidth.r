#!/usr/bin/env Rscript



computeBandwidth <- function(csvFileName, bandwidthTimeResolution, protocol) {
  
  # column names
  TIME <- "frame.time_relative"
  EPOCH <- "frame.time_epoch"
  IPSRC <- "ip.src"
  IPDST <- "ip.dst"
  PROTO <- "ip.proto"
  if(protocol=="6") {
    SRCPORT <- "tcp.srcport"
    DSTPORT <- "tcp.dstport"
  } else if(protocol=="17") {
    SRCPORT <- "udp.srcport"
    DSTPORT <- "udp.dstport"
  }
  LENGTH <- "frame.len"
  
  # get all captured traffic
  capture <- read.csv(csvFileName, header=TRUE, sep=",", quote="\"", dec=".", fill=TRUE)
  # use only udp traffic from iperf host one to two
  iperfTraffic <- capture[ capture[[PROTO]] == protocol & capture[[IPSRC]] == "100.0.1.101" & capture[[IPDST]] == "100.0.1.201", ]
  
  # first and latest complete second in capture file
  timeMin=ceiling(min(capture[,EPOCH]))
  timeMax=floor(max(capture[,EPOCH]))
  # time values to compute bandwidth for
  time <- unique(floor(capture[, EPOCH]))
  rm(capture, timeMin, timeMax)
  
  # calculate the bandwidth
  source("/home/lorry/Masterthesis/vm/leftVm/python/rScripts/getBandwidth.r")
  # bandwidth of all connections
  bandwidthData <- data.frame("time"=time, "bandwidthAll"=getBandwidth(time, iperfTraffic[, c(EPOCH, LENGTH)], 1024))
  
  # get all src/dst port pairs
  source("/home/lorry/Masterthesis/vm/leftVm/python/rScripts/getUniquePorts.r")
  portList <- getUniquePorts(iperfTraffic, DSTPORT, SRCPORT)
  
  # calculate bandwidth for each port pair
  i <- 1
  for(portPair in portList){
    traffic <- iperfTraffic[ iperfTraffic[[SRCPORT]]==portPair[[1]] & iperfTraffic[[DSTPORT]]==portPair[[2]], ]
    # add results to data frame as new column
    name = paste(portPair[[2]], ", ", portPair[[1]], sep="")
    #print(name)
    bandwidthData[[name]] <- getBandwidth(time, traffic[, c(EPOCH, LENGTH)], 1024)
    i <- i+1
  }
  if(exists("traffic")) {
    rm(traffic)
  }
  rm(i)
  
  return(bandwidthData)
  
}