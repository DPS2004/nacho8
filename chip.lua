--ideally, this file is *entirely* separated from love2d.

local gchip = {}

function gchip.init(mode) -- make a new instance of chip8
  mode = mode or "common" -- define default mode.
  local chip = {}
  
  chip.pc = 0x200 -- the program counter
  chip.index = 0 -- index register
  
  chip.stack = {} -- stack for subroutines
  
  chip.screenupdated = true -- has a function that modifies the screen been called?
  
  chip.delay = 0 -- sound and delay timers
  chip.sound = 0
  
  chip.v = {}
  for i=0,15 do -- set up v0-vf
    chip.v[i] = 0
  end
  
  chip.mem = {}
  for i=0,4096 do -- set up memory
    chip.mem[i] = 0
  end
  
  local fontdata = { --font data from tobiasvl.github.io
    0xF0, 0x90, 0x90, 0x90, 0xF0,
    0x20, 0x60, 0x20, 0x20, 0x70,
    0xF0, 0x10, 0xF0, 0x80, 0xF0,
    0xF0, 0x10, 0xF0, 0x10, 0xF0,
    0x90, 0x90, 0xF0, 0x10, 0x10,
    0xF0, 0x80, 0xF0, 0x10, 0xF0,
    0xF0, 0x80, 0xF0, 0x90, 0xF0,
    0xF0, 0x10, 0x20, 0x40, 0x40,
    0xF0, 0x90, 0xF0, 0x90, 0xF0,
    0xF0, 0x90, 0xF0, 0x10, 0xF0,
    0xF0, 0x90, 0xF0, 0x90, 0x90,
    0xE0, 0x90, 0xE0, 0x90, 0xE0,
    0xF0, 0x80, 0x80, 0x80, 0xF0,
    0xE0, 0x90, 0x90, 0x90, 0xE0,
    0xF0, 0x80, 0xF0, 0x80, 0xF0,
    0xF0, 0x80, 0xF0, 0x80, 0x80
  }
  
  for i,v in ipairs(fontdata) do --load into memory starting at 0x050
    chip.mem[0x050+(i-1)] = v
  end
  
  chip.display = {}
  for x=0,63 do
    chip.display[x] = {}
    for y= 0,31 do
      chip.display[x][y] = false -- initialize all pixels to black
    end
  end
  
  function chip.decode(b1,b2)
    local c = rshift(band(b1,0xf0),4) -- first nibble, the instruction
    local x = band(b1,0x0f) -- second nibble, for a register
    local y = rshift(band(b2,0xf0),4) -- third nibble, for a register
    local n = band(b2,0x0f) -- fourth nibble, 4 bit number
    local nn = b2 -- second byte, 8 bit number
    local nnn = x*256 + b2 -- nibbles 2 3 and 4, 12 bits
  end
  
  function chip.update()
    
  end
  
  function chip.draw()
    
  end
  
  
  return chip
  
end


return gchip