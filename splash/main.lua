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

-- TODO: https://gamedevelopment.tutsplus.com/tutorials/create-a-glowing-flowing-lava-river-using-bezier-curves-and-shaders--gamedev-919

local Message = require('message')

local unpack = unpack or table.unpack

local _time = 0
local _mode = 3
local _shader = nil
local _message = nil
local _debug = false

local MARGIN = 64

local _sequence = {
  { points = { {   0 + MARGIN,   0 + MARGIN }, { 512 - MARGIN,   0 + MARGIN }, { 256, 256 } }, duration = 2.5, easing = 'outCirc' },
  { points = { { 256, 256 }, { 512 - MARGIN,   0 }, { 512 - MARGIN, 512 - MARGIN } }, duration = 5.0, easing = 'outQuad' },
  { points = { { 512 - MARGIN, 512 - MARGIN }, {   0 + MARGIN, 512 - MARGIN }, { 256, 256 } }, duration = 2.5, easing = 'outSine' },
  { points = { { 256, 256 }, {   0 + MARGIN, 512 - MARGIN }, {   0 + MARGIN,   0 + MARGIN } }, duration = 5.0, easing = 'outBack' }
}

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

  _shader = love.graphics.newShader('assets/shaders/waves.glsl')
--  _shader = love.graphics.newShader('assets/shaders/freeload.glsl')

  local shader = 'assets/shaders/gradients.glsl'
  local color = { 1.0, 1.0, 1.0 }

  _message = Message.new('XYZ', { family = 'assets/fonts/8bit_wonder-8px.ttf', size = 48 }, shader, _sequence, 'looped')
end

function love.update(dt)
  _time = _time + dt

  _shader:send('_time', _time)

  _message:update(dt)
  _message:format('%03d', math.floor(_time))
end

function love.draw()
  love.graphics.push('all')
    _shader:send('_mode', _mode)
    love.graphics.setShader(_shader)
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  love.graphics.pop()

  _message:draw(_debug)

  love.graphics.setColor(1.0, 1.0, 1.0, 0.5)
  love.graphics.print(love.timer.getFPS() .. ' FPS', 0, 0)
end

function love.mousepressed(x, y, button, istouch, presses)
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'f1' then
    _message:reset()
  elseif key == 'f2' then
    _mode =(_mode + 1) % 4
  elseif key == 'f12' then
    _debug = not _debug
  end
end
