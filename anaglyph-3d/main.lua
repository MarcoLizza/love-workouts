--[[

Copyright (c) 2018 by Marco Lizza (marco.lizza@gmail.com)

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgement in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.

]] --

local ANAGLYPH_MODES = {
  'RED-BLUE GREY', 'RED-GREEN GREY', 'BLUE-GREEN GREY',
  'RED-CYAN GREY', 'RED-CYAN COLOR', 'RED-CYAN HALF-COLOR', 'RED-CYAN DUBOIS',
  'AMBER-BLUE GREY', 'AMBER-BLUE COLOR', 'AMBER-BLUE HALF-COLOR (ColorCode-3D)', 'AMBER-BLUE DUBOIS',
  'MAGENTA-GREEN GREY', 'MAGENTA-GREEN COLOR', 'MAGENTA-GREEN HALF-COLOR (Trioscopics-3D)', 'MAGENTA-GREEN DUBOIS',
  'MAGENTA-YELLOW COLOR *', 'MAGENTA-CYAN COLOR *', 'YELLOW-CYAN COLOR *'
}

local COLOUR_BLINDNESS_TYPES = {
  'NORMAL', 'PROTANOPE (NO REDS)', 'DEUTERANOPE (NO GREENS)', 'TRITANOPE (NO BLUES)', 'ACHROMATOPSIA', 'BLUE-CONE MONOCHROMACY'
}

local unpack = unpack or table.unpack

local _time = 0
local _debug = false

local _font = nil

local _shader = nil
local _images = {
    ['left'] = 0,
    ['center'] = 0,
    ['right'] = 0
  }
local _mode = 0

local _filter = nil
local _type = 0

function love.load(args)
  love.graphics.setDefaultFilter('nearest', 'nearest', 1)

  love.mouse.setVisible(true)
  love.mouse.setGrabbed(false)

  if love.joystick and love.filesystem.getInfo("assets/mappings/gamecontrollerdb.txt") then
    love.joystick.loadGamepadMappings("assets/mappings/gamecontrollerdb.txt")
  end

  math.randomseed(os.time())
  for _ = 1, 1024 do
    math.random()
  end

  _font = love.graphics.newFont('assets/fonts/m6x11.ttf', 32)

  _shader = love.graphics.newShader('assets/shaders/anaglyph.glsl')

  _filter = love.graphics.newShader('assets/shaders/colour-blindness.glsl')

  for key, _ in pairs(_images) do
    _images[key] = love.graphics.newImage('data/' .. key .. '.png')
  end
end

function love.update(dt)
  _time = _time + dt
  if _shader:hasUniform('_time') then
    _shader:send('_time', _time)
  end
  if _filter:hasUniform('_time') then
    _filter:send('_time', _time)
  end
end

function love.draw()
--[[
  love.graphics.push('all')
    _shader:send('_left', _images['left'])
    _shader:send('_right', _images['right'])
    _shader:send('_mode', _mode)
    love.graphics.setShader(_shader)
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
    love.graphics.draw(_images['center'])
  love.graphics.pop()
]]--
  love.graphics.push('all')
    _filter:send('_type', _type)
    love.graphics.setShader(_filter)
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
    love.graphics.draw(_images['center'])
  love.graphics.pop()

  love.graphics.push('all')
    love.graphics.setFont(_font)
    love.graphics.setColor(1.0, 1.0, 1.0, 0.5)
    love.graphics.print(ANAGLYPH_MODES[_mode + 1], 0, love.graphics.getHeight() - 64)
    love.graphics.print(COLOUR_BLINDNESS_TYPES[_type + 1], 0, love.graphics.getHeight() - 32)
  love.graphics.pop()

  love.graphics.setColor(0.0, 0.0, 0.0, 0.5)
  love.graphics.print(love.timer.getFPS() .. ' FPS', 0, 0)
end

function love.mousepressed(x, y, button, istouch, presses)
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'f1' then
    _mode = (_mode + 1) % #ANAGLYPH_MODES
  elseif key == 'f2' then
    _type = (_type + 1) % #COLOUR_BLINDNESS_TYPES
  elseif key == 'f12' then
    _debug = not _debug
  end
end
