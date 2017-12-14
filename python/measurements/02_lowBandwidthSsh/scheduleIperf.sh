#!/bin/bash

leftVmPath="/home/lorry/Masterthesis/vm/leftVm/"

IAT="0" 			# inter arrival time
BANDWIDTH="400"		# flow bandwidth
VARIATION="0" 		# percentage of bandwidth deviation
COUNT="1"			# simultanious connections per iPerf instance
DURATION="120"		# iPerf client creation duration
FLOWDUR=$DURATION	# duration for each flow
TIMEDELAY="0"		# time error to compensate from the actual measurement start
RUN="1"				# iPerf client runs
SEED="1"			# seed for the RANDOM variable
VIRTUAL=false		# only the flows after the runtime duration count
USEUDP=false		# use udp traffic
TYPE="ORG"			# measurement type

runCommand="runIperf.sh [-i <inter arrival time in seconds>] \
[-b <bandwidth per flow in kbit/s>] [-v <bandwidth variation>] [-l <duration per flow>] \
[-c <number of flows per iPerf instance>] [-d <overall measurement duration in seconds>] \
[-e <time delay in seconds>] [-r <iPerf run number>] [-s <seed>] [-f] [-u] -t {ORG|MOD|NMS}"

vmUser="ubuntu"
vmIp="192.168.33.10"
mininetServerIp="100.0.1.201"

while getopts "i:b:v:l:c:d:e:r:s:fut:h" opt; do
  case $opt in
	i)
      #echo "Flow inter arrival time: $OPTARG seconds" >&2
      IAT=$OPTARG
      ;;
	b)
      #echo "IPerf connection bandwidth: $OPTARG kbit/s" >&2
      BANDWIDTH=$OPTARG
      ;;
    v)
      #echo "Bandwidth deviation: $OPTARG" >&2
      VARIATION=$OPTARG
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
      #echo "Time delay: $OPTARG seconds" >&2
      TIMEDELAY=$OPTARG
      ;;
    r)
      #echo "IPerf run number: $OPTARG" >&2
      RUN=$OPTARG
      ;;
    s)
      #echo "Seed is: $OPTARG" >&2
      SEED=$OPTARG
      ;;
    f)
      #echo "Use UDP rather than TCP." >&2
      VIRTUAL=true
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
	conNumArg=$1
	serverPortArg=$2
	flowDurationArg=$3
	varBandwidthArg=$4
	iperfResultName="iperfResult${conNumArg}"
	
	iperfCommand="ssh ${vmUser}@${vmIp}"
	iperfCommand="$iperfCommand 'screen -dm bash -c \"/home/ubuntu/python/measurements/02_lowBandwidthSsh/testOverSsh.py"
	iperfCommand="$iperfCommand -d $flowDurationArg -c $COUNT -b $varBandwidthArg -v $BANDWIDTH"
	if [ "$USEUDP" == true ]; then
	  iperfCommand="$iperfCommand -u"
	fi
	if [ "$TYPE" == "NMS" ]; then
	  iperfCommand="$iperfCommand -a"
	fi
	iperfCommand="$iperfCommand -p $serverPortArg -n iperf${conNumArg}"
	iperfCommand="$iperfCommand -r /home/ubuntu/${iperfResultName};"
	iperfCommand="$iperfCommand cp /home/ubuntu/${iperfResultName}*.txt /home/ubuntu/captures/\"'"
	
	unset conNumArg serverPortArg flowDurationArg varBandwidthArg iperfResultName
}

getServerPort ()
{
	#printf "Search for unused server port.\n"
	tempPort=$1
	ssh ${vmUser}@${vmIp} "nc -z -v -w5 $mininetServerIp $tempPort" 2> /dev/null
	while [ $? == 0 ]; do
		tempPort=$(($tempPort + 1))
		ssh ${vmUser}@${vmIp} "nc -z -v -w5 $mininetServerIp $tempPort" 2> /dev/null
	done
	serverPort=$tempPort
	unset tempPort
	#printf "Found unused port %s.\n" "$serverPort"
}

waitForServer ()
{
	portToWait=$1
	#printf "Waiting for server on port %s.\n" "$portToWait"
	ssh ${vmUser}@${vmIp} "nc -z -v -w5 $mininetServerIp $portToWait" 2> /dev/null
	while [ $? == 1 ]; do
	  sleep 1
	  ssh ${vmUser}@${vmIp} "nc -z -v -w5 $mininetServerIp $portToWait" 2> /dev/null
	done
	#printf "Server on port %s is listening.\n" "$portToWait"
	unset portToWait
}

iperfNumber=$RUN

if [ "$IAT" == "0" ]; then
	createCommand $iperfNumber "5001" $FLOWDUR
	# execute command and move iperf result to captures folder at the end
	gnome-terminal -e "$iperfCommand"
	unset iperfCommand
	
	exit $iperfNumber
else
	if [ "$VIRTUAL" == "false" ]; then
		# run iPerf instances in real time
		
		measStartTime=$(date +%s.%N)	# measurement start time
		timeError=$TIMEDELAY			# initial time beyond actual measurement time
		calcIatCounter=0 				# calculated IAT sum
		serverPort=$((5000 + $iperfNumber))		# the port to use for the iPerf server
		
		# set the seed for the random variable
		RANDOM=$SEED
		newSeed=$RANDOM
		RANDOM=$newSeed
		printf "Set seed to %s get new seed %s via random and set this as seed." "$SEED" "$newSeed"
		unset newSeed
		
		# run as long as the measurement time is not over (measurementTime = currentTime - measurementStartTime)
		while [ $(echo "($(date +%s.%N) - $measStartTime) < $DURATION" | bc -l) == 1 ]; do
			
			loopStartTime=$(date +%s.%N)
			#counter=$(($counter + 1))
			printf "\n### iPerf run %s ###\n" "$iperfNumber"
			
			# calculate next connection start in seconds
			# (negative exponential distribution function)
			random=$RANDOM
			nextIat=$(bc -l <<< "-l(1.0 - ${random}/32768.0) * $IAT")
			# update iat counter
			calcIatCounter=$(bc -l <<< "$calcIatCounter + $nextIat")
			
			# remove the time error from the previous run
			nextTime=$(bc -l <<< "$nextIat - $timeError")
			
			# calculate the connections duration based on a negative
			# exponential distribution function
			random=$RANDOM
			LANG=C printf -v flowDuration "%.0f" "$(bc -l <<< "-l(1.0 - ${random}/32768.0) * $FLOWDUR")"
			
			# calculate the variaton of the bandwidth
			random=$RANDOM
			LANG=C printf -v varBandwidth "%.0f" "$(bc -l <<< "$BANDWIDTH + (($BANDWIDTH * $VARIATION * 2) * ${random}/32768.0 - ($BANDWIDTH * $VARIATION))")"
			
			LANG=C printf "Previous time error: %.3f\tNew calc. IAT: %.3f\tTime to wait: %.3f\tCalc. flow duration: %s\tBandwidth: %s\n" \
			"$timeError" "$nextIat" "$nextTime" "$flowDuration" "$varBandwidth"
			
			# exit if the next iperf instance start is too late
			if [ $(echo "(($(date +%s.%N) - $measStartTime) + $nextTime) > $DURATION" | bc -l) == 1 ]; then
				# wait until measurement duration is over
				sleep $(bc -l <<< "$DURATION - ($(date +%s.%N) - $measStartTime)")
				printf "Exit iPerf instance creation script. Duration of %s is over.\n" "$DURATION"
				break
			fi
			
			# find the next unused port for the iPerf server
			getServerPort $serverPort
			
			# linux sleep function supports floating point numbers but solaris not
			# only wait if the iperf start time is bigger as the already passed time
			if [ $(echo "$nextTime > ($(date +%s.%N) - $loopStartTime)" | bc -l) == 1 ]; then
				sleep $(bc -l <<< "$nextTime - ($(date +%s.%N) - $loopStartTime)")
			fi
		  
			# run the iPerf server and client
			createCommand $iperfNumber $serverPort $flowDuration $varBandwidth
			eval "$iperfCommand"
			# wait for the iPerf server to start
			#waitForServer $serverPort
			unset iperfCommand varBandwidth
			
			# print infos
			measTime=$(bc -l <<< "$(date +%s.%N) - $measStartTime")
			LANG=C printf "iPerf start Time: %.3f\tServer Port: %s\tAvr. real IAT: %.3f\tAvr. calc. IAT: %.3f\n" \
			"$measTime" "$serverPort" "$(bc -l <<< "$measTime / ($iperfNumber - $RUN + 1)")" "$(bc -l <<< "$calcIatCounter / ($iperfNumber - $RUN + 1)")"
			
			# update loop variables
			iperfNumber=$(($iperfNumber + 1))
			serverPort=$(($serverPort + 1))
			
			runTime=$(bc -l <<< "$(date +%s.%N) - $loopStartTime")
			# calculate the time error = loopRunTime - interArrivalTime + remainingTimeError
			timeError=$(bc -l <<< "($runTime - $nextIat) + $timeError")
			if [ $(echo "$timeError < 0" | bc -l) == 1 ]; then
				timeError=0
			fi
			
			# print final infos
			LANG=C printf "Run Time: %.2f\tNew time Error: %.3f\n" \
			"$runTime" "$timeError"
			
			unset flowDuration loopStartTime random nextIat nextTime measTime runTime
			
		done
	else
		# only run the iPerf instaces at the end of the script
		
		measRunTime=0						# measurement start time
		calcIatCounter=0 					# calculated IAT sum
		serverPort=$((5000 + $iperfNumber))	# the port to use for the iPerf server
		
		relConNum=0			# number of relevant connections
		
		# set the seed for the random variable
		RANDOM=$SEED
		newSeed=$RANDOM
		RANDOM=$newSeed
		printf "Set seed to %s get new seed %s via random and set this as seed." "$SEED" "$newSeed"
		unset newSeed
		
		# run as long as the measurement time is not over
		while [ $(echo "$measRunTime < $DURATION" | bc -l) == 1 ]; do
			
			printf "\n### iPerf run %s ###\n" "$iperfNumber"
			
			# calculate next connection start in seconds
			# (negative exponential distribution function)
			random=$RANDOM
			nextIat=$(bc -l <<< "-l(1.0 - ${random}/32768.0) * $IAT")
			# update iat counter
			calcIatCounter=$(bc -l <<< "$calcIatCounter + $nextIat")
			
			# calculate the connections duration based on a negative
			# exponential distribution function
			random=$RANDOM
			LANG=C printf -v flowDuration "%.0f" "$(bc -l <<< "-l(1.0 - ${random}/32768.0) * $FLOWDUR")"
			
			# calculate the variaton of the bandwidth
			random=$RANDOM
			LANG=C printf -v varBandwidth "%.0f" "$(bc -l <<< "$BANDWIDTH + (($BANDWIDTH * $VARIATION * 2) * ${random}/32768.0 - ($BANDWIDTH * $VARIATION))")"
			
			LANG=C printf "New calc. IAT: %.3f\tCalc. flow duration: %s\tBandwidth: %s\n" \
			"$nextIat" "$flowDuration" "$varBandwidth"
			
			# exit if the next iperf instance start is too late
			if [ $(echo "($measRunTime + $nextIat) > $DURATION" | bc -l) == 1 ]; then
				# wait until measurement duration is over
				printf "Exit iPerf instance creation script. Duration of %s is over.\n" "$DURATION"
				break
			fi
			
			# find the next unused port for the iPerf server
			getServerPort $serverPort
			
			# update measurement run time
			measRunTime=$(bc -l <<< "$measRunTime + $nextIat")
			
			# check if the iPerf instance would run longer than the script duration
			if [ $(echo "($measRunTime + $flowDuration) > $DURATION" | bc -l) == 1 ]; then
				# increase relevent connection number
				relConNum=$(bc -l <<< "$relConNum + 1")
				# create array with duration values, server ports, iPerf number and bandwidth
				durations[$relConNum]=$(bc -l <<< "($measRunTime + $flowDuration) - $DURATION")
				ports[$relConNum]=$serverPort
				iPerfNumbers[$relConNum]=$iperfNumber
				bandwidths[$relConNum]=$varBandwidth
			fi
			
			# print infos
			#measTime=$(bc -l <<< "$(date +%s.%N) - $measStartTime")
			LANG=C printf "iPerf start Time: %.3f\tServer Port: %s\tAvr. real IAT: %.3f\tAvr. calc. IAT: %.3f\n" \
			"$measRunTime" "$serverPort" "$(bc -l <<< "$measRunTime / ($iperfNumber - $RUN + 1)")" "$(bc -l <<< "$calcIatCounter / ($iperfNumber - $RUN + 1)")"
			
			# update loop variables
			iperfNumber=$(($iperfNumber + 1))
			serverPort=$(($serverPort + 1))
			
			unset flowDuration random nextIat varBandwidth
			
		done
		
		# start remaining iPerf instances
		for num in `seq 1 $relConNum`; do
			createCommand ${iPerfNumbers[$num]} ${ports[$num]} ${durations[$num]} ${bandwidths[$num]}
			eval "$iperfCommand"
			unset iperfCommand
		done
		
		unset iPerfNumbers ports durations bandwidths relConNum
		
	fi
fi

unset IAT BANDWIDTH COUNT DURATION FLOWDUR TIMEDELAY RUN USEUDP TYPE
unset vmUser vmIp mininetServerIp

# return the iperf instace number
exit $iperfNumber
