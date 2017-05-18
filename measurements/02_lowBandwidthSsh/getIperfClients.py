#!/usr/bin/python

"""
Read iperf output and return iperf clients in a map with additional
information
"""

import os.path, subprocess, time

SKIPLINES=1

# return the line count of a file
def file_len(fname):
    p = subprocess.Popen(['wc', '-l', fname], stdout=subprocess.PIPE, 
                                              stderr=subprocess.PIPE)
    result, err = p.communicate()
    if p.returncode != 0:
        raise IOError(err)
    return int(result.strip().split()[0])


# wait until iperf created the file containing the client information
def waitForClientInformation(resultIperf, clientCount):
  # wait until file contains client information
  lines = 0
  maxTries = 20
  tries = 0
  try:
    while lines < (SKIPLINES + int(clientCount)) and tries < maxTries:
      if os.path.isfile(resultIperf): 
        try:
          lines = file_len(resultIperf)
        except IOError, e:
          print 'IOError:\n{}Trying again.'.format(e)
        if lines < (SKIPLINES + int(clientCount)):
          print 'Result file containing {} lines has no client information'.format(lines)
          time.sleep(1)
          tries = tries + 1
      else:
        print 'No iPerf result file {} found!'.format(resultIperf)
        time.sleep(1)
        tries = tries + 1
  except KeyboardInterrupt:
    print('\n\nKeyboard exception received. Exiting.')
    exit()
  
  if tries < maxTries:
    print('+++ Client information found.')
    return True
  else:
    print('+++ No client information found!')
    return False
    


# add the active clients in the resultIperf file to the clientListPath
# file in JSON format
def getIperfClients(resultIperf, clientCount, bandwidth, serverPort):
  
  # wait until iperf created the client information in result file
  if waitForClientInformation(resultIperf, clientCount):
  
    f = open(resultIperf, 'r')
    
    # skip first 5 lines
    for i in range(SKIPLINES):
      f.readline()

    clientPortMap = {}
    # read number of clientCount lines
    for line in range(int(clientCount)):
      words = f.readline().split()
      # client Number
      num = words[1]
      num = num[:-1]
      # source port Number of client
      port = words[5]
      clientPortMap[num] = {"src": port, "dst": serverPort, "bandwidth": bandwidth}

    f.close()
    return clientPortMap
  else:
    return {}
