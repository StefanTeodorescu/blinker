#!/usr/bin/python

import os
import sys
import json
import signal
from time import sleep
from random import SystemRandom

from mininet.topolib import TreeTopo
from mininet.nodelib import LinuxBridge
from mininet.net import Mininet

class SimpleTopo(TreeTopo):
  def __init__(self, *args, **params):
    sr = SystemRandom()
    self.prefix = str(sr.randrange(10000, 99999))+'-'
    TreeTopo.__init__(self, *args, **params)

  def addTree(self, depth, fanout):
    isSwitch = depth > 0
    if isSwitch:
      node = self.addSwitch( '%ss%s' % (self.prefix, self.switchNum) )
      self.switchNum += 1
      for _ in range( fanout ):
        child = self.addTree( depth - 1, fanout )
        self.addLink( node, child )
    else:
      node = self.addHost( '%sh%s' % (self.prefix, self.hostNum) )
      self.hostNum += 1
    return node

sudo_user = os.environ['SUDO_USER']

if sudo_user == None or os.getuid() != 0:
  print("Please run as root via sudo.")
  exit(1)

cfg = json.loads(sys.stdin.read())

procs = []

topo = SimpleTopo(depth=1, fanout=len(cfg['hosts']))
net = Mininet(topo=topo, switch=LinuxBridge, controller=None)

for i,host in enumerate(cfg['hosts']):
  h = net['{}h{}'.format(topo.prefix,i+1)]
  h.setIP(host['ip'], cfg['mask'])
  host['mn'] = h

net.start()

tcpdumps = []

for i,host in enumerate(cfg['hosts']):
  if host['capture']:
    proc = host['mn'].popen(['/bin/sh', '-c', 'tcpdump -w h{}.pcap -Z {} >tcpdump-h{}.output 2>&1'.format(i+1, sudo_user, i+1)])
    tcpdumps.append(proc)
    print('tcpdump on h{} is pid {}'.format(i+1, proc.pid))

for i,host in enumerate(cfg['hosts']):
  prelude = 'cd {}; exec 0<&- 1>h{}.output 2>&1; '.format(os.getcwd(), i+1)
  proc = host['mn'].popen(['/bin/su', '-c', prelude + host['command'], '-l', sudo_user])
  print('command on h{} is pid {} (command: {})'.format(i+1, proc.pid, host['command']))
  procs.append(proc)

kill = False
while not kill:
  for p in procs:
    if p.poll() != None:
      print('pid {} exited with return code {}'.format(p.pid, p.returncode))
      kill = True
      break

sleep(3)

for p in tcpdumps:
  if p.returncode == None:
    print('terminating pid {}'.format(p.pid))
    os.kill(p.pid, signal.SIGTERM)
    while p.poll() == None:
      sleep(0.3)
    print('terminated pid {}'.format(p.pid))

for p in procs:
  if p.returncode == None:
    print('terminating pid {}'.format(p.pid))
    os.kill(p.pid, signal.SIGTERM)
    i = 0
    while i < 20 and p.poll() == None:
      sleep(0.3)
      i+=1
    if p.poll() == None:
      print('KILLing pid {}'.format(p.pid))
      os.killpg(p.pid, signal.SIGKILL)
    print('terminated pid {}'.format(p.pid))

net.stop()
