#!/bin/bash

mnVmIp="192.168.33.10"
onosVmIp="192.168.33.20"

# kill mininet
ssh ubuntu@$mnVmIp "sudo killall /usr/bin/python; sudo mn -c"

# kill onos via karaf shell
ssh -p 8101 karaf@$onosVmIp "shutdown -f"

unset mnVmIp onosVmIp
