#!/usr/bin/python

from mininet.log import setLogLevel, info
from pexpect import pxssh
import getIperfClients
import threading, subprocess
import os.path, json, sys, getopt, time
import initialiseConstraints


CLIENTLISTPATH='/home/ubuntu/clientList.txt'
hostname1 = '100.0.1.101'
hostname2 = '100.0.1.201'
username = 'ubuntu'
password = '4fa3fe78fc88f8b5c19e50c0'


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
		bandwidth, serverPort, useUdp):
    threading.Thread.__init__(self)
    self.threadID = threadID
    self.name = name
    self.duration = duration
    self.clientCount = clientCount
    self.resultIperf = resultIperf
    self.bandwidth = bandwidth
    self.serverPort = serverPort
    self.useUdp = useUdp
  
  def run(self):
    info("+++ Starting thread " + self.name + "\n")
    # run iperf ssh command here
    startIperfClient(threadName=self.name, duration=self.duration, 
        clientCount=self.clientCount, resultIperf=self.resultIperf,
        bandwidth=self.bandwidth, serverPort=self.serverPort,
        useUdp=self.useUdp)
    info("+++ Exiting thread " + self.name + "\n")


# start an iperf client on host via ssh
def startIperfClient(threadName, duration='10', clientCount='1',
      interval='2', resultIperf='$HOME/iperfResult.txt',
      bandwidth='200', serverPort='5001', useUdp=False):
  
  try:
    # log in to host1 via ssh
    h1 = pxssh.pxssh()
    h1.login(hostname1, username, password)
    
    # starting iperf client bandwidth measurement
    info('+++ Start iperf client:\nRuntime: {}\nServerPort: {}\nUDP: {}\n'.format(duration, serverPort, useUdp))
    cmd =  'stdbuf -i0 -o0 -e0'
    cmd += ' iperf3'
    cmd += ' -c ' + hostname2
    if(useUdp):
      cmd += ' -u'
    else:
      #cmd += ' -O 60'
      cmd += ' -C cubic'
    cmd += ' -b ' + bandwidth + 'k'
    cmd += ' -P ' + clientCount
    cmd += ' -t ' + duration
    cmd += ' -i ' + interval
    cmd += ' -p ' + serverPort
    cmd += ' -l 1470'
    cmd += ' | tee ' + resultIperf
    h1.sendline(cmd)
    # wait until finished and match the next shell prompt
    time.sleep(float(duration))
    h1.prompt()
    
    info('+++ iperf client ended\n')
    time.sleep(5)
    h1.logout()
    
  except pxssh.ExceptionPxssh, e:
    print "pxssh failed on login."
    print str(e)
  except KeyboardInterrupt:
      print('\n\nKeyboard exception received. Exiting.')
      exit()


# connect to both hosts and run iperf server and client on them
# write the active connections to a file for network management
def performanceTest(duration, clientCount, resultIperf, bandwidth,
    iperfName, serverPort='5001', addConstraints=False, useUdp=False):
  
  try:
    
    # log in to host2 via ssh
    h2 = pxssh.pxssh()
    h2.login(hostname2, username, password)

    # start iperf server on host 2
    info("+++ Start iperf server\n")
    h2.sendline('iperf3 -s -D -p '+serverPort)
    # is prompt needed here?
    h2.prompt()
    
    h2.logout()
    
    # remove old iperf result files
    if os.path.isfile(resultIperf):
      subprocess.Popen(['rm', resultIperf], stdout=subprocess.PIPE, 
                                              stderr=subprocess.PIPE)
    
    # create iperf client measurement thread
    thread = myThread(1, "IperfClientMeasurementThread-1", duration,
		clientCount, resultIperf, bandwidth, serverPort, useUdp)
    # start thread
    thread.start()
    
    info("+++ Get iPerf clients from output\n")
    # read iperf output and append it to the client list
    clientPortMap = getIperfClients.getIperfClients(resultIperf=resultIperf,
      clientCount=clientCount, bandwidth=bandwidth+'000',
      serverPort=serverPort)
    
    info("+++ Adding clients to list\n")
    addClientsToList(clientListPath=CLIENTLISTPATH, clientPortMap=clientPortMap,
        instanceName=iperfName)
    
    if addConstraints:
      info("+++ Adding constraints to intents\n")
      # add constraints to intents
      initialiseConstraints.initialiseConstraints(clientPortMap=clientPortMap)
    
    # wait until iperf client has finished measurement
    info("+++ Waiting for iperf client to finish\n")
    thread.join()
    
    # remove clients from client list
    info("+++ Remove iperf clients from clientList\n")
    removeClientsFromList(clientListPath=CLIENTLISTPATH, instanceName=iperfName)
    
    if addConstraints:
      info("+++ Remove all intents created for this iPerf instance.\n")
      initialiseConstraints.removeIperfIntents(clientPortMap=clientPortMap)
    
    
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
  [-u] [-a]'.format(sys.argv[0])
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
    opts, args = getopt.getopt(argv,"d:c:r:b:n:p:ua",
		["duration=", "clientCount=", "resultIperf=", "bandwidth=", 
    "iperfName=", "serverPort=", "addConstraints", "udp"])
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
  useUdp = False

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
    elif opt in ("-u", "--udp"):
      useUdp = True

  performanceTest(duration=durationArg, clientCount=clientCountArg,
      resultIperf=resultIperfArg, bandwidth=bandwidthArg,
      iperfName=iperfNameArg, serverPort=serverPortArg,
      addConstraints=addConstraintsArg, useUdp=useUdp)


