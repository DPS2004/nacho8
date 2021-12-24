function love.conf(t) -- love2d config

  t.externalstorage = true
  t.console = true
  
  cf = {--chip8 config
    file = "IBM Logo.ch8", -- file to load into memory
    sw = 64, -- screen width
    sh = 32, -- screen height
    scale = 8, -- screen scale
    chatty = true,
  }
end
