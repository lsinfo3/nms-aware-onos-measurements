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
outFilePath <- "./flowFairness_reallocations_cpuLoad_ecdf"

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
folderNames=c("../meas/modIat", "../meas/iatNew")
folders <- seq(20, 60, by=10)
numMeas <- 10
parameterName <- "Controller Type"

source("../getEcdfCompareData.r")
metricsAvg <- getEcdfCompareData(FALSE, folderName, folders, numMeas, parameterName)
metricsDetail <- getEcdfCompareData(TRUE, folderName, folders, numMeas, parameterName)

# set factor
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '6', '8', '10', '12'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('10', '30', '60', '90', '120'))
metricsAvg[["parameter"]] <- factor(metricsAvg[["parameter"]], levels=c('20', '30', '40', '50', '60'))
metricsDetail[["parameter"]] <- factor(metricsDetail[["parameter"]], levels=c('20', '30', '40', '50', '60'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '6', '8', '10', '12'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('40', '60', '80', '100', '120'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '8', '12', '16', '20'))

metricsAvg[["measurement"]] <- factor(metricsAvg[["measurement"]], levels=folderNames, labels=c("MOD", "NMS"))
metricsDetail[["measurement"]] <- factor(metricsDetail[["measurement"]], levels=folderNames, labels=c("MOD", "NMS"))

metricsDetail <- metricsDetail[metricsDetail[["variable"]]=="Flow Fairness" | metricsDetail[["variable"]]=="Throughput" | metricsDetail[["variable"]]=="CPU Load", ]
metricsAvg <- metricsAvg[metricsAvg[["variable"]]=="Flow Fairness" | metricsAvg[["variable"]]=="Reallocations" | metricsAvg[["variable"]]=="CPU Load", ]
library('grid')

figure1 <- ggplot(data=metricsDetail, aes(x=value, color=measurement)) +
  stat_ecdf(geom="step", na.rm=TRUE) +
  facet_grid(. ~ variable, scales="free_x") +
  coord_cartesian(xlim=c(0.8, 1.0)) +
  labs(x=NULL, y="Cumulative Probability") +
  theme_bw() +
  scale_color_manual(name=parameterName, values=colorRampPalette(c("blue", "red"))(2)) +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1), text = element_text(size=12),
        panel.spacing.x = unit(0.75, "lines"), legend.position = "bottom")
g1 <- ggplotGrob(figure1)

figure2 <- ggplot(data=metricsAvg, aes(x=value, color=measurement)) +
  stat_ecdf(geom="step", na.rm=TRUE) +
  facet_grid(. ~ variable, scales="free_x") +
#  coord_cartesian(xlim=c(0.0, 1.0)) +
  labs(x=NULL, y="Cumulative Probability") +
  theme_bw() +
  scale_color_manual(name=parameterName, values=colorRampPalette(c("blue", "red"))(2)) +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1), text = element_text(size=12),
        panel.spacing.x = unit(0.75, "lines"), legend.position = "bottom")
g2 <- ggplotGrob(figure2)

figure3 <- ggplot(data=metricsDetail, aes(x=value, color=measurement)) +
  stat_ecdf(geom="step", na.rm=TRUE) +
  facet_grid(. ~ variable, scales="free_x") +
  labs(x="Throughput", y="Cumulative Probability") +
#  coord_cartesian(xlim = c(0.75, 1.0)) +
  theme_bw() +
  scale_color_manual(name=parameterName, values=colorRampPalette(c("blue", "red"))(2)) +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1), text = element_text(size=12),
        panel.spacing.x = unit(0.75, "lines"), legend.position = "bottom")
g3 <- ggplotGrob(figure3)

# Copy second plot into first plot of first figure
g1[["grobs"]][[2]] <- g1[["grobs"]][[3]] # second figure into first figure
g1[["grobs"]][[13]] <- g1[["grobs"]][[14]] # second label to first label

# copy second plot of second figure into second plot of first figure
g1[["grobs"]][[3]] <- g2[["grobs"]][[3]] # plot
g1[["grobs"]][[9]] <- g2[["grobs"]][[9]] # x-axis
g1[["grobs"]][[14]] <- g2[["grobs"]][[14]] # label

# copy third plot of third figure into third plot of first figure
g1[["grobs"]][[4]] <- g3[["grobs"]][[4]] # plot
g1[["grobs"]][[10]] <- g3[["grobs"]][[10]] # x-axis

#grid.newpage()
#grid.draw(g1)

# save plot as pdf
width <- 15; height <- 8.0
ggsave(paste(outFilePath, ".pdf", sep=""), plot = g1, width = width, height = height, units="cm")