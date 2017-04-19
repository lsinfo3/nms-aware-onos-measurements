#!/bin/bash

# default values
outFilePath="./out.png"
rFilePath="./bandwidth_allClients_onePlot.r"
capFilePath1=""
capFilePath2=""

while getopts "hi:o:r:" opt; do
  case $opt in
    a)
      echo "Input cap filepath one: $OPTARG" >&2
      capFilePath1=$OPTARG
      ;;
    b)
      echo "Input cap filepath two: $OPTARG" >&2
      capFilePath2=$OPTARG
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
      echo -e "Usage:\ncreatePlot.sh -a CAPTURE_FILE1 [-b CAPTURE_FILE2] -r R_SCRIPT_FILE [-o OUTPUT_FILE]"
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

if [ -z "$capFilePath1" ] || [ -z "$rFilePath"]
  then
    echo "No cap file or r script file path defined! Exiting." >&2
    exit 1
  else
    # convert first cap to csv file
    tshark -T fields -n -r $capFilePath1 -E separator=, -E header=y \
	  -E quote=d -e frame.time_relative -e frame.time_epoch -e ip.src \
	  -e ip.dst -e ip.proto -e udp.srcport -e udp.dstport \
	  -e frame.len > ./temp1.csv

    if [ -z "$capFilePath2"]
	  then
	    # if no further cap file is defined execute script
        # create graph from csv file
        $rFilePath $outFilePath ./temp1.csv

      else
        # convert second cap to csv file
        tshark -T fields -n -r $capFilePath2 -E separator=, -E header=y \
	      -E quote=d -e frame.time_relative -e frame.time_epoch -e ip.src \
	      -e ip.dst -e ip.proto -e udp.srcport -e udp.dstport \
	      -e frame.len > ./temp2.csv
	    
	    $rFilePath $outFilePath ./temp1.csv ./temp2.csv
	    
	    # remove csv file2
        rm ./temp2.csv
    fi
    
    # remove csv file1
    rm ./temp1.csv

fi
