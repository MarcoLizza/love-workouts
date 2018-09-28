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

function Message.new(text, font, color, origin, destination, easing, duration)
  local path = Path.new()
  path:push(duration, origin, destination, origin, easing)
  path:seek(0)

  return setmetatable({
      text = text,
      font = love.graphics.newFont(font.family, font.size),
      color = color,
      path = path
    }, Message)
end

function Message:update(dt)
  if self.path.loops == 0 then
    self.path:update(dt)
  end
end

function Message:draw()
  local position = self.path.position

  local w, h = self.font:getWidth(self.text), self.font:getHeight(self.text)
  local x, y = position.x - w / 2, position.y - h / 2

  love.graphics.push('all')
    love.graphics.setFont(self.font)
    love.graphics.setColor(unpack(self.color))
    love.graphics.print(self.text, x, y)
    love.graphics.setColor(1.0, 0.0, 0.0)
    love.graphics.rectangle('line', x, y, w, h)
  love.graphics.pop()
end

return Message