#!/usr/bin/python

"""
Creating topology with 8 clients where
every client has an ssh server running
"""

from mininet.net import Mininet
from mininet.node import Node, RemoteController, Controller, OVSSwitch
from mininet.topolib import TreeTopo
from mininet.cli import CLI
from mininet.log import setLogLevel, info
from mininet.link import Intf
from twoRoutesTopo import TwoRoutes
from mininet.util import waitListening

import sys, time, subprocess, getopt



def restrictBandwidth( net ):
  
  s2 = net.switches[1]
  s4 = net.switches[3]
  
  info( '*** Throttling maximum network rate to 1000kbps for switch s2 and s4\n' )
  s2.cmd('tc qdisc add dev s2-eth1 root tbf rate 1mbit burst 10kb \
    latency 70ms peakrate 2mbit minburst 1540')
  s2.cmd('tc qdisc add dev s2-eth2 root tbf rate 1mbit burst 10kb \
    latency 70ms peakrate 2mbit minburst 1540')
  s4.cmd('tc qdisc add dev s4-eth1 root tbf rate 1mbit burst 10kb \
    latency 70ms peakrate 2mbit minburst 1540')
  s4.cmd('tc qdisc add dev s4-eth2 root tbf rate 1mbit burst 10kb \
    latency 70ms peakrate 2mbit minburst 1540')


def restoreBandwidth( net ):
  
  s2 = net.switches[1]
  s4 = net.switches[3]
  
  info( '*** Restoring bandwidth rate for switch s2 and s4\n' )
  s2.cmd('sudo tc qdisc del dev s2-eth1 root netem')
  s2.cmd('sudo tc qdisc del dev s2-eth2 root netem')
  s4.cmd('sudo tc qdisc del dev s4-eth1 root netem')
  s4.cmd('sudo tc qdisc del dev s4-eth2 root netem')


def connectToRootNS( network, switch, ip, routes ):
    """Connect hosts to root namespace via switch. Starts network.
      network: Mininet() network object
      switch: switch to connect to root namespace
      ip: IP address for root namespace node
      routes: host networks to route to"""
    # Create a node in root namespace and link to switch 0
    root = Node( 'root', inNamespace=False )
    intf = network.addLink( root, switch ).intf1
    root.setIP( ip, intf=intf )
    # Start network that now includes link to root namespace
    network.start()
    # Add routes from root ns to hosts
    for route in routes:
        root.cmd( 'route add -net ' + route + ' dev ' + str( intf ) )


def sshd( network, cmd='/usr/sbin/sshd', opts='-D',
          ip='10.123.123.1/32', routes=None, switch=None ):
    """Start a network, connect it to root ns, and run sshd on all hosts.
       ip: root-eth0 IP address in root namespace (10.123.123.1/32)
       routes: Mininet host networks to route to (10.0/24)
       switch: Mininet switch to connect to root namespace (s1)"""
    if not switch:
        switch = network[ 's1' ]  # switch to use
    if not routes:
        routes = [ '100.0.1.0/24' ]
    connectToRootNS( network, switch, ip, routes )
    for host in network.hosts:
        host.cmd( cmd + ' ' + opts + '&' )
    info( "*** Waiting for ssh daemons to start\n" )
    for server in network.hosts:
        waitListening( server=server, port=22, timeout=5 )

    info( "\n*** Hosts are running sshd at the following addresses:\n" )
    for host in network.hosts:
        info( host.name, host.IP(), '\n' )
        
    restrictBandwidth( network )
    
    info( "\n*** Type 'exit' or control-D to shut down network\n" )
    CLI( network )
    for host in network.hosts:
        host.cmd( 'kill %' + cmd )
    
    restoreBandwidth( network )
    
    network.stop()


def sbyodTestingNetwork( controllerIp, args ):
    """Create a topology, run an ssh client on every host and restrict
    the bandwidth of the two central routers"""

#   Create Mininet object and add remote controller
    net = Mininet( topo=TwoRoutes(), controller=None, switch=OVSSwitch )
    c0 = RemoteController('c0', ip=controllerIp, port=6633 )
    net.addController(c0)
    
    # run ssh script
    # get sshd args from the command line or use default args
    # useDNS=no -u0 to avoid reverse DNS lookup timeout
    argvopts = ' '.join( args ) if len( args ) > 0 else (
        '-D -o UseDNS=no -u0' )
    sshd( net, opts=argvopts, ip='100.0.1.1/32' )


#    info( '*** Printing flow rules of switch s4' )
#    proc = subprocess.Popen(['sudo', 'ovs-ofctl', 'dump-flows', 's4'], stdout=subprocess.PIPE)
#    for line in proc.stdout.readlines():
#      print line.rstrip()


if __name__ == '__main__':
    setLogLevel( 'info' )
    
    cmd='Usage:\n{} -c <controllerIp> [sshdArguments]'.format(sys.argv[0])
    argv = sys.argv[1:]
    
    # check mandatory arguments
    if not any(x in ["-c", "--controllerIp", "-h"] for x in argv):
      print cmd
      sys.exit(2)
    
    # parsing commandline arguments
    try:
      opts, args = getopt.getopt(argv,"hc:",["controllerIp="])
    except getopt.GetoptError:
      print cmd
      sys.exit(2)
    
    controllerIp = ''

    for opt, arg in opts:
      if opt == '-h':
        print cmd
        sys.exit()
      elif opt in ("-c", "--controllerIp"):
        sbyodTestingNetwork( controllerIp=arg, args=args )
