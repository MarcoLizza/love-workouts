local COLORS = { -- PICO-8 palette
  { 0.000000, 0.000000, 0.000000 },
  { 0.372549, 0.341176, 0.309804 },
  { 0.760784, 0.764706, 0.780392 },
  { 1.000000, 0.945098, 0.909804 },
  { 1.000000, 0.925490, 0.152941 },
  { 1.000000, 0.639216, 0.000000 },
  { 1.000000, 0.800000, 0.666667 },
  { 0.670588, 0.321569, 0.211765 },
  { 1.000000, 0.466667, 0.658824 },
  { 1.000000, 0.000000, 0.301961 },
  { 0.513725, 0.462745, 0.611765 },
  { 0.494118, 0.145098, 0.325490 },
  { 0.160784, 0.678431, 1.000000 },
  { 0.113725, 0.168627, 0.325490 },
  { 0.000000, 0.529412, 0.317647 },
  { 0.000000, 0.894118, 0.211765 }
}
local COLOR_SPEED = 0.25

local ANGLE_SPEED = math.pi * 0.5
local ANGLE_STEPS = 16
local ANGLE_STEP = (2.0 * math.pi) / ANGLE_STEPS
local HALF_ANGLE_STEP = ANGLE_STEP / 2.0

local HOLE_RATIO = 0.2
local HOLE_STEPS = 24

local _angle = 0
local _color = 0
local _cx, _cy
local _radius

function love.load(args)
  love.graphics.setDefaultFilter('nearest', 'nearest')

  _cx, _cy = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
  _radius = math.sqrt((_cx * _cx) + (_cy * _cy))
  _radius = _radius + (_radius * 0.1)
end

function love.update(dt)
  _angle = _angle + ANGLE_SPEED * dt
  _color = _color + COLOR_SPEED * dt
end

function love.draw()
  love.graphics.push('all')
    for i = 1, ANGLE_STEPS do -- We are basically drawing a top-down viewed umbrella...
      local color = i % 2 == 0 and COLORS[math.floor(_color) % #COLORS + 1] or COLORS[(math.floor(_color) + 1) % #COLORS + 1]
      love.graphics.setColor(unpack(color))

      local angle = _angle + (ANGLE_STEP * i)
      local ax, ay = math.cos(angle - HALF_ANGLE_STEP) * _radius + _cx, math.sin(angle - HALF_ANGLE_STEP) * _radius + _cy
      local bx, by = math.cos(angle + HALF_ANGLE_STEP) * _radius + _cx, math.sin(angle + HALF_ANGLE_STEP) * _radius + _cy
      love.graphics.polygon('fill', _cx, _cy, ax, ay, bx, by)
    end

    for i = 1, HOLE_STEPS do
      local ratio = (i - 1) / HOLE_STEPS
      love.graphics.setColor(0.0, 0.0, 0.0, 1 - ratio)
      love.graphics.circle('fill', _cx, _cy, ratio * _radius * HOLE_RATIO)
    end
  love.graphics.pop()

  love.graphics.setColor(1.0, 1.0, 1.0, 0.5)
  love.graphics.print(string.format('%d FPS', love.timer.getFPS()), 0, 0)
end
