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

local Path = require('path')

local Message = {}

Message.__index = Message

local unpack = unpack or table.unpack

function Message.new(text, font, color, sequence, looped)
  local path = Path.new()
  for _, part in ipairs(sequence) do
    path:push(part.points, part.duration, part.easing)
  end
  path:seek(0)

  return setmetatable({
      text = text,
      font = love.graphics.newFont(font.family, font.size),
      color = color,
      path = path,
      looped = looped
    }, Message)
end

function Message:reset()
  self.path:seek(0)
end

function Message:update(dt)
  if self.path.finished and self.looped then
    self.path:seek(0)
  end

  self.path:step(dt)
end

function Message:draw()
  local x, y = unpack(self.path.position)
--[[
  love.graphics.setColor(0, 1, 0)
  love.graphics.circle('fill', x, y, 2)
]]--
  local w, h = self.font:getWidth(self.text), self.font:getHeight(self.text)
  local x, y = x - w / 2, y - h / 2

  love.graphics.push('all')
    love.graphics.setFont(self.font)
    love.graphics.setColor(unpack(self.color))
    love.graphics.print(self.text, x, y)
    love.graphics.setColor(1.0, 0.0, 0.0)
    love.graphics.rectangle('line', x, y, w, h)
  love.graphics.pop()
end

return Message