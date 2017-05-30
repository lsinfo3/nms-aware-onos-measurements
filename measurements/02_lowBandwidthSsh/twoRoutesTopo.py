"""Custom topology example

Two directly connected switches plus a host for each switch:

   host --- switch --- switch --- host

Adding the 'topos' dict with a key/value pair to generate our newly defined
topology enables one to pass in '--topo=mytopo' from the command line.
"""

from mininet.topo import Topo
from mininet.log import info


class TwoRoutes( Topo ):
    "Simple topology example."

    def __init__( self ):
      "Create custom topo."

      # Initialize topology
      Topo.__init__( self )
      
      hostsPerSide = 1

#     info( '*** Adding hosts\n' )
      HostList = []
      for i in range(1, 3):
        for j in range(1, hostsPerSide + 1):
          HostList.append(self.addHost( 'h' + str(i) + 'x' + str(j), ip='100.0.1.'\
          + str(i) + '0' + str(j) + '/24', mac='00:00:00:00:00:' + str(i) + str(j) ))

#     info( '*** Adding switches\n' )
      SwitchList = []
      for i in range(1, 5):
        SwitchList.append(self.addSwitch( 's' + str(i) ))
      

#     info( '*** Creating switch to switch links\n' )
      for i in range(4):
#       info( 'Adding Link between Switch[' + str(i+1) + '] and Switch[' + str((i+1)%4+1) + ']\n' )
        self.addLink(SwitchList[i], SwitchList[(i+1)%4])
#  	  self.addLink(SwitchList[0], SwitchList[2])

#      info( '*** Creating host to switch links\n' )
      for i in range(2):
        for j in range(hostsPerSide):
#  	      info( 'Adding Link between Host[' + str((i*hostsPerSide+j)+1) + '] and Switch[' + str(i*2+1) + ']\n' )
          self.addLink(HostList[i*hostsPerSide+j], SwitchList[i*2])

topos = { 'tworoutes': ( lambda: TwoRoutes() ) }
