local gchip = {}

function gchip:init(self) -- make a new instance of chip8
  local chip = {}
  
  chip.pc = 0 --the program counter
  
  return chip
  
end


return gchip