#!/usr/bin/env Rscript



computeBandwidth <- function(csvFileName, bandwidthTimeResolution) {
  
  source("/home/lorry/Masterthesis/vm/leftVm/python/rScripts/getBandwidth.r")
  source("/home/lorry/Masterthesis/vm/leftVm/python/rScripts/getUniquePorts.r")
  
  # column names
  TIME = "frame.time_relative"
  EPOCH = "frame.time_epoch"
  IPSRC = "ip.src"
  IPDST = "ip.dst"
  PROTO = "ip.proto"
  SRCPORT = "udp.srcport"
  DSTPORT = "udp.dstport"
  LENGTH = "frame.len"
  
  # get all captured traffic
  capture <- read.csv(csvFileName, header=TRUE, sep=",", quote="\"", dec=".", fill=TRUE)
  # use only udp traffic from iperf host one to two
  iperfTraffic <- capture[ capture[[PROTO]] == "17" & capture[[IPSRC]] == "100.0.1.101" & capture[[IPDST]] == "100.0.1.201", ]
  
  # get all src/dst port pairs
  portList <- getUniquePorts(iperfTraffic, DSTPORT, SRCPORT)
  
  # latest complete second in capture file
  timeMax=floor(max(capture[,EPOCH]))
  timeMin=ceiling(min(capture[,EPOCH]))
  # time values to compute bandwidth for
  time <- seq(timeMin, timeMax, by=bandwidthTimeResolution)
  rm(capture)
  
  # calculate the bandwidth
  # bandwidth of all connections
  bandwidthData <- data.frame("time"=time, "bandwidthAll"=getBandwidth(time, iperfTraffic, bandwidthTimeResolution, 1024, EPOCH, LENGTH))
  # calculate bandwidth for each port pair
  i <- 1
  for(portPair in portList){
    traffic <- iperfTraffic[ iperfTraffic[[SRCPORT]]==portPair[[1]] & iperfTraffic[[DSTPORT]]==portPair[[2]], ]
    # add results to data frame as new column
    name = paste(portPair[[2]], ", ", portPair[[1]], sep="")
    bandwidthData[[name]] <- getBandwidth(time, traffic, bandwidthTimeResolution, 1024, EPOCH, LENGTH)
    i <- i+1
  }
  rm(traffic)
  rm(i)
  
  return(bandwidthData)
  
}