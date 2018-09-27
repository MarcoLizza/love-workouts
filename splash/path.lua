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

local Path = {}

Path.__index = Path

local function bezier(p0, p1, p2, t)
  local omt = 1 - t
  return p0
end

function Path.new()
  return setmetatable({
      segments = {},
      current = nil,
      time = 0,
      position = nil
    }, Path)
end

function Path:clear()
  self.segments = {}
  self.iterator = nil
  self.index = nil
  self.time = 0
  self.position = nil
end

function Path:push(duration, from, to, mid_point, easing)
  self.segments[#self.segments + 1] = {
      p0 = from,
      p1 = mid_point,
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
end

function Path:update(dt)
  self.time = self.time + dt
  local current = self.segments[self.index]
  while self.time > self.current.duration do
    self.time = self.time - self.current.duration
    self.index = self.index + 1
    current = self.segments[self.index]
  end
  local t = self.time / current.duration
  self.position = bezier(current.p0, current.p1, current.p2, t)
end

function Path:position()
  return self.position
end

return Path