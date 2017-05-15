#!/bin/bash

DURATION="120"
TYPE="ORG"
USEUDP=false

while getopts "t:d:hu" opt; do
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
    d)
      echo "Measurement duration: $OPTARG seconds" >&2
      DURATION=$OPTARG
      ;;
    u)
      echo "Use UDP rather than TCP." >&2
      USEUDP=true
      ;;
    h)
      echo -e "Usage:\nsimpleBandwidthTest.sh [-d DURATION] [-u] -t {ORG|MOD|NMS}"
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

# monitor traffic with tcpdump to file
# output of switch 2 (first data stream)
#gnome-terminal -e "bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c 'cd /home/ubuntu/captures/; sudo tcpdump -i s2-eth2 -Z ubuntu -w "$TYPE"_s2-eth2.cap'\""
#sleep 1
# output of switch 4 (second data stream)
#gnome-terminal -e "bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c 'cd /home/ubuntu/captures/; sudo tcpdump -i s4-eth1 -Z ubuntu -w "$TYPE"_s4-eth1.cap'\""
#sleep 1
# output of switch 3 (both data streams)
#gnome-terminal -e "bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c 'cd /home/ubuntu/captures/; sudo tcpdump -i s3-eth3 -Z ubuntu -w "$TYPE"_s3-eth3.cap'\""
#sleep 1
# output of switch 1 (both data streams before limitation)
#gnome-terminal -e "bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c 'cd /home/ubuntu/captures/; sudo tcpdump -i s1-eth3 -Z ubuntu -w "$TYPE"_s1-eth3.cap'\""
#sleep 1

if [ "$TYPE" == "NMS" ]; then
  # start network management system
  nmsCommand="bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c '/home/ubuntu/python/measurements/02_lowBandwidthSsh/simpleNms.py -i 10 -r $(($DURATION + 100))"
  if [ "$USEUDP" == true ]; then
	nmsCommand="$nmsCommand -u"
  fi
  gnome-terminal -e "$nmsCommand; exec bash'\""
fi

sleep 5

# start iperf bandwidth test
iperfCommand="bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c '/home/ubuntu/python/measurements/02_lowBandwidthSsh/testOverSsh.py -d $DURATION -c 4 -b 200"
if [ "$USEUDP" == true ]; then
  # use UDP rather than TCP
  iperfCommand="$iperfCommand -u"
fi
if [ "$TYPE" == "NMS" ]; then
  # add constraints if NMS is used
  iperfCommand="$iperfCommand -a"
fi
gnome-terminal -e "$iperfCommand -p 5001 -n iperf1 -r /home/ubuntu/iperfResult1.txt'\""
unset iperfCommand

killIperf()
{
	# kill iperf server on mininet vm in vagrant vm
	gnome-terminal -e "bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c 'sudo killall iperf3'\""
	exit 1
}
trap killIperf SIGINT

sleep $DURATION & wait
sleep 10 & wait
