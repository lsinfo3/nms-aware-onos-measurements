#!/bin/bash

# Public ssh key has to be installed in the ONOS and mininet VM!

onosVmFolder="../../../vagrant/onos"
mnVmFolder="../../../vagrant/nms"
mnLocation="/home/ubuntu/python/measurements/02_lowBandwidthSsh/8clientSshd.py"
onosVmIp="192.168.33.20"
onosUiPort="8181"
mnVmIp="192.168.33.10"


# start onos vm
printf "Starting ONOS VM\n"
printf "Vagrant log\n\nStart ONOS VM:\n\n" > vagrant_log.txt
( cd $onosVmFolder ; vagrant up ) >> vagrant_log.txt 2>&1
ssh ubuntu@192.168.33.20 'screen -dm bash -c "/opt/onos/bin/onos-service start"'

# start mininet vm
printf "Starting mininet VM\n"
printf "\nStart Mininet VM:\n\n" >> vagrant_log.txt
( cd $mnVmFolder ; vagrant up ) >> vagrant_log.txt 2>&1

# wait for Onos to start
printf "Waiting for ONOS to start\n"
nc -z -v -w5 $onosVmIp $onosUiPort
while [ $? -ne 0 ]; do
  printf "ONOS not yet available\n"
  sleep 10
  nc -z -v -w5 $onosVmIp $onosUiPort >/dev/null 2>&1
done
printf "ONOS is available\n"

while [ true ]; do
  printf "Starting mininet\n"
  # start mininet in vm
  ssh ubuntu@$mnVmIp "screen -dm bash -c \"sudo $mnLocation -c $onosVmIp\""

  waitTime=0
  mnIsNotAvailable=1
  printf "Waiting for mininet hosts to be available\n"
  while [ $mnIsNotAvailable -ne 0 ] && [ "$waitTime" -le 30 ]; do
    ssh ubuntu@$mnVmIp "nc -z -v -w5 100.0.1.101 22 >/dev/null 2>&1"
    mnIsNotAvailable=$?
    printf "Host is not available: %s\tWaited time: %s\n" "$mnIsNotAvailable" "$waitTime"
    if [ $mnIsNotAvailable -ne 0 ]; then
	  sleep 5
      waitTime=$(($waitTime + 5))
    fi
  done
  unset waitTime

  if [ $mnIsNotAvailable -ne 0 ]; then
    # kill mininet instance and reset mininet
    printf "Mininet host still not available after 20 seconds. Kill mininet and restart.\n"
    ssh ubuntu@$mnVmIp "sudo killall /usr/bin/python; sudo mn -c"
  else
    printf "Mininet host available. Exit startup script.\n"
    break
  fi
done

unset onosVmFolder mnVmFolder mnLocation onosVmIp onosUiPort mnVmIp mnIsNotAvailable
