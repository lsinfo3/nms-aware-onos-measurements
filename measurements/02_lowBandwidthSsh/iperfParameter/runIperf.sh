#!/bin/bash

leftVmPath="/home/lorry/Masterthesis/vm/leftVm/"

IAT="0"
BANDWIDTH="400"
COUNT="1"
DURATION="120"
FLOWDUR=$DURATION
USEUDP=false
TYPE="ORG"
runCommand="runIperf.sh [-i <inter arrival time in seconds>] \
[-b <bandwidth per flow in kbit/s>] [-l <duration per flow>] \
[-c <number of flows per iPerf instance>] [-d <overall measurement duration in seconds>] \
[-u] -t {ORG|MOD|NMS}"

while getopts "i:b:l:c:d:ut:h" opt; do
  case $opt in
	i)
      #echo "Flow inter arrival time: $OPTARG seconds" >&2
      IAT=$OPTARG
      ;;
	b)
      #echo "IPerf connection bandwidth: $OPTARG kbit/s" >&2
      BANDWIDTH=$OPTARG
      ;;
    l)
      #echo "Flow duration: $OPTARG" >&2
      FLOWDUR=$OPTARG
      ;;
    c)
      #echo "Connection count: $OPTARG" >&2
      COUNT=$OPTARG
      ;;
    d)
      #echo "Measurement duration: $OPTARG seconds" >&2
      DURATION=$OPTARG
      ;;
    u)
      #echo "Use UDP rather than TCP." >&2
      USEUDP=true
      ;;
    t)
	  TYPE=$OPTARG
	  if [ "$TYPE" == "ORG" ] || [ "$TYPE" == "MOD" ] || [ "$TYPE" == "NMS" ]
		then
		  #echo "Measurement type: $OPTARG" >&2
		  # no-op command is :
		  :
		else
		  echo "Measurement type not valid!"
	      exit 1
	  fi
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


createCommand ()
{
	conNum=$1
	serverPort=$2
	
	iperfCommand="bash -c \"cd $leftVmPath;"
	iperfCommand="$iperfCommand vagrant ssh -c"
	iperfCommand="$iperfCommand '/home/ubuntu/python/measurements/02_lowBandwidthSsh/testOverSsh.py"
	iperfCommand="$iperfCommand -d $FLOWDUR -c $COUNT -b $BANDWIDTH"
	if [ "$USEUDP" == true ]; then
	  iperfCommand="$iperfCommand -u"
	fi
	if [ "$TYPE" == "NMS" ]; then
	  iperfCommand="$iperfCommand -a"
	fi
	iperfResultName="iperfResult${conNum}.txt"
	iperfCommand="$iperfCommand -p $serverPort -n iperf${conNum}"
	iperfCommand="$iperfCommand -r /home/ubuntu/${iperfResultName};"
	iperfCommand="$iperfCommand cp /home/ubuntu/${iperfResultName} ./captures/${iperfResultName}'\""
}


if [ "$IAT" == "0" ]; then
	createCommand "1" "5001"
	# execute command and move iperf result to captures folder at the end
	gnome-terminal -e "$iperfCommand"
	unset iperfCommand
else
	timeCounter=0
	counter=1
	# run as long as the measurement time is not over
	while [ $(echo "$timeCounter < $DURATION" | bc -l) == 1 ]; do
		# calculate next connection start in seconds
		# (negative exponential distribution function)
		nextTime=$(bc -l <<< "-l(1.0 - $RANDOM/32767.0) * $IAT")
		# linux supports floating point numbers but solaris not
		sleep $nextTime
		timeCounter=$(bc -l <<< "$timeCounter + $nextTime")
	
		printf "Time: %s\tCounter: %s\tServer Port: %s\tAverage IAT: %s\n" "$timeCounter" \
		"$counter" "$((5000 + $counter))" "$(bc -l <<< "$timeCounter / $counter")"
		createCommand $counter $((5000 + $counter))
		gnome-terminal -e "$iperfCommand"
		counter=$(($counter + 1))
		unset iperfCommand
	done
fi
