# nms-aware-onos-measurements

This repository contains a measurement setup for the [NMS aware ONOS](https://github.com/lsinfo3/nms-aware-onos/tree/networkManagement-1.12) SDN controller. The setup consists of two virtual machines which are managed with vagrant. One VM hosts the NMS and the virtual topology and the other one is used as SDN controller.

A measurement is initiated with the `startMetricsMeasurement.sh` script. It is located inside the nms-aware-onos-measurements/python/measurements/02_lowBandwidthSsh/ folder.

## Prerequisites
These prerequisites are necessary in order to evaluate the measurement results.

Tshark is used to parse the packet capture files into csv.
```
$ sudo apt-get install tshark
```
Install R in order to calculate and present the results.
```
$ sudo apt-get install r-base
```
Install ggplot2 in R.
```
$ R
$ install.packages("ggplot2")
```
