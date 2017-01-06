#!/usr/bin/python

"""
BYOD example topology
"""

from mininet.net import Mininet
from mininet.node import RemoteController, Controller, OVSSwitch
from mininet.topolib import TreeTopo
from mininet.cli import CLI
from mininet.log import setLogLevel, info
import time

def sbyodTestingNetwork():
    "Create a two host, three switch network with two controllers"


    info('*** Creating Mininet object\n')
    net = Mininet( controller=RemoteController, switch=OVSSwitch, autoSetMacs=True )

    info( '*** Adding controller\n' )
    # net.addController( 'c0', controller=RemoteController, ip="0.0.0.0", port=6633 )
    c0 = net.addController('c0', ip='192.168.33.11', port=6633 )
    c1 = net.addController('c1', ip='192.168.33.12', port=6633 )

    info( '*** Adding hosts\n' )
    h1 = net.addHost( 'h1', ip='10.1.0.101' )
    h2 = net.addHost( 'h2', ip='10.1.0.102' )
    HostList = (h1,h2)

    info( '*** Adding switches\n' )
    s1 = net.addSwitch( 's1' )
    s2 = net.addSwitch( 's2' )
    s3 = net.addSwitch( 's3' )
    SwitchList = (s1,s2,s3)

    info( '*** Creating switch to switch links\n' )
    net.addLink('s1', 's2')
    net.addLink('s1', 's3')

    info( '*** Creating host to switch links\n' )
    net.addLink('h1', 's1')
    net.addLink('h2', 's2')
    net.addLink('h2', 's3')

    info( '*** Starting network\n')
    net.build()
    c0.start()
    c1.start()
    s1.start( [ c0 ] )
    s2.start( [ c1 ] )
    s3.start( [ c1 ] )

    info( '*** Running CLI\n' )
    CLI( net )

    info( '*** Stopping network' )
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )
    sbyodTestingNetwork()
