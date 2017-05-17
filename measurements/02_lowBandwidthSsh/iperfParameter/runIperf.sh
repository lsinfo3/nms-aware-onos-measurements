#!/bin/bash

leftVmPath="/home/lorry/Masterthesis/vm/leftVm/"

COUNT="1"
DURATION="120"
BANDWIDTH="400"
ARRIVAL="0"
USEUDP=false
TYPE="ORG"

while getopts "c:d:b:a:ut:h" opt; do
  case $opt in
	  c)
      #echo "Connection count: $OPTARG" >&2
      COUNT=$OPTARG
      ;;
    d)
      #echo "Measurement duration: $OPTARG seconds" >&2
      DURATION=$OPTARG
      ;;
    b)
      #echo "IPerf connection bandwidth: $OPTARG kbit/s" >&2
      BANDWIDTH=$OPTARG
      ;;
    a)
	  echo "Interarrival time: $OPTARG s" >&2
      ARRIVAL=$OPTARG
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
      echo -e "Usage:\nconnectionNumber.sh [-c COUNT] [-d DURATION] [-b BANDWIDTH] [-u] -t {ORG|MOD|NMS}"
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

createCommand ()
{
	iperfCommand="bash -c \"cd $leftVmPath;"
	iperfCommand="$iperfCommand vagrant ssh -c"
	iperfCommand="$iperfCommand '/home/ubuntu/python/measurements/02_lowBandwidthSsh/testOverSsh.py"
	iperfCommand="$iperfCommand -d $DURATION -c $3 -b $BANDWIDTH"
	if [ "$USEUDP" == true ]; then
	  iperfCommand="$iperfCommand -u"
	fi
	if [ "$TYPE" == "NMS" ]; then
	  iperfCommand="$iperfCommand -a"
	fi
	iperfResultName="iperfResult${1}.txt"
	iperfCommand="$iperfCommand -p ${2} -n iperf${1}"
	iperfCommand="$iperfCommand -r /home/ubuntu/${iperfResultName};"
	iperfCommand="$iperfCommand cp /home/ubuntu/${iperfResultName} ./captures/${iperfResultName}'\""
}


if [ "$ARRIVAL" == "0" ]
then
	createCommand "1" "5001" $COUNT
	# execute command and move iperf result to captures folder at the end
	gnome-terminal -e "$iperfCommand"
	unset iperfCommand
	
else
	for conNum in `seq 1 $COUNT`; do
		createCommand $conNum $((5000 + $conNum)) "1"
		gnome-terminal -e "$iperfCommand"
		unset iperfCommand
		sleep $ARRIVAL
	done
fi
