-- This project aims to be very commented.
-- It is based on https://tobiasvl.github.io/blog/write-a-chip-8-emulator/



function love.load() -- called once at the very start of execution
  
  function pr(x) 
    if prgconf.chatty then -- helper function to print only if its asked for
      print(x)
    end
  end
  
  lovebird = require('lovebird/lovebird') -- load lovebird debugging library
  bit = require('bit') -- load LuaJIT's bitwise library
  tb = bit.tobit -- define shortcuts from bit library
  th = bit.tohex
  rol = bit.rol
  ror = bit.ror
  lshift = bit.lshift
  rshift = bit.rshift
  band = bit.band
  bor = bit.bor
  bxor = bit.bxor
  function get(x,i)
    return string.sub(x,i+1,i+1)
  end
  function gbit(byte,i)
    return (band(rshift(byte, i), 0x01)) == 1
  end
  
  function binarystring(x,reverse)
    local t = {}
    for i = 0, 7 do
      if reverse then
        table.insert(t,1, band(x, 0x01))
      else
        table.insert(t, band(x, 0x01))
      end
      x = ror(x, 1)
    end
    return table.concat(t)
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
  
  chip = gchip.init(prgconf.mode,prgconf.custom) -- init chip 8
  chip = loadtochip(prgconf.file,chip) --load file defined in conf.lua
  
  
  love.graphics.setDefaultFilter("nearest", "nearest") -- make the graphics nice and pixelly
  love.graphics.setLineStyle("rough")
  love.graphics.setLineJoin("miter")
  
  chipcanvas = love.graphics.newCanvas(chip.cf.sw,chip.cf.sh)
  

  love.window.setMode(chip.cf.sw*prgconf.scale, chip.cf.sh*prgconf.scale, {resizable=true}) -- set the love2d window size to that of the config

  
end

function love.keypressed(key, scancode, isrepeat)
   if key == "return" then
      chip.update()
   end
end

function love.update()
  lovebird.update()
  
end

function love.draw()
  love.graphics.setColor(1,1,1,1)
  love.graphics.setCanvas(chipcanvas)
    love.graphics.setBlendMode("alpha")
    if chip.screenupdated then
      print('drawing screen')
      love.graphics.clear()
      for x=0,chip.cf.sw-1 do
        for y=0,chip.cf.sw-1 do
          if chip.display[x][y] then
            love.graphics.points(x,y)
          end
        end
      end
      chip.screenupdated = false
    end
    love.graphics.setBlendMode("alpha")
  love.graphics.setCanvas()
  love.graphics.draw(chipcanvas,0,0,0,prgconf.scale,prgconf.scale)

end