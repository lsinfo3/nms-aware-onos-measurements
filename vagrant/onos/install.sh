#!/bin/bash

# Locale.
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
sudo locale-gen en_US.UTF-8

# Install ONOS prerequisites (cf. https://wiki.onosproject.org/display/ONOS/Developer+Quick+Start).
sudo apt-get update
sudo apt-get install software-properties-common -y && \
sudo add-apt-repository ppa:webupd8team/java -y && \
sudo apt-get update && \
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections && \
sudo apt-get install oracle-java8-installer oracle-java8-set-default -y && \
sudo apt-get install zip -y && \
sudo apt-get install python -y

# Clone ONOS repo.
git clone https://github.com/lsinfo3/nms-aware-onos ./nms-aware-onos/

# Install ONOS (cf. https://wiki.onosproject.org/display/ONOS/Developer+Quick+Start).
cd nms-aware-onos
export ONOS_ROOT=$(pwd)
# Set variable persistently.
echo "export ONOS_ROOT=$(pwd)" >> ~/.bashrc
tools/build/onos-buck build onos --show-output

# Configure ONOS.


