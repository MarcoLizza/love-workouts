local _max_x, _max_y
local _time = 0
local _fan = false

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

  _max_x = love.graphics.getWidth() - 1
  _max_y = love.graphics.getHeight() - 1
end

function love.keypressed(key)
  if key == "return" then
    _fan = not _fan
  end
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

      local v = math.min(1.0, length(rx, ry))
      v = 1.0 - v * v -- Tweak to smooth the color change differently.

      if _fan then
        local rad = math.atan2(ry, rx) + math.pi -- Find the octanct of the rotated point to pick the color.
        local deg = math.floor(rad * (180.0 / math.pi)) % 180
        if deg > 3 and deg < 87 then
          square(x, y, 7, 0.0, 0.5, v)
        elseif deg > 93 and deg < 177 then
          square(x, y, 7, 0.0, v, 0.0)
        else
          square(x, y, 7, 0.0, 0.0, 0.0)
        end
      else
        square(x, y, 7, rx, ry, v)
      end
    end
  end
end
