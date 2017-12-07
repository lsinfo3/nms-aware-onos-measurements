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
outFilePath <- "./reallocations_cpuLoad"

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
#detail=FALSE
folderName="../meas/nmsInt"
#folders=seq(20, 60, by=10)
#folders=c(4, 8, 16, 32, 64)
folders=c(10, seq(30, 120, by=30))
numMeas=10
parameterName <- "Update Interval"

#tempFiles <- c("avg10/1.csv", "avg10/2.csv")
#tempValues <- c("10", "10")

# get ecdf data from measurement files
source("../getEcdfData.r")
metricsDetail <- getEcdfData(TRUE, folderName, folders, numMeas, parameterName)
metricsAvg <- getEcdfData(FALSE, folderName, folders, numMeas, parameterName)

# set factor
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '6', '8', '10', '12'))
metricsDetail[["parameter"]] <- factor(metricsDetail[["parameter"]], levels=c('10', '30', '60', '90', '120'))
metricsAvg[["parameter"]] <- factor(metricsAvg[["parameter"]], levels=c('10', '30', '60', '90', '120'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('20', '30', '40', '50', '60'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('40', '60', '80', '100', '120'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '8', '12', '16', '20'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '8', '16', '32', '64'))

legendTitle=paste(parameterName, " [s]", sep="")

metricsDetail <- metricsDetail[metricsDetail[["variable"]]=="Throughput" | metricsDetail[["variable"]]=="CPU Load", ]
metricsAvg <- metricsAvg[metricsAvg[["variable"]]=="Reallocations" | metricsAvg[["variable"]]=="CPU Load", ]
library('grid')

figure1 <- ggplot(data=metricsAvg, aes(x=value, color=parameter)) +
  stat_ecdf(geom="step", na.rm=TRUE) +
  facet_grid(. ~ variable, scales="free_x") +
  labs(x=NULL, y="Cumulative Probability") +
#  coord_cartesian(xlim = c(0.0, 1.0)) +
  theme_bw() +
  scale_color_manual(name=legendTitle, values=colorRampPalette(c("blue", "red"))(5)) +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1), text = element_text(size=12),
        panel.spacing.x = unit(0.75, "lines"), legend.position = "bottom")
g1 <- ggplotGrob(figure1)

figure2 <- ggplot(data=metricsDetail, aes(x=value, color=parameter)) +
  stat_ecdf(geom="step", na.rm=TRUE) +
  facet_grid(. ~ variable, scales="free_x") +
  labs(x=NULL, y="Cumulative Probability") +
#  coord_cartesian(xlim = c(0.75, 1.0)) +
  theme_bw() +
  scale_color_manual(name=legendTitle, values=colorRampPalette(c("blue", "red"))(5)) +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1), text = element_text(size=12),
        panel.spacing.x = unit(0.75, "lines"), legend.position = "bottom")
g2 <- ggplotGrob(figure2)

# Replace the upper panels and upper axis of p1 with that of p2
# Tweak panels of second plot - the upper panels
#g2[["grobs"]][[1]] <- g1[["grobs"]][[1]]
#g2[["grobs"]][[2]] <- g1[["grobs"]][[2]] # first figure
g1[["grobs"]][[3]] <- g2[["grobs"]][[3]] # second figure
#g2[["grobs"]][[4]] <- g1[["grobs"]][[4]]
#g2[["grobs"]][[5]] <- g1[["grobs"]][[5]]
#g2[["grobs"]][[6]] <- g1[["grobs"]][[6]] # first x-axis
g1[["grobs"]][[7]] <- g2[["grobs"]][[7]] # second x-axis
#g2[["grobs"]][[8]] <- g1[["grobs"]][[8]]
#g2[["grobs"]][[9]] <- g1[["grobs"]][[9]]


#Tweak axis
#g2[["grobs"]][[4]] <- g1[["grobs"]][[4]]

#grid.newpage()
#grid.draw(g1)

# save plot as pdf
width <- 15; height <- 8.0
ggsave(paste(outFilePath, "_ecdf.pdf", sep=""), plot = g1, width = width, height = height, units="cm")