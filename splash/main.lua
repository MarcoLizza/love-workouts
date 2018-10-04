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

-- TODO: apply shader or color
-- TODO: https://gamedevelopment.tutsplus.com/tutorials/create-a-glowing-flowing-lava-river-using-bezier-curves-and-shaders--gamedev-919

-- https://javascript.info/bezier-curve

local Message = require('message')

local unpack = unpack or table.unpack

local _messages = {}
local _debug = false

local function compile_bezier_love2d(control_points)
  local points = {}
  for _, v in ipairs(control_points) do
    points[#points + 1] = v[1]
    points[#points + 1] = v[2]
  end
  local bezier = love.math.newBezierCurve(points)
  return function(t)
      local x, y = bezier:evaluate(t)
      return x, y
    end
end

-- https://www.gamedev.net/articles/programming/math-and-physics/practical-guide-to-bezier-curves-r3166/
local function compile_bezier_horner(control_points)
  local n = #control_points
  return function(t)
      local u = 1 - t
      local bc = 1
      local tn = 1
      local x, y = unpack(control_points[1])
      x = x * u
      y = y * u
      for i = 2, n - 1 do
        tn = tn * t -- Incremental powers
        bc = bc * (n + 1 - i) / i -- Multiplicative formula for binomial calulation
        local tn_bc = tn * bc
        local px, py = unpack(control_points[i])
        x = (x + tn_bc * px) * u
        y = (y + tn_bc * py) * u
      end
      local tn_t = tn * t
      local px, py = unpack(control_points[n])
      x = x + tn_t * px
      y = y + tn_t * py
      return x, y
    end
end

local function compile_bezier_fast_horner(control_points)
  local n = #control_points
  return function(t)
      local s = 1 - t
      local C = n * t
      local Px, Py = unpack(control_points[1])
      for k = 1, n do
        local ykx, yky = unpack(control_points[k])
        Px = Px * s + C * ykx
        Py = Py * s + C * yky
        C = C * t * (n - k) / (k + 1)
      end
      return Px, Py
    end
end

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

local function test()
  local COUNT = 10000000
  for n = 2, 4 do
    print(string.format('BEZIER #%d ORDER', n))
    local p = { }
    for _ = 1, n do
      p[#p  + 1] = { math.random(), math.random() }
    end
    local bezier = {
        ['decasteljau'] = compile_bezier_decasteljau(p),
        ['horner'] = compile_bezier_horner(p),
        ['fast-horner'] = compile_bezier_fast_horner(p),
        ['love2d'] = compile_bezier_love2d(p)
      }
    for i, b in pairs(bezier) do
      local s = os.clock()
      for j = 0, COUNT do
        local t = j / COUNT
        b(t)
      end
      local e = os.clock()
      print(string.format('%s took %.3fs', i, e - s))
    end
  end

  local points = { { 0, 0 }, { 1, 0 }, { 1, 1 }, { 0, 1 } }
  local b_d = compile_bezier_decasteljau(points)
  local b_h = compile_bezier_horner(points)
  local b_l = compile_bezier_love2d(points)
  for i = 0, 100 do
    local t = i / 100;
    local ax, ay = b_d(t)
    local bx, by = b_h(t)
    local cx, cy = b_l(t)
    print(string.format('%.2f %.2f %.2f %.2f %.2f %.2f', ax, bx, cx, ay, by, cy))
  end
end

function love.load(args)
  love.graphics.setDefaultFilter('nearest', 'nearest', 1)

  love.mouse.setVisible(true)
  love.mouse.setGrabbed(false)

  if love.joystick and love.filesystem.getInfo("assets/mappings/gamecontrollerdb.txt") then
    love.joystick.loadGamepadMappings("assets/mappings/gamecontrollerdb.txt")
  end

  math.randomseed(os.time())
  for _ = 1, 1024 do
    math.random()
  end

  test()

  _messages[#_messages + 1] = Message.new('aPPlEjAck', { family = 'assets/fonts/m6x11.ttf', size = 64 },  { 1.0, 1.0, 1.0 },  { { 256, 0 }, { 0, 0 }, { 256, 224 } }, 2.5, 'outBounce')
  _messages[#_messages + 1] = Message.new('presents', { family = 'assets/fonts/m5x7.ttf', size = 32 },  { 1.0, 1.0, 1.0 }, { { 256, 512 }, { 0, 0 }, { 256, 270 } }, 2.5, 'outExpo')
end

function love.update(dt)
  for _, message in ipairs(_messages) do
    message:update(dt)
  end
end

function love.draw()
  for _, message in ipairs(_messages) do
    message:draw()
  end

--  love.graphics.line(0, 256, 512, 256)
  local b = love.math.newBezierCurve({256, 0, 0, 0, 256, 224})
  love.graphics.setColor(1.0, 1.0, 1.0, 0.5)
  love.graphics.line(b:render())

  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.print(love.timer.getFPS() .. ' FPS', 0, 0)
  love.graphics.print(string.format('%d objects(s)', #_messages), 0, 16)
end

function love.mousepressed(x, y, button, istouch, presses)
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'f1' then
  elseif key == 'f2' then
  elseif key == 'f5' then
  elseif key == 'f6' then
  elseif key == 'f12' then
    _debug = not _debug
  end
end
