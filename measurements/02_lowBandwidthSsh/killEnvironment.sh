#!/bin/bash

# Public ssh key has to be installed in the mininet VM and the karaf shell

onosVmFolder="$HOME/Masterthesis/vm/firstOnosVm"
mnVmFolder="$HOME/Masterthesis/vm/leftVm"
mnVmIp="192.168.33.10"
onosVmIp="192.168.33.20"

# kill mininet
ssh ubuntu@$mnVmIp "sudo killall /usr/bin/python; sudo mn -c" > /dev/null 2>&1

# kill onos via karaf shell
ssh -p 8101 -i ~/.ssh/id_rsa lorry@$onosVmIp "shutdown -f"

unset mnVmIp onosVmIp

printf "\nKill Mininet VM:\n\n" >> vagrant_log.txt
( cd $mnVmFolder ; vagrant halt ) >> vagrant_log.txt 2>&1
printf "\nKill ONOS VM:\n\n" >> vagrant_log.txt
( cd $onosVmFolder ; vagrant halt ) >> vagrant_log.txt 2>&1
