--[[
http://www.kfish.org/boids/pseudocode.html
https://gamedevelopment.tutsplus.com/tutorials/3-simple-rules-of-flocking-behaviors-alignment-cohesion-and-separation--gamedev-3444
http://www.red3d.com/cwr/boids/
https://github.com/iamwilhelm/frock/blob/master/boid.lua
https://en.wikipedia.org/wiki/Exterior_algebra
https://en.wikipedia.org/wiki/Vector_projection
https://math.stackexchange.com/questions/2239169/reflecting-a-vector-over-another-line
https://www.youtube.com/watch?v=QbUPfMXXQIY
https://github.com/jackaperkins/boids/blob/master/Boid.pde
]]--

-- Could this become a game? Underwater chasing?

local Arrays = require('lib/collections/arrays')
local Vector = require('lib/math/vector')

local Boid = require('boid')
local Obstacle = require('obstacle')
local Rules = require('rules')

local BOIDS = 32
local OBSTACLES_PADDING = 16
local INFLUENCE_RADIUS = 48
local FOV = math.pi / 4 * 3

local RULES = {
  { rule = Rules.alignment, weight = 4 },
  { rule = Rules.cohesion, weight =  2 },
  { rule = Rules.separation, weight = 3 },
  { rule = Rules.follow, weight = 1 },
  -- scattering
  -- perching
}

local _objects = {}
local _debug = false

local function spawn(objects)
  local x = math.random(0, love.graphics.getWidth() - 1)
  local y = math.random(0, love.graphics.getHeight() - 1)
  local angle = math.random() * 2 * math.pi
  table.insert(objects, Boid.new(Vector.new(x, y), angle, FOV, INFLUENCE_RADIUS))
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
  love.graphics.setDefaultFilter('nearest', 'nearest', 1)

  love.mouse.setVisible(true)
  love.mouse.setGrabbed(false)

  if love.filesystem.getInfo("assets/mappings/gamecontrollerdb.txt") then
    love.joystick.loadGamepadMappings("assets/mappings/gamecontrollerdb.txt")
  end

  math.randomseed(os.time())
  for _ = 1, 1000 do
    math.random()
  end

  for _ = 1, BOIDS do
    spawn(_objects)
  end
end

local _flockmates = {}

function love.update(dt)
  _flockmates = {}

  local velocities = {}
  for _, object in ipairs(_objects) do
    local flockmates = object:find_flockmates(_objects)

    local velocity = Vector.new()
    for _, rule in ipairs(RULES) do
      velocity:add(rule.rule(object, flockmates, { weight = rule.weight }))
    end
    velocities[object] = velocity

    _flockmates[object] = flockmates
  end

  for object, velocity in pairs(velocities) do
    object:update(velocity, dt)
  end
end

function love.draw()
  for _, object in ipairs(_objects) do
    object:draw(_debug)
  end

  if _debug then
    for object, flockmates in pairs(_flockmates) do
      for _, flockmate in ipairs(flockmates) do
        love.graphics.setColor(1.0, 1.0, 1.0, 0.25)
        love.graphics.line(object.position.x, object.position.y, flockmate.position.x, flockmate.position.y)
      end
    end
  end

  love.graphics.setColor(1.0, 1.0, 1.0)
  love.graphics.print(love.timer.getFPS() .. ' FPS', 0, 0)
  love.graphics.print(string.format('%d objects(s)', #_objects), 0, 16)
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
