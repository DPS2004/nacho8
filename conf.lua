function love.conf(t) -- love2d config

  t.externalstorage = true
  t.console = true
  
  prgconf = {--chip8 config
    file = "IBM Logo.ch8", -- file to load into memory
    scale = 8, -- screen scale
    chatty = true,
    -- valid modes:
    -- common
    -- custom
    mode = "common",
    custom = {
      sw = 64, -- screen width
      sh = 32, -- screen height
      vyshift = false, --set vx to vy in 8xy6 and 8xye
    }
  }
end
