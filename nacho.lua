local nacho = {}

function nacho.setup(dontusejit,bitops)
  if not dontusejit then
    local bit = require('bit')
    nacho.bit = {}
    
    nacho.bit.tobit = bit.tobit
    nacho.bit.tohex = bit.tohex
    
    nacho.bit.rol = bit.rol
    nacho.bit.ror = bit.ror
    
    nacho.bit.lshift = bit.lshift
    nacho.bit.rshift = bit.rshift
    
    nacho.bit.band = bit.band
    nacho.bit.bor = bit.bor
    nacho.bit.bxor = bit.bxor
    
    nacho.get = function(x,i)
      return string.sub(x,i+1,i+1)
    end
    
    nacho.gbit = function(byte,i)
      return (nacho.bit.band(nacho.bit.rshift(byte, i), 0x01)) == 1
    end
    
    nacho.binarystring = function(x,reverse)
      local t = {}
      for i = 0, 7 do
        if reverse then
          table.insert(t,1, nacho.bit.band(x, 0x01))
        else
          table.insert(t, nacho.bit.band(x, 0x01))
        end
        x = nacho.bit.ror(x, 1)
      end
      return table.concat(t)
    end
    
    
  else
    
  end

end
if not pr then
  pr = function() end
end
-- general utility functions go up here i guess?
function nacho.addleadings(x,n,f)
  n = n or 4
  f = f or '0'
  local r = tostring(x)
  local l = n-#r
  for i=1,l do
    r = f..r
  end
  return r
end

function nacho.init(mode,cmode,extras) -- make a new instance of chip8
  local chip = {}
  
  if extras then
    for k,v in pairs(extras) do
      chip[k] = v
    end
  end
  
  chip.dmp = function() end
  chip.dmpj = function() end
  chip.unk = function() end
  chip.spr = function() end
  
  if chip.dumper then
    chip.dump = {}
    chip.labels = {}
    chip.lcount = {}
    chip.sprites = {}
    
    chip.dmp = function(val,pos,og,length)
      
      pos = pos or (chip.pc - 2)
      og = og or nacho.bit.tohex(chip.mem[pos],2).. nacho.bit.tohex(chip.mem[pos+1],2)
      
      
      length = length or 2
      
      
      chip.dump[pos] = {length=length - 1,val=val,og=og,pos=pos}
    end
    chip.dmpj = function(txt,val,pos,pos2)
      if not chip.labels[val] then
        chip.labels[val] = {}
        chip.lcount[val] = 0
      end
      
      local lblholder = nil
      local lblname = nil
      
      for _,lb in pairs(chip.labels) do
        for k,v in pairs(lb) do
          if v.pos == pos then -- this label already exists!
            lblholder = _
            lblname = k
          end
        end
      end
      
      if lblname then
        
        
      else
      
        chip.lcount[val] = chip.lcount[val] + 1
        --haha what
        chip.labels[val][val..'_'..chip.lcount[val]] = {pos=pos}
        lblname = val..'_'..chip.lcount[val]
        chip.unk(pos)
      end
      txt = txt:gsub('#LBL#',lblname)
      chip.dmp(txt,pos2)
    end
    chip.spr = function(pos,h)
      local binstr = ''
      local bytestr = ''
      for dyi = 0,h-1 do 
        local sprbyte = chip.mem[chip.index+dyi] -- get byte from memory
        binstr = binstr .. nacho.binarystring(sprbyte,true) .. '\n'
        bytestr = bytestr .. nacho.bit.tohex(sprbyte,2)
      end
      binstr = binstr:gsub('0','.')
      binstr = binstr:gsub('1','#')
      if chip.sprites[pos] then
        if chip.sprites[pos].height >= h then
          return
        end
      end
      chip.dmp(binstr,pos,bytestr,h)
      chip.sprites[pos] = {height=h}
      
    end
    
    chip.unk = function(pos)
      if not chip.dump[pos] then -- don't overwrite a known with an unknown
        chip.dmp('unknown',pos)
      end
    end
  end
  
  chip.mode = mode or "common" -- define default mode.
  
  
  
  chip.modelist = {
    
    -- COMMON: the default mode, should work for most programs.
    common = {
      sw = 64, -- screen width
      sh = 32, -- screen height
      ips = 700, -- number of instructions to execute per second
      memsize = 4096, -- how many bytes of memory
      vyshift = false, --set vx to vy in 8xy6 and 8xye
      vxoffsetjump = false, -- false for bnnn, true for bxnn
      indexoverflow = true, -- true to set vf to 1 if index goes over 1000
      tempstoreload = true, -- set false to increment i for fx55 and fx65 instead of using a temporary variable
      waitforrelease = false, -- wait for the key to be released for fx0a
      dotimedupdate = false, -- set to true to emulate the vip cosmac's timing. overides ips.
      pagesize = 256, -- only used if timedupdate = true, this is just a guess!!
    },
    
    -- COSMAC VIP: The original. Use for super old programs.
    cosmac = {
      vyshift = true,
      indexoverflow = false, 
      tempstoreload = false,
      waitforrelease = true,
      dotimedupdate = true,
    },
    
    -- SUPER-CHIP: bigger screen res, and some other extra fun stuff.
    schip = {
      sw = 128,
      sh = 64,
    },
    
    -- BISQWIT: runs programs made by Bisqwit for his Chip-8 interpreter, found in this video https://www.youtube.com/watch?v=rpLoS7B6T94
    -- note: currently does not ;)
    bisqwit = {
    },
    
  }
  chip.cf = {}
  for k,v in pairs(chip.modelist.common) do
    chip.cf[k] = v
  end
 
  
  local ncf = nil
  if chip.mode == 'custom' then
    ncf = cmode
  else
    ncf = chip.modelist[chip.mode]
  end
  for k,v in pairs(ncf) do
    chip.cf[k] = v
  end
  
  chip.last = '0000'
  
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
  
  chip.microseconds = 0 --how many microseconds have elapsed
  
  chip.maxms = math.floor(1000000/60) --assuming 60fps for now
  
  function chip.ms(x,v,a,b)
    chip.microseconds = chip.microseconds + x
    
    if v then
      if b then
        if math.floor(a/chip.cf.pagesize) == math.floor(b/chip.cf.pagesize) then
          chip.microseconds = chip.microseconds - v
        else
          chip.microseconds = chip.microseconds + v
        end
      elseif a ~= nil then
        if a then
          chip.microseconds = chip.microseconds - v
        else
          chip.microseconds = chip.microseconds + v
        end
      else
        chip.microseconds = chip.microseconds + v
      end
    end
  end
  
  chip.screenupdated = true -- has a function that modifies the screen been called?
  
  chip.delay = 0 -- sound and delay timers
  chip.sound = 0
  
  chip.v = {}
  for i=0,15 do -- set up v0-vf
    chip.v[i] = 0
  end
  
  chip.mem = {}
  for i=0,chip.cf.memsize do -- set up memory
    chip.mem[i] = 0
  end
  
  local fontdata = { --font data from tobiasvl.github.io
    0xf0, 0x90, 0x90, 0x90, 0xf0,
    0x20, 0x60, 0x20, 0x20, 0x70,
    0xf0, 0x10, 0xf0, 0x80, 0xf0,
    0xf0, 0x10, 0xf0, 0x10, 0xf0,
    0x90, 0x90, 0xf0, 0x10, 0x10,
    0xf0, 0x80, 0xf0, 0x10, 0xf0,
    0xf0, 0x80, 0xf0, 0x90, 0xf0,
    0xf0, 0x10, 0x20, 0x40, 0x40,
    0xf0, 0x90, 0xf0, 0x90, 0xf0,
    0xf0, 0x90, 0xf0, 0x10, 0xf0,
    0xf0, 0x90, 0xf0, 0x90, 0x90,
    0xe0, 0x90, 0xe0, 0x90, 0xe0,
    0xf0, 0x80, 0x80, 0x80, 0xf0,
    0xe0, 0x90, 0x90, 0x90, 0xe0,
    0xf0, 0x80, 0xf0, 0x80, 0xf0,
    0xf0, 0x80, 0xf0, 0x80, 0x80
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
    chip.last = nacho.bit.tohex(b1,2).. nacho.bit.tohex(b2,2)
    pr('decoding '..chip.last)
    local c = nacho.bit.rshift(nacho.bit.band(b1,0xf0),4) -- first nibble, the instruction
    local x = nacho.bit.band(b1,0x0f) -- second nibble, for a register
    local y = nacho.bit.rshift(nacho.bit.band(b2,0xf0),4) -- third nibble, for a register
    local n = nacho.bit.band(b2,0x0f) -- fourth nibble, 4 bit number
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
        chip.dmp('clearscreen')
        chip.ms(109)
        
        pr('executing clear screen')
        for dx=0,#chip.display do
          for dy=0,#chip.display[dx] do
            chip.display[dx][dy] = false
          end
        end
        chip.screenupdated = true
        
      elseif nnn == 0x0ee then
        --return from subroutine
        pr('executing return from subroutine')
        chip.dmp('return')
        chip.ms(105,5,chip.pc,chip.peek())
        
        pr('pc has gone from '..chip.pc ..' to '..chip.peek())
        chip.pc = chip.pop()
      else
        print('unknown instruction!')
      end
    elseif c == 1 then
      -- jump
      pr('executing jump')
      chip.dmpj('jump(#LBL#)','jump',nnn)
      chip.ms(105,5,chip.pc,nnn)
      
      pr('pc has gone from '..chip.pc.. ' to '..nnn)
      chip.pc = nnn
      
    elseif c == 2 then
      -- go to subroutine
      pr('executing go to subroutine')
      chip.dmpj('goto(#LBL#)','goto',nnn)
      chip.ms(105,5,chip.pc,nnn)
      
      pr('pc has gone from '..chip.pc.. ' to '..nnn)
      chip.push(chip.pc)
      chip.pc = nnn
    elseif c == 3 then
      -- skip if equal
      pr('executing skip if equal')
      chip.dmp('if v'..x..' == '..nn..' then jump('..chip.pc+2 ..') --skip next')
      chip.unk(chip.pc)
      chip.unk(chip.pc+2)
      chip.ms(55,9,nn == chip.v[x])
      
      pr('nn is '..nn..', v'..x..' is ' .. chip.v[x])
      if nn == chip.v[x] then
        pr('pc has gone from '..chip.pc.. ' to '..chip.pc + 2)
        chip.pc = chip.pc + 2
      else
        pr('pc remains at '..chip.pc)
      end
    elseif c == 4 then
      -- skip if not equal
      pr('executing skip if not equal')
      chip.dmp('if v'..x..' != '..nn..' then jump('..chip.pc+2 ..') --skip next')
      chip.unk(chip.pc)
      chip.unk(chip.pc+2)
      chip.ms(55,9,nn ~= chip.v[x])
      
      pr('nn is '..nn..', v'..x..' is ' .. chip.v[x])
      if nn ~= chip.v[x] then
        pr('pc has gone from '..chip.pc.. ' to '..chip.pc + 2)
        chip.pc = chip.pc + 2
      else
        pr('pc remains at '..chip.pc)
      end
    elseif c == 5 then
      -- register skip if equal
      pr('executing register skip if equal')
      chip.dmp('if v'..x..' == v'..y..' then jump('..chip.pc+2 ..') --skip next')
      chip.unk(chip.pc)
      chip.unk(chip.pc+2)
      chip.ms(73,9,chip.v[x] == chip.v[y])
      
      pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
      if chip.v[x] == chip.v[y] then
        pr('pc has gone from '..chip.pc.. ' to '..chip.pc + 2)
        chip.pc = chip.pc + 2
      else
        pr('pc remains at '..chip.pc)
      end
    elseif c == 6 then
      -- set
      pr('executing set')
      chip.dmp('v'..x..' = '..nn)
      chip.ms(27)
      
      pr('v'..x..' has gone from '..chip.v[x] .. ' to '.. nn)
      chip.v[x] = nn
    elseif c == 7 then
      -- add
      pr('executing add')
      chip.dmp('v'..x..' += '..nn)
      chip.ms(45) 
      
      pr('v'..x..' has gone from '..chip.v[x] .. ' to '.. (chip.v[x] + nn) % 256)
      chip.v[x] = (chip.v[x] + nn) % 256
    elseif c == 8 then
      chip.ms(200)
      if n == 0 then
        -- register set
        pr('executing register set')
        chip.dmp('v'..x..' = v'..y)
      
        pr('setting v'..x..' from ' .. chip.v[x]..' to v'..y..', which is ' .. chip.v[y])
        chip.v[x] = chip.v[y]
      elseif n == 1 then
        --register or
        pr('executing register or')
        chip.dmp('v'..x..' = bor(v'..x..'v'..y..')')
        
        pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
        pr('setting v'..x..' to ' .. nacho.bit.bor(chip.v[x],chip.v[y]))
        chip.v[x] = nacho.bit.bor(chip.v[x],chip.v[y])
      elseif n == 2 then
        --register and
        pr('executing register and')
        chip.dmp('v'..x..' = band(v'..x..'v'..y..')')
        
        pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
        pr('setting v'..x..' to ' .. nacho.bit.band(chip.v[x],chip.v[y]))
        chip.v[x] = nacho.bit.band(chip.v[x],chip.v[y])
      elseif n == 3 then
        --register xor
        pr('executing register xor')
        chip.dmp('v'..x..' = bxor(v'..x..'v'..y..')')
        
        pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
        pr('setting v'..x..' to ' .. nacho.bit.bxor(chip.v[x],chip.v[y]))
        chip.v[x] = nacho.bit.bxor(chip.v[x],chip.v[y])
      elseif n == 4 then
        --register add
        pr('executing register add')
        chip.dmp('v'..x..' += v'..y)
        
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
        --register subtract
        pr('executing register subtract')
        chip.dmp('v'..x..' -= v'..y)
        
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
        --register shift right        
        pr('executing register shift right')
        
        local stradd = ''

        if chip.cf.vyshift then
          pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
          pr('setting v'..x..' to ' .. chip.v[y])
          chip.v[x] = chip.v[y]
          stradd = 'v'..x..' = v'..y..'\n'
        end
        
        chip.dmp(stradd..'v'..x..' = rshift(v'..x..', 1)')
        
        local shiftout = nacho.gbit(chip.v[x],0)
        pr('setting v'..x..' from '.. chip.v[x]..' to '..(nacho.bit.rshift(chip.v[x],1))%256)
        chip.v[x] = (nacho.bit.rshift(chip.v[x],1))%256
        if shiftout then
          chip.v[0xf] = 1
          pr('shifted out 1')
        else
          chip.v[0xf] = 0
          pr('shifted out 0')
        end
      elseif n == 7 then
        --register subtract, but like, the other way?
        pr('executing register subtract')
        chip.dmp('v'..x..' = v'..y..' - v'..x )
        
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
        --register left shift
        pr('executing register shift left')
        
        local stradd = ''
        
        if chip.cf.vyshift then
          pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
          pr('setting v'..x..' to ' .. chip.v[y])
          chip.v[x] = chip.v[y]
          stradd = 'v'..x..' = v'..y..'\n'
        end
        
        chip.dmp(stradd..'v'..x..' = lshift(v'..x..', 1')
        
        local shiftout = nacho.gbit(chip.v[x],7)
        pr('setting v'..x..' from '.. chip.v[x]..' to '..(nacho.bit.lshift(chip.v[x],1))%256)
        chip.v[x] = (nacho.bit.lshift(chip.v[x],1))%256
        if shiftout then
          chip.v[0xf] = 1
          pr('shifted out 1')
        else
          chip.v[0xf] = 0
          pr('shifted out 0')
        end
      end
    elseif c == 9 then
      -- register skip if not equal
      pr('executing register skip if not equal')
      chip.dmp('if v'..x..' != v'..y..' then jump('..chip.pc+2 ..') --skip next')
      chip.unk(chip.pc)
      chip.unk(chip.pc+2)
      chip.ms(73,9,chip.v[x] ~= chip.v[y])
      
      pr('v'..x..' is ' .. chip.v[x]..', v'..y..' is ' .. chip.v[y])
      if chip.v[x] ~= chip.v[y] then
        pr('pc has gone from '..chip.pc.. ' to '..chip.pc + 2)
        chip.pc = chip.pc + 2
      else
        pr('pc remains at '..chip.pc)
      end
    elseif c == 0xa then
      -- set index
      pr('executing set index')
      chip.dmp('index = '..nnn)
      chip.unk(nnn)
      chip.ms(55)
      
      pr('index has gone from '..chip.index .. ' to '.. nnn)
      chip.index = nnn
      
    elseif c == 0xb then
      -- offset jump
      pr('executing jump with offset')
      if not vxoffsetjump then
        chip.dmp('jump('..nnn..' + v0')
        chip.unk(nnn + chip.v[0])
        chip.ms(73,9,chip.pc,nnn+chip.v[0])
        
        pr('pc has gone from '..chip.pc.. ' to '..nnn .. ' + v0, ('..nnn..'+'..chip.v[0]..'=' .. nnn + chip.v[0] .. ')')
        chip.pc = nnn + chip.v[0]
      else
        chip.dmp('jump({'..x..'}'..y..n..' + v{'..x..'} -- {'..x..'} must be the same number')
        chip.unk(nnn + chip.v[x])
        chip.ms(73,9,chip.pc,nnn+chip.v[x])
        
        
        pr('pc has gone from '..chip.pc.. ' to '..nnn .. ' + v'..x..', ('..nnn..'+'..chip.v[x]..'=' .. nnn + chip.v[x] .. ')')
        chip.pc = nnn + chip.v[x]
      end
    elseif c == 0xc then
      -- random number
      pr('executing random number')
      chip.dmp('v'..x..' = band(random(0,255), '..nn..')')
      chip.ms(164)
      
      local rn = nacho.bit.band(math.random(0,255),nn)
      pr('setting v'..x..' from '.. chip.v[x]..' to '.. rn)
      chip.v[x] = rn
      
    elseif c == 0xd then
      -- display to screen (oh god)
      pr('executing draw at '..chip.v[x]..','..chip.v[y])
      chip.dmpj('draw(v'..x..', v'..y..', '..n..')','spr',chip.index)
      chip.spr(chip.index,n)
      chip.ms(22734,(n-8)*662) --this is my best guess, probably not be accurate
      
      local dx = chip.v[x] % chip.cf.sw
      local dy = chip.v[y] % chip.cf.sh
      chip.v[0xf] = 0 -- set vf to 0
      for dyi = 0,n-1 do -- iterate n times
        local sprbyte = chip.mem[chip.index+dyi] -- get byte from memory
        pr('drawing ' .. nacho.binarystring(sprbyte,true))
        for dxi=0,7 do -- iterate through the byte
          local val = nacho.gbit(sprbyte,7-dxi) -- get value of bit
          if dx+dxi < chip.cf.sw and dy+dyi < chip.cf.sh then --make sure we are in bounds
            if val  then
              if chip.display[dx+dxi][dy+dyi+1] then 
                chip.v[0xf] = 1
                chip.display[dx+dxi][dy+dyi+1] = false -- turn off pixel
              else
                chip.display[dx+dxi][dy+dyi+1] = true -- turn on pixel
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
        chip.dmp('if keydown(v'..x..') then jump('..chip.pc+2 ..') --skip next')
        chip.unk(chip.pc)
        chip.unk(chip.pc+2)
        
        
        pr('v'..x..' is'..nacho.bit.tohex(chip.v[x],1))
        if chip.keys then
          if chip.keys[chip.v[x]].down then
            pr('key '..nacho.bit.tohex(chip.v[x],1)..' is down')
            pr('pc has gone from '..chip.pc.. ' to '..chip.pc + 2)
            chip.pc = chip.pc + 2
            
            chip.ms(73,-9)
          else
            pr('key '..nacho.bit.tohex(chip.v[x],1)..' is not down')
            pr('pc remains at '..chip.pc)
            
            chip.ms(73,9)
          end
        else
          print('no key setup found! assuming that no keys are pressed.')
          pr('key '..nacho.bit.tohex(chip.v[x],1)..' is not down')
          pr('pc remains at '..chip.pc)
          
          chip.ms(73,9)
        end
        
      elseif nn == 0xa1 then
        --skip if key not down
        pr('executing skip if key not down')
        chip.dmp('if not keydown(v'..x..') then jump('..chip.pc+2 ..') --skip next')
        chip.unk(chip.pc)
        chip.unk(chip.pc+2)
        
        pr('v'..x..' is'..nacho.bit.tohex(chip.v[x],1))
        if chip.keys then
          if chip.keys[chip.v[x]].down then
            pr('key '..nacho.bit.tohex(chip.v[x],1)..' is down')
            pr('pc remains at '..chip.pc)
            
            chip.ms(73,-9)
          else
            pr('key '..nacho.bit.tohex(chip.v[x],1)..' is not down')
            pr('pc has gone from '..chip.pc.. ' to '..chip.pc + 2)
            chip.pc = chip.pc + 2
            
            chip.ms(73,9)
          end
        else
          print('no key setup found! assuming that no keys are pressed.')
          pr('key '..nacho.bit.tohex(chip.v[x],1)..' is not down')
          pr('pc has gone from '..chip.pc.. ' to '..chip.pc + 2)
          chip.pc = chip.pc + 2
          
          chip.ms(73,9)
        end
      end
    elseif c == 0xf then
      if nn == 0x07 then
        -- set register to delay
        pr('executing set register to delay')
        chip.dmp('v'..x..' = delay')
        chip.ms(45)

        pr('setting v'..x..' from '.. chip.v[x]..' to '.. chip.delay)
        chip.v[x] = chip.delay
      elseif nn == 0x0a then
        --wait for key
        pr('executing wait for key')
        chip.dmp('v'..x ..' = waitforkey')
        
        
        if chip.keys then
          local key = nil
          for k,v in pairs(chip.keys) do
            if chip.cf.waitforrelease then
              if v.released then
                key = k
              end
            else
              if v.pressed then
                key = k
              end
            end
          end
          if key then 
            pr('key '..key..' pressed, setting v'..x..' from '..chip.v[x]..' to '..key)
            chip.v[x] = key
          else
            chip.pc = chip.pc - 2
            pr('key not pressed, pc remains at '..chip.pc)
          end
        else
          print('no key setup found! assuming that no keys are pressed.')
          chip.pc = chip.pc - 2
          pr('key not pressed, pc remains at '..chip.pc)
        end
        
        if chip.cf.dotimedupdate then
          chip.microseconds = -1
        end
        
      elseif nn == 0x15 then
        -- set delay to register
        pr('executing set delay to resgister')
        chip.dmp('delay = v'..x)
        chip.ms(45)
        
        pr('setting delay from '.. chip.delay ..' to v'..x..', which is '..chip.v[x])
        chip.delay = chip.v[x]
      elseif nn == 0x18 then
        -- set sound timer to register
        pr('executing set sound timer to resgister')
        chip.dmp('sound = v'..x)
        chip.ms(45)
        
        pr('setting sound from '.. chip.sound ..' to v'..x..', which is '..chip.v[x])
        chip.sound = chip.v[x]
      elseif nn == 0x1e then
        -- index add
        pr('executing index add')
        chip.dmp('index += v'..x)
        
        pr('adding v'..x..'('..chip.v[x]..') to index ('..chip.index..') ('..chip.index..'+'..chip.v[x]..'='..(chip.index+chip.v[x])%4096 ..')')
        local newindex = chip.index+chip.v[x]
        if chip.cf.indexoverflow then
          if newindex >= 4096 then
            newindex = newindex % 4096
            pr('setting vf to 1 for overflow')
            chip.v[0xf] = 1
          end
        end
        chip.ms(86,14,chip.index,newindex)
        
        chip.index = newindex
      
      elseif nn == 0x29 then
        --get font character
        pr('executing get font character')
        chip.dmp('index = font(v'..x..')')
        chip.ms(91)
        
        pr('v'..x..' is ' .. nacho.bit.tohex(chip.v[x]))
        local newindex = 0x050 + nacho.bit.band(chip.v[x],0x0f)*5 --get character last nybble of vx
        pr('changing index from '..chip.index..' to ' .. nacho.bit.tohex(newindex) ..'(should be character '..nacho.bit.tohex(chip.v[x])..')')
        chip.index = newindex ---AAAAAAAAAAAA WHY DID THIS HAPPEN TWICE I SWEAR TO
      elseif nn == 0x33 then
        --decimal split
        pr('executing decimal split')
        
        chip.ms(364+(math.floor(num/(10^2))%10+math.floor(num/(10^1))%10+math.floor(num)%10)*73)
        -- the math doesn't check out *exactly*, but its whats on the page.
        
        local num = chip.v[x]
        pr('v'..x..' is ' .. num)
        pr('index is ' .. chip.index)
        
        pr('changing mem address '..chip.index+0 ..' from '..chip.mem[chip.index+0]..' to ' .. math.floor(num/(10^2))%10)
        pr('changing mem address '..chip.index+1 ..' from '..chip.mem[chip.index+1]..' to ' .. math.floor(num/(10^1))%10)
        pr('changing mem address '..chip.index+2 ..' from '..chip.mem[chip.index+2]..' to ' .. math.floor(num/(10^0))%10)
        chip.mem[chip.index+0] = math.floor(num/(10^2))%10
        chip.mem[chip.index+1] = math.floor(num/(10^1))%10
        chip.mem[chip.index+2] = math.floor(num/(10^0))%10
        
        
      elseif nn == 0x55 then
        --store memory
        pr('executing store to memory')
        chip.dmp('for i=0,'..x..' do mem[index + i] = vi')
        
        chip.ms(64*(x+1))
        
        pr('storing from v0 to v'..x..', starting at mem address '..chip.index)
        for i=0,x do
          pr('changing memory '..chip.index+i ..' from '..chip.mem[chip.index+i]..' to v'..i..', which is '..chip.v[i])
          chip.mem[chip.index+i] = chip.v[i]
        end
        
        if not chip.cf.tempstoreload then
          pr('changing index from '..chip.index..' to ' .. chip.index + x + 1)
          chip.index = chip.index + x + 1
        end
        
      elseif nn == 0x65 then
        --read memory
        pr('executing read from memory')
        chip.dmp('for i=0,'..x..' do vi = mem[index + i]')
        
        chip.ms(64*(x+1))
        
        pr('reading from mem address '..chip.index ..' to '..chip.index+x..' and storing in v0 to v'..x)
        for i=0,x do
          pr('changing v'..i..' from '..chip.v[i]..' to mem '..chip.index+i..', which is '..chip.mem[chip.index+i])
          chip.v[i] = chip.mem[chip.index+i]
        end
        
        if not chip.cf.tempstoreload then
          pr('changing index from '..chip.index..' to ' .. chip.index + x + 1)
          chip.index = chip.index + x + 1
        end
        
      end
    else
      print('!!!!!!!!!!!!!!!!!unknown instruction!!!!!!!!!!!!!!!!!!!!')
    end
  end
  
  function chip.timerdec()
    pr('updating timers')
    if chip.delay > 0 then
      chip.delay = chip.delay - 1
    end
    if chip.sound > 0 then
      chip.sound = chip.sound - 1
      if chip.beep then
        chip.beep()
      else
        print('BEEEEP!')
      end
    end
      
  end
  
  function chip.update()
    --fetch 
    local b1,b2 = chip.mem[chip.pc],chip.mem[chip.pc+1]
    chip.pc = chip.pc + 2 -- increment pc
    local c,x,y,n,nn,nnn = chip.decode(b1,b2) -- decode the two bytes
    chip.execute(c,x,y,n,nn,nnn) -- interpret the decoded bytes
  end
  
  function chip.timedupdate()
    -- microsecond timing values from
    chip.microseconds = 0 
    local opsrun = 0
    while (chip.microseconds < chip.maxms) and (chip.microseconds >= 0) do
      chip.update()
      opsrun = opsrun + 1
    end
    return opsrun
  end
  
  function chip.savedump()
    if chip.dumper then
      local dstring = ''
      local lines = {}
      for k,v in pairs(chip.dump) do
        table.insert(lines,k)
      end
      table.sort(lines)
      local sorted = {}
      
      
        
      
      for i,line in ipairs(lines) do
        local op = chip.dump[line]
        
        local lblname = nil
        
        for _,lb in pairs(chip.labels) do
          for k,v in pairs(lb) do
            if v.pos == op.pos then
              lblname = k
            end
          end
        end
        
        if lblname then
          dstring = dstring .. '::'..lblname..'::\n'
        end
        dstring = dstring .. nacho.addleadings(op.pos) .. '-' .. nacho.addleadings(op.pos+op.length) .. ': ' .. op.og .. '\n'
        dstring = dstring .. op.val .. '\n\n'
      end
      return dstring
      
      
    end
  end
  
  
  return chip
  
end


return nacho