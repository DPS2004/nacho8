function love.conf(t) -- love2d config

  t.externalstorage = true
  t.console = true
  
  prgconf = {--chip8 config
    file = "IBM Logo.ch8", -- file to load into memory
    scale = 8, -- screen scale
    chatty = true,
    -- valid modes:
    -- common
    -- schip
    -- custom
    mode = "common",
    -- the custom mode gets loaded from this table
    custom = {
      sw = 64, -- screen width
      sh = 32, -- screen height
      vyshift = true, --set vx to vy in 8xy6 and 8xye
      vxoffsetjump = false -- false for bnnn, true for bxnn
    }
  }
end
