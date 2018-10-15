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

-- TODO: apply shader or color
-- TODO: https://gamedevelopment.tutsplus.com/tutorials/create-a-glowing-flowing-lava-river-using-bezier-curves-and-shaders--gamedev-919

-- https://javascript.info/bezier-curve

local Message = require('message')

local unpack = unpack or table.unpack

local _time = 0
local _shader = nil
local _messages = {}
local _debug = false

local _points = {
  { { 256, 0 }, { 0, 0 }, { 256, 224 } },
  { { 256, 512 }, { 0, 0 }, { 256, 270 } }
}

local function convert_points(points)
  local sequence = {}
  for _, point in ipairs(points) do
    sequence[#sequence + 1] = point[1]
    sequence[#sequence + 1] = point[2]
  end
  return sequence
end

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
  _shader:send('screen_resolution', { love.graphics.getDimensions() })

  _messages[#_messages + 1] = Message.new('iCE:7', { family = 'assets/fonts/m6x11.ttf', size = 64 },  { 1.0, 1.0, 1.0 },  _points[1], 2.5, 'outBounce')
  _messages[#_messages + 1] = Message.new('presents', { family = 'assets/fonts/m5x7.ttf', size = 32 },  { 1.0, 1.0, 1.0 }, _points[2], 2.5, 'outExpo')
end

function love.update(dt)
  _time = _time + dt

  _shader:send('time', _time)

  for _, message in ipairs(_messages) do
    message:update(dt)
  end
end

function love.draw()
  for _, message in ipairs(_messages) do
    message:draw()
  end

  love.graphics.push('all')
    love.graphics.setShader(_shader)
    love.graphics.setColor(0.0, 1.0, 1.0, 1.0)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  love.graphics.pop()

  if _debug then
    love.graphics.setColor(1.0, 1.0, 1.0, 0.5)
    for _, p in ipairs(_points) do
      local b = love.math.newBezierCurve(convert_points(p))
      love.graphics.line(b:render())
      end
  end

  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.print(love.timer.getFPS() .. ' FPS', 0, 0)
  love.graphics.print(string.format('%d objects(s)', #_messages), 0, 16)
end

function love.mousepressed(x, y, button, istouch, presses)
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'f1' then
    for _, message in ipairs(_messages) do
      message:reset()
    end
  elseif key == 'f2' then
  elseif key == 'f5' then
  elseif key == 'f6' then
  elseif key == 'f12' then
    _debug = not _debug
  end
end
