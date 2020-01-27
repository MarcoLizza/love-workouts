local _max_x, _max_y
local _center_x, _center_y
local _max_distance
local _time = 0

local function distance(x0, y0, x1, y1)
  local dx = x0 - x1
  local dy = y0 - y1
  return math.sqrt((dx * dx) + (dy * dy))
end

function love.load(args)
  if args[#args] == '-debug' then require('mobdebug').start() end

  love.graphics.setDefaultFilter('nearest', 'nearest', 1)
  love.graphics.setBlendMode('add') -- Change the blend mode to "mix" the square a bit ;)

  love.mouse.setVisible(false)
  love.mouse.setGrabbed(false)

  math.randomseed(os.time())
  for _ = 1, 1000 do
    math.random()
  end

  _max_x = love.graphics.getWidth()
  _max_y = love.graphics.getHeight()
  _center_x = love.graphics.getWidth() / 2
  _center_y = love.graphics.getHeight() / 2
  _max_distance = distance(0, 0, _center_x, _center_y)
end

function love.update(dt)
  _time = _time + dt
end

local function square(x, y, s, r, g, b)
  love.graphics.setColor(0.1, 0.1, 0.1)
  love.graphics.rectangle('line', x, y, s, s) -- Draw the outline...
  love.graphics.setColor(r, g, b)
  love.graphics.rectangle('fill', x, y, s, s) -- ... then blend the inside!
end

function love.draw()
  for y = 0, _max_y, 7 do
    for x = 0, _max_x, 7 do
      local d = distance(x, y, _center_x, _center_y)
      local r = 1.0 - d / _max_distance

      local angle = _time + r * math.pi -- Angle increase as we reach the center.
      local c, s = math.cos(angle), math.sin(angle)
      local rx = x - _center_x
      local ry = y - _center_y
      rx, ry = c * rx - s * ry, s * rx + c * ry
      rx = rx + _center_x
      ry = ry + _center_y

      local d2 = distance(rx, ry, _center_x, _center_y) -- Compute color according to the position in the original.
      local r2 = 1.0 - d2 / _max_distance -- We should normalized differently, however.
      square(x, y, 7, rx / _max_x, ry / _max_y, r2)
    end
  end
end
