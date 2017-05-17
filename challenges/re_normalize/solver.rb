require 'json'

# get cfg from r2:
# r2 -A -c 's main; agj' -q ren.x

cfg = JSON.parse($stdin.read)
bbs = cfg.select { |f| f["name"] == 'sym.main' }.first["blocks"]

goal = 0x113d0
from = 0x1117c
trace = [bbs.select { |bb| bb["offset"] == goal }.first]

until trace.first["offset"] == from
  trace.unshift(bbs.select { |bb| [bb["jump"],bb["fail"]].include? trace.first["offset"] }.first)
end

trace = trace[0..-2]
values = trace.map { |bb|
  mov = bb["ops"].select { |op| op["type"] == "mov" }.first
  xor = bb["ops"].select { |op| op["type"] == "xor" }.first
  cmp = bb["ops"].select { |op| op["type"] == "cmp" }.first

  offset = (mov["opcode"] =~ /local_([0-9a-f]+)h/) ? $~[1] : nil
  xor = (xor["opcode"] =~ /0x[0-9a-f]{2}/) ? $~[0] : nil
  cmp = (cmp["opcode"] =~ /0x[0-9a-f]{2}/) ? $~[0] : nil

  raise 'something zero' unless offset and xor and cmp

  [offset.to_i(16), xor.to_i(16) ^ cmp.to_i(16)]
}

puts values.sort_by(&:first).reverse.map { |offset, value| value.chr }.join
