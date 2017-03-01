#!/usr/bin/python

"""
Manage the network links by annotation
"""

from mininet.log import setLogLevel, info
from urllib import quote
from helpers import get, put, post
import getIperfClients
import json, time


INTENTURL='http://192.168.33.20:8181/onos/v1/intents'

CLIENTCOUNT='8'
RESULTPATH='/home/ubuntu/iperf_test_1.txt'

ADVCONST = '{\"key\": \"bandwidth\", \
\"threshold\": 200000, \
\"isUpperLimit\": false, \
\"type\": \"AdvancedAnnotationConstraint\"}'
LATCONST = '{\"latencyNanos\": 13000, \
\"type\": \"LatencyConstraint\"}'


# gather the intent keys of the iperf clients
# returns a map of intentKey and appId
def findIperfIntents(intentsMap, clientPortMap):
  
  # resulting relevant intent keys mapped to the corresponding appId
  relevantIntentKeyMap = {}
  
  # iperf server port
  iperfServerPort = clientPortMap.values()[1]['dst']
  # list of only the source tp ports
  iperfClientPorts = []
  for clientInfo in clientPortMap.values():
    iperfClientPorts.append(clientInfo['src'])
  
  # iterrate through all intents
  for intent in intentsMap['intents']:
    # get the key and appId of the intent
    key = intent['key']
    appId = intent['appId']
    # print("Intent: " + str(intent) + ", Key: " + str(key) + ", appId: " + str(appId) + "\n")
    # print("Is iperf server port="+str(iperfServerPort)+" in IntentKey="+str(key)+"?\n")
    
    # check if the key contains the iperf tp destination port string
    if iperfServerPort in key:
      # print("Iperf server port="+str(iperfServerPort)+" is in IntentKey="+str(key)+"!\n")
      # check for every iperf source port if the key contains it
      for iperfClientPort in iperfClientPorts:
        if iperfClientPort in key:
          # print("Iperf client port="+str(iperfClientPort)+" is in IntentKey="+str(key)+"\n")
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


def initialiseConstraints(clientPortMap):
  
  # info("+++ Client Port Map:\n")
  # print(str(clientPortMap) + "\n")
  
  # map of the corresponding iperf intents of onos
  iperfIntentKeyMap = {}
  # run loop until all intents are provisioned
  while len(iperfIntentKeyMap) < len(clientPortMap):
    
    # get all installed intents in ONOS as json
    response = get(INTENTURL)
    # print("All Intents:" + str(response.json()) + "\n")
    
    # gather the intent keys of the iperf clients
    iperfIntentKeyMap = findIperfIntents(response.json(), clientPortMap)
    # print("Iperf Intent Key Map" + str(iperfIntentKeyMap) + "\n")
    try:
        time.sleep(1)
    except KeyboardInterrupt:
      print('\n\nKeyboard exception received. Exiting.')
      exit()
  
  # info("+++ iperf intents updated:\n")
  # add desired constraint to the intents
  bandwidth=clientPortMap.values()[1]['bandwidth']
  advConstraint = json.loads(ADVCONST)
  advConstraint["threshold"] = bandwidth
  for intentKey, appId in iperfIntentKeyMap.items():
    # info("Intent: " + str(intentKey) + ", Constraint: " + str(advConstraint) + "\n")
    addConstraint(appId, intentKey, advConstraint)


if __name__ == '__main__':
  setLogLevel( 'info' )
  
  clientPortMap = getIperfClients.getIperfClients(resultIperf=RESULTPATH, clientCount=int(CLIENTCOUNT),
      bandwidth='200000', serverPort='5001')
  initialiseConstraints(clientPortMap)
