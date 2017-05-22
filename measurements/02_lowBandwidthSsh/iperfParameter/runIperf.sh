#!/bin/bash

leftVmPath="/home/lorry/Masterthesis/vm/leftVm/"

IAT="0"
BANDWIDTH="400"
COUNT="1"
DURATION="120"
FLOWDUR=$DURATION
TIMEDELAY="0"
USEUDP=false
TYPE="ORG"
runCommand="runIperf.sh [-i <inter arrival time in seconds>] \
[-b <bandwidth per flow in kbit/s>] [-l <duration per flow>] \
[-c <number of flows per iPerf instance>] [-d <overall measurement duration in seconds>] \
[-e <time delay in seconds>] [-u] -t {ORG|MOD|NMS}"

vmUser="ubuntu"
vmIp="192.168.33.10"
mininetServerIp="100.0.1.201"

while getopts "i:b:l:c:d:e:ut:h" opt; do
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
    e)
      echo "Time delay: $OPTARG seconds" >&2
      TIMEDELAY=$OPTARG
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
	
	#iperfCommand="bash -c \"cd $leftVmPath;"
	#iperfCommand="$iperfCommand vagrant ssh -c"
	iperfCommand="ssh ${vmUser}@${vmIp}"
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
	#iperfCommand="$iperfCommand cp /home/ubuntu/${iperfResultName} ./captures/${iperfResultName}'\""
	iperfCommand="$iperfCommand cp /home/ubuntu/${iperfResultName} ./captures/${iperfResultName}'"
}

getServerPort ()
{
	#printf "Search for unused server port.\n"
	serverPort='5001'
	ssh ${vmUser}@${vmIp} "nc -z -v -w5 $mininetServerIp $serverPort" 2> /dev/null
	while [ $? == 0 ]; do
		serverPort=$(($serverPort + 1))
		ssh ${vmUser}@${vmIp} "nc -z -v -w5 $mininetServerIp $serverPort" 2> /dev/null
	done
	#printf "Found unused port %s.\n" "$serverPort"
}

waitForServer ()
{
	port=$1
	#printf "Waiting for server on port %s.\n" "$port"
	ssh ${vmUser}@${vmIp} "nc -z -v -w5 $mininetServerIp $port" 2> /dev/null
	while [ $? == 1 ]; do
	  sleep 0.1
	  ssh ${vmUser}@${vmIp} "nc -z -v -w5 $mininetServerIp $port" 2> /dev/null
	done
	#printf "Server on port %s is listening.\n" "$port"
}


if [ "$IAT" == "0" ]; then
	createCommand "1" "5001"
	# execute command and move iperf result to captures folder at the end
	gnome-terminal -e "$iperfCommand"
	unset iperfCommand
else
	
	measStartTime=$(date +%s.%N)	# measurement start time
	timeError=$TIMEDELAY
	counter=0
	calcIatCounter=0 # calculated IAT sum
	
	# run as long as the measurement time is not over
	# measurementTime = currentTime - measurementStartTime
	while [ $(echo "($(date +%s.%N) - $measStartTime) < $DURATION" | bc -l) == 1 ]; do
		
		startTime=$(date +%s.%N)
		counter=$(($counter + 1))
		printf "\n### iPerf run %s ###\n" "$counter"
		
		# calculate next connection start in seconds
		# (negative exponential distribution function)
		nextIat=$(bc -l <<< "-l(1.0 - $RANDOM/32767.0) * $IAT")
		calcIatCounter=$(bc -l <<< "$calcIatCounter + $nextIat")
		
		# remove the time error from the previous run
		nextTime=$(bc -l <<< "$nextIat - $timeError")
		
		LANG=C printf "Previous time error: %.3f\tNew calc. IAT: %.3f\tTime to wait: %.3f\n" \
		"$timeError" "$nextIat" "$nextTime"
		
		# find an unused port for the iPerf server
		getServerPort
		
		# linux supports floating point numbers but solaris not
		# only wait if the iperf start time is bigger as the already passed time
		if [ $(echo "$nextTime > ($(date +%s.%N) - $startTime)" | bc -l) == 1 ]; then
			sleep $(bc -l <<< "$nextTime - ($(date +%s.%N) - $startTime)")
		fi
	  
	  # run the iPerf server and client
		createCommand $counter $serverPort
		gnome-terminal -e "$iperfCommand"
		# wait for the iPerf server to start
		waitForServer $serverPort
		unset iperfCommand
		
		# print infos
		measTime=$(bc -l <<< "$(date +%s.%N) - $measStartTime")
		LANG=C printf "iPerf start Time: %.3f\tServer Port: %s\tAvr. real IAT: %.3f\tAvr. calc. IAT: %.3f\n" \
		"$measTime" "$serverPort" "$(bc -l <<< "$measTime / $counter")" "$(bc -l <<< "$calcIatCounter / $counter")"
		
		runTime=$(bc -l <<< "$(date +%s.%N) - $startTime")
		# calculate the time error = loopRunTime - interArrivalTime + remainingTimeError
		timeError=$(bc -l <<< "($runTime - $nextIat) + $timeError")
		if [ $(echo "$timeError < 0" | bc -l) == 1 ]; then
			timeError=0
		fi
		
		# print final infos
		LANG=C printf "Run Time: %.2f\tNew time Error: %.3f\n" \
		"$runTime" "$timeError"
	done
fi
