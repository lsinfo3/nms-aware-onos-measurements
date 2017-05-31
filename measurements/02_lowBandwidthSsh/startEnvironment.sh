#!/bin/bash

# Public ssh key has to be install in the ONOS and mininet VM!

onosVmFolder="$HOME/Masterthesis/vm/firstOnosVm"
mnVmFolder="$HOME/Masterthesis/vm/leftVm"
mnLocation="/home/ubuntu/python/measurements/02_lowBandwidthSsh/8clientSshd.py"
onosVmIp="192.168.33.20"
onosUiPort="8181"
mnVmIp="192.168.33.10"


# start onos vm
printf "Starting ONOS VM\n"
gnome-terminal -e "bash -c \"cd $onosVmFolder; vagrant up; vagrant ssh -c 'onos-karaf'\""
sleep 5
# start mininet vm
printf "Starting mininet VM\n"
gnome-terminal -e "bash -c \"cd $mnVmFolder; vagrant up\""

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
  gnome-terminal -x sh -c "cd $mnVmFolder;vagrant ssh -c \"sudo $mnLocation -c $onosVmIp\""

  waitTime=0
  mnIsNotAvailable=1
  printf "Waiting for mininet hosts to be available\n"
  while [ $mnIsNotAvailable -ne 0 ] && [ "$waitTime" -le 15 ]; do
    ssh ubuntu@$mnVmIp "nc -z -v -w5 100.0.1.101 22 >/dev/null 2>&1"
    mnIsNotAvailable=$?
    printf "Host is not available: %s\nWait time: %s\n" "$mnIsNotAvailable" "$waitTime"
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
