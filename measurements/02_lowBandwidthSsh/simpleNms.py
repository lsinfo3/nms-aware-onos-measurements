#!/usr/bin/python

"""
A simple Network Management System
reading connection information from a text file and applying them
to the network controller
"""

from mininet.log import setLogLevel, info
from helpers import get, post, printDict
from urllib import quote
import json, time, sys, getopt, os.path


DEVICEID2 = 'of:0000000000000002'
DEVICEID4 = 'of:0000000000000004'
FLOWURL = 'http://192.168.33.20:8181/onos/v1/flows/'
LINKURL = 'http://192.168.33.20:8181/onos/v1/network/configuration/links'
SRCPORT = 'UDP_SRC'
DSTPORT = 'UDP_DST'


# open file and read the connection information in json format
def readConnectionInformation(filePath):
  
  if os.path.isfile(filePath):
    # open file and load json
    f = open(filePath, 'r')
    iperfInstancesJson = json.load(f)
    f.close()
    
    # create list of all connections
    connections = []
    for iperfInstance in iperfInstancesJson:
      connectionsJson = iperfInstancesJson[iperfInstance]
      for connectionId in connectionsJson:
        connections.append(connectionsJson[connectionId])
    
    return connections
  else:
    return []


def getFlows(deviceId, flowUrl):
  
  # get installed flows from controller
  flowsJson = get(flowUrl + quote(deviceId, safe='')).json()
  
  # go through every flow
  connectionList = []
  for flowJson in flowsJson['flows']:
    selector = flowJson['selector']
    
    # save the udp's connection src and dst port
    connection = {}
    for criteria in selector['criteria']:
      if criteria['type'] == SRCPORT:
        connection['src'] = criteria['udpPort']
        # print SRCPORT + ': {}'.format(criteria['udpPort'])
      if criteria['type'] == DSTPORT:
        connection['dst'] = criteria['udpPort']
        # print DSTPORT + ': {}'.format(criteria['udpPort'])
    
    # if the connection dict has two elements
    if len(connection.keys()) == 2:
      connectionList.append(connection)
    
  return connectionList


# count the bandwidth of the active connections for each switch
def countConnections(activeConnections, controllerConnections):
  
  switchCount = {}
  # count for every device
  for deviceId in controllerConnections:
    switchCount[deviceId] = 0
    # go through every active connection
    for activeConnection in activeConnections:
      # check if the connection is on current device
      connection = {'src': int(activeConnection['src']), 'dst': int(activeConnection['dst'])}
      if connection in controllerConnections[deviceId]:
        switchCount[deviceId] += int(activeConnection['bandwidth'])
  
  return switchCount


# update link annotations of controller
def updateLinkAnnotations(linkUrl, switchCount, annotationType):
  
  # get the links from the controller
  linksJson = get(linkUrl).json()
  
  newLinks = {}
  # go through every link
  for linkId in linksJson:
    # annotate for every switch
    for switchId in switchCount:
      # check if link is connected to switch
      if switchId in linkId:
        # get the link config
        linkConfig = linksJson[linkId]
        info("+++ link {} is connected to switch {}\n".format(linkId, switchId))
        # only update if the config has changed
        if linkConfig['basic'][annotationType] != switchCount[switchId]:
          info("+++ config has changed\n")
          # update the bandwidth
          linkConfig['basic'][annotationType] = switchCount[switchId]
          # save new config
          newLinks[linkId] = linkConfig
        else:
          info("+++ config has NOT changed\n")
  
  # update the links on the controller
  post(linkUrl, json.dumps(newLinks))


# set the default value for the link annotation
def resetLinkAnnotations(linkUrl, defaultValue, annotationType):
  
  # get the links from the controller
  linksJson = get(linkUrl).json()
  
  newLinks = {}
  # go through every link
  for linkId in linksJson:
    # get the link config
    linkConfig = linksJson[linkId]
    if linkConfig['basic'][annotationType] != defaultValue:
      # update the bandwidth
      linkConfig['basic'][annotationType] = defaultValue
      # save new config
      newLinks[linkId] = linkConfig
  
  # update the links on the controller
  post(linkUrl, json.dumps(newLinks))


# manage network
def manage(interval):
  
  # cycle through the update process
  while 1:
    
    startTime = time.time()
    info("Updating config at {}.\n".format(int(startTime)))
    # get the active connections
    activeConnections = readConnectionInformation('/home/ubuntu/clientList.txt')
    
    # only update if there are active connections
    if activeConnections:
      # get the relevant connections from the controller
      controllerConnections = {}
      for deviceId in [DEVICEID2, DEVICEID4]:
        controllerConnections[deviceId] = getFlows(deviceId, FLOWURL)
    
      # count the bandwidth of the active connections for each switch
      switchCount = countConnections(activeConnections, controllerConnections)
    
      print 'SwitchCount:'
      printDict(switchCount)
      
      # update the annotations of the controller
      updateLinkAnnotations(LINKURL, switchCount, annotationType='bandwidth')
      
    # no connections -> set link annotation to default value
    else:
      info("No connections. Set link annotation to default value.\n")
      resetLinkAnnotations(linkUrl=LINKURL, defaultValue=0, annotationType='bandwidth')
    
    endTime = time.time()
    
    timeDiff = endTime - startTime
    info("Updated config. Took {} seconds.\n\n".format(timeDiff))
    if timeDiff > interval:
      info("Warning: Updated process takes longer than the repetition interval")
    else:
      try:
        time.sleep(interval - timeDiff)
      except KeyboardInterrupt:
        print('\n\nKeyboard exception received. Exiting.')
        exit()


if __name__ == '__main__':
  setLogLevel( 'info' )
  
  cmd='Usage:\n{} [-i <interval>]'.format(sys.argv[0])
  argv = sys.argv[1:]
  
  # parsing commandline arguments
  try:
    opts, args = getopt.getopt(argv,"i:",["interval="])
  except getopt.GetoptError:
    print cmd
    sys.exit(2)
    
  intervalArg = ''
  
  # set command line arguments
  for opt, arg in opts:
    if opt == '-h':
      print cmd
      sys.exit()
    elif opt in ("-i", "--interval"):
      intervalArg = arg
  
  # setting default values if no other was defined
  if intervalArg=='':
    intervalArg='30'
  
  manage(int(intervalArg))