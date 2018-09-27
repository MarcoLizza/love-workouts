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

-- TODO: define a path of movement (origin, destination, easing, duration)
-- TODO: apply shader or color

local Vector = require('lib/math/vector')
local Message = require('message')

local _messages = {}
local _debug = false

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

  _messages[#_messages + 1] = Message.new('AppleJack', { family = 'assets/fonts/m6x11.ttf', size = 64 },  { 1.0, 1.0, 1.0 }, Vector.new(256, 0), Vector.new(256, 224), 'outBounce', 2.5)
  _messages[#_messages + 1] = Message.new('presents', { family = 'assets/fonts/m5x7.ttf', size = 32 },  { 1.0, 1.0, 1.0 }, Vector.new(256, 512), Vector.new(256, 270), 'outExpo', 2.5)
end

function love.update(dt)
  for _, message in ipairs(_messages) do
    message:update(dt)
  end
end

function love.draw()
  for _, message in ipairs(_messages) do
    message:draw()
  end

--  love.graphics.line(0, 256, 512, 256)

  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.print(love.timer.getFPS() .. ' FPS', 0, 0)
  love.graphics.print(string.format('%d objects(s)', #_messages), 0, 16)
end

function love.mousepressed(x, y, button, istouch, presses)
  local point = Vector.new(x, y)
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'f1' then
  elseif key == 'f2' then
  elseif key == 'f5' then
  elseif key == 'f6' then
  elseif key == 'f12' then
    _debug = not _debug
  end
end
