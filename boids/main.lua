-- http://www.kfish.org/boids/pseudocode.html

local Rules = require('rules')
local Vectors = require('vectors')

local BOIDS = 256

local SPEED_LIMIT = 64

local COLORS = {
  { 1.0, 0.0, 0.0 },
  { 0.0, 1.0, 0.0 },
  { 0.0, 0.0, 1.0 },
  { 1.0, 0.0, 1.0 },
  { 1.0, 1.0, 0.0 },
  { 0.0, 1.0, 1.0 },
  { 1.0, 1.0, 1.0 }
}

local RULES = {
  { rule = Rules.alignment, weight = 2 },
  { rule = Rules.cohesion, weight = 3 },
  { rule = Rules.separation, weight = 4 },
  { rule = Rules.stay_visible, weight = 1 },
}

local _boids = {}
local _threshold = 128.0

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

local function spawn(boids)
  local x = math.random(0, love.graphics.getWidth() - 1)
  local y = math.random(0, love.graphics.getWidth() - 1)
  local angle = math.random() * math.pi
  local color =  COLORS[math.random(1, #COLORS)]
  table.insert(boids, {
    color = color,
    position = { x = x, y = y },
    velocity = { x = math.cos(angle) * SPEED_LIMIT, y = math.sin(angle) * SPEED_LIMIT }
  })
end

local function kill(boids)
  table.remove(boids)
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

  for _ = 1, BOIDS do
    spawn(_boids)
  end
end

function love.draw()
  for _, boid in ipairs(_boids) do
    local position = boid.position
    local velocity = boid.velocity
    local r, g, b = unpack(boid.color)
    love.graphics.setColor(r, g, b)
--    love.graphics.line(position.x, position.y, position.x - velocity.x, position.y - velocity.y)
--    love.graphics.setColor(1.0, 1.0, 1.0)
    love.graphics.circle('fill', position.x, position.y, 2)
  end
  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.print(love.timer.getFPS() .. ' FPS', 0, 0)
  love.graphics.print(string.format('%d point(s) w/ threshold %d (%s)', #_boids, _threshold, love.graphics.getBlendMode()), 0, 16)
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'f1' then
    kill(_boids)
  elseif key == 'f2' then
    spawn(_boids)
  elseif key == 'f12' then
    local mode = love.graphics.getBlendMode()
    love.graphics.setBlendMode(mode == 'add' and 'alpha' or 'add')
  end
end

function love.update(dt)
  for _, boid in ipairs(_boids) do
    local neighbours = Rules.find_neighbours(boid, _boids, 16)
    local velocity = Vectors.new()
    for _, rule in ipairs(RULES) do
      velocity = Vectors.add(velocity, rule.rule(boid, neighbours, rule.weight))
    end

    boid.velocity = Vectors.normalize(Vectors.add(boid.velocity, velocity), SPEED_LIMIT)

    boid.position = Vectors.add(boid.position, Vectors.scale(boid.velocity, dt))
  end
end