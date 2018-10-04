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

local Path = {}

Path.__index = Path

local unpack = unpack or table.unpack

-- https://www.math.ubc.ca/~cass/graphics/manual/pdf/a6.pdf
local function compile_bezier_horner(control_points)
  local n = #control_points
  return function(t)
      local s = 1 - t
      local C = n * t
      local Px, Py = unpack(control_points[1])
      for k = 1, n do
        local ykx, yky = unpack(control_points[k])
        Px = Px * s + C * ykx
        Py = Py * s + C * yky
        C = C * ((n - k) / (k + 1)) * t
      end
      return Px, Py
    end
end

-- The function *compiles* a bézier curve evaluator, given the control points
-- (as `Vector` instances). The aim of this function is to avoid passing the
-- control-control_points at each evaluation.
--
-- It supports linear, quadratic, and cubic béziers cuvers. The evaluators are
-- the following (with `u = 1 - t`)
--
-- B1(p0, p1, t) = u*p0 + t*p2
-- B2(p0, p1, p2, t) = u*u*p0 + 2*t*u*p1 + t*t*p2
-- B3(p0, p1, p2, p3, t) = u*u*u*p0 + 3*u*u*t*p1 + 3*u*t*t*p2 + t*t*t*p3
local function compile_bezier_decasteljau(control_points)
  if #control_points == 4 then
    local p0, p1, p2, p3 = unpack(control_points)
    local p0x, p0y = unpack(p0)
    local p1x, p1y = unpack(p1)
    local p2x, p2y = unpack(p2)
    local p3x, p3y = unpack(p3)
    return function(t)
        local u = 1 - t
        local uu = u * u -- Precalculate, to avoid two multiplications.
        local tt = t * t
        local a = uu * u
        local b = 3 * uu * t
        local c = 3 * u * tt
        local d = t * tt
        local x = a * p0x + b * p1x + c * p2x + d * p3x
        local y = a * p0y + b * p1y + c * p2y + d * p3y
        return x, y
      end
  elseif #control_points == 3 then
    local p0, p1, p2 = unpack(control_points)
    local p0x, p0y = unpack(p0)
    local p1x, p1y = unpack(p1)
    local p2x, p2y = unpack(p2)
    return function(t)
        local u = 1 - t
        local a = u * u
        local b = 2 * t * u
        local c = t * t
        local x = a * p0x + b * p1x + c * p2x
        local y = a * p0y + b * p1y + c * p2y
        return x, y
      end
  elseif #control_points == 2 then
    local p0, p1 = unpack(control_points)
    local p0x, p0y = unpack(p0)
    local p1x, p1y = unpack(p1)
    return function(t)
        local u = 1 - t
        local x = u * p0x + t * p1x
        local y = u * p0y + t * p1y
        return x, y
      end
  else
    error('Beziér curves are supported up to 3rd order.')
  end
end

function Path.new()
  return setmetatable({
      segments = {},
      index = nil,
      time = 0,
      position = nil,
      finished = false
    }, Path)
end

function Path:clear()
  self.segments = {}
  self.index = nil
  self.time = 0
  self.position = nil
  self.finished = false
end

function Path:push(control_points, duration, easing)
  self.segments[#self.segments + 1] = {
      -- control_points = control_points,
      duration = duration,
      easing = Easings[easing or 'linear'],
      bezier = compile_bezier_decasteljau(control_points)
    }
end

function Path:seek(time)
  self.time = 0
  self.index = nil
  self.position = nil
  for index, segment in ipairs(self.segments) do
    if time <= segment.duration then
      self.index = index
      break
    end
    time = time - segment.duration
  end
  self.finished = not self.index
  self:step(time)
end

function Path:step(dt)
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
    self.position = { current.bezier(t) }
  else
    self.finished = true
  end
end

return Path