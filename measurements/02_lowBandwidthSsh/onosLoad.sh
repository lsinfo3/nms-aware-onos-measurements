#!/bin/bash

# This script has to be placed in the ONOS VM's "/vagrant" folder, in
# order to be called by the measurement script.

if [ -z $1 ]; then
  waitTime=5
else
  waitTime=$1
fi

printf "\"time\",\"onosCpu\",\"onosMem\",\"cpu\",\"mem\"\n"
numCpu="$(lscpu | grep Core\(s\)\ per\ socket: | awk '{ printf "%s\n", $4}')"
#printf "Cpu(s): %s" "$numCpu"

while [ true ]; do
  loopStartTime="$(date +%s.%N)"
  row="\"${loopStartTime}\""
  
  # get the program id of onos-karaf
  onosPid="$(ps -ax | grep [/]home/ubuntu/onos/tools/dev/bin/onos-karaf | awk '{ printf "%s", $1}')"
  # if onos-karaf is running, print values
  if [ ! -z $onosPid ]; then
    row="${row},\"$(pidstat -p $onosPid | grep onos-karaf | awk '{printf "%s", $8}')\""
    row="${row},\"$(pidstat -p $onosPid -r | grep onos-karaf | awk '{printf "%s", $9}')\""
  else
    row="${row},,"
  fi
  
  # print system cpu usage
  
  cpuLoad=$(top -bn1 | grep load | awk '{printf "%.2f", $(NF-2)}')
  LANG=C printf -v row "${row},\"%.2f\"" "$(bc -l <<< "$cpuLoad / $numCpu")"
  # print system memory usage
  row="${row},\"$(free -m | awk 'NR==2{printf "%.2f", $3/$2 }')\""
  printf "%s\n" "$row"
  
  # sleep wait time minus the elapsed time
  sleep $(bc -l <<< "$waitTime - ($(date +%s.%N) - $loopStartTime)")
done

unset waitTime row onosPid
