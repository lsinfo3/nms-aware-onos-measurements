#!/usr/bin/python
# Copyright 2012 William Yu
# wyu@ateneo.edu
#
from mininet.net import Mininet
from mininet.node import Controller, OVSKernelSwitch, RemoteController
from mininet.cli import CLI
from mininet.log import setLogLevel, info
# from mininet.util import createLink

def createDoubleControllerNetwork():
    info( '*** Creating network for Double Controller Example\n' )

    FIRST_CTR='192.168.33.20'
    SECOND_CTR='192.168.33.21'
    H0_IP='192.168.1.10'
    H1_IP='192.168.1.11'
    H2_IP='192.168.1.12'
    H3_IP='192.168.1.13'
    hostIps=(H0_IP, H1_IP, H2_IP, H3_IP)
    H0_MAC='00:00:00:00:00:10'
    H1_MAC='00:00:00:00:00:11'
    H2_MAC='00:00:00:00:00:12'
    H3_MAC='00:00:00:00:00:13'
    hostMacs=(H0_MAC, H1_MAC, H2_MAC, H3_MAC)

    # Create an empty network.
    net = Mininet( controller=RemoteController, switch=OVSKernelSwitch)
    c0 = net.addController('c0', ip='192.168.33.20', port=6633)
    c1 = net.addController('c1', ip='192.168.33.21', port=6633)

    # Creating nodes in the network.
    h0 = net.addHost('h0', ip=hostIps[0], mac=hostMacs[0])
    h1 = net.addHost('h1', ip=hostIps[1], mac=hostMacs[1])
    s0 = net.addSwitch('s0')
    h2 = net.addHost('h2', ip=hostIps[2], mac=hostMacs[2])
    h3 = net.addHost('h3', ip=hostIps[3], mac=hostMacs[3])
    s1 = net.addSwitch('s1')

    # Creating links between nodes in network.
    net.addLink(h0, s0)
    net.addLink(h1, s0)
    net.addLink(h2, s1)
    net.addLink(h3, s1)
    net.addLink(s0, s1)

    # Start network
    net.build()

    # Attaching Controllers to Switches
    c0.start()
    c1.start()
    s0.start([c0])
    s1.start([c1])

    # Setting interface only routes and not default routes
    # s0.cmd("route del -net 0.0.0.0")
    # s1.cmd("route del -net 0.0.0.0")
    # h0.cmd("route del -net 0.0.0.0")
    # h1.cmd("route del -net 0.0.0.0")
    # h2.cmd("route del -net 0.0.0.0")
    # h3.cmd("route del -net 0.0.0.0")
    # s0.cmd("route add -net 192.168.1.0 netmask 255.255.255.0 s0-eth3")
    # s1.cmd("route add -net 192.168.1.0 netmask 255.255.255.0 s1-eth3")
    # h0.cmd("route add -net 192.168.1.0 netmask 255.255.255.0 h0-eth0")
    # h1.cmd("route add -net 192.168.1.0 netmask 255.255.255.0 h1-eth0")
    # h2.cmd("route add -net 192.168.1.0 netmask 255.255.255.0 h2-eth0")
    # h3.cmd("route add -net 192.168.1.0 netmask 255.255.255.0 h3-eth0")

    # Adding ARP table entries to each host
    h0.cmd("arp -s " + hostIps[2] + " " + hostMacs[2] + " -i h0-eth0")
    h0.cmd("arp -s " + hostIps[3] + " " + hostMacs[3] + " -i h0-eth0")
    h1.cmd("arp -s " + hostIps[2] + " " + hostMacs[2] + " -i h1-eth0")
    h1.cmd("arp -s " + hostIps[3] + " " + hostMacs[3] + " -i h1-eth0")
    h2.cmd("arp -s " + hostIps[0] + " " + hostMacs[0] + " -i h2-eth0")
    h2.cmd("arp -s " + hostIps[1] + " " + hostMacs[1] + " -i h2-eth0")
    h3.cmd("arp -s " + hostIps[0] + " " + hostMacs[0] + " -i h3-eth0")
    h3.cmd("arp -s " + hostIps[1] + " " + hostMacs[1] + " -i h3-eth0")

    # dump stuff on the screen
    info( '*** Network state:\n' )
    for node in c0, c1, s0, s1, h0, h1, h2, h3:
        info( str( node ) + '\n' )

    # Start command line
    CLI(net)

    # Stop network
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )
    createDoubleControllerNetwork()
