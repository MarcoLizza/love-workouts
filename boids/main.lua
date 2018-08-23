-- http://www.kfish.org/boids/pseudocode.html

-- Could this become a game? Underwater chasing?

local Arrays = require('lib/collections/arrays')
local Vector = require('lib/math/vector')

local Boid = require('boid')
local Obstacle = require('obstacle')
local Rules = require('rules')

local BOIDS = 128

local INFLUENCE_RADIUS = 16

local OBSTACLES_PADDING = 16

local RULES = {
  { rule = Rules.alignment, weight = 3 },
  { rule = Rules.cohesion, weight = 1 },
  { rule = Rules.separation, weight = 4 },
  { rule = Rules.stay_visible, weight = 2 },
  -- scattering
  -- occasionally, a boid pick a target and hold it for a while
  -- perching
  -- scanning radius for obstacles should be greater? They are more visible?
}

local _objects = {}
local _radius = INFLUENCE_RADIUS
local _debug = false

local function spawn(objects)
  local x = math.random(0, love.graphics.getWidth() - 1)
  local y = math.random(0, love.graphics.getHeight() - 1)
  local angle = math.random() * 2 * math.pi
  table.insert(objects, Boid.new(Vector.new(x, y), angle, math.pi / 4 * 3))
end

local function kill(objects)
  Arrays.erase_if(objects,
    function(value, index, length, array)
      if not value.is_obstacle then
        return true, true -- delete only the first boid we find
      end
    end)
end

function love.load(args)
  if args[#args] == '-debug' then require('mobdebug').start() end

  love.graphics.setDefaultFilter('nearest', 'nearest', 1)
  love.graphics.setBlendMode('add')

  love.mouse.setVisible(true)
  love.mouse.setGrabbed(false)

  math.randomseed(os.time())
  for _ = 1, 1000 do
    math.random()
  end

  for _ = 1, BOIDS do
    spawn(_objects)
  end
end

function love.draw()
  for _, object in ipairs(_objects) do
    object:draw(_debug, _radius)
  end

  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.print(love.timer.getFPS() .. ' FPS', 0, 0)
  love.graphics.print(string.format('%d objects(s) w/ radius %d', #_objects, _radius), 0, 16)
end

function love.mousepressed(x, y, button, istouch, presses)
  local point = Vector.new(x, y)

  local erased = Arrays.erase_if(_objects,
    function(value, index, length, array)
      if not value.is_obstacle then
        return false
      end
      local distance = point:distance_from(value.position)
      if distance < OBSTACLES_PADDING then
        return true, true -- Remove just the first viable obstacle
      end
    end)

  if erased == 0 then
    _objects[#_objects + 1] = Obstacle.new(point, 0.0)
  end
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'f1' then
    kill(_objects)
  elseif key == 'f2' then
    spawn(_objects)
  elseif key == 'f3' then
    _radius = _radius - 1
  elseif key == 'f4' then
    _radius = _radius + 1
  elseif key == 'f5' then
    Arrays.erase_if(_objects,
      function(value, index, length, array)
        if value.is_obstacle then
          return true
        end
      end)
  elseif key == 'f6' then
    local padding = OBSTACLES_PADDING * 2
    for y = 0, love.graphics.getHeight(), padding do
      for x = 0, love.graphics.getWidth(), padding do
        _objects[#_objects + 1] = Obstacle.new(Vector.new(x, y), 0.0)
      end
    end
  elseif key == 'f12' then
    _debug = not _debug
  end
end

function love.update(dt)
  local velocities = {}
  for _, object in ipairs(_objects) do
    local flockmates = object:find_flockmates(_objects, _radius) -- obstacles should be static boids?
    object.flockmates = flockmates
    local velocity = Vector.new()
    for _, rule in ipairs(RULES) do
      velocity:add(rule.rule(object, flockmates, { weight = rule.weight }))
    end
    velocities[object] = velocity
  end

  for object, velocity in pairs(velocities) do
    object:update(object.flockmates, velocity, dt)
  end
end