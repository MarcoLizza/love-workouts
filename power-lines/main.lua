local POINTS = 96

local COLORS = {
  { 1.0, 0.0, 0.0 },
  { 0.0, 1.0, 0.0 },
  { 0.0, 0.0, 1.0 },
  { 1.0, 0.0, 1.0 },
  { 1.0, 1.0, 0.0 },
  { 0.0, 1.0, 1.0 },
  { 1.0, 1.0, 1.0 }
}

local SET_1 = {
  'share an idea',
  'be thankful',
  'recognize someone',
  'think...',
  'set a goal',
  'be sincere'
}
local SET_2= {
  'genuinely',
  'x 2',
  'right away',
  'with passion',
  'today',
  'without fear'
}

local _ticks = 0.0
local _phrase = nil
local _points = {}
local _threshold = 128.0

local function distance_squared(p0, p1)
  local a = p0.x - p1.x
  local b = p0.y - p1.y
  return (a * a) + (b * b)
end

local function distance(p0, p1)
  return math.sqrt(distance_squared(p0, p1))
end

local function influence(p0, p1, radius)
  local d = distance(p0, p1)
  if d > radius then
    return nil
  end
  return (radius - d) / radius
end

local function lerp(a, b, ratio)
  if type(a) == 'table' then
    local v = {}
    for i = 1, #a do
      table.insert(v, lerp(a[i], b[i], ratio))
    end
    return v
  else
    return (b - a) * ratio + a
  end
end

local function spawn(bundle)
  local x = math.random(0, love.graphics.getWidth() - 1)
  local y = math.random(0, love.graphics.getWidth() - 1)
  local speed = math.random(4, 8)
  local angle = math.random() * math.pi
  local color =  COLORS[math.random(1, #COLORS)]
  table.insert(bundle, { color = color, x = x, y = y, vx = math.cos(angle) * speed, vy = math.sin(angle) * speed })
end

local function kill(bundle)
  table.remove(bundle)
end

function love.load(args)
  if args[#args] == '-debug' then require('mobdebug').start() end

  love.graphics.setDefaultFilter('nearest', 'nearest', 1)
  love.graphics.setBlendMode('add')

  love.mouse.setVisible(false)
  love.mouse.setGrabbed(false)

  math.randomseed(os.time())
  for _ = 1, 1000 do
    math.random()
  end
  _phrase = SET_1[math.random(1, 6)] .. ' ' .. SET_2[math.random(1, 6)]

  for _ = 1, POINTS do
    spawn(_points)
  end
end

function love.draw()
  for i = 1, #_points do
    local p0 = _points[i]
    for j = i + 1, #_points do
      local p1 = _points[j]
      local v = influence(p0, p1, _threshold)
      if v then
        local r, g, b = unpack(lerp(p0.color, p1.color, v))
--        love.graphics.setColor(0.25, 0.25, 0.75, v)
        love.graphics.setColor(r, g, b, v)
        love.graphics.line(p0.x, p0.y, p1.x, p1.y)
      end
    end
    love.graphics.setColor(1.0, 1.0, 1.0)
    love.graphics.circle('fill', p0.x, p0.y, 2)
  end
--[[
  local x, y = love.mouse.getX(), love.mouse.getY()
  local w, h = 16, 16
  local s = 2
  love.graphics.push('all')
    love.graphics.setColor(1.0, 1.0, 1.0)
    love.graphics.rectangle('fill', x - s/2, y - h/2, s, h)
    love.graphics.rectangle('fill', x - h/2, y - s/2, w, s)
  love.graphics.pop()
]]
  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.print(love.timer.getFPS() .. ' FPS', 0, 0)
  love.graphics.print(string.format('%d point(s) w/ threshold %d (%s)', #_points, _threshold, love.graphics.getBlendMode()), 0, 16)
  love.graphics.print(_phrase, 0, love.graphics.getHeight() - 16)
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'f1' then
    kill(_points)
  elseif key == 'f2' then
    spawn(_points)
  elseif key == 'f3' then
    _threshold = math.max(_threshold - 1, 0)
  elseif key == 'f4' then
    _threshold = math.min(_threshold + 1, 999)
  elseif key == 'f12' then
    local mode = love.graphics.getBlendMode()
    love.graphics.setBlendMode(mode == 'add' and 'alpha' or 'add')
  end
end

function love.update(dt)
  _ticks = _ticks + dt
  if _ticks > 5.0 then
    _phrase = SET_1[math.random(1, 6)] .. ' ' .. SET_2[math.random(1, 6)]
    _ticks = 0.0
  end

  for _, point in ipairs(_points) do
    local x = point.x + point.vx * dt
    local y = point.y + point.vy * dt
    if x < 0 then
      x = 0
      point.vx = -point.vx
    end
    if x >= love.graphics.getWidth() then
      x = love.graphics.getWidth()
      point.vx = -point.vx
    end
    if y < 0 then
      y = 0
      point.vy = -point.vy
    end
    if y >= love.graphics.getHeight() then
      y = love.graphics.getHeight()
      point.vy = -point.vy
    end
    point.x = x
    point.y = y
  end
end