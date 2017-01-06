#!/usr/bin/python

"""
BYOD example topology
"""

from mininet.net import Mininet
from mininet.node import RemoteController, Controller, OVSSwitch
from mininet.topolib import TreeTopo
from mininet.cli import CLI
from mininet.log import setLogLevel, info
from mininet.link import Intf

import time

def sbyodTestingNetwork():
    "Create the left topology, with one host and one switch connected via tunnel to two other switches"

    LEFT_IP='192.168.33.10'
    RIGHT_IP='192.168.33.11'
    FIRST_CONTROLLER_IP='192.168.33.20'

    info('*** Creating Mininet object\n')
    net = Mininet( controller=RemoteController, switch=OVSSwitch, autoSetMacs=True )

    info( '*** Adding controller\n' )
    c0 = net.addController('c0', ip=FIRST_CONTROLLER_IP, port=6633 )

    info( '*** Adding hosts\n' )
    h1 = net.addHost( 'h1', ip='100.0.1.101/24', mac='00:00:00:00:00:01' )
    h2 = net.addHost( 'h2', ip='100.0.1.102/24', mac='00:00:00:00:00:02' )
    HostList = (h1, h2)

    info( '*** Adding switches\n' )
    s1 = net.addSwitch( 's1' )
    SwitchList = (s1)

    info( '*** Creating host to switch links\n' )
    net.addLink('h1', 's1')
    net.addLink('h2', 's1')

    info( '*** Creating GRE tunnel from s1 to 192.168.33.11\n' )
    # open vSwitch built in GRE tunnel
    # s1.cmd('ovs-vsctl add-port s1 s1-gre1 -- set interface s1-gre1 type=gre options:remote_ip='+RIGHT_IP)
    # s1.cmd('ovs-vsctl show')

    # linux GRE tunnel
    s1.cmd('ip link add s1-gre1 type gretap local '+LEFT_IP+' remote '+RIGHT_IP+' ttl 255')
    s1.cmd('ip link set dev s1-gre1 up')
    s1.cmd('ip addr add 100.0.1.1 dev s1-gre1')
    s1.cmd('ip route add 100.0.1.0/24 dev s1-gre1')
    Intf( 's1-gre1', node=s1 )

    info( '*** Starting network\n')
    net.build()
    c0.start()
    s1.start( [ c0 ] )

    info( '*** Running CLI\n' )
    CLI( net )

    info( '*** Stopping network' )
    # s1.cmd('ip link set s1-gre1 down')
    # s1.cmd('ip tunnel del s1-gre1')
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )
    sbyodTestingNetwork()
