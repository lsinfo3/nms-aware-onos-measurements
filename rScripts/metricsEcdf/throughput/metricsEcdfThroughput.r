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
outFilePath <- "./throughput"

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
#folders=seq(40, 140, by=20)
#folders=c(4, 8, 16, 32, 64)
folders=c(10, seq(30, 120, by=30))
#folders=c(4,8,16,32,64)
numMeas=10
parameterName <- "Update Interval"

#tempFiles <- c("avg10/1.csv", "avg10/2.csv")
#tempValues <- c("10", "10")

# get ecdf data from measurement files
source("../getEcdfData.r")
metrics <- getEcdfData(detail, folderName, folders, numMeas, parameterName)

# set factor
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '6', '8', '10', '12'))
metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('10', '30', '60', '90', '120'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('20', '30', '40', '50', '60'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('40', '60', '80', '100', '120', '140'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '8', '12', '16', '20'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '8', '16', '32', '64'))

legendTitle=paste(paste(strsplit(parameterName, " ")[[1]], collapse = "\n"), " [s]", sep="")
#legendTitle=paste(strsplit(parameterName, " ")[[1]], collapse = "\n")
#legendTitle=paste(parameterName, " [s]", sep="")

figure1 <- ggplot(data=metrics[metrics[["variable"]]=="Throughput", ], aes(x=value, color=parameter)) +
  stat_ecdf(geom="step", na.rm=TRUE) +
#  scale_x_continuous(limits=c(0.75, 1.0)) +
  coord_cartesian(xlim=c(0.5, 1.0)) +
  labs(x="Throughput", y="Cumulative Probability") +
  theme_bw() +
  scale_color_manual(name=legendTitle,
                     values=colorRampPalette(c("blue", "red"))(length(unique(metrics$parameter)))) +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1),
        text = element_text(size=12),
        panel.spacing.x = unit(0.75, "lines"),
        legend.position = c(.19, .58),
        legend.background = element_rect(fill=alpha('white', .5)))
#  guides(col=guide_legend(nrow=1, title.position = "top"))

# save plot as pdf
width <- 8.5; height <- 7.0
ggsave(paste(outFilePath, "_ecdf1.pdf", sep=""), plot = figure1, width = width, height = height, units="cm")


# plot once more without legend
figure1 <- figure1 +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1), text = element_text(size=12),
        panel.spacing.x = unit(0.75, "lines"), legend.position = 'none')

# save plot as pdf
width <- 6; height <- 7.0
ggsave(paste(outFilePath, "_ecdf2.pdf", sep=""), plot = figure1, width = width, height = height, units="cm")


figure3 <- ggplot(data=metrics[metrics[["variable"]]=="Throughput", ], aes(x=parameter, y=value, group=1)) +
  # smean.cl.normal computes 3 summary variables:
  # the sample mean and lower and upper Gaussian confidence limits based on the t-distribution
  stat_summary(geom="errorbar", fun.data=mean_cl_normal,
               fun.args=list(conf.int=0.95),
               size = .5,    # Thinner lines
               width = .5,
               position = position_dodge(.9)) +
  stat_summary(aes(color=parameter), geom="point", fun.y=mean, size = 2, stroke=0.7, shape=4) +
#  coord_cartesian(ylim=c(0.85, 1.0)) +
  labs(x=paste(parameterName, " [s]", sep=""), y="Throughput") +
  theme_bw() +
  scale_color_manual(name=parameterName,
                     values=colorRampPalette(c("blue", "red"))(length(unique(metrics$parameter)))) +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1), text = element_text(size=12),
        panel.spacing.x = unit(0.75, "lines"), legend.position = "none")

# save plot as pdf
width <- 6; height <- 7.0
ggsave(paste(outFilePath, "_conf.pdf", sep=""), plot = figure3, width = width, height = height, units="cm")


#figure3 <- ggplot(data=metrics[metrics[["variable"]]=="Throughput", ], aes(x=parameter, y=value)) +
#  geom_boxplot(outlier.color = NULL, outlier.shape = NULL, outlier.size = NULL, notch=TRUE)

#ylim1 = boxplot.stats(metrics[metrics[["vairable"]]=="Throughput", ]$value)$stats[c(1,5)]

#figure3 <- figure3 +
#  #labs(x="Throughput", y="Throughput") +
#  theme_bw() +
#  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1), text = element_text(size=12),
#        panel.spacing.x = unit(0.75, "lines"), legend.position = "right")

# save plot as pdf
#width <- 6; height <- 7.0
#ggsave(paste(outFilePath, "_box.pdf", sep=""), plot = figure3, width = width, height = height, units="cm")