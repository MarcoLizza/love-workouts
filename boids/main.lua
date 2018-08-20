-- http://www.kfish.org/boids/pseudocode.html

local Rules = require('rules')
local Vector = require('vector')

local BOIDS = 128

local MINIMUM_SPEED = 8
local MAXIMUM_SPEED = 256

local MINIMUM_SPEED_SQUARED = MINIMUM_SPEED * MINIMUM_SPEED
local MAXIMUM_SPEED_SQUARED = MAXIMUM_SPEED * MAXIMUM_SPEED

local MINIMUM_SIZE = 1
local MAXIMUM_SIZE = 6

local INFLUENCE_RADIUS = 16

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
local _radius = INFLUENCE_RADIUS
local _debug = false

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
  local y = math.random(0, love.graphics.getHeight() - 1)
  local angle = math.random() * 2 * math.pi
  local color =  COLORS[math.random(1, #COLORS)]
  table.insert(boids, {
    color = color,
    position = Vector.new(x, y),
    velocity = Vector.from_polar(angle, MINIMUM_SPEED)
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
    local speed = velocity:length_squared()
    local size = ((MAXIMUM_SPEED_SQUARED - speed) / (MAXIMUM_SPEED_SQUARED - MINIMUM_SPEED_SQUARED)) * (MAXIMUM_SIZE - MINIMUM_SIZE) + MINIMUM_SIZE
    love.graphics.circle('fill', position.x, position.y, size)

    if not debug then
      velocity = velocity:clone():normalize(_radius)
      love.graphics.setColor(1.0, 1.0, 1.0, 0.25)
      love.graphics.line(position.x, position.y, position.x + velocity.x, position.y + velocity.y)

      love.graphics.setColor(1.0, 1.0, 1.0, 0.25)
      love.graphics.circle('line', position.x, position.y, _radius)
    end
  end
  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.print(love.timer.getFPS() .. ' FPS', 0, 0)
  love.graphics.print(string.format('%d boids(s) w/ radius %d', #_boids, _radius), 0, 16)
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'f1' then
    kill(_boids)
  elseif key == 'f2' then
    spawn(_boids)
  elseif key == 'f3' then
    _radius = _radius - 1
  elseif key == 'f4' then
    _radius = _radius + 1
  elseif key == 'f10' then
    _debug = not _debug
  end
end

function love.update(dt)
  local velocities = {}
  for _, boid in ipairs(_boids) do
    local neighbours = Rules.find_neighbours(boid, _boids, _radius)
    local velocity = Vector.new()
    for _, rule in ipairs(RULES) do
      velocity:add(rule.rule(boid, neighbours, rule.weight))
    end
    velocities[boid] = velocity
  end

  for boid, velocity in pairs(velocities) do
    boid.velocity:add(velocity)
    local speed_squared = boid.velocity:length_squared()
    if speed_squared < MINIMUM_SPEED_SQUARED then
      boid.velocity = boid.velocity:normalize(MINIMUM_SPEED)
    elseif speed_squared > MAXIMUM_SPEED_SQUARED then
      boid.velocity = boid.velocity:normalize(MAXIMUM_SPEED)
    end
    boid.position:add(boid.velocity:clone():scale(dt))
  end
end