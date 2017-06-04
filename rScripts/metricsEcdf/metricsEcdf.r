#!/usr/bin/env Rscript

library(ggplot2)
library(reshape2)

# remove all objects in workspace
rm(list=ls())

# get commandline args
args <- commandArgs(trailingOnly = TRUE)

# default values
csvFiles <- ""
values <- ""
parameter <- ""
outFilePath <- "./out"

if(length(args) >= 1){
  csvFiles <- strsplit(as.character(args[1]), " ")[[1]]
}
if(length(args) >= 2){
  values <- strsplit(as.character(args[2]), " ")[[1]]
}
if(length(args) >= 3){
  parameter <- as.character(args[3])
}
if(length(args) >= 4){
  outFilePath <- as.character(args[4])
}
rm(args)

#csvFiles <- c("20.csv", "30.csv", "40.csv", "50.csv", "60.csv")
#values <- c("20", "30", "40", "50", "60")
#csvFiles <- c("metrics_detail.csv")
#values <- c("10")

#for(i in seq(20, 60, by=10)) {
#  for(j in seq(1, 2)) {
#    if(exists("tempFiles")) {
#      tempFiles <- c(tempFiles, paste("avg", i, "/", j, ".csv", sep=""))
#    } else {
#      tempFiles <- c(paste("avg", i, "/", j, ".csv", sep=""))
#    }
#  }
#  if(exists("tempValues")) {
#    tempValues <- c(tempValues, rep(toString(i), 2))
#  } else {
#    tempValues <- c(rep(toString(i), 2))
#  }
#}

for(i in seq(20, 60, by=10)) {
  for(j in seq(6, 10)) {
    if(exists("tempFiles")) {
      tempFiles <- c(tempFiles, paste(i, "/", j, ".csv", sep=""))
    } else {
      tempFiles <- c(paste(i, "/", j, ".csv", sep=""))
    }
  }
  if(exists("tempValues")) {
    tempValues <- c(tempValues, rep(toString(i), 5))
  } else {
    tempValues <- c(rep(toString(i), 5))
  }
}

csvFiles <- tempFiles
values <- tempValues
rm(tempFiles, tempValues)
parameter <- "iat"

# combine all csv data to long format
for(i in 1:length(csvFiles)) {
  metricsPart <- read.csv(csvFiles[i], header=TRUE, sep=",", quote="\"", dec=".", fill=TRUE)
  metricsPart[[parameter]] <- values[i]
  
  if(exists("metrics")) {
    metrics <- rbind(metrics, metricsPart)
  } else {
    metrics <- metricsPart
  }
}
rm(metricsPart)
metrics2 <- metrics
# normalize reallocations
#metrics[, "reallocations"] <- (1/(metrics[, "reallocations"]+1))^(1/10)

# read csv metrics file
#metrics <- read.csv(csvFile, header=TRUE, sep=",", quote="\"", dec=".", fill=TRUE)
#metrics <- melt(metrics[2:6], measure.vars=1:4, id=parameter)
metrics <- melt(metrics[2:5], measure.vars=1:3, id=parameter)
labels <- c(throughput="Throughput", linkFairness="Link Fairness", flowFairness="Flow Fairness", reallocations="Reallocations")
# set max value to 1
metrics[metrics[["value"]] > 1, "value"] <- 1

# round the values to max 3 digits
myBreaks <- function(x){
  precission <- 1
  fac <- 10^precission # factor
  breaks <- c(ceiling(min(x)*fac)/fac,round(median(x),precission),floor(max(x)*fac)/fac)
  while(length(unique(breaks)) < length(unique(x))+1) {
    precission <- precission + 1
    fac <- 10^precission # factor
    breaks <- c(ceiling(min(x)*fac)/fac,round(median(x),precission),floor(max(x)*fac)/fac)
  }
  if(breaks[1] < 0){
    breaks[1] <- 0
  }
  names(breaks) <- attr(breaks,"labels")
  breaks
}
myFacetLabeler <- function(variable, value) {
  return(paste("IAT=", value, sep=""))
}
#levels(metrics[[parameter]]) <- c("IAT=20", "IAT=30", "IAT=40", "IAT=50", "IAT=60")

figure <- ggplot(data=metrics, aes(x=value, color=variable)) +
  stat_ecdf(geom="step") +
  facet_grid(iat ~ ., labeller=myFacetLabeler) +
  scale_x_continuous(breaks=myBreaks)+
  labs(x="Metric Values", y="Cumulative Probability") +
  theme_bw() +
  scale_color_discrete(name="Metric", labels=labels) +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1), text = element_text(size=12),
        panel.spacing.x = unit(0.75, "lines"), legend.position = "bottom")

# save plot as pdf
width <- 15.0; height <- 20.0
ggsave(paste(outFilePath, ".pdf", sep=""), plot = figure, width = width, height = height, units="cm")