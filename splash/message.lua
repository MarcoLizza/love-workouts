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

local Easings = require('lib/math/easings')

local Message = {}

Message.__index = Message

function Message.new(text, font, color, origin, destination, easing, duration)
  return setmetatable({
      text = text,
      font = love.graphics.newFont(font.family, font.size),
      color = color,
      origin = origin,
      destination = destination,
      easing = Easings[easing or 'outExpo'],
      duration = duration or 5,
      direction = destination:clone():sub(origin),
      time = 0,
      position = nil
    }, Message)
end

function Message:update(dt)
  self.time = self.time + dt

  local ratio = self.time >= self.duration and 1.0 or self.easing(self.time, 0, 1, self.duration)

  self.position = self.direction:clone():scale(ratio):add(self.origin)

--  self.x = (love.graphics.getWidth() - w) / 2
--  local value = math.abs(math.cos(self.time * 4.0)) * (love.graphics.getHeight() / 2)
--  local dampening = (self.time >= self.duration) and 0.0 or (1.0 - (self.time / self.duration))
--  self.y = (love.graphics.getHeight() / 2) - (h / 2) - value * dampening
  -- self.y = self.easing(self.time, 0, love.graphics.getHeight() / 2, self.duration) - (h / 2)
end

function Message:draw()
  local w, h = self.font:getWidth(self.text), self.font:getHeight(self.text)
  local x, y = self.position.x - w / 2, self.position.y - h / 2

  love.graphics.push('all')
    love.graphics.setFont(self.font)
    love.graphics.setColor(unpack(self.color))
    love.graphics.print(self.text, x, y)
    love.graphics.setColor(1.0, 0.0, 0.0)
    love.graphics.rectangle('line', x, y, w, h)
  love.graphics.pop()
end

return Message