local GRID_WIDTH = 24
local GRID_HEIGHT = 24

local COLORS = {
  ['0'] = { 0.500, 0.250, 0.500 },
  ['1'] = { 0.250, 0.500, 0.250 },
  ['2'] = { 0.500, 0.500, 1.000 }
}

local _grid = {}

local function distance_squared(p0, p1)
  local a = p0[1] - p1[1]
  local b = p0[2] - p1[2]
  return (a * a) + (b * b)
end

local function distance(p0, p1)
  return math.sqrt(distance_squared(p0, p1))
end

local function influence(p0, p1, radius)
  local radius_squared = radius * radius
  return radius_squared - distance_squared(p0, p1)
--  return radius - distance(p0, p1)
end

local function filter(point, bundle, radius)
  local zones = {}
  for _, v in ipairs(bundle) do
    if v.value then
      local alpha = influence(point, { v.x, v.y }, radius)
      if alpha > 0 then
        if not zones[v.value] then
          zones[v.value] = 0
        end
        zones[v.value] = zones[v.value] + alpha
      end
    end
  end
  return zones
end

local function compute(x, y, bundle, radius)
  local zones = filter({ x, y }, bundle, radius)
  
  local aux = {}
  for k, v in pairs(zones) do
    aux[#aux + 1] = { key = k, value = v }
  end
  table.sort(aux, function(a, b) return a.value > b.value end)

  if #aux == 0 then
    return { 0, 0, 0 }
  else
    return COLORS[aux[1].key]
  end
end

function love.load(args)
  if args[#args] == '-debug' then require('mobdebug').start() end
--[[
  for i = 1, 100 do
    local x = math.random(0, love.graphics.getWidth() - 1)
    local y = math.random(0, love.graphics.getHeight() - 1)
      _grid[#_grid + 1] = { x = x, y = y, value = nil }
  end
]]--
  for y = 0, love.graphics.getHeight(), GRID_HEIGHT do
    for x = 0, love.graphics.getWidth(), GRID_WIDTH do
      _grid[#_grid + 1] = { x = x, y = y, value = nil }
    end
  end
end

function love.draw()
  for y = 0, love.graphics.getHeight() do
    for x = 0, love.graphics.getWidth()  do
      local color = compute(x, y, _grid, GRID_WIDTH)
      love.graphics.setColor(color)
--      love.graphics.circle('fill', x, y, 2)
      love.graphics.points(x, y)
    end
  end

  love.graphics.setColor(0.75, 0.75, 0.75)
  for _, v in ipairs(_grid) do
--    love.graphics.circle('fill', v.x, v.y, 2)
    love.graphics.points(v.x, v.y)
  end

  love.graphics.print(love.timer.getFPS() .. " FPS", 0, 0)
end

local function nearest(x, y, bundle)
  local index = nil
  local max = 99999
  for i, v in ipairs(bundle) do
    local d = distance({ x, y }, { v.x, v.y })
    if d < max then
      max = d
      index = i
    end
  end
  return index
end

function love.mousepressed(x, y, button)
  local index = nearest(x, y, _grid)
  if not index then
    return
  end
  if button == 1 then
    _grid[index].value = '0'
  elseif button == 2 then
    _grid[index].value = '1'
  elseif button == 3 then
    _grid[index].value = '2'
  end
end

function love.update(dt)
end
