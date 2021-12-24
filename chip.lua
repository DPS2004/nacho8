--ideally, this file is *entirely* separated from love2d.

local gchip = {}

function gchip.init(mode) -- make a new instance of chip8
  mode = mode or "common" -- define default mode.
  local chip = {}
  
  chip.pc = 0x200 -- the program counter
  chip.index = 0 -- index register
  
  chip.stack = {} -- stack for subroutines
  
  function chip.push(x) --push to stack
    table.insert(chip.stack,x)
  end
  
  function chip.pop() -- pop from stack
    return table.remove(chip.stack)
  end
  
  function chip.peek() -- look at last item in stack
    return chip.stack[#chip.stack]
  end
  
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
    pr('decoding '..th(b1,2)..th(b2,2))
    local c = rshift(band(b1,0xf0),4) -- first nibble, the instruction
    local x = band(b1,0x0f) -- second nibble, for a register
    local y = rshift(band(b2,0xf0),4) -- third nibble, for a register
    local n = band(b2,0x0f) -- fourth nibble, 4 bit number
    local nn = b2 -- second byte, 8 bit number
    local nnn = x*256 + b2 -- nibbles 2 3 and 4, 12 bits
    return c,x,y,n,nn,nnn
  end
  
  function chip.execute(c,x,y,n,nn,nnn)
    -- technically this doesnt have to be separate from the decode,
    -- but it's good practice for more complicated systems.
    if c == 0 then
      if nnn == 0x0e0 then
        -- clear screen
        pr('executing clear screen')
        for dx=0,#chip.display do
          for dy=0,#chip.display[dx] do
            chip.display[dx][dy] = false
          end
        end
        chip.screenupdated = true
      elseif nnn == 0x0ee then
        pr('executing return from subroutine')
        pr('pc has gone from '..chip.pc ..' to '..chip.peek())
        --return from subroutine
        chip.pc = chip.pop()
      else
        print('unknown instruction!')
    elseif c == 1 then
      pr('executing jump')
      pr('pc has gone from '..chip.pc.. ' to '..nnn)
      -- jump
      chip.pc = nnn
    elseif c == 2 then
      pr('executing go to subroutine')
      pr('pc has gone from '..chip.pc.. ' to '..nnn)
      -- go to subroutine
      chip.push(chip.pc)
      chip.pc = nnn
    elseif c == 6 then
      pr('executing set')
      pr('v'..x..' has gone from '..chip.v[x] .. ' to '.. nn)
      -- set
      chip.v[x] = nn
    elseif c == 7 then
      -- add
      pr('executing add')
      pr('v'..x..' has gone from '..chip.v[x] .. ' to '.. (chip.v[x] + nn) % 256)
      chip.v[x] = (chip.v[x] + nn) % 256
    elseif c == 0xa then
      pr('executing set index')
      pr('index has gone from '..chip.index .. ' to '.. nnn)
      -- set index
      chip.index = nnn
    elseif c == 0xd then
      pr('executing draw at '..chip.v[x]..','..chip.v[y])
      -- display to screen (oh god)
      local dx = chip.v[x] % 64
      local dy = chip.v[y] % 32
      chip.v[0xf] = 0 -- set vf to 0
      for dyi = 0,n-1 do -- iterate n times
        local sprbyte = chip.mem[chip.index+dyi] -- get byte from memory
        pr('drawing ' .. binarystring(sprbyte,true))
        for dxi=0,7 do -- iterate through the byte
          local val = gbit(sprbyte,7-dxi) -- get value of bit
          if dx+dxi < 64 and dy+dyi < 32 then --make sure we are in bounds
            if val  then
              if chip.display[dx+dxi][dy+dyi] then 
                chip.v[0xf] = 1
                chip.display[dx+dxi][dy+dyi] = false -- turn off pixel
              else
                chip.display[dx+dxi][dy+dyi] = true -- turn on pixel
              end
            end
          end
        end
      end
      chip.screenupdated = true
    else
      print('unknown instruction!')
    end
  end
  
  function chip.update()
    --fetch 
    local b1,b2 = chip.mem[chip.pc],chip.mem[chip.pc+1]
    chip.pc = chip.pc + 2 -- increment pc
    local c,x,y,n,nn,nnn = chip.decode(b1,b2) -- decode the two bytes
    chip.execute(c,x,y,n,nn,nnn) -- interpret the decoded bytes
  end
  
  
  return chip
  
end


return gchip