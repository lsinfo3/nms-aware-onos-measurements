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
import subprocess

def sbyodTestingNetwork():
    "Create a topology with two host and four switch connected in form of a square"

    FIRST_CONTROLLER_IP='192.168.33.20'

    info('*** Creating Mininet object\n')
    net = Mininet( controller=RemoteController, switch=OVSSwitch, autoSetMacs=True )

    info( '*** Adding controller\n' )
    c0 = net.addController('c0', ip=FIRST_CONTROLLER_IP, port=6633 )

    info( '*** Adding hosts\n' )
    HostList = []
    for i in range(1, 3):
      for j in range(1, 4):
        HostList.append(net.addHost( 'h' + str(i) + 'x' + str(j), \
            ip='100.0.1.' + str(i) + '0' + str(j) + '/24', mac='00:00:00:00:00:' + str(i) + str(j) ))
    h1x1 = HostList[0]
    h1x2 = HostList[1]
    h1x3 = HostList[2]
    h2x1 = HostList[3]
    h2x2 = HostList[4]
    h2x3 = HostList[5]

    info( '*** Adding switches\n' )
    SwitchList = []
    for i in range(1, 5):
      SwitchList.append(net.addSwitch( 's' + str(i) ) )
    s1 = SwitchList[0]
    s2 = SwitchList[1]
    s3 = SwitchList[2]
    s4 = SwitchList[3]

    info( '*** Creating switch to switch links\n' )
    for i in range(4):
      info( 'Adding Link between Switch[' + str(i+1) + '] and Switch[' + str((i+1)%4+1) + ']\n' )
      net.addLink(SwitchList[i], SwitchList[(i+1)%4])
#    net.addLink(SwitchList[0], SwitchList[2])

    info( '*** Creating host to switch links\n' )
    for i in range(2):
      for j in range(3):
        info( 'Adding Link between Host[' + str((i*3+j)+1) + '] and Switch[' + str(i*2+1) + ']\n' )
        net.addLink(HostList[i*3+j], SwitchList[i*2])

    info( '*** Starting network\n' )
    net.build()
    c0.start()
    for i in range(4):
      SwitchList[i].start( [ c0 ] )

    info( '*** wait 5 seconds\n' )
    time.sleep(5)

#    info( '*** Adding delay to s4-eth1\n' )
#    s2.cmd('sudo tc qdisc add dev s2-eth1 root netem loss 50%')
#    s2.cmd('sudo tc qdisc add dev s2-eth2 root netem loss 50%')
#    s4.cmd('sudo tc qdisc add dev s4-eth1 root netem loss 50%')
#    s4.cmd('sudo tc qdisc add dev s4-eth2 root netem loss 50%')

    info( '*** Throttling maximum network rate to 100kbps for s2-eth1 and s4-eth1\n' )
    s2.cmd('tc qdisc add dev s2-eth1 root tbf rate 1mbit burst 10kb \
    latency 70ms peakrate 2mbit minburst 1540')
    s2.cmd('tc qdisc add dev s2-eth2 root tbf rate 1mbit burst 10kb \
    latency 70ms peakrate 2mbit minburst 1540')
    s4.cmd('tc qdisc add dev s4-eth1 root tbf rate 1mbit burst 10kb \
    latency 70ms peakrate 2mbit minburst 1540')
    s4.cmd('tc qdisc add dev s4-eth2 root tbf rate 1mbit burst 10kb \
    latency 70ms peakrate 2mbit minburst 1540')

#    info( '*** Printing flow rules of switch s4' )
#    proc = subprocess.Popen(['sudo', 'ovs-ofctl', 'dump-flows', 's4'], stdout=subprocess.PIPE)
#    for line in proc.stdout.readlines():
#      print line.rstrip()

    DURATION='20'
    INTERVAL='4'
    CLIENTS='8'

    info( '*** Running iperf between hosts for ' + DURATION + ' seconds\n' )
    h2x1.cmd('iperf -s -u -D')
#    h2x2.cmd('iperf -s -u -D')
#    h2x3.cmd('iperf -s -u -D')
    info(h1x1.cmd('iperf -c ' + h2x1.IP() + ' -u -b 10m -P ' + CLIENTS \
    + ' -t ' + DURATION + ' -i ' + INTERVAL + ' | tee iperf_test_1.txt'))
#    h1x1.cmd('iperf -c ' + h2x2.IP() + ' -u -b 100m -t ' + DURATION + ' &')
#    h1x1.cmd('iperf -c ' + h2x3.IP() + ' -u -b 100m -t ' + DURATION + ' &')
#    h1x2.cmd('iperf -c ' + h2x1.IP() + ' -u -b 100m -t ' + DURATION + ' &')
#    h1x2.cmd('iperf -c ' + h2x2.IP() + ' -u -b 100m -t ' + DURATION + ' &')
#    h1x2.cmd('iperf -c ' + h2x3.IP() + ' -u -b 100m -t ' + DURATION + ' &')
#    h1x3.cmd('iperf -c ' + h2x1.IP() + ' -u -b 100m -t ' + DURATION + ' &')
#    h1x3.cmd('iperf -c ' + h2x2.IP() + ' -u -b 100m -t ' + DURATION + ' &')
#    h1x3.cmd('iperf -c ' + h2x3.IP() + ' -u -b 100m -t ' + DURATION + ' &')

    CLI( net )

    info( '*** Stopping network\n' )
    info(h2x1.cmd('sudo killall iperf'))
#    s2.cmd('sudo tc qdisc del dev s2-eth1 root netem')
#    s2.cmd('sudo tc qdisc del dev s2-eth2 root netem')
#    s4.cmd('sudo tc qdisc del dev s4-eth1 root netem')
#    s4.cmd('sudo tc qdisc del dev s4-eth2 root netem')
    s2.cmd('sudo tc qdisc del dev s2-eth1 root')
    s4.cmd('sudo tc qdisc del dev s4-eth1 root')
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )
    sbyodTestingNetwork()
