#!/usr/bin/env Rscript

mergeBandwidth <- function(fileNames, resolution) {
  
  bandwidthList <- list()
  for(fileName in fileNames) {
    # compute the bandwidth data
    bandwidthData1 <- computeBandwidth(fileName, resolution)
    
    # remove "bandwidthAll" column
    bandwidthData1[["bandwidthAll"]] <- NULL
    
    # melt the results together
    bandwidthData1 <- melt(bandwidthData1, id="time", variable.name="tpPorts", value.name = "bandwidth")
    
    # check if tport column is available
    if(!("tpPorts" %in% colnames(bandwidthData1))) {
       next
    }
    
    # add factor for variable order
    if(!is.null(levels(bandwidthData1$tpPorts))){
      bandwidthData1$tpPorts <- factor(bandwidthData1$tpPorts, levels=sort(levels(bandwidthData1$tpPorts)))
    }
    
    # extract source and destination port as columns
    bandwidthData1[["src"]] <- strsplit(as.character(bandwidthData1[["tpPorts"]]), ", ")
    bandwidthData1[["src"]] <- sapply(bandwidthData1[["src"]], function (x) x[2])
    bandwidthData1[["dst"]] <- strsplit(as.character(bandwidthData1[["tpPorts"]]), ", ")
    bandwidthData1[["dst"]] <- sapply(bandwidthData1[["dst"]], function (x) x[1])
    
    # append item to list
    bandwidthList[[length(bandwidthList)+1]] <- bandwidthData1
  }
  
  if(length(bandwidthList)==0){
    stop("No tp ports to measure.")
  }
  
  # combine both frames
  if(length(bandwidthList)==1) {
    bandwidthData <- bandwidthList[[1]]
  } else if (length(bandwidthList)==2){
    bandwidthList[[1]][["Switch"]] <- "s2"
    bandwidthList[[2]][["Switch"]] <- "s4"
    bandwidthData <- rbind(bandwidthList[[1]], bandwidthList[[2]])
  } else {
    return(data.frame())
  }
  
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