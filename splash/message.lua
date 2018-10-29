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

function Message.new(text, font, colorOrShader, sequence, looped)
  local path = Path.new(function(self)
        if looped then
          self:seek(0)
        end
      end)
  for _, part in ipairs(sequence) do
    path:push(part.duration, part.easing, part.points, part.limits)
  end
  path:seek(0)

  local color = nil
  local shader = nil
  if type(colorOrShader) == 'string' then
    shader = love.graphics.newShader(colorOrShader)
  else
    color = colorOrShader
  end

  return setmetatable({
      text = text,
      font = love.graphics.newFont(font.family, font.size),
      color = color,
      shader = shader,
      path = path,
      looped = looped
    }, Message)
end

function Message:reset()
  self.path:seek(0)
end

function Message:update(dt)
  self.path:step(dt)
end

function Message:draw(debug)
  if debug then
    local function convert_points(points)
      local sequence = {}
      for _, point in ipairs(points) do
        sequence[#sequence + 1] = point[1]
        sequence[#sequence + 1] = point[2]
      end
      return sequence
    end
    love.graphics.push('all')
    love.graphics.setColor(1.0, 1.0, 1.0, 0.5)
    for _, segment in ipairs(self.path.segments) do
      local b = love.math.newBezierCurve(convert_points(segment.control_points))
      love.graphics.line(b:render())
    end
    love.graphics.pop()
  end

  local x, y = unpack(self.path.position)
--[[
  love.graphics.setColor(0, 1, 0)
  love.graphics.circle('fill', x, y, 2)
]]--
  local w, h = self.font:getWidth(self.text), self.font:getHeight(self.text)
  x, y = x - w / 2, y - h / 2

  love.graphics.push('all')
    love.graphics.setFont(self.font)
    if self.shader then
      self.shader:send('_origin', { x, y })
      self.shader:send('_size', { w, h })
      love.graphics.setShader(self.shader)
    end
    if self.color then
      love.graphics.setColor(unpack(self.color))
    else
      love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
    end
    love.graphics.print(self.text, x, y)
    if debug then
      love.graphics.setColor(1.0, 0.0, 0.0)
      love.graphics.rectangle('line', x, y, w, h)
    end
  love.graphics.pop()
end

return Message