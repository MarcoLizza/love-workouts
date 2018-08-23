local Arrays = require('lib/collections/arrays')
local Math = require('lib/math/math')
local Vector = require('lib/math/vector')

local Palette = require('assets/palettes/pico8')

local Boid = {}

Boid.__index = Boid

local MINIMUM_SPEED = 8
local MAXIMUM_SPEED = 192

local MINIMUM_SPEED_SQUARED = MINIMUM_SPEED * MINIMUM_SPEED
local MAXIMUM_SPEED_SQUARED = MAXIMUM_SPEED * MAXIMUM_SPEED

local MINIMUM_SIZE = 1
local MAXIMUM_SIZE = 4

local unpack = unpack or table.unpack

function Boid.new(position, angle, fov)
  return setmetatable({
    color = Palette[math.random(1, #Palette)],
    position = position,
    velocity = Vector.from_polar(angle, MINIMUM_SPEED),
    fov = fov }, Boid)
end

function Boid:neighbours(boids, radius)
  local radius_squared = radius * radius
  local neighbours = Arrays.filter(boids,
    function(value, index, length, array)
      if self ~= value then
        local angle = self.position:angle_to(value.position)
        if math.abs(angle) > self.fov then
          return false
        end
        local distance_squared = self.position:distance_from_squared(value.position)
        if distance_squared > radius_squared then
          return false
        end
        return true
      end
    end)
  return neighbours
end

function Boid:update(velocity, dt)
  self.velocity:add(velocity)
  local speed_squared = self.velocity:magnitude_squared()
  if speed_squared < MINIMUM_SPEED_SQUARED then
    self.velocity = self.velocity:normalize(MINIMUM_SPEED)
  elseif speed_squared > MAXIMUM_SPEED_SQUARED then
    self.velocity = self.velocity:normalize(MAXIMUM_SPEED)
  end
  self.position:add(self.velocity:clone():scale(dt))
end

function Boid:draw(debug, radius)
  local position = self.position
  local velocity = self.velocity
  local r, g, b = unpack(self.color)

  love.graphics.setColor(r, g, b, 1.0)
  local speed = velocity:magnitude_squared()
  local size = Math.lerp(MINIMUM_SIZE, MAXIMUM_SIZE, (MAXIMUM_SPEED_SQUARED - speed) / (MAXIMUM_SPEED_SQUARED - MINIMUM_SPEED_SQUARED))
  love.graphics.circle('fill', position.x, position.y, size)

  if debug then
    local angle, _ = velocity:to_polar()
    local l = Vector.from_polar(angle - self.fov, radius)
    local c = Vector.from_polar(angle           , radius)
    local r = Vector.from_polar(angle + self.fov, radius)

    love.graphics.setColor(1.0, 1.0, 1.0, 0.25)
    love.graphics.line(position.x, position.y, position.x + l.x, position.y + l.y)
    love.graphics.circle('fill', position.x + c.x, position.y + c.y, 2)
--    love.graphics.line(position.x, position.y, position.x + c.x, position.y + c.y)
    love.graphics.line(position.x, position.y, position.x + r.x, position.y + r.y)

    love.graphics.setColor(1.0, 1.0, 1.0, 0.25)
    love.graphics.circle('line', position.x, position.y, radius)
  end
end

return Boid