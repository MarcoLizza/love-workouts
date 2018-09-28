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
local Vector = require('lib/math/vector')

local Path = {}

Path.__index = Path

-- Let
--   u = 1 - t
-- Then
--   B(p0, p1, p2, t) = u*u*p0 + 2*t*u*p1 + t*t*p2
local function bezier(p0, p1, p2, t)
  local u = 1 - t
  local a = u * u
  local b = 2 * t * u
  local c = t * t
  local x = a * p0.x + b * p1.x + c * p2.x
  local y = a * p0.y + b * p1.y + c * p2.y
  return Vector.new(x, y)
end

function Path.new()
  return setmetatable({
      segments = {},
      current = nil,
      time = 0,
      position = nil,
      loops = 0
    }, Path)
end

function Path:clear()
  self.segments = {}
  self.index = nil
  self.time = 0
  self.position = nil
  self.finished = false
end

function Path:push(duration, from, to, mid_point, easing)
  self.segments[#self.segments + 1] = {
      p0 = from,
      p1 = mid_point or from,
      p2 = to,
      duration = duration,
      easing = Easings[easing or 'linear']
    }
end

function Path:seek(time)
  for index, segment in ipairs(self.segments) do
    if time <= segment.duration then
      self.index = index
      break
    end
    time = time - segment.duration
  end
  self.time = time
  self.finished = false
end

function Path:update(dt)
  if self.finished then
    return
  end

  self.time = self.time + dt
  local current = self.segments[self.index]
  while self.time > current.duration do
    self.time = self.time - current.duration
    self.index = self.index + 1
    if self.index > #self.segments then
      current = nil
      break
    end
    current = self.segments[self.index]
  end

  if current then
    local t = current.easing(self.time, 0, 1, current.duration)
    self.position = bezier(current.p0, current.p1, current.p2, t)
  else
    self.finished = true
  end
end

return Path