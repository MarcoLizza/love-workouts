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

local unpack = unpack or table.unpack

local _time = 0
local _debug = false
local _shader = nil
local _depth_map = nil

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

  _depth_map = love.graphics.newImage('data/depth-map.png')

  _shader = love.graphics.newShader('assets/shaders/anaglyph.glsl')
end

function love.update(dt)
  _time = _time + dt

  _shader:send('_time', _time)
end

function love.draw()
  love.graphics.push('all')
    _shader:send('_depth_map', _depth_map)
    love.graphics.setShader(_shader)
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
--    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.draw(_depth_map)
  love.graphics.pop()

  love.graphics.setColor(1.0, 1.0, 1.0, 0.5)
  love.graphics.print(love.timer.getFPS() .. ' FPS', 0, 0)
end

function love.mousepressed(x, y, button, istouch, presses)
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'f1' then
  elseif key == 'f2' then
  elseif key == 'f12' then
    _debug = not _debug
  end
end
