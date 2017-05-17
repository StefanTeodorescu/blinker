#!/usr/bin/python2
# Source: http://ebfe.dk/ctf/2016/03/21/codegate_quals_serial/

import angr

# Adjust these as needed.
start =0x115b0
goal = 0x11705

p = angr.Project("./serial")

s = p.factory.blank_state(addr = start )
serial = s.se.BVS("serial", 32*8)
s.memory.store(0x6020BA, serial) # store some symbolic memory in the bss
s.regs.rdi = 0x6020BA # let the first arguemnt(rdi) point to it

pg = p.factory.path_group(s)
pg.explore(find = goal) # I want to go here now!

# Find out what to give as input to reach this state. (Solve it like a TI-89, please?)
print "Serial is: %r" % pg.found[0].state.se.any_str(serial).strip("\x00")
