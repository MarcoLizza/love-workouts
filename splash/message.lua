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
      x = 100,
      y = 100,
      text = text,
      font = love.graphics.newFont(font.family, font.size),
      easing = Easings.outBounce,
      time = 0,
      duration = 1
    }, Message)
end

function Message:update(dt)
  self.time = self.time + dt
end

function Message:draw()
  local w, h = self.font:getWidth(self.text), self.font:getHeight(self.text)
  local x, y = self.x, self.y
  y = y - (h / 2) + self.easing(self.time, 0, 128, self.duration)
  love.graphics.push('all')
    love.graphics.setFont(self.font)
    love.graphics.print(self.text, x, y)
  love.graphics.pop()
end

return Message