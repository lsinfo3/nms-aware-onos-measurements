#!/bin/bash

# default values
outFilePath="./out.png"
rFilePath="./bandwidth_allClients_onePlot.r"
capFiles=""
legendNames=""

while getopts "hi:o:r:n:" opt; do
  case $opt in
    i)
      echo "Input cap filepaths: $OPTARG" >&2
      capFiles=$OPTARG
      ;;
    n)
      echo "Legend names: $OPTARG" >&2
      legendNames=$OPTARG
      ;;
    o)
      echo "Output filepath: $OPTARG" >&2
      outFilePath=$OPTARG
      ;;
    r)
      echo "R filepath to create graph: $OPTARG" >&2
      rFilePath=$OPTARG
      ;;
    h)
      echo -e "Usage:\ncreatePlot.sh -i \"CAPTURE_FILE1 [CAPTURE_FILE2 ...]\" -n \"LEGEND_NAME1 [LEGEND_NAME2 ...]\" -r R_SCRIPT_FILE [-o OUTPUT_FILE]"
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

if [ -z "$capFiles" ] || [ -z "$rFilePath" ]
  then
    echo "No cap file or r script file path defined! Exiting." >&2
    exit 1
  else
    
    # input for r script
    csvFiles=""
    
    # iterate over every cap file
    capFilesList=$(echo $capFiles | tr " " "\n")
    for capFile in $capFilesList; do
      
      fileBaseName=$(basename "$capFile")
      fileName="${fileBaseName%.*}"
      
      # convert first cap to csv file
      tshark -T fields -n -r $capFile -E separator=, -E header=y \
	    -E quote=d -e frame.time_relative -e frame.time_epoch -e ip.src \
	    -e ip.dst -e ip.proto -e udp.srcport -e udp.dstport \
	    -e frame.len > ./${fileName}.csv
	  
	  # save output in string
	  if [ -z $csvFiles ]; then
	    csvFiles="./${fileName}.csv"
	  else
	    csvFiles="$csvFiles ./${fileName}.csv"
	  fi
    done
	
	# create graph from csv file
    $rFilePath $outFilePath "$csvFiles" "$legendNames"
    
    # remove csv files
    for capFile in $capFilesList; do
      fileBaseName=$(basename "$capFile")
      fileName="${fileBaseName%.*}"
      rm ./${fileName}.csv
    done
    
fi
