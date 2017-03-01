#!/bin/bash

DURATION="120"

while getopts "d:h" opt; do
  case $opt in
    d)
      echo "Measurement duration: $OPTARG s" >&2
      DURATION=$OPTARG
      ;;
    h)
      echo -e "Usage:\nsimpleBandwidthTest.sh [-d DURATION]"
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

# start network management system
gnome-terminal -e "bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c '/home/ubuntu/python/measurements/02_lowBandwidthSsh/simpleNms.py -i 10; exec bash'\""

sleep 5
# start iperf bandwidth test
gnome-terminal -e "bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c '/home/ubuntu/python/measurements/02_lowBandwidthSsh/testOverSsh.py -d $DURATION -c 4 -b 400 -p 5001 -n iperf1 -a -r /home/ubuntu/iperfResult1.txt'\""

killIperf()
{
	# kill iperf client on mininet client h1x1 in vagrant vm
	gnome-terminal -e "bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c 'ssh ubuntu@100.0.1.101 'sudo killall iperf'; expect \"password:\"; sleep 1; send \"4fa3fe78fc88f8b5c19e50c0\"'\""
	# kill iperf server on mininet client h2x1 in vagrant vm
	gnome-terminal -e "bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c 'ssh ubuntu@100.0.1.201 'sudo killall iperf'; expect \"password:\"; sleep 1; send \"4fa3fe78fc88f8b5c19e50c0\"'\""
	exit 1
}
trap killIperf SIGINT

sleep $DURATION & wait
sleep 10 & wait
# kill iperf server on mininet client h2x1 in vagrant vm
gnome-terminal -e "bash -c \"cd $HOME/Masterthesis/vm/leftVm/; vagrant ssh -c 'ssh ubuntu@100.0.1.201 'sudo killall iperf'; expect \"password:\"; sleep 1; send \"4fa3fe78fc88f8b5c19e50c0\"'\""
