#!/bin/bash

# Public ssh key has to be installed in the mininet VM and the karaf shell

onosVmFolder="../../../vagrant/onos"
mnVmFolder="../../../vagrant/nms"
onosVmIp="192.168.33.20"
mnVmIp="192.168.33.10"
logFile="./killEnvironment.log"

# kill mininet
ssh ubuntu@$mnVmIp "sudo killall /usr/bin/python; sudo mn -c" > /dev/null 2>&1

# kill onos via karaf shell
#ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R [$onosVmIp]:8101
#ssh -oStrictHostKeyChecking=no -p 8101 -i ~/.ssh/id_rsa karaf@$onosVmIp "shutdown -f"
ssh ubuntu@$onosVmIp "screen -X -S onos quit"

unset mnVmIp onosVmIp

printf "\nKill Mininet VM:\n\n" >> $logFile
( cd $mnVmFolder ; vagrant halt ) >> $logFile 2>&1
printf "\nKill ONOS VM:\n\n" >> $logFile
( cd $onosVmFolder ; vagrant halt ) >> $logFile 2>&1
