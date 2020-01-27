local _max_x, _max_y
local _time = 0

local function square(x, y, s, r, g, b)
  love.graphics.setColor(0.1, 0.1, 0.1)
  love.graphics.rectangle('line', x, y, s, s) -- Draw the outline...
  love.graphics.setColor(r, g, b)
  love.graphics.rectangle('fill', x, y, s, s) -- ... then blend the inside!
end

local function length(x, y)
  return math.sqrt((x * x) + (y * y))
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
end

function love.update(dt)
  _time = _time + dt
end

function love.draw()
  for y = 0, _max_y, 7 do
    local oy = (y / _max_y) * 2 - 1
    for x = 0, _max_x, 7 do
      local ox = (x / _max_x) * 2 - 1
      local d = length(ox, oy)
      local r = 1.0 - d

      local angle = _time + r * math.pi -- Angle increase as we reach the center.
      local c, s = math.cos(angle), math.sin(angle)
      local rx, ry = c * ox - s * oy, s * ox + c * oy
--[[
      local angle = math.atan(oy, ox)
      angle = angle + _time + r * math.pi
      local rx, ry = math.cos(angle), math.sin(angle)
]]
      local d2 = length(rx, ry)
      local r2 = 1.0 - d2
      square(x, y, 7, math.abs(rx), math.abs(ry), r2)
    end
  end
end
