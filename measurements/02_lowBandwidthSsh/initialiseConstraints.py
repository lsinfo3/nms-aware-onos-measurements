#!/usr/bin/python

"""
Manage the network links by annotation
"""

from mininet.log import setLogLevel, info
from urllib import quote
from helpers import get, put, post
import json


INTENTURL='http://192.168.33.20:8181/onos/v1/intents'

CLIENTCOUNT='8'
RESULTPATH='/home/ubuntu/iperf_test_1.txt'

ADVCONST = '{\"key\": \"bandwidth\", \
\"threshold\": 200000, \
\"isUpperLimit\": false, \
\"type\": \"AdvancedAnnotationConstraint\"}'
LATCONST = '{\"latencyNanos\": 13000, \
\"type\": \"LatencyConstraint\"}'


# reads iperf result file
# returns a map of all clients and their transport protocol source port
def clientsOfIperf(iperfResultFile, clientCount):
  
  f = open(iperfResultFile, 'r')
  
  # skip first 5 lines
  for i in range(5):
    f.readline()

  clientPortMap = {}
  # read next number of "clientCount" lines
  for line in range(int(clientCount)):
    words = f.readline().split()
    # client Number
    num = words[1]
    num = num[:-1] # remove closing bracket ']'
    # source port Number of client
    port = words[5]
    clientPortMap[num] = port

  f.close()
  return clientPortMap


# gather the intent keys of the iperf clients
# returns a map of intentKey and appId
def findIperfIntents(intentsMap, clientPortMap, iperfDestPort='5001'):
  
  # resulting relevant intent keys mapped to the corresponding appId
  relevantIntentKeyMap = {}
  # list of only the source tp ports
  ports = list(clientPortMap.values())
  
  # iterrate through all intents
  for intent in intentsMap['intents']:
    # get the key and appId of the intent
    key = intent['key']
    appId = intent['appId']
    # check if the key contains the iperf tp destination port string
    if iperfDestPort in key:
      # check for every iperf source port if the key contains it
      for srcport in ports:
        if srcport in key:
          # map the matching key with its appId
          relevantIntentKeyMap[key] = appId
  
  return relevantIntentKeyMap


# add constraint to intent with matching intentKey and appId
def addConstraint(appId, intentKey, newConstraint):
  
  # get the intent as json containing the constraints
  # (quote masks the intent key as html)
  intentDict = get(INTENTURL + "/" + appId + "/" + quote(intentKey, safe='')).json()
  constraintList = intentDict['constraints']
  
  # remove the old constraint from the list if existing
  for constraint in constraintList:
    if constraint['type'] == newConstraint['type']:
      constraintList.remove(constraint)
  
  # add new constraint
  constraintList.append(newConstraint)
  # update constraints in intent
  intentDict['constraints'] = constraintList
  
  # PUT new intent json file to ONOS
  put(INTENTURL, json.dumps(intentDict))


def initaliseConstraints():
  
  # get all installed intents in json
  response = get(INTENTURL)
  
  # get iperf connections: mapping id to source transport protocol port
  clientPortMap = clientsOfIperf(RESULTPATH, CLIENTCOUNT)
  info("+++ Client Port Map:\n")
  print(str(clientPortMap) + "\n")
  
  # gather the intent keys of the iperf clients
  iperfIntentKeyMap = findIperfIntents(response.json(), clientPortMap)
  
  info("+++ iperf intents updated:\n")
  # add desired constraint to the intents
  for intentKey, appId in iperfIntentKeyMap.items():
    addConstraint(appId, intentKey, json.loads(LATCONST))
    print(str(intentKey))


if __name__ == '__main__':
  setLogLevel( 'info' )
  initaliseConstraints()
