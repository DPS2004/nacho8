-- This project aims to be very commented.

function love.load() -- called once at the very start of execution
  cf = require('config') -- load the config file.
  bit = require('bit') -- load LuaJIT's bitwise library
  gchip = require('chip') -- load the chip8 interpreter
  
  love.window.setMode(cf.sw*cf.scale, cf.sh*cf.scale, {resizable=true}) -- set the love2d window size to that of the config
  chip = gchip:init()
end

function love.update()
  
end

function love.draw()

end