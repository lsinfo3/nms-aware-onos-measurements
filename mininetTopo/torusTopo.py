#!/usr/bin/python

"torusTopo.py: Demo of Mininet TorusTopo"

from mininet.net import Mininet
from mininet.topolib import TorusTopo
from mininet.log import setLogLevel, info
from mininet.node import RemoteController, Controller, OVSSwitch
from mininet.cli import CLI


c0 = RemoteController('c0', ip='192.168.33.20', port=6633 )

class MultiSwitch( OVSSwitch ):
    "Custom Switch() subclass that connects to different controllers"
    def start( self, controllers ):
        return OVSSwitch.start( self, [ c0 ] )

def demo():

    topo = TorusTopo( x=3, y=3 )
    net = Mininet( switch=MultiSwitch, topo=topo, build=False )

    net.addController(c0)
    net.build()
    net.start()

    net.pingAll()
    h1x1 = net.getNodeByName('h1x1')
    h2x2 = net.getNodeByName('h2x2')
    result = net.iperf( hosts=[h1x1, h2x2])

    #info("h1x1" + result[0])
    #CLI( net )
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )
    demo()
