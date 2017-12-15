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
outFilePath <- "./linkFairness"

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
folderName="../meas/load"
folders=seq(40, 140, by=20)
#folders=c(4, 8, 16, 32, 64)
#folders=c(10, seq(30, 120, by=30))
#folders=c(4,8,16,32,64)
#folders=c("udp", "tcp")
numMeas=10
parameterName <- "Offered Network Load"

# get ecdf data from measurement files
source("../getEcdfData.r")
metrics <- getEcdfData(detail, folderName, folders, numMeas, parameterName)

# set factor
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '6', '8', '10', '12'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('10', '30', '60', '90', '120'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('20', '30', '40', '50', '60'))
metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('40', '60', '80', '100', '120', '140'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '8', '12', '16', '20'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('4', '8', '16', '32', '64'))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('0', '10', '20', '30', '40'), labels=c('0'="0", '10'=paste("\U00B1","10", sep=""), '20'=paste("\U00B1","20", sep=""), '30'=paste("\U00B1","30", sep=""), '40'=paste("\U00B1","40", sep="")))
#metrics[["parameter"]] <- factor(metrics[["parameter"]], levels=c('udp', 'tcp'), labels=c("udp"="UDP", "tcp"="TCP"))


legendTitle=paste(paste(strsplit(parameterName, " ")[[1]], collapse = "\n"), " [%]", sep="")
#legendTitle=paste(strsplit(parameterName, " ")[[1]], collapse = "\n")

figure1 <- ggplot(data=metrics[metrics[["variable"]]=='Link Fairness', ], aes(x=value, color=parameter)) +
  stat_ecdf(geom="step", na.rm=TRUE) +
#  scale_x_continuous(limits=c(0.3, 1.0)) +
#  coord_cartesian(xlim=c(0.3, 1.0)) +
  labs(x="Link Fairness", y="Cumulative Probability") +
  theme_bw() +
  scale_color_manual(name=legendTitle,
                     values=colorRampPalette(c("blue", "red"))(length(unique(metrics$parameter)))) +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1),
        text = element_text(size=12),
        panel.spacing.x = unit(0.75, "lines"),
        #legend.position = "right",
        legend.position = c(.23, .62),
        legend.background = element_rect(fill=alpha('white', 0.0)))
#  guides(col=guide_legend(nrow=2, title.position = "top"))

# save plot as pdf
width <- 8.5; height <- 7.0
ggsave(paste(outFilePath, "_ecdf1.pdf", sep=""), plot = figure1, width = width, height = height, units="cm")


# plot once more without legend
figure2 <- figure1 +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1), text = element_text(size=12),
        panel.spacing.x = unit(0.75, "lines"), legend.position = 'none')

# save plot as pdf
width <- 6; height <- 7.0
ggsave(paste(outFilePath, "_ecdf2.pdf", sep=""), plot = figure2, width = width, height = height, units="cm")


figure3 <- ggplot(data=metrics[metrics[["variable"]]=="Link Fairness", ], aes(x=parameter, y=value, group=1)) +
  stat_summary(geom="errorbar", fun.data=mean_cl_normal, 
               fun.args=list(conf.int=0.95),
               size = .5,    # Thinner lines
               width = .3,
               position = position_dodge(.9)) +
  stat_summary(aes(color=parameter), geom="point", fun.y=mean, size = 5, stroke=0.7, shape=45) +
#  scale_y_continuous(breaks=seq(0.7, 1.0, by=0.05)) +
#  coord_cartesian(ylim=c(0.7, 1.0)) +
  labs(x=paste(parameterName, " [%]", sep=""), y="Link Fairness") +
#  labs(x="Offered Network\nLoad [%]", y="Link Fairness") +
  theme_bw() +
  scale_color_manual(name=parameterName,
                     values=colorRampPalette(c("blue", "red"))(length(unique(metrics$parameter)))) +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1),
        text = element_text(size=12),
        panel.spacing.x = unit(0.75, "lines"),
        legend.position = "none")

# save plot as pdf
width <- 6; height <- 7.0
ggsave(paste(outFilePath, "_conf.pdf", sep=""), plot = figure3, width = width, height = height, units="cm")