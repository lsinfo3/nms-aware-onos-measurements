#!/bin/bash

#############
## Locale. ##
#############
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

######################
## Clone ONOS repo. ##
######################
printf "\n### Cloning ONOS Repository ###"
if [ -d "\home\ubuntu\nms-aware-onos" ]; then
rm -rf \home\ubuntu\nms-aware-onos
fi
git clone https://github.com/lsinfo3/nms-aware-onos ./nms-aware-onos/ --progress

#######################################################################################
## Build ONOS (cf. https://wiki.onosproject.org/display/ONOS/Developer+Quick+Start). ##
#######################################################################################
cd nms-aware-onos
cd /home/ubuntu/nms-aware-onos; git checkout networkManagement-1.12
printf "\n### Building ONOS with Buck ###"
export ONOS_ROOT=$(pwd)
# Set variable persistently.
echo "export ONOS_ROOT=$(pwd)" >> /home/ubuntu/.bashrc
echo "export ONOS_ROOT=$(pwd)" >> /home/ubuntu/.profile
tools/build/onos-buck build onos --show-output
# Generate IntelliJ project structure.
tools/build/onos-buck project
