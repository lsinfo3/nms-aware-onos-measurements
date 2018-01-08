#!/bin/bash

REP="1" 		# measurement repetitions
COUNT="1"		# simultanious connections per iPerf instance
DURATION="120"	# complete measurment duration
IAT="0"			# inter arrival time
FLOWS="8"		# amount of flows
BWD="200"		# bandwidth
VARIATION="0" # percentage of bandwidth deviation
TYPE="ORG"		# measurement type
NMSINT="10" 	# updated interval of the NMS
SEED="1"		# seed for the RANDOM variable
USEUDP=false	# use udp traffic

mnVmIp="192.168.33.10"		# mininet VM's IP address
onosVmIp="192.168.33.20"	# ONOS VM's IP address

runCommand="
Usage:
 startMetricsMeasurement.sh [options]

Options:
 -r\t number of measurement repetitions. Default: 1
 -c\t number of flows per iPerf instance. Default: 1
 -i\t expected flow inter arrival time in seconds. Average value. Default: 0
 \t An inter arrival time of 0 means that all flows are active during the whole measurement. From the beginning to the end.
 -f\t expected number of simultaneously active flows. Average value. Default: 8
 -b\t bandwidth per flow in kbit/s. Default: 200 kbit/s
 -v\t bandwidth variation in percent. Default: 0. Range: [0-1]
 \t The bandwidth defined in \"-t\" is deviated by the given percentage.
 -d\t overall measurement duration in seconds. Default: 120s
 -s\t seed for the random variable. Default: 1. Ranged: [0-32767]
 -n\t update interval of the nms in seconds. Default: 10s
 -u\t tag if the UDP protocol should be used, instead of TCP. Default: TCP
 -t\t measurement type. Default: ORG. Values: {ORG|MOD|NMS}.
 \t Type: ORG
 \t A measurement for the originial ONOS version is executed. No NMS is used.
 \t Type: MOD
 \t A measurement for the modified ONOS version is executed. No NMS is used.
 \t Type: NMS
 \t A measurement for the NMS aware ONOS version is executed. An NMS is instantiated. The created flows are measured and annotated.

"

while getopts "r:c:i:f:b:v:d:s:n:ut:h" opt; do
  case $opt in
    r)
      if [ $OPTARG -le 0 ]; then
        printf "\nExiting: Measurement repetitions must be a positive value.\n" >&2
        printf "$runCommand"
        exit 0
      else
        echo "Measurement repetitions: $OPTARG" >&2
        REP=$OPTARG
      fi
      ;;
    c)
      if [ $OPTARG -le 0 ]; then
        printf "\nExiting: Number of flows must be a positive value.\n" >&2
        printf "$runCommand"
        exit 0
      else
        echo "Number of flows per iPerf instance: $OPTARG" >&2
        COUNT=$OPTARG
      fi
      ;;
    i)
      if [ $OPTARG -lt 0 ]; then
        printf "\nExiting: Flow inter arrival time must be a positive value.\n" >&2
        printf "$runCommand"
        exit 0
      else
        echo "Flow inter arrival time: $OPTARG seconds" >&2
        IAT=$OPTARG
      fi
      ;;
    f)
      if [ $OPTARG -le 0 ]; then
        printf "\nExiting: Number of simultaneous flows must be a positive value.\n" >&2
        printf "$runCommand"
        exit 0
      else
        echo "Number of simultaneous flows: $OPTARG" >&2
        FLOWS=$OPTARG
      fi
      ;;
    b)
      if [ $OPTARG -le 0 ]; then
        printf "\nExiting: Bandwidth per flow must be a positive value.\n" >&2
        printf "$runCommand"
        exit 0
      else
        echo "Bandwidth per flow: $OPTARG kbit/s" >&2
        BWD=$OPTARG
      fi
      ;;
    v)
      if [ $OPTARG -lt 0 ] || [ $OPTARG -gt 1 ]; then
        printf "\nExiting: Bandwidht deviation must be a value between 0 and 1.\n" >&2
        printf "$runCommand"
        exit 0
      else
        echo "Bandwidth deviation: $OPTARG" >&2
        VARIATION=$OPTARG
      fi
      ;;
    d)
      if [ $OPTARG -le 0 ]; then
        printf "\nExiting: Measurement duration must be a positive value.\n" >&2
        printf "$runCommand"
        exit 0
      else
        echo "Measurement duration: $OPTARG seconds" >&2
        DURATION=$OPTARG
      fi
      ;;
    s)
      if [ $OPTARG -lt 0 ] || [ $OPTARG -gt 32767 ]; then
        printf "\nExiting: Random seed must be a value between 0 and 32767.\n" >&2
        printf "$runCommand"
        exit 0
      else
        echo "Seed is: $OPTARG" >&2
        SEED=$OPTARG
      fi
      ;;
    n)
      if [ $OPTARG -lt 0 ]; then
        printf "\nExiting: Flow inter arrival time must be a positive value.\n" >&2
        printf "$runCommand"
        exit 0
      else
        echo "NMS update interval is: $OPTARG" >&2
        NMSINT=$OPTARG
      fi
      ;;
    u)
      echo "Use UDP rather than TCP." >&2
      USEUDP=true
      ;;
    t)
	  TYPE=$OPTARG
	  if [ "$TYPE" == "ORG" ] || [ "$TYPE" == "MOD" ] || [ "$TYPE" == "NMS" ]
		then
		  echo "Measurement type: $OPTARG" >&2
		else
		  echo "Exciting: Measurement type not valid."
		  printf "$runCommand"
		  exit 0
	  fi
	  ;;
    h)
      printf "$runCommand"
      exit 1
      ;;
    \?)
      echo "Exciting: Invalid option: -$OPTARG" >&2
      printf "$runCommand"
      exit 0
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      printf "$runCommand"
      exit 0
      ;;
  esac
done
unset runCommand

# if no iat is given the flow duration corresponds to the measurement
# duration, otherwise the flow duration is determined by the iat and
# the flow amount
if [ "$IAT" == "0" ]; then
	FLOWDUR=$DURATION
else
	FLOWDUR=$(($IAT * $FLOWS / $COUNT))
fi
echo "Duration per flow: $FLOWDUR s." >&2


# create results folder with date and time
onosVmFolder="../../../vagrant/onos"
leftVmFolder="../../../vagrant/nms"
STARTTIME=$(date +%F_%H-%M-%S)
resultFolder="$leftVmFolder/captures/${TYPE}_${STARTTIME}"
if [ ! -d "$leftVmFolder/captures" ]; then
mkdir "$leftVmFolder/captures"
fi
mkdir $resultFolder


# write measurement values to file
infoFile="${resultFolder}/meas_info.txt"
if [ ! -e $infoFile ]; then
  printf "Repetitions: %s\n\
Measurement duration: %s\n\
Inter arrival time: %s\n\
Avg. simultaneous flows: %s\n\
Bandwidth per flow: %s\n\
Avg. flow duration: %s\n\
Bandwidth variation: %s\n\
Iperf flow number: %s\n\
Type: %s\n\
NMS update interval: %s\n\
UDP: %s\n\
Seed: %s\n"\
    "$REP" "$DURATION" "$IAT" "$FLOWS" "$BWD" "$FLOWDUR" "$VARIATION" "$COUNT" "$TYPE" "$NMSINT" "$USEUDP" "$SEED" >> $infoFile
fi


### repeat measurement ###

for run in `seq 1 $REP`; do

printf "\n\n--------------Run #%s--------------\n" "${run}"

# start measurement environment
printf "## Starting the testing environment. ##\n"
./startEnvironment.sh
printf "\n"

# remove files from previous measurements
ssh ubuntu@$mnVmIp "if [ -f /home/ubuntu/clientList.txt ]; then \
rm /home/ubuntu/clientList.txt; \
fi; \
if ls /home/ubuntu/iperfResult*.txt 1> /dev/null 2>&1; then \
rm /home/ubuntu/iperfResult*.txt; \
fi"

initTimeFactor="1.5"
INITTIME=$(bc -l <<< "$FLOWDUR * $initTimeFactor")

# only run initialization phase if an init time is defined
if [ "$INITTIME" != "0" ]; then
# iPerf traffic initialisation phase
printf "Starting initial iPerf traffic phase for %s s\n" "$INITTIME"
iperfCommand="./scheduleIperf.sh -i $IAT -b $BWD -v $VARIATION -l $FLOWDUR -c $COUNT -d $INITTIME -t $TYPE -s $SEED -f"
if [ "$USEUDP" == true ]; then
	iperfCommand="$iperfCommand -u"
fi
eval $iperfCommand
iperfInstanceCount=$?
# update seed
SEED=$(($SEED + 1))
printf "\nInitialisation phase is over.\n\n"
fi
# measure time of tcpdump startup
TIMEA=$(date +%s.%N)
unset iperfCommand INITTIME


if [ "$TYPE" == "NMS" ]; then
  # start network management system
  LANG=C printf -v NMSDURATION "%.0f" "$(bc -l <<< "$DURATION + 10")"
  printf "Starting NMS with runtime %s s.\n\n" "$NMSDURATION"
  nmsCommand="ssh ubuntu@$mnVmIp 'screen -dm bash -c \"/home/ubuntu/python/measurements/02_lowBandwidthSsh/simpleNms.py -i $NMSINT -r $NMSDURATION"
  if [ "$USEUDP" == true ]; then
	nmsCommand="$nmsCommand -u"
  fi
  nmsCommand="$nmsCommand > nms_log.txt 2>&1"
  eval "$nmsCommand\"'"
fi
unset nmsCommand NMSDURATION


printf "Starting tcpdump packet capture.\n"
# remove old captures
if ls $leftVmFolder/*.cap 1> /dev/null 2>&1; then
  rm $leftVmFolder/*.cap
fi
# monitor traffic with tcpdump to file
# output of switch 1 (both data streams before limitation)
IFACE="s1-eth3"
ssh ubuntu@$mnVmIp 'screen -dm bash -c "sudo tcpdump -i '"$IFACE"' -Z ubuntu -w /tmp/'"${TYPE}_${IFACE}"'.cap > tcpdump_'"$IFACE"'_log.txt 2>&1"'
sleep 1
# output of switch 2 (first data stream)
IFACE="s2-eth2"
ssh ubuntu@$mnVmIp 'screen -dm bash -c "sudo tcpdump -i '"$IFACE"' -Z ubuntu -w /tmp/'"${TYPE}_${IFACE}"'.cap > tcpdump_'"$IFACE"'_log.txt 2>&1"'
sleep 1
# output of switch 4 (second data stream)
IFACE="s4-eth1"
ssh ubuntu@$mnVmIp 'screen -dm bash -c "sudo tcpdump -i '"$IFACE"' -Z ubuntu -w /tmp/'"${TYPE}_${IFACE}"'.cap > tcpdump_'"$IFACE"'_log.txt 2>&1"'
sleep 1
# output of switch 3 (both data streams)
IFACE="s3-eth3"
ssh ubuntu@$mnVmIp 'screen -dm bash -c "sudo tcpdump -i '"$IFACE"' -Z ubuntu -w /tmp/'"${TYPE}_${IFACE}"'.cap > tcpdump_'"$IFACE"'_log.txt 2>&1"'
sleep 1
# TODO: check if all four cap files exist

# output of controller
IFACE="enp0s8"
ssh ubuntu@$onosVmIp 'screen -dm bash -c "sudo tcpdump -i '"$IFACE"' -Z ubuntu -w /tmp/'"${TYPE}_${IFACE}"'.cap > tcpdump_'"$IFACE"'_log.txt 2>&1"'
unset IFACE

# start system load measurement of ONOS
ssh ubuntu@$onosVmIp 'screen -dm bash -c "/vagrant/onosLoad.sh 1 > /vagrant/systemLoad.csv 2>&1"'


killScripts () {
  trap SIGINT
  # kill tcpdump in NMS VM and move results to "/vagrant" folder
  printf "Kill tcpdump in NMS VM\n"
  ssh ubuntu@$mnVmIp "sudo killall tcpdump; mv /tmp/*.cap /home/ubuntu/*_log.txt /vagrant/"
  # kill tcpdump in onos vm and move results to "/vagrant" folder
  printf "Kill tcpdump in ONOS VM\n"
  ssh ubuntu@$onosVmIp "sudo killall tcpdump; mv /tmp/*.cap /home/ubuntu/*_log.txt /vagrant/"

  # kill onosLoad script
  printf "Kill onosLoad.sh script\n"
  ssh ubuntu@$onosVmIp 'ps -ax | grep [/]bin/bash\ /vagrant/onosLoad.sh | awk '"'"'{ printf "%s", $1 }'"'"' | xargs kill -15'
  
  # kill iperf server and client on mininet vm in NMS VM
  printf "Kill iperf server and client.\n"
  ssh ubuntu@$mnVmIp 'ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R 100.0.1.201; ssh -oStrictHostKeyChecking=no ubuntu@100.0.1.201 "echo \"$(ps -ax | grep '"'"'[i]perf3'"'"' | awk '"'"'{if ($5 == "iperf3") print $1}'"'"')\" | xargs kill -15"'
  # kill iperf python script on mininet vm in NMS VM
  printf "Kill iperf python script\n"
  ssh ubuntu@$mnVmIp 'ssh -oStrictHostKeyChecking=no ubuntu@100.0.1.201 "echo \"$(ps -ax | grep '"'"'[/]usr/bin/python /home/ubuntu/python/measurements/02_lowBandwidthSsh/testOverSsh.py'"'"' | awk '"'"'{print $1}'"'"')\" | xargs kill -15"'
  # kill all remaining ssh connections on mininet vm
  printf "Kill all remaining ssh connections on NMS VM\n"
  ssh ubuntu@$mnVmIp 'ssh -oStrictHostKeyChecking=no ubuntu@100.0.1.201 "killall /usr/bin/ssh"'
  ssh ubuntu@$mnVmIp 'ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R 100.0.1.101; ssh -oStrictHostKeyChecking=no ubuntu@100.0.1.101 "killall /usr/bin/ssh"'
}

interruptScript () {
  killScripts
  exit 1
}

# Set up SIGINT trap to call function.
trap "interruptScript" INT

printf "Starting main iPerf traffic phase for %s s\n" "$DURATION"
# start iperf instances
TIMEDIFF=$(bc -l <<< "$(date +%s.%N) - $TIMEA")
iperfCommand="./scheduleIperf.sh -i $IAT -b $BWD -v $VARIATION -l $FLOWDUR -c $COUNT -d $DURATION -t $TYPE -e $TIMEDIFF -r $(($iperfInstanceCount + 1)) -s $SEED"
if [ "$USEUDP" == true ]; then
	iperfCommand="$iperfCommand -u"
fi
eval $iperfCommand
# update seed
SEED=$(($SEED + 1))
unset iperfCommand TIMEA TIMEDIFF


#sleep 5

printf "\nKilling tcpdump, onosLoad, etc.\n"
killScripts
# kill measurement environment
printf "Stopping the virtual machine setup.\n"
./killEnvironment.sh

sleep 5


### create results ###

rScriptFolder="../../../rScripts"

# wait for capture files to be available
printf "\nWaiting for capture files to be available.\n"
for f in $leftVmFolder/*.cap; do
  while :
  do
    if [[ "lsof | grep $f" ]]; then
      break
    fi
    sleep 0.5
  done
done

# copy captures to the new folder
printf "Copying capture files to result folder.\n"
cp $leftVmFolder/*.cap $resultFolder

capFiles=""
legendNames=""
for f in $resultFolder/*.cap; do

  # echo "File: $f"
  fileBaseName=$(basename "$f") # example: ./out.pdf -> out.pdf
  # echo "FileBaseName: $fileBaseName"
  fileName="${fileBaseName%.*}" # example: out.pdf -> out
  # echo "FileName: $fileName"
  #fileFolderName="$resultFolder/$fileName"
  # get the legend name
  legendNamePos=`expr index "$fileName" "_"`
  legendName=${fileName:$legendNamePos:2}
  
  # concatenate capture file and legend names
  if [ -z "$capFiles" ]
    then
	  capFiles="$f"
	else
	  capFiles="${capFiles} $f"
  fi
  
  if [ -z "$legendNames" ]
    then
	  legendNames="$legendName"
	else
	  legendNames="${legendNames} $legendName"
  fi

done

# create and execute R file command
rCommand="$rScriptFolder/createPlot.sh"
if [ "$USEUDP" == true ]; then
  # use UDP rather than TCP
  rCommand="$rCommand -u"
fi
rCommand="$rCommand -i \"${capFiles}\""
rCommand="$rCommand -n \"${legendNames}\""
rCommand="$rCommand -r $rScriptFolder/computeMetrics/computeMetrics.r"
rCommand="$rCommand -o $resultFolder/metrics"

eval $rCommand
unset rCommand

# move iperf result and graphs to extra folder with timestamp
dataFolder="${resultFolder}/$(date +%F_%H-%M-%S)"
mkdir $dataFolder
mkdir $dataFolder/iperfResult
mv $leftVmFolder/captures/*.txt $dataFolder/iperfResult
mv ${resultFolder}/*.pdf $dataFolder
# move all csv files to data folder
mv ${resultFolder}/*.csv $dataFolder
# move metrics back to parent folder
mv ${dataFolder}/metrics.csv $resultFolder

# move onos load results (folder is defined at the beginning of the document)
mv ${onosVmFolder}/*.csv $dataFolder
unset onosVmFolder

# remove capture files
rm ${resultFolder}/*.cap
# move capture files to measurement folder
#mv ${resultFolder}/*.cap $dataFolder

unset fileBaseName fileName fileName2 fileFolderName dataFolder

sleep 10

done

unset resultFolder STARTTIME leftVmFolder
