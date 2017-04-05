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
def countConnections(activeConnections, controllerConnections, annotationType, switchCapacityPath):
  
  switchCount = {}
  
  # check if a file with default values exists
  if os.path.isfile(switchCapacityPath):
    # load the default values of the switches
    f = open(switchCapacityPath, 'r')
    switchCapacityJson = json.load(f)
    f.close()
    
    # TODO: check if annotation type is set!
    
    # count for every device
    for deviceId in controllerConnections:
      
      # define the start value
      switchCount[deviceId] = switchCapacityJson[deviceId][annotationType]
      # info("setting default switch count for switch {} to {}.\n".format(deviceId, switchCapacityJson[deviceId][annotationType]))
      
      # go through every active connection
      for activeConnection in activeConnections:
        
        # check if the connection is on current device
        connection = {'src': int(activeConnection['src']), 'dst': int(activeConnection['dst'])}
        # info("Is {} in {}?\n".format(connection, controllerConnections[deviceId]))
        
        if connection in controllerConnections[deviceId]:
          #info("It is. Removing {} from {}.\n".format(activeConnection[annotationType], switchCount[deviceId]))
          switchCount[deviceId] -= int(activeConnection[annotationType])
    
  else:
    # count for every device
    for deviceId in controllerConnections:
      # start value
      switchCount[deviceId] = 0
      # go through every active connection
      for activeConnection in activeConnections:
        # check if the connection is on current device
        connection = {'src': int(activeConnection['src']), 'dst': int(activeConnection['dst'])}
        if connection in controllerConnections[deviceId]:
          switchCount[deviceId] += int(activeConnection[annotationType])

  # do not allow negative values
  for deviceId in switchCount:
    if switchCount[deviceId] < 0:
      switchCount[deviceId] = 0
  
  return switchCount


# update link annotations of controller
def updateLinkAnnotations(linkUrl, switchCount, annotationType, alwaysUpdate=False):
  
  # TODO: use 'onos/v1/links' instead!
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
        # info("+++ link {} is connected to switch {}\n".format(linkId, switchId))
        # only update if the config has changed or alwaysUpdate flag ist true
        if (linkConfig['basic'][annotationType] != switchCount[switchId]) | alwaysUpdate:
          # info("+++ config has changed\n")
          # update the bandwidth
          linkConfig['basic'][annotationType] = switchCount[switchId]
          # store new  link config
          newLinks[linkId] = linkConfig
        else:
          # info("+++ config has NOT changed\n")
          pass
  
  # update the links on the controller
  post(linkUrl, json.dumps(newLinks))


# set the default value for the link annotation
def resetLinkAnnotations(linkUrl, annotationType, switchCapacityPath):
  
  # get the links from the controller
  linksJson = get(linkUrl).json()
  
  newLinks = {}
  
  # check if a file with default values exists
  if os.path.isfile(switchCapacityPath):
    # load the default values of the switches
    f = open(switchCapacityPath, 'r')
    switchCapacityJson = json.load(f)
    f.close()
    
    # TODO: check if annotation type is set!
    
    # go through every link
    for linkId in linksJson:
      # get the link config
      linkConfig = linksJson[linkId]
      for deviceId in switchCapacityJson:
        if deviceId in linkId:
          defaultValue = switchCapacityJson[deviceId][annotationType]
          if linkConfig['basic'][annotationType] != defaultValue:
            # update the bandwidth
            linkConfig['basic'][annotationType] = defaultValue
            # save new config
            newLinks[linkId] = linkConfig
  else:
    # go through every link
    for linkId in linksJson:
      # get the link config
      linkConfig = linksJson[linkId]
      if linkConfig['basic'][annotationType] != 0:
        # update the bandwidth
        linkConfig['basic'][annotationType] = 0
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
    
    #info("Active Connections:\n")
    #printDict(activeConnections)
    
    # only update if there are active connections
    if activeConnections:
      # get the relevant connections from the controller
      controllerConnections = {}
      for deviceId in [DEVICEID2, DEVICEID4]:
        controllerConnections[deviceId] = getFlows(deviceId, FLOWURL)
    
      # count the bandwidth of the active connections for each switch
      switchCount = countConnections(activeConnections, controllerConnections,
          annotationType='bandwidth',
          switchCapacityPath='/home/ubuntu/python/measurements/02_lowBandwidthSsh/switchCapacity.txt')
    
      info("SwitchCount:\n")
      printDict(switchCount)
      
      # update the annotations of the controller
      updateLinkAnnotations(LINKURL, switchCount, annotationType='bandwidth', alwaysUpdate=True)
      
    # no connections -> set link annotation to default value
    else:
      info("No connections. Set link annotation to default value.\n")
      resetLinkAnnotations(linkUrl=LINKURL, annotationType='bandwidth',
          switchCapacityPath='/home/ubuntu/python/measurements/02_lowBandwidthSsh/switchCapacity.txt')
    
    endTime = time.time()
    
    timeDiff = endTime - startTime
    info("Updated config. Took {} seconds.\n\n".format(timeDiff))
    if timeDiff > interval:
      info("Warning: Update process takes longer than the repetition interval")
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
