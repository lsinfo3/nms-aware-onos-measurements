#!/bin/bash

REP="1" 		# measurement repetitions
COUNT="1"		# simultanious connections per iPerf instance
DURATION="120"	# complete measurment duration
IAT="0"			# inter arrival time
FLOWS="8"		# amount of flows
BWD="200"		# bandwidth
TYPE="ORG"		# measurement type
USEUDP=false	# use udp traffic
runCommand="simpleBandwidthTest.sh [-r <measurement runs>] \
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


### repeat measurement ###

for run in `seq 1 $REP`; do

printf "\n--------------Run #%s--------------\n" "$run" >&2

# reset intents in ONOS
printf "Reseting ONOS intents.\n"
ssh ubuntu@192.168.33.10 "/home/ubuntu/python/measurements/02_lowBandwidthSsh/initialiseConstraints.py -r"


if [ "$TYPE" == "NMS" ]; then
  # start network management system
  LANG=C printf -v NMSDURATION "%.0f" "$(bc -l <<< "$DURATION + 10")"
  printf "Starting NMS with runtime %s s.\n" "$NMSDURATION"
  nmsCommand="bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c '/home/ubuntu/python/measurements/02_lowBandwidthSsh/simpleNms.py -i 10 -r $NMSDURATION"
  if [ "$USEUDP" == true ]; then
	nmsCommand="$nmsCommand -u"
  fi
  gnome-terminal -e "$nmsCommand'\""
fi
unset nmsCommand NMSDURATION


# iPerf traffic initialisation phase
printf "Starting iPerf traffic phase for %s s" "$DURATION"
iperfCommand="./iperfParameter/runIperf.sh -i $IAT -b $BWD -l $FLOWDUR -c $COUNT -d $DURATION -t $TYPE"
if [ "$USEUDP" == true ]; then
	iperfCommand="$iperfCommand -u"
fi
eval $iperfCommand
# measure time of tcpdump startup
unset iperfCommand


sleep 5
# kill tcpdump in vagrant vm
#gnome-terminal -e "bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c 'sudo killall tcpdump'\""
# kill iperf server on mininet vm in vagrant vm
#ssh ubuntu@192.168.33.10 'ssh ubuntu@100.0.1.201 "echo \"$(ps -ax | grep '"'"'[i]perf3'"'"' | awk '"'"'{if ($5 == "iperf3") print $0}'"'"')\""'
ssh ubuntu@192.168.33.10 'ssh ubuntu@100.0.1.201 "echo \"$(ps -ax | grep '"'"'[i]perf3'"'"' | awk '"'"'{if ($5 == "iperf3") print $1}'"'"')\" | xargs kill -15"'
#ssh ubuntu@192.168.33.10 'ssh ubuntu@100.0.1.201 "echo \"$(ps -ax | grep '"'"'[/]usr/bin/python /home/ubuntu/python/measurements/02_lowBandwidthSsh/testOverSsh.py'"'"' | awk '"'"'{print $0}'"'"')\""'
ssh ubuntu@192.168.33.10 'ssh ubuntu@100.0.1.201 "echo \"$(ps -ax | grep '"'"'[/]usr/bin/python /home/ubuntu/python/measurements/02_lowBandwidthSsh/testOverSsh.py'"'"' | awk '"'"'{print $1}'"'"')\" | xargs kill -15"'

sleep 5


# remove capture files and iPerf results
#rm $leftVmFolder/captures/*.cap
rm $leftVmFolder/captures/*.txt


done

unset resultFolder STARTTIME leftVmFolder
