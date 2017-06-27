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
outFilePath <- "./cpuLoad"

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
detail=TRUE
folderName="../meas/nmsInt"
#folders=seq(20, 60, by=10)
#folders=c(4, 8, 16, 32, 64)
folders=c(10, seq(30, 120, by=30))
numMeas=10
parameterName <- "Update Interval"

# get ecdf data from measurement files
source("../getEcdfData.r")
metrics <- getEcdfData(detail, folderName, folders, numMeas, parameterName)

# set factor
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '6', '8', '10', '12'))
metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('10', '30', '60', '90', '120'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('20', '30', '40', '50', '60'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('40', '60', '80', '100', '120'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '8', '12', '16', '20'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '8', '16', '32', '64'))

figure <- ggplot(data=metrics[metrics[["variable"]]=='CPU Load', ], aes(x=value, color=parameter)) +
  stat_ecdf(geom="step", na.rm=TRUE) +
  coord_cartesian(xlim=c(0.0, 1.0)) +
  labs(x="CPU Load", y="Cumulative Probability") +
  theme_bw() +
  scale_color_manual(name=parameterName, labels=labels, values=colorRampPalette(c("blue", "red"))(5)) +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1), text = element_text(size=12),
        panel.spacing.x = unit(0.75, "lines"), legend.position = "bottom") +
  guides(col=guide_legend(nrow=1, byrow=TRUE, title.position = "top", label.position = "bottom"))

# save plot as pdf
width <- 5.5; height <- 8.0
ggsave(paste(outFilePath, "_ecdf.pdf", sep=""), plot = figure, width = width, height = height, units="cm")


# plot mean values with confidence interval
figure <- ggplot(data=metrics[metrics[["variable"]]=="CPU Load", ], aes(x=parameter, y=value, group=1)) +
  stat_summary(geom="ribbon", fun.data=mean_cl_normal, 
               fun.args=list(conf.int=0.95), fill="lightblue")+
  stat_summary(geom="line", fun.y=mean, linetype="dashed")+
  stat_summary(geom="point", fun.y=mean, color="red") +
  labs(x=paste(parameterName, " [s]", sep=""), y="CPU Load") +
  theme_bw() +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1), text = element_text(size=12),
        panel.spacing.x = unit(0.75, "lines"), legend.position = "right")

# save plot as pdf
width <- 5.5; height <- 8.0
ggsave(paste(outFilePath, "_conf.pdf", sep=""), plot = figure, width = width, height = height, units="cm")