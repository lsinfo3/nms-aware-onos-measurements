#!/bin/bash

#############
## Locale. ##
#############
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
sudo locale-gen en_US.UTF-8

###########################################
## Install NMS and Mininet prerequisites ##
###########################################
printf "\n### Updating the Packet Sources ###"
sudo apt-get update
printf "\n### Installing zip and python ###"
sudo apt-get install zip -y && \
sudo apt-get install python python-pip -y && \
sudo apt-get install mininet -y
LC_ALL=C pip install requests

###########################
## Adding public SSH key ##
###########################
printf "\n### Copy public SSH key ###"
if [ -f /home/ubuntu/.ssh/me.pub ]; then
  cat /home/ubuntu/.ssh/me.pub >> /home/ubuntu/.ssh/authorized_keys
  rm /home/ubuntu/.ssh/me.pub
else
  printf "No public SSH key available! No connection via SSH possible without password!\n" 1>&2
fi

###########################
## Make files executable ##
###########################
if [ -f /home/ubuntu/python/measurements/02_lowBandwidthSsh/simpleNms.py ]; then
  chmod +x /home/ubuntu/python/measurements/02_lowBandwidthSsh/simpleNms.py;
fi
