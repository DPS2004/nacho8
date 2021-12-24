local gchip = {}

function gchip:init(self,mode) -- make a new instance of chip8
  mode = mode or "common" -- define default mode.
  local chip = {}
  
  chip.pc = 0 -- the program counter
  
  chip.stack = {} -- stack for subroutines
  
  chip.delay = 0 -- sound and delay timers
  chip.sound = 0
  
  chip.v = {}
  for i=0,15 do --set up v0-vf
    chip.v[i] = 0
  end
  
  return chip
  
end


return gchip