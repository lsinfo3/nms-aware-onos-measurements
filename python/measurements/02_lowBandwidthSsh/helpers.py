#!/usr/bin/python

"""
Shortcuts for the requests package
"""

import requests
from mininet.log import setLogLevel, info


USER='karaf'
PASSWORD='karaf'

def get(url):
  response = requests.get(url, auth=(USER, PASSWORD))
  if response.status_code != 200:
    info('+++ ApiError')
    info('GET /tasks/ {}'.format(response.status_code))
    print(response)
  return response

def post(url, data):
  response = requests.post(url, data=data, auth=(USER, PASSWORD))
  if response.status_code != 200:
    info('+++ ApiError')
    info('POST /tasks/ {}'.format(response.status_code))
    print(response)
  return response

def put(url, data):
  response = requests.put(url, data=data, auth=(USER, PASSWORD))
  if response.status_code != 201:
    info('+++ ApiError')
    info('POST /tasks/ {}'.format(response.status_code))
    print(response)
  return response
  
def delete(url):
  response = requests.delete(url, auth=(USER, PASSWORD))
  if response.status_code != 204:
    info('+++ ApiError')
    info('DELETE /tasks/ {}'.format(response.status_code))
    print(response)
  return response


def printDict(d,depth=0):
  
  if isinstance(d, list):
    info( ("  ")*depth + "[\n" )
    for item in d:
      printDict(item,depth+1)
    info( ("  ")*depth + "]\n" )
  else:
    for k,v in d.items():
      if isinstance(v, dict):
        info( ("  ")*depth + ("%s:" % k) + " {\n" )
        printDict(v,depth+1)
        info( ("  ")*depth + "}\n" )
      elif isinstance(v, list):
        info( ("  ")*depth + ("%s:" % k) + " [\n" )
        for item in v:
          printDict(item, depth+1)
        info( ("  ")*depth + "]\n" )
      else:
        info( ("  ")*depth + "%s: %s\n" % (k, v) )
