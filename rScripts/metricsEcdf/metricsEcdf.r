#!/usr/bin/env Rscript

library(ggplot2)

# remove all objects in workspace
rm(list=ls())

# get commandline args
args <- commandArgs(trailingOnly = TRUE)

# default values
csvFile <- "metrics.csv"
outFilePath <- "./out"

if(length(args) >= 1){
  csvFile <- as.character(args[1])
}
if(length(args) >= 2){
  outFilePath <- as.character(args[2])
}
rm(args)

# read csv metrics file
metrics <- read.csv(csvFile, header=TRUE, sep=",", quote="\"", dec=".", fill=TRUE)

figure <- ggplot(data=metrics) +
  stat_ecdf(aes(x=throughput, color=0), geom="step") +
  stat_ecdf(aes(x=flowFairness, color=1), geom="step") +
  stat_ecdf(aes(x=linkFairness, color=0.5), geom="step") +
  labs(title="Empirical Cumulative Density Function", x="throughput", y="F(throughput)") +
  theme_bw() +
  theme(text = element_text(size=12))

figure