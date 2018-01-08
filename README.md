# nms-aware-onos-measurements

This repository contains a measurement setup for the [NMS aware ONOS](https://github.com/lsinfo3/nms-aware-onos/tree/networkManagement-1.12) SDN controller. The setup consists of two virtual machines which are managed with vagrant. One VM hosts the NMS and the virtual topology and the other one is used as SDN controller.

## Usage
A measurement is initiated with the `startMetricsMeasurement.sh` script. It is located inside the python/measurements/02_lowBandwidthSsh/ folder.
```
Usage:
 startMetricsMeasurement.sh [options]

Options:
 -r	 number of measurement repetitions. Default: 1
 -d	 overall measurement duration in seconds. Default: 120s
 -c	 number of flows per iPerf instance. Default: 1
 -i	 expected flow inter arrival time in seconds. Average value. Default: 0
 	 An inter arrival time of 0 means that all flows are active during the whole measurement. From the beginning to the end.
 -f	 expected number of simultaneously active flows. Average value. Default: 8
 -b	 bandwidth per flow in kbit/s. Default: 200 kbit/s
 -v	 bandwidth variation in percent. Default: 0. Range: [0-1]
 	 The bandwidth defined in "-t" is deviated by the given percentage.
 -s	 seed for the random variable. Default: 1. Ranged: [0-32767]
 -n	 update interval of the nms in seconds. Default: 10s
 -u	 tag if the UDP protocol should be used, instead of TCP. Default: TCP
 -t	 measurement type. Default: ORG. Values: {ORG|MOD|NMS}.
 	 Type: ORG
 	 A measurement for the originial ONOS version is executed. No NMS is used.
 	 Type: MOD
 	 A measurement for the modified ONOS version is executed. No NMS is used.
 	 Type: NMS
 	 A measurement for the NMS aware ONOS version is executed. An NMS is instantiated. The created flows are measured and annotated.
```

### Example

```
./startMetricsMeasurement.sh -r 2 -d 300 -c 1 -i 5 -f 4 -b 400 -n 10 -u -t NMS
```
In this example, the measurement is repeated two times where each run has a total duration of 300 seconds. Every iPerf instance creates one flow. An expected inter arrival time of 5 seconds between two flows is configured and an expected amount of 4 flows are running simultaneously. Each flow has a bandwidth of 400 kbit/s. The NMS has an update interval of 10 seconds. Network traffic is sent with UDP. The SDN controller is an NMS aware ONOS and an NMS is instantiated to manage the traffic.

The default values determine that no bandwidth variation is performed and that the random seed is 1.


```
./startMetricsMeasurement.sh -d 60 -i 5 -f 4 -b 400 -v 0.1 -s 2 -t ORG
```
This measurement has a total duration of 60 seconds and is repeated only once. The expected flow inter arrival time is 5 seconds and an expected number of 4 simultaneous flows is active. The bandwidth of 400 kbit/s per flow is deviated by a percentage of 10. This means the bandwidth of the flows is spread evenly between 360 and 440 kbit/s. As the seed is set to a value of 2, the inter arrival time, flow duration, and bandwidth variation is based on different random variables, compared to the first example. As the measurement is of type ORG, no NMS instance is used to manage the traffic. The measurement expects an unmodified ONOS version as SDN controller.

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
