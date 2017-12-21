#!/bin/bash

#############
## Locale. ##
#############
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8

#######################################################################################################
## Install ONOS prerequisites (cf. https://wiki.onosproject.org/display/ONOS/Developer+Quick+Start). ##
#######################################################################################################
printf "\n### Updating the Packet Sources ###"
apt-get update
printf "\n### Installing Java8 ###"
apt-get install software-properties-common -y && \
add-apt-repository ppa:webupd8team/java -y && \
apt-get update && \
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
apt-get install oracle-java8-installer oracle-java8-set-default -y
echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle/jre" >> /home/ubuntu/.profile
printf "\n### Installing zip and python ###"
apt-get install zip -y && \
apt-get install python -y && \
apt-get install bc -y
