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
parameterName <- ""
outFilePath <- "./out"

if(length(args) >= 1){
  csvFiles <- strsplit(as.character(args[1]), " ")[[1]]
}
if(length(args) >= 2){
  values <- strsplit(as.character(args[2]), " ")[[1]]
}
if(length(args) >= 3){
  parameterName <- as.character(args[3])
}
if(length(args) >= 4){
  outFilePath <- as.character(args[4])
}
rm(args)


# --- create file and value vector ---

detail <- TRUE
folderNames=c("./meas/modIat", "./meas/iatNew")
folders <- seq(20, 60, by=10)
numMeas <- 10
parameterName <- "Measurement Type"

source("./getEcdfCompareData.r")
metrics <- getEcdfCompareData(detail, folderName, folders, numMeas, parameterName)

# set factor
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '6', '8', '10', '12'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('10', '30', '60', '90', '120'))
metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('20', '30', '40', '50', '60'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '6', '8', '10', '12'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('40', '60', '80', '100', '120'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '8', '12', '16', '20'))

metrics[["measurement"]] <- factor(metrics[["measurement"]], levels=folderNames, labels=c("MOD", "NMS"))


figure <- ggplot(data=metrics, aes(x=value, color=measurement)) +
  stat_ecdf(geom="step", na.rm=TRUE) +
  facet_grid(. ~ variable, scales="free_x")
if(detail == TRUE) {
  figure <- figure +
    scale_x_continuous(breaks=c(0, .5, .75, .875, 1.0), trans=scales::exp_trans(exp(3)))
}
figure <- figure +  
  labs(x="Metric Values", y="Cumulative Probability") +
  theme_bw() +
  scale_color_manual(name=parameterName, values=c("blue", "red", "#E69F00", "#009E73", "#CC79A7", "#56B4E9", "#0072B2", "#D55E00")) +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1), text = element_text(size=12),
        panel.spacing.x = unit(0.75, "lines"), legend.position = "bottom")

# save plot as pdf
width <- 15.0; height <- 8.0
ggsave(paste(outFilePath, ".pdf", sep=""), plot = figure, width = width, height = height, units="cm")