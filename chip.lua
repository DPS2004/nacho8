--ideally, this file is *entirely* separated from love2d.

local gchip = {}

function gchip.init(mode,cmode) -- make a new instance of chip8
  local chip = {}
  
  chip.mode = mode or "common" -- define default mode.
  
  chip.modelist = {
    common = {
      sw = 64, -- screen width
      sh = 32, -- screen height
      vyshift = true, --set vx to vy in 8xy6 and 8xye
      vxoffsetjump = false -- false for bnnn, true for bxnn
    },
    schip = {
      sw = 128, -- screen width
      sh = 64, -- screen height
      vyshift = false, --set vx to vy in 8xy6 and 8xye
      vxoffsetjump = true -- false for bnnn, true for bxnn
    }
  }
  
  if chip.mode == 'custom' then
    chip.cf = cmode
  else
    chip.cf = chip.modelist[chip.mode]
  end
  
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
  for x=0,chip.cf.sw-1 do
    chip.display[x] = {}
    for y= 0,chip.cf.sh-1 do
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
      end
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
    elseif c == 3 then
      pr('executing skip if equal')
      pr('nn is '..nn..', v'..x..' is ' .. chip.v[x])
      -- skip if equal
      if nn == chip.v[x] then
        pr('pc has gone from '..chip.pc.. ' to '..chip.pc + 2)
        chip.pc = chip.pc + 2
      else
        pr('pc remains at '..chip.pc)
      end
    elseif c == 4 then
      pr('executing skip if not equal')
      pr('nn is '..nn..', v'..x..' is ' .. chip.v[x])
      -- skip if not equal
      if nn ~= chip.v[x] then
        pr('pc has gone from '..chip.pc.. ' to '..chip.pc + 2)
        chip.pc = chip.pc + 2
      else
        pr('pc remains at '..chip.pc)
      end
    elseif c == 5 then
      pr('executing register skip if equal')
      pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
      -- register skip if equal
      if chip.v[x] == chip.v[y] then
        pr('pc has gone from '..chip.pc.. ' to '..chip.pc + 2)
        chip.pc = chip.pc + 2
      else
        pr('pc remains at '..chip.pc)
      end
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
    elseif c == 8 then
      if n == 0 then
        pr('executing register set')
        pr('setting v'..x..' from ' .. chip.v[x]..' to v'..y..', which is ' .. chip.v[y])
        chip.v[x] = chip.v[y]
      elseif n == 1 then
        pr('executing register or')
        pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
        pr('setting v'..x..' to ' .. bor(chip.v[x],chip.v[y]))
        chip.v[x] = bor(chip.v[x],chip.v[y])
      elseif n == 2 then
        pr('executing register or')
        pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
        pr('setting v'..x..' to ' .. band(chip.v[x],chip.v[y]))
        chip.v[x] = band(chip.v[x],chip.v[y])
      elseif n == 3 then
        pr('executing register xor')
        pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
        pr('setting v'..x..' to ' .. bxor(chip.v[x],chip.v[y]))
        chip.v[x] = bxor(chip.v[x],chip.v[y])
      elseif n == 4 then
        pr('executing register add')
        pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
        pr('setting v'..x..' to ' .. (chip.v[x] + chip.v[y]))
        chip.v[x] = (chip.v[x] + chip.v[y])
        if chip.v[x] > 256 then
          chip.v[x] = chip.v[x] % 256
          pr('setting vf to 1 for overflow')
          chip.v[0xf] = 1
        else
          pr('setting vf to 0')
          chip.v[0xf] = 0
        end
      elseif n == 5 then
        pr('executing register subtract')
        pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
        pr('setting v'..x..' to ' .. (chip.v[x] - chip.v[y]))
        chip.v[x] = (chip.v[x] - chip.v[y])
        
        if chip.v[x] < 0 then
          chip.v[x] = chip.v[x] % 256
          pr('setting vf to 0 for underflow')
          chip.v[0xf] = 1
        else
          pr('setting vf to 1')
          chip.v[0xf] = 0
        end
      elseif n == 6 then
        pr('executing register shift right')
        if chip.cf.vyshift then
          pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
          pr('setting v'..x..' to ' .. chip.v[y])
          chip.v[x] = chip.v[y]
        end
        
        local shiftout = gbit(chip.v[x],0)
        pr('setting v'..x..' from '.. chip.v[x]..' to '..rshift(chip.v[x],1))
        chip.v[x] = rshift(chip.v[x],1)
        if shiftout then
          chip.v[0xf] = 1
          pr('shifted out 1')
        else
          chip.v[0xf] = 1
          pr('shifted out 0')
        end
      elseif n == 7 then
        pr('executing register subtract')
        pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
        pr('setting v'..x..' to ' .. (chip.v[y]-chip.v[x]))
        chip.v[x] = (chip.v[y]-chip.v[x])
        if chip.v[x] < 0 then
          chip.v[x] = chip.v[x] % 256
          pr('setting vf to 0 for underflow')
          chip.v[0xf] = 1
        else
          pr('setting vf to 1')
          chip.v[0xf] = 0
        end
      elseif n == 0xe then
        pr('executing register shift left')
        if chip.cf.vyshift then
          pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
          pr('setting v'..x..' to ' .. chip.v[y])
          chip.v[x] = chip.v[y]
        end
        
        local shiftout = gbit(chip.v[x],7)
        pr('setting v'..x..' from '.. chip.v[x]..' to '..lshift(chip.v[x],1))
        chip.v[x] = lshift(chip.v[x],1)
        if shiftout then
          chip.v[0xf] = 1
          pr('shifted out 1')
        else
          chip.v[0xf] = 1
          pr('shifted out 0')
        end
      end
    elseif c == 9 then
      pr('executing register skip if not equal')
      pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
      -- register skip if not equal
      if chip.v[x] ~= chip.v[y] then
        pr('pc has gone from '..chip.pc.. ' to '..chip.pc + 2)
        chip.pc = chip.pc + 2
      else
        pr('pc remains at '..chip.pc)
      end
    elseif c == 0xa then
      pr('executing set index')
      pr('index has gone from '..chip.index .. ' to '.. nnn)
      -- set index
      chip.index = nnn
    elseif c == 0xb then
      pr('executing jump with offset')
      -- offset jump
      if not vxoffsetjump then
        pr('pc has gone from '..chip.pc.. ' to '..nnn .. ' + v0, ('..nnn..'+'..chip.v[0]..'=' .. nnn + chip.v[0] .. ')')
        chip.pc = nnn + chip.v[0]
      else
        pr('pc has gone from '..chip.pc.. ' to '..nnn .. ' + v'..x..', ('..nnn..'+'..chip.v[x]..'=' .. nnn + chip.v[x] .. ')')
        chip.pc = nnn + chip.v[x]
      end
    elseif c == 0xc then
      pr('executing random number')
      local rn = band(math.random(0,255),nn)
      pr('setting v'..x..' from '.. chip.v[x]..' to '.. rn)
      chip.v[x] = rn
      -- random number
      
    elseif c == 0xd then
      pr('executing draw at '..chip.v[x]..','..chip.v[y])
      -- display to screen (oh god)
      local dx = chip.v[x] % chip.cf.sw
      local dy = chip.v[y] % chip.cf.sh
      chip.v[0xf] = 0 -- set vf to 0
      for dyi = 0,n-1 do -- iterate n times
        local sprbyte = chip.mem[chip.index+dyi] -- get byte from memory
        pr('drawing ' .. binarystring(sprbyte,true))
        for dxi=0,7 do -- iterate through the byte
          local val = gbit(sprbyte,7-dxi) -- get value of bit
          if dx+dxi < chip.cf.sw and dy+dyi < chip.cf.sh then --make sure we are in bounds
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
    elseif c == 0xe then
      
      if nn == 0x9e then
        --skip if key down
        pr('executing skip if key down')
        if chip.keys[x].down then
          pr('key '..x..' is down')
          pr('pc has gone from '..chip.pc.. ' to '..chip.pc + 2)
          chip.pc = chip.pc + 2
        else
          pr('key '..x..' is not down')
        end
        
      elseif nn == 0xa1 then
        --skip if key not down
        pr('executing skip if key not down')
        if chip.keys[x].down then
          pr('key '..x..' is down')
        else
          pr('key '..x..' is not down')
          pr('pc has gone from '..chip.pc.. ' to '..chip.pc + 2)
          chip.pc = chip.pc + 2
        end
      end
    else
      print('!!!!!!!!!!!!!!!!!unknown instruction!!!!!!!!!!!!!!!!!!!!')
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