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

function Message.new(text, font)
  return setmetatable({
      text = text,
      font = love.graphics.newFont(font.family, font.size),
      easing = Easings.outExpo,
      time = 0,
      duration = 2.5,
      x = nil,
      y = nil
    }, Message)
end

function Message:update(dt)
  self.time = self.time + dt
  local w, h = self.font:getWidth(self.text), self.font:getHeight(self.text)
  self.x = (love.graphics.getWidth() - w) / 2
  local value = math.abs(math.cos(self.time * 4.0)) * (love.graphics.getHeight() / 2)
  local dampening = (self.time >= self.duration) and 0.0 or (1.0 - (self.time / self.duration))
  self.y = (love.graphics.getHeight() / 2) - (h / 2) - value * dampening
  -- self.y = self.easing(self.time, 0, love.graphics.getHeight() / 2, self.duration) - (h / 2)
end

function Message:draw()
  love.graphics.push('all')
    love.graphics.setFont(self.font)
    love.graphics.print(self.text, self.x, self.y)
  love.graphics.pop()
end

return Message