#!/bin/bash

# default values
outFilePath="./out.png"
rFilePath="./bandwidth_allClients_onePlot.r"
capFiles=""
legendNames=""
useUdp=false

while getopts "hi:o:r:n:u" opt; do
  case $opt in
    i)
      printf "Input cap filepaths:\n$OPTARG\n" >&2
      capFiles=$OPTARG
      ;;
    n)
      printf "Legend names:\n$OPTARG\n" >&2
      legendNames=$OPTARG
      ;;
    o)
      printf "Output filepath:\n$OPTARG\n" >&2
      outFilePath=$OPTARG
      ;;
    r)
      printf "R filepath to create graph:\n$OPTARG\n" >&2
      rFilePath=$OPTARG
      ;;
    u)
      printf "Use UDP rather than TCP.\n" >&2
      useUdp=true
      ;;
    h)
      printf "Usage:\ncreatePlot.sh -i \"CAPTURE_FILE1 [CAPTURE_FILE2 ...]\" -n \"LEGEND_NAME1 [LEGEND_NAME2 ...]\" -r R_SCRIPT_FILE [-u] [-o OUTPUT_FILE]\n"
      exit 1
      ;;
    \?)
      printf "Invalid option: -$OPTARG\n" >&2
      exit 1
      ;;
    :)
      printf "Option -$OPTARG requires an argument.\n" >&2
      exit 1
      ;;
  esac
done

if [ -z "$capFiles" ] || [ -z "$rFilePath" ]
  then
    printf "No cap file or r script file path defined!\nExiting.\n" >&2
    exit 1
  else
    
    # input for r script
    csvFiles=""
    
    # iterate over every cap file
    capFilesList=$(echo $capFiles | tr " " "\n")
    for capFile in $capFilesList; do
      
      fileBaseName=$(basename "$capFile")
      fileName="${fileBaseName%.*}"
      
      if [ ! -f ./${fileName}.csv ]; then
        # convert cap to csv file
        tsharkCmd="tshark -T fields -n -r $capFile -E separator=,"
        tsharkCmd="$tsharkCmd -E header=y -E quote=d"
        tsharkCmd="$tsharkCmd -e frame.time_relative -e frame.time_epoch"
        tsharkCmd="$tsharkCmd -e ip.src -e ip.dst -e ip.proto"
        tsharkCmd="$tsharkCmd -e udp.srcport -e udp.dstport"
        tsharkCmd="$tsharkCmd -e tcp.srcport -e tcp.dstport"
        tsharkCmd="$tsharkCmd -e frame.len > ./${fileName}.csv"
        eval $tsharkCmd
      fi
	  
	  # save output in string
	  if [ -z "$csvFiles" ]
	  then
	    csvFiles="./${fileName}.csv"
	  else
	    csvFiles="$csvFiles ./${fileName}.csv"
	  fi
    done
	
	# create graph from csv file
	if [ "$useUdp" == true ]
	then
      $rFilePath "17" $outFilePath "$csvFiles" "$legendNames"
    else
      $rFilePath "6" $outFilePath "$csvFiles" "$legendNames"
    fi
    
    # remove csv files
    #for capFile in $capFilesList; do
    #  fileBaseName=$(basename "$capFile")
    #  fileName="${fileBaseName%.*}"
    #  rm ./${fileName}.csv
    #done
    
fi

# tshark -T fields -n -r s1.cap -E separator=, -E header=y -E quote=d -e frame.time_relative -e frame.time_epoch -e ip.src -e ip.dst -e ip.proto -e udp.srcport -e udp.dstport -e tcp.srcport -e tcp.dstport -e frame.len > s1.csv
