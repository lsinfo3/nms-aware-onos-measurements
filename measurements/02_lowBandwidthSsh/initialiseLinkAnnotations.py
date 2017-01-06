#!/usr/bin/python

"""
Initialise the annotation of each link in the network
"""

from mininet.log import setLogLevel, info
from helpers import get, put, post, printDict
from json import dumps


LINKSURL='http://192.168.33.20:8181/onos/v1/network/configuration/links'

BANDWIDTH='bandwidth'
LATENCY='latency'

# iterate recursively through the json dictionary until the bandwidth
# key is found and set the value
# return the updated json dictionary
def setKey(dictionary, key, value, depth=0):

  result = {}
  for k,v in dictionary.items():
    if isinstance(v, dict):
      result[k] = setKey(v, key, value, depth+1)
    else:
      if k==key:
        v = value
      result[k] = v
  
  return result


# initialise the annotations of all ONOS links
def initialiseAnnotations(annotationMap):
  
  # get all links from ONOS as json
  linksDict = get(LINKSURL).json()
  
  # update each annotation values of the link dictionary
  for key,value in annotationMap.items():
    linksDict = setKey(linksDict, key, value)

  info('+++ New link configuration to POST:\n\n')
  printDict(linksDict)
  info('\n')
  
  # post the new link configuration to ONOS
  post(LINKSURL, dumps(linksDict))


if __name__ == '__main__':
  setLogLevel( 'info' )
  
  # bandwidth in bits
  # latency in milliseconds?
  allAnnotation = {BANDWIDTH: '1000000', LATENCY: '500'}
  bandwidth = {BANDWIDTH: '1000000'}
  latency = {LATENCY: '500'}
  
  initialiseAnnotations(bandwidth)
