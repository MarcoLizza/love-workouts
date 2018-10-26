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

local CURVE_ORDER_LIMIT = 4

-- The function *compiles* a bézier curve evaluator, given the control points
-- (as two-element arrays). The aim of this function is to avoid passing the
-- control-control_points at each evaluation.
--
-- It supports linear, quadratic, and cubic béziers cuvers. The evaluators are
-- the following (with `u = 1 - t`)
--
-- B1(p0, p1, t) = u*p0 + t*p1
-- B2(p0, p1, p2, t) = u*u*p0 + 2*t*u*p1 + t*t*p2
-- B3(p0, p1, p2, p3, t) = u*u*u*p0 + 3*u*u*t*p1 + 3*u*t*t*p2 + t*t*t*p3
--
-- https://javascript.info/bezier-curve
local function compile_bezier(control_points)
  local n = #control_points
  if n == 4 then
    local p0, p1, p2, p3 = unpack(control_points)
    local p0x, p0y = unpack(p0)
    local p1x, p1y = unpack(p1)
    local p2x, p2y = unpack(p2)
    local p3x, p3y = unpack(p3)
    return function(t)
        local u = 1 - t
        local uu = u * u
        local tt = t * t
        local a = uu * u
        local b = 3 * uu * t
        local c = 3 * u * tt
        local d = t * tt
        local x = a * p0x + b * p1x + c * p2x + d * p3x
        local y = a * p0y + b * p1y + c * p2y + d * p3y
        return x, y
      end
  elseif n == 3 then
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
  elseif n == 2 then
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
    error('Bézier curves are supported from 2nd to 4th order.')
  end
end

function Path.new(on_finished)
  return setmetatable({
      segments = {},
      index = nil,
      time = 0,
      position = nil,
      on_finished = on_finished
    }, Path)
end

-- Scans the control-points sequence by creating sub-sequences no longer than
-- the limit defined in the sequence of limits. Also, the last point of a
-- sub-sequence is the first point of the following one.
local function split(points, limits, callback)
  local n = #points
  local from = 1
  for _, limit in ipairs(limits) do
    local count = math.min(limit, n)
    local to = from + (count - 1)
    local control_points = {}
    for i = from, to do
      control_points[#control_points + 1] = points[i]
    end
    callback(control_points)
    n = n - (count - 1)
    from = to
  end
end

function Path:push(duration, easing, points, limits)
  if not limits then
    limits = { CURVE_ORDER_LIMIT }
  end
  split(points, limits, function(control_points)
      self.segments[#self.segments + 1] = {
        control_points = control_points,
        duration = duration,
        easing = Easings[easing],
        bezier = compile_bezier(control_points)
      }
    end)
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
  self:step(time)
end

function Path:step(dt)
  if not self.index then
    return
  end

  local current = self.segments[self.index]

  self.time = self.time + dt
  while self.time > current.duration do
    self.time = self.time - current.duration
    self.index = self.index + 1
    if self.index > #self.segments then -- End of path, cap the very end of the last segment.
      self.time = current.duration
      self.index = nil
      break
    end
    current = self.segments[self.index]
  end

  local t = current.easing(self.time, 0, 1, current.duration)
  self.position = { current.bezier(t) }

  if not self.index and self.on_finished then -- Reached the end of the segment, notify the callback.
    self:on_finished()
  end
end

return Path