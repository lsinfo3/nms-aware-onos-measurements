#!/usr/bin/env Rscript

mergeBandwidth <- function(fileName1, fileName2, resolution) {
  
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
  
  return(bandwidthData)
  
}