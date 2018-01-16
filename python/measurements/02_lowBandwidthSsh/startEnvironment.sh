#!/bin/bash

# Public ssh key has to be installed in the ONOS and mininet VM!

onosVmFolder="../../../vagrant/onos"
mnVmFolder="../../../vagrant/nms"
mnLocation="/home/ubuntu/python/measurements/02_lowBandwidthSsh/8clientSshd.py"
onosVmIp="192.168.33.20"
onosUiPort="8181"
mnVmIp="192.168.33.10"
logFile="./startEnvironment.log"

# Remove old ssh keys if present
printf "## Remove old SSH keys of VM if present. ##"
ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R $onosVmIp
ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R $mnVmIp

# start ONOS VM
printf "## Starting ONOS VM ##\n"
printf "Vagrant log\n\nStart ONOS VM:\n\n" > $logFile
( cd $onosVmFolder ; vagrant up ) >> $logFile 2>&1
# source profile file (no environment variables set) and start ONOS
#ssh -oStrictHostKeyChecking=no ubuntu@$onosVmIp 'screen -dm bash -c "source /home/ubuntu/.profile; /opt/onos/bin/onos-service start"'
ssh -oStrictHostKeyChecking=no ubuntu@$onosVmIp 'screen -dm -S onos bash -c "source /home/ubuntu/.profile; cd /home/ubuntu/nms-aware-onos/; ./tools/build/onos-buck run onos-local -- clean > /home/ubuntu/onosLog.txt 2>&1"'

# start mininet vm
printf "## Starting mininet VM ##\n"
printf "\nStart Mininet VM:\n\n" >> $logFile
( cd $mnVmFolder ; vagrant up ) >> $logFile 2>&1

# wait for Onos to start
printf "## Waiting for ONOS to start ##\n"
nc -z -v -w5 $onosVmIp $onosUiPort
while [ $? -ne 0 ]; do
  printf "ONOS not yet available\n"
  sleep 10
  nc -z -v -w5 $onosVmIp $onosUiPort >/dev/null 2>&1
done
printf "ONOS is available\n"

# configure ONOS links via REST
printf "## Configure ONOS link via REST ##\n"

printf "## Push Config via REST ## \n" >> $logFile
curl_output="$(curl --user karaf:karaf -X POST -H \"Content-Type:application/json\" -w "%{http_code}" http://$onosVmIp:8181/onos/v1/network/configuration -d \"@network-cfg.json\")"
echo "$curl_output" >> $logFile
echo "$curl_output" | grep -q '200'
retval=$?

while [ $retval -ne 0 ]; do
	sleep 5
	printf "## Push Config via REST ## \n" >> $logFile
	curl_output="$(curl --user karaf:karaf -X POST -H Content-Type:application/json -w \"%{http_code}\" http://$onosVmIp:8181/onos/v1/network/configuration -d @network-cfg.json)"
	echo "$curl_output" >> $logFile
	echo "$curl_output" | grep -q '200'
	retval=$?
done

while [ true ]; do
  printf "## Starting mininet ##\n"
  # start mininet in vm
  ssh -oStrictHostKeyChecking=no ubuntu@$mnVmIp "screen -dm bash -c \"chmod +x $mnLocation; sudo $mnLocation -c $onosVmIp\""

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
