-- This project aims to be very commented.
-- It is based on https://tobiasvl.github.io/blog/write-a-chip-8-emulator/



function love.load() -- called once at the very start of execution
  
  function pr(x) 
    if cf.chatty then -- helper function to print only if its asked for
      print(x)
    end
  end
  
  bit = require('bit') -- load LuaJIT's bitwise library
  tb = bit.tobit -- define shortcuts from bit library
  th = bit.tohex
  lshift = bit.lshift
  rshift = bit.rshift
  band = bit.band
  function get(x,i)
    return string.sub(x,i+1,i+1)
  end
  gchip = require('chip') -- load the chip8 interpreter
  
  function loadtochip(file,chip) --load a file into chip8's memory
    local contents, size = love.filesystem.read(file)
    pr('loading file:')
    for i=1,size do
      local byte = string.byte(string.sub(contents,i,i))
      pr(th(byte))
      chip.mem[0x200+(i-1)] = byte
      
    end
    return chip
  end
  
  chip = gchip.init() -- init chip 8
  chip = loadtochip(cf.file,chip) --load file defined in conf.lua
  
  
  
  love.window.setMode(cf.sw*cf.scale, cf.sh*cf.scale, {resizable=true}) -- set the love2d window size to that of the config
  
  
  
  
  
end

function love.update()
  
end

function love.draw()

end