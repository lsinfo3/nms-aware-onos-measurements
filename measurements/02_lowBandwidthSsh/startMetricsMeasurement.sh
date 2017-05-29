#!/bin/bash

REP="1" 		# measurement repetitions
COUNT="1"		# simultanious connections per iPerf instance
DURATION="120"	# complete measurment duration
IAT="0"			# inter arrival time
FLOWS="8"		# amount of flows
BWD="200"		# bandwidth
TYPE="ORG"		# measurement type
USEUDP=false	# use udp traffic

runCommand="startMetricsMeasurement.sh [-r <measurement runs>] \
[-i <inter arrival time in seconds>] [-f <number of simultaneous flows>] \
[-b <bandwidth per flow in kbit/s>] [-c <number of flows per iPerf instance>] \
[-d <overall measurement duration in seconds>] [-u] -t {ORG|MOD|NMS}"

while getopts "i:f:b:t:d:c:r:uh" opt; do
  case $opt in
	t)
	  TYPE=$OPTARG
	  if [ "$TYPE" == "ORG" ] || [ "$TYPE" == "MOD" ] || [ "$TYPE" == "NMS" ]
		then
		  echo "Measurement type: $OPTARG" >&2
		else
		  echo "Measurement type not valid!"
		  exit 1
	  fi
	  ;;
    i)
      echo "Flow inter arrival time: $OPTARG seconds" >&2
      IAT=$OPTARG
      ;;
    f)
      echo "Number simultaneous of flows: $OPTARG" >&2
      FLOWS=$OPTARG
      ;;
    b)
      echo "Bandwidht per flow: $OPTARG kbit/s" >&2
      BWD=$OPTARG
      ;;
    d)
      echo "Measurement duration: $OPTARG seconds" >&2
      DURATION=$OPTARG
      ;;
    c)
      echo "Connection count: $OPTARG" >&2
      COUNT=$OPTARG
      ;;
    r)
      echo "Measurement repetitions: $OPTARG" >&2
      REP=$OPTARG
      ;;
    u)
      echo "Use UDP rather than TCP." >&2
      USEUDP=true
      ;;
    h)
      echo -e "Usage:\n$runCommand"
      exit 1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
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
leftVmFolder="$HOME/Masterthesis/vm/leftVm"
STARTTIME=$(date +%F_%H-%M-%S)
resultFolder="$leftVmFolder/captures/metrics/${TYPE}_${STARTTIME}"
mkdir $resultFolder


### repeat measurement ###

for run in `seq 1 $REP`; do

printf "\n--------------Run #%s--------------\n" "${run}"

# start measurement environment
./startEnvironment.sh

# remove files from previous measurements
ssh ubuntu@192.168.33.10 "rm /home/ubuntu/clientList.txt; rm iperfResult*.txt"


INITTIME=$(bc -l <<< "$FLOWDUR * 1.2")

if [ "$TYPE" == "NMS" ]; then
  # start network management system
  LANG=C printf -v NMSDURATION "%.0f" "$(bc -l <<< "$DURATION + $INITTIME + 10")"
  printf "Starting NMS with runtime %s s.\n" "$NMSDURATION"
  nmsCommand="bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c '/home/ubuntu/python/measurements/02_lowBandwidthSsh/simpleNms.py -i 10 -r $NMSDURATION"
  if [ "$USEUDP" == true ]; then
	nmsCommand="$nmsCommand -u"
  fi
  gnome-terminal -e "$nmsCommand'\""
fi
unset nmsCommand NMSDURATION


# iPerf traffic initialisation phase
printf "Starting initial iPerf traffic phase for %s s\n" "$INITTIME"
iperfCommand="./iperfParameter/runIperf.sh -i $IAT -b $BWD -l $FLOWDUR -c $COUNT -d $INITTIME -t $TYPE"
if [ "$USEUDP" == true ]; then
	iperfCommand="$iperfCommand -u"
fi
eval $iperfCommand
iperfInstanceCount=$?
# measure time of tcpdump startup
TIMEA=$(date +%s.%N)
unset iperfCommand INITTIME


# monitor traffic with tcpdump to file
# output of switch 2 (first data stream)
gnome-terminal -e "bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c 'cd /home/ubuntu/captures/; sudo tcpdump -i s2-eth2 -Z ubuntu -w "$TYPE"_s2-eth2.cap'\""
sleep 1
# output of switch 4 (second data stream)
gnome-terminal -e "bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c 'cd /home/ubuntu/captures/; sudo tcpdump -i s4-eth1 -Z ubuntu -w "$TYPE"_s4-eth1.cap'\""
sleep 1
# output of switch 3 (both data streams)
gnome-terminal -e "bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c 'cd /home/ubuntu/captures/; sudo tcpdump -i s3-eth3 -Z ubuntu -w "$TYPE"_s3-eth3.cap'\""
sleep 1
# output of switch 1 (both data streams before limitation)
gnome-terminal -e "bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c 'cd /home/ubuntu/captures/; sudo tcpdump -i s1-eth3 -Z ubuntu -w "$TYPE"_s1-eth3.cap'\""
sleep 1
# TODO: check if all four cap files exist


# start iperf instances
TIMEDIFF=$(bc -l <<< "$(date +%s.%N) - $TIMEA")
iperfCommand="./iperfParameter/runIperf.sh -i $IAT -b $BWD -l $FLOWDUR -c $COUNT -d $DURATION -t $TYPE -e $TIMEDIFF -r $(($iperfInstanceCount + 1))"
if [ "$USEUDP" == true ]; then
	iperfCommand="$iperfCommand -u"
fi
eval $iperfCommand
unset iperfCommand TIMEA TIMEDIFF

sleep 5
# kill tcpdump in vagrant vm
gnome-terminal -e "bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c 'sudo killall tcpdump'\""
# kill iperf server and client on mininet vm in vagrant vm
ssh ubuntu@192.168.33.10 'ssh ubuntu@100.0.1.201 "echo \"$(ps -ax | grep '"'"'[i]perf3'"'"' | awk '"'"'{if ($5 == "iperf3") print $1}'"'"')\" | xargs kill -15"'
# kill iperf python script on mininet vm in vagrant vm
ssh ubuntu@192.168.33.10 'ssh ubuntu@100.0.1.201 "echo \"$(ps -ax | grep '"'"'[/]usr/bin/python /home/ubuntu/python/measurements/02_lowBandwidthSsh/testOverSsh.py'"'"' | awk '"'"'{print $1}'"'"')\" | xargs kill -15"'
# kill all remaining ssh connections
ssh ubuntu@192.168.33.10 'ssh ubuntu@100.0.1.201 "killall /usr/bin/ssh"'
ssh ubuntu@192.168.33.10 'ssh ubuntu@100.0.1.101 "killall /usr/bin/ssh"'
# kill measurement environment
./killEnvironment.sh

sleep 5


### create results ###

# move captures to the new folder
mv $leftVmFolder/captures/*.cap $resultFolder

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
rCommand="$leftVmFolder/python/rScripts/createPlot.sh"
if [ "$USEUDP" == true ]; then
  # use UDP rather than TCP
  rCommand="$rCommand -u"
fi
rCommand="$rCommand -i \"${capFiles}\""
rCommand="$rCommand -n \"${legendNames}\""
rCommand="$rCommand -r $leftVmFolder/python/rScripts/computeMetrics/computeMetrics.r"
rCommand="$rCommand -o $resultFolder/metrics"

eval $rCommand
unset rCommand

# move iperf result and graphs to extra folder with timestamp
dataFolder="${resultFolder}/$(date +%F_%H-%M-%S)"
mkdir $dataFolder
mv $leftVmFolder/captures/*.txt $dataFolder
mv ${resultFolder}/*.pdf $dataFolder

# remove capture files
rm $resultFolder/*.cap

unset fileBaseName fileName fileName2 fileFolderName dataFolder

sleep 10

done

unset resultFolder STARTTIME leftVmFolder
