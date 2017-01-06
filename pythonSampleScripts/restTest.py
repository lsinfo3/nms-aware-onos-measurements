#!/usr/bin/python

import requests
from mininet.log import info
from pprint import pprint

resp = requests.get('http://192.168.33.20:8181/onos/v1/links', auth=('karaf', 'karaf'))
if resp.status_code != 200:
  info('ApiError')
  # raise ApiError('GET /tasks/ {}'.format(resp.status_code))
# print(resp.text)
for obj in resp.json():
  pprint('{}'.format(obj))
  for link in resp.json()[obj]:
    pprint('{}'.format(link))
