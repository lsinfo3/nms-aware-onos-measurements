#!/usr/bin/python

"""
Test the functionality of the sys.argv variable
"""

from mininet.log import setLogLevel, info
import sys, getopt


if __name__ == '__main__':
  setLogLevel( 'info' )
  argv = sys.argv[1:]
  print 'Argvalues: {}'.format(argv)
  
  #if not "-c" in argv and not "--controllerIp" in argv:
  #  print 'test.py -c <controllerIp>'
  #  sys.exit(2)
  
  print any(x in ["-c", "--controllerIp", "-h"] for x in argv)
  print [x for x in ["-c", "--controllerIp", "-h"] if x in argv]
  
  controllerIp = ''

  try:
    opts, args = getopt.getopt(argv,"hc:",["controllerIp="])
  except getopt.GetoptError:
    print 'test.py -c <controllerIp>'
    sys.exit(2)
  
  for opt, arg in opts:
      if opt == '-h':
         print 'test.py -c <controllerIp>'
         sys.exit()
      elif opt in ("-c", "--controllerIp"):
         controllerIp = arg
  
  print 'Controller IP is {}'.format(controllerIp)
  print 'Opts is {}'.format(opts)
  print 'Rest of argv is {}'.format(str(args))
  
  
