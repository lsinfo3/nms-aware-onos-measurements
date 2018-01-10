#!/usr/bin/python

from mininet.log import setLogLevel, info
from pexpect import pxssh
import getIperfClients
import threading, subprocess
import os.path, json, sys, getopt, time
import initialiseConstraints
try:
    from subprocess import DEVNULL # py3k
except ImportError:
    import os
    DEVNULL = open(os.devnull, 'wb')


CLIENTLISTPATH='/home/ubuntu/clientList.txt'
hostname1 = '10.0.0.1'
hostname1testnet = '172.16.44.12'
hostname2 = '10.0.0.2'
hostname2testnet = '172.16.44.13'
username = 'ubuntu'
password = 'onos123'


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
class clientThread (threading.Thread):
  
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
    info("+++ Starting client thread " + self.name + "\n")
    # run iperf ssh command here
    startIperfClient(threadName=self.name, duration=self.duration, 
        clientCount=self.clientCount, resultIperf=self.resultIperf,
        bandwidth=self.bandwidth, serverPort=self.serverPort,
        useUdp=self.useUdp)
    info("+++ Exiting client thread " + self.name + "\n")


# start an iperf client on host via ssh
def startIperfClient(threadName, duration='10', clientCount='1',
      interval='2', resultIperf='$HOME/iperfClientResult.txt',
      bandwidth='200', serverPort='5001', useUdp=False):
  
  try:
    # log in to host1 via ssh
    h1 = pxssh.pxssh()
    h1.login(hostname1testnet, username, password)
    
    # starting iperf client bandwidth measurement
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
    #cmd += ' -V -d'
    cmd += ' 2>&1'
    cmd += ' | tee ' + resultIperf
    
    info("+++ Starting client with command: {}\n".format(cmd))
    h1.sendline(cmd)
    info('+++ Started iperf client:\nRuntime: {}\nServerPort: {}\nUDP: {}\n'.format(duration, serverPort, useUdp))
    # wait until finished and match the next shell prompt
    time.sleep(float(duration))
    
    if not h1.prompt():
      info('+++ iPerf client: Could not match the prompt! Sending SIGKILL.\n')
      h1.kill(9)
    else:
      info('+++ iPerf client ended\n')
    info('+++ iPerf client session content:\n{}'.format(h1.before))
    
    h1.logout()
    
  except pxssh.ExceptionPxssh, e:
    print "pxssh failed on login."
    print str(e)
  except KeyboardInterrupt:
    print('\n\nKeyboard exception received. Exiting.')
    exit()
  except:
    print('Exception received in client thread.')
    h1.logout()


# thread running an iperf client
class serverThread (threading.Thread):
  
  def __init__(self, threadID, serverPort, duration, resultIperf):
    threading.Thread.__init__(self)
    self.threadID = threadID
    self.serverPort = serverPort
    self.duration = duration
    self.resultIperf = resultIperf


  def run(self):
    info("+++ Starting server thread\n")
    # run iperf ssh command
    startIperfServer(serverPort=self.serverPort, duration=self.duration,
        resultIperf=self.resultIperf)
    info("+++ Exiting server thread\n")


# start an iperf server on host via ssh
def startIperfServer(resultIperf, serverPort='5001', duration='10'):
  
  try:
    # log in to host1 via ssh
    h2 = pxssh.pxssh()
    h2.login(hostname2testnet, username, password)
    
    # start iperf server on host 2
    cmd = "timeout {}s".format(float(duration)+5)
    cmd += " iperf3 -s -p {}".format(serverPort)
    cmd += " -V -d 2>&1"
    cmd += " | tee {}".format(resultIperf)
    
    info("+++ Starting server with command: {}\n".format(cmd))
    h2.sendline(cmd)
    info("+++ Started iPerf server\n")
    time.sleep(float(duration)+6)
    
    if not h2.prompt():
      info('+++ iPerf server: Could not match the prompt! Sending SIGKILL.\n')
      h2.kill(9)
    else:
      info('+++ iPerf server ended\n')
    info('+++ iPerf server session content:\n{}'.format(h2.before))
    
    h2.logout()
    
  except pxssh.ExceptionPxssh, e:
    print "pxssh failed on login."
    print str(e)
  except KeyboardInterrupt:
    print('\n\nKeyboard exception received. Exiting.')
    exit()
  except:
    print('Exception received in server thread.')
    h2.logout()


def isPortOpen(port, name='iperf3', user='ubuntu', ip='100.0.1.201'):
  try:
    subprocess.check_call(["ssh", user+"@"+ip, "netstat -ntlp", "|", "grep", port, 
        "|", "grep", name], stdout=DEVNULL, stderr=DEVNULL)
  except subprocess.CalledProcessError:
    return False
  return True


# connect to both hosts and run iperf server and client on them
# write the active connections to a file for network management
def performanceTest(duration, clientCount, resultIperf, bandwidth,
    nmsBandwidth, iperfName, serverPort='5001', addConstraints=False,
    useUdp=False):
  
  try:
    
    # remove old iperf result files
    if os.path.isfile(resultIperf):
      subprocess.Popen(['rm', resultIperf+"_server.txt"], stdout=subprocess.PIPE, 
                                              stderr=subprocess.PIPE)
      subprocess.Popen(['rm', resultIperf+"_client.txt"], stdout=subprocess.PIPE, 
                                              stderr=subprocess.PIPE)
    
    # run iPerf server in thread    
    st = serverThread(1, serverPort, duration, resultIperf+"_server.txt")
    st.start()
    
    # check if the server port is available via netstat
    while not isPortOpen(port=serverPort):
      info('### IPerf server port {} not open.\n'.format(serverPort))
      time.sleep(1)
    info('+++ Server is running and port {} open for client connection\n'
        .format(serverPort))
    
    # create iperf client measurement thread
    ct = clientThread(2, "IperfClientMeasurementThread-1", duration,
		clientCount, resultIperf+"_client.txt", bandwidth, serverPort, useUdp)
    # start thread
    ct.start()
    
    info("+++ Get iPerf clients from output\n")
    # read iperf output and append it to the client list
    clientPortMap = getIperfClients.getIperfClients(resultIperf=resultIperf+"_client.txt",
      clientCount=clientCount, bandwidth=nmsBandwidth+'000',
      serverPort=serverPort)
    
    # add clients to list if clients where found
    if clientPortMap:
      info("+++ Adding clients to list\n")
      addClientsToList(clientListPath=CLIENTLISTPATH, clientPortMap=clientPortMap,
          instanceName=iperfName)
      
      if addConstraints:
        info("+++ Adding constraints to intents\n")
        # add constraints to intents
        initialiseConstraints.initialiseConstraints(clientPortMap=clientPortMap)
    else:
      info("### No clients found! Client port-map list empty!\nList: {}\n".format(clientPortMap))
    
    # wait until iperf client has finished measurement
    info("+++ Waiting for iperf client and server to finish\n")
    ct.join()
    st.join()
    
    # remove clients from client list
    info("+++ Remove iperf clients from clientList\n")
    removeClientsFromList(clientListPath=CLIENTLISTPATH, instanceName=iperfName)
    
    if addConstraints and clientPortMap:
      info("+++ Remove all intents created for this iPerf instance.\n")
      initialiseConstraints.removeIperfIntents(clientPortMap=clientPortMap)

  except pxssh.ExceptionPxssh, e:
    print "pxssh failed on login."
    print str(e)


if __name__ == '__main__':
  setLogLevel( 'info' )
  
  cmd='Usage:\n{} [-d <duration>] [-c <clientCount>] [-b <iperfBandwidthInKb>] \
	[-v <nmsBandwidthInKb>] [-p <iperfServerPort>] [-n <iperfInstanceName>] \
  [-r <iperfResultPath>] [-u] [-a]'.format(sys.argv[0])
  argv = sys.argv[1:]
  
  # parsing commandline arguments
  try:
    opts, args = getopt.getopt(argv,"d:c:r:b:v:n:p:ua",
		["duration=", "clientCount=", "resultIperf=", "bandwidth=", 
    "nmsBandwidth=", "iperfName=", "serverPort=", "addConstraints", "udp"])
  except getopt.GetoptError:
    print cmd
    sys.exit(2)
  
  # setting default values
  durationArg = '10'
  clientCountArg = '1'
  resultIperfArg = '/home/ubuntu/iperfResult'
  bandwidthArg = '200'
  nmsBandwidthArg = '200'
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
    elif opt in ("-v", "--nmsBandwidth"):
      nmsBandwidthArg = arg
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
      nmsBandwidth=nmsBandwidthArg, iperfName=iperfNameArg,
      serverPort=serverPortArg, addConstraints=addConstraintsArg,
      useUdp=useUdp)


