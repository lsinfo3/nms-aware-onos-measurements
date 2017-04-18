#!/bin/bash

# default values
outFilePath="./out.png"
rFilePath="./bandwidth_allClients_onePlot.r"
capFilePath=""

while getopts "hi:o:r:" opt; do
  case $opt in
    i)
      echo "Input cap filepath: $OPTARG" >&2
      capFilePath=$OPTARG
      ;;
    o)
      echo "Output png filepath: $OPTARG" >&2
      outFilePath=$OPTARG
      ;;
    r)
      echo "R filepath to create graph: $OPTARG" >&2
      rFilePath=$OPTARG
      ;;
    h)
      echo -e "Usage:\ncreatePlot.sh [-r R_SCRIPT_FILE] [-o OUTPUT_FILE] -i CAPTURE_FILE"
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

if [ -z "$capFilePath" ]
  then
    echo "No cap file defined! Exiting." >&2
  else
    # convert cap to csv file
    tshark -T fields -n -r $capFilePath -E separator=, -E header=y \
	  -E quote=d -e frame.time_relative -e frame.time_epoch -e ip.src \
	  -e ip.dst -e ip.proto -e udp.srcport -e udp.dstport \
	  -e frame.len > ./temp.csv

    # create graph from csv file
    $rFilePath 1 ./temp.csv $outFilePath

    # remove csv file
    rm ./temp.csv
fi
