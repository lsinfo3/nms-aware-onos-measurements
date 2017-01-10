#!/usr/bin/python

from mininet.log import setLogLevel, info
from pexpect import pxssh
import threading, subprocess
import os.path, json, sys, getopt, time
import initialiseConstraints

CLIENTLISTPATH='/home/ubuntu/clientList.txt'
hostname1 = '100.0.1.101'
hostname2 = '100.0.1.201'
username = 'ubuntu'
password = '4fa3fe78fc88f8b5c19e50c0'


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
  while lines < (5 + int(clientCount)):
    
    if os.path.isfile(resultIperf): 
      try:
        lines = file_len(resultIperf)
      except IOError, e:
        print 'IOError:\n{}Trying again.'.format(e)


# add the active clients in the resultIperf file to the clientListPath
# file in JSON format
def getIperfClients(resultIperf, clientCount, bandwidth):
  
  # wait until iperf created the client information in result file
  waitForClientInformation(resultIperf, clientCount)
  
  f = open(resultIperf, 'r')
  
  # skip first 5 lines
  for i in range(5):
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
    clientPortMap[num] = {"src": port, "dst": "5001", "bandwidth": bandwidth}

  f.close()
  return clientPortMap
  
def addClientsToList(clientListPath, clientPortMap, instanceName):
  
  # write client information to file
  info("+++ Add iperf clients to clientList\n")
  if not os.path.isfile(clientListPath):
    # create new file while opening it writeable
    f = open(clientListPath, 'w')
    # write json to empty file
    clientList = {instanceName: clientPortMap}
    json.dump(clientList, f)
    f.close()
  else:
    # open existing file readable
    f = open(clientListPath, 'r')
    # load existing json file
    clientList = json.load(f)
    f.close()
    
    # remove old client information if present
    if instanceName in clientList:
      del clientList[instanceName]
    
    # write updated information to file
    clientList[instanceName] = clientPortMap
    f = open(clientListPath, 'w')
    json.dump(clientList, f)
    f.close()


# remove clients from list
def removeClientsFromList(clientListPath, instanceName):
  
  # only remove if file exists
  if os.path.isfile(clientListPath):
    # open file readable
    f = open(clientListPath, 'r')
    # load client list in json format
    clientList = json.load(f)
    f.close()
    
    # remove information of this iperf instance
    if instanceName in clientList:
      del clientList[instanceName]
    
    # write updated information to file
    f = open(clientListPath, 'w')
    json.dump(clientList, f)
    f.close()

# thread running an iperf client
class myThread (threading.Thread):
  
  def __init__(self, threadID, name, duration, clientCount, resultIperf,
		bandwidth, serverPort):
    threading.Thread.__init__(self)
    self.threadID = threadID
    self.name = name
    self.duration = duration
    self.clientCount = clientCount
    self.resultIperf = resultIperf
    self.bandwidth = bandwidth
    self.serverPort = serverPort
  
  def run(self):
    info("+++ Starting thread " + self.name + "\n")
    # run iperf ssh command here
    startIperfClient(threadName=self.name, duration=self.duration, 
        clientCount=self.clientCount, resultIperf=self.resultIperf,
        bandwidth=self.bandwidth, serverPort=self.serverPort)
    info("+++ Exiting thread " + self.name + "\n")


# start an iperf client on host via ssh
def startIperfClient(threadName, duration='10', clientCount='1', interval='2', 
      resultIperf='$HOME/iperfResult.txt', bandwidth='200', serverPort='5001'):
  
  try:
    # log in to host1 via ssh
    h1 = pxssh.pxssh()
    h1.login(hostname1, username, password)
    
    # starting iperf client bandwidth measurement
    info('+++ Start iperf client:\nRuntime: {}\nServerPort: {}\n'.format(duration, serverPort))
    
    h1.sendline('iperf -c '+hostname2+' -u -b '+bandwidth+'k -P '
		+clientCount+' -t '+duration+' -i '+interval+' -p '+serverPort
    +' | tee '+resultIperf + ' &')
    h1.prompt()
    
    try:
        time.sleep(int(duration)+5)
    except KeyboardInterrupt:
      print('\n\nKeyboard exception received. Exiting.')
      exit()
    
    info('+++ iperf client ended\n')
    
    h1.logout()
    
  except pxssh.ExceptionPxssh, e:
    print "pxssh failed on login."
    print str(e)


# connect to both hosts and run iperf server and client on them
# write the active connections to a file for network management
def performanceTest(duration, clientCount, resultIperf, bandwidth,
    iperfName, serverPort='5001', addConstraints=False):
  
  try:
    
    # log in to host2 via ssh
    h2 = pxssh.pxssh()
    h2.login(hostname2, username, password)

    # start iperf server on host 2
    info("+++ Start iperf server\n")
    h2.sendline('iperf -s -u -D -p '+serverPort)
    h2.prompt()
    
    h2.logout()
    
    # remove old iperf result files
    if os.path.isfile(resultIperf):
      subprocess.Popen(['rm', resultIperf], stdout=subprocess.PIPE, 
                                              stderr=subprocess.PIPE)
    
    # create iperf client measurement thread
    thread = myThread(1, "IperfClientMeasurementThread-1", duration,
		clientCount, resultIperf, bandwidth, serverPort)
    # start thread
    thread.start()
    
    # read iperf output and append it to the client list
    clientPortMap = getIperfClients(resultIperf=resultIperf,
      clientCount=clientCount, bandwidth=bandwidth+'000')
    
    addClientsToList(clientListPath=CLIENTLISTPATH, clientPortMap=clientPortMap,
        instanceName=iperfName)
    
    if addConstraints:
      info("+++ Adding constraints to intents\n")
      # add constraints to intents
      initialiseConstraints.initialiseConstraints(resultIperf, clientCount)
    
    # wait until iperf client has finished measurement
    info("+++ Waiting for iperf client to finish\n")
    thread.join()
    
    # remove clients from client list
    info("+++ Remove iperf clients from clientList\n")
    removeClientsFromList(clientListPath=CLIENTLISTPATH, instanceName=iperfName)
    
    # kill the iperf server on host 2
    # TODO: WARNING do not kill the iperf server! other clients lose connection!
    # info('+++ kill iperf server\n')
    # h2.sendline('sudo killall iperf')
    # h2.prompt()
    
    # h2.logout()

  except pxssh.ExceptionPxssh, e:
    print "pxssh failed on login."
    print str(e)


if __name__ == '__main__':
  setLogLevel( 'info' )
  
  cmd='Usage:\n{} [-d <duration>] [-c <clientCount>] [-b <iperfBandwidthInKb>] \
	[-p <iperfServerPort>] [-n <iperfInstanceName>] [-r <iperfResultPath>] \
  [-a]'.format(sys.argv[0])
  argv = sys.argv[1:]
  
  # check mandatory arguments
  ### TODO: any is wrong here! Which arguments are mandatory?
#  if not any(x in ["-d", "--duration", "-r", "--resultIperf", "-h"]
#      for x in argv):
#    print cmd
#    sys.exit(2)
  
  # parsing commandline arguments
  ### TODO: Missing arguments: clientListPath, host1, host2?
  try:
    opts, args = getopt.getopt(argv,"d:c:r:b:n:p:a",
		["duration=", "clientCount=", "resultIperf=", "bandwidth=", 
    "iperfName=", "serverPort=", "addConstraints"])
  except getopt.GetoptError:
    print cmd
    sys.exit(2)
  
  # setting default values
  durationArg = '10'
  clientCountArg = '1'
  resultIperfArg = '/home/ubuntu/iperfResult.txt'
  bandwidthArg = '200'
  iperfNameArg = 'iperfInstance'
  serverPortArg = '5001'
  addConstraintsArg = False

  # set command line arguments
  for opt, arg in opts:
    if opt == '-h':
      print cmd
      sys.exit()
    elif opt in ("-d", "--duration"):
      durationArg = arg
    elif opt in ("-c", "--clientCount"):
      clientCountArg = arg
    elif opt in ("-r", "--resultIperf"):
      resultIperfArg = arg
    elif opt in ("-b", "--bandwidth"):
      bandwidthArg = arg
    elif opt in ("-n", "--iperfName"):
      iperfNameArg = arg
    elif opt in ("-p", "--serverPort"):
      serverPortArg = arg
    elif opt in ("-a", "--addConstraints"):
      addConstraintsArg = True

  performanceTest(duration=durationArg, clientCount=clientCountArg,
      resultIperf=resultIperfArg, bandwidth=bandwidthArg,
      iperfName=iperfNameArg, serverPort=serverPortArg,
      addConstraints=addConstraintsArg)


