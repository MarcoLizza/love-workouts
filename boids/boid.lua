local Arrays = require('lib/collections/arrays')
local Vector = require('lib/math/vector')

local Palette = require('assets/palettes/pico8')

local Boid = {}

Boid.__index = Boid

local OBSTACLE_RANGE_MULTIPLIER = 16

local MINIMUM_SPEED = 8
local MAXIMUM_SPEED = 192

local MINIMUM_SPEED_SQUARED = MINIMUM_SPEED * MINIMUM_SPEED
local MAXIMUM_SPEED_SQUARED = MAXIMUM_SPEED * MAXIMUM_SPEED

local unpack = unpack or table.unpack

function Boid.new(position, angle, fov)
  return setmetatable({
    color = Palette[math.random(1, #Palette)],
    fov = fov,
    position = position,
    velocity = Vector.from_polar(angle, MINIMUM_SPEED),
    aim = nil,
    aim_timer = 0,
    flockmates = {} }, Boid)
end

function Boid:find_flockmates(objects, radius)
  local radius_squared = radius * radius
  local flockmates = Arrays.filter(objects,
    function(value, index, length, array)
      if self ~= value then
        local angle = self.position:angle_to(value.position)
        if math.abs(angle) > self.fov then
          return false
        end

        -- If the checked object is an obstacle, we detect if far more earlier.
        local range = value.is_obstacle and (radius_squared * OBSTACLE_RANGE_MULTIPLIER) or radius_squared

        local distance_squared = self.position:distance_from_squared(value.position)
        if distance_squared > range then
          return false
        end
        return true
      end
    end)
  return flockmates
end

function Boid:update(flockmates, velocity, dt)
  self.velocity:add(velocity)
  local speed_squared = self.velocity:magnitude_squared()
  if speed_squared > 0.0 and speed_squared < MINIMUM_SPEED_SQUARED then
    self.velocity = self.velocity:normalize(MINIMUM_SPEED)
  elseif speed_squared > MAXIMUM_SPEED_SQUARED then
    self.velocity = self.velocity:normalize(MAXIMUM_SPEED)
  end
  self.position:add(self.velocity:clone():scale(dt))

  self.flockmates = flockmates

  self.aim_timer = self.aim_timer - dt
  if self.aim_timer <= 0 then
    if self.aim then
      self.aim = nil
    end
      local set_aim = math.random() <= 0.25
      if set_aim then
        local x = math.random(0, love.graphics.getWidth() - 1)
        local y = math.random(0, love.graphics.getHeight() - 1)
        self.aim = Vector.new(x, y)
      end
    end
    self.aim_timer = math.random(5, 15)
  end

function Boid:draw_fast(debug, radius)
  local position = self.position

  love.graphics.push()
  love.graphics.translate(position.x, position.y)

  local velocity = self.velocity
  local angle, _ = velocity:to_polar()

  love.graphics.rotate(angle)

  local tip = Vector.from_polar(0, 6)
  local left_tail = Vector.from_polar(-self.fov, 6)
  local right_tail = Vector.from_polar(self.fov, 6)

  local r, g, b = unpack(self.color)
  love.graphics.setColor(r, g, b, 1.0)
  love.graphics.polygon('fill', tip.x, tip.y, right_tail.x, right_tail.y, left_tail.x, left_tail.y)

  if debug then
    love.graphics.setColor(0.5, 1.0, 0.5, 0.1)
    love.graphics.arc('fill', 'pie', 0, 0, radius, -self.fov, self.fov, 16)

    love.graphics.setColor(1.0, 0.5, 0.5, 0.1)
    love.graphics.circle('line', 0, 0, radius)

    love.graphics.setColor(1.0, 1.0, 1.0, 0.25)
    for _, object in ipairs(self.flockmates) do
      love.graphics.line(0, 0, object.position.x - position.x, object.position.y - position.y)
    end
  end

  love.graphics.pop()
end

function Boid:draw(debug, radius)
  local position = self.position
  local velocity = self.velocity
  local r, g, b = unpack(self.color)
  local angle, _ = velocity:to_polar()

  local tip = Vector.from_polar(angle, 6, position:unpack())
  local left_tail = Vector.from_polar(angle - self.fov, 6, position:unpack())
  local right_tail = Vector.from_polar(angle + self.fov, 6, position:unpack())

  love.graphics.setColor(r, g, b, 1.0)
  love.graphics.polygon('fill', tip.x, tip.y, right_tail.x, right_tail.y, left_tail.x, left_tail.y)

  if debug then
    love.graphics.setColor(0.5, 1.0, 0.5, 0.1)
    love.graphics.arc('fill', 'pie', position.x, position.y, radius, angle - self.fov, angle + self.fov, 16)

    love.graphics.setColor(1.0, 0.5, 0.5, 0.1)
    love.graphics.circle('line', position.x, position.y, radius)

    if self.aim then
      love.graphics.setColor(r, g, b, 0.5)
      love.graphics.line(position.x, position.y, self.aim.x, self.aim.y)
    end

    love.graphics.setColor(1.0, 1.0, 1.0, 0.25)
    for _, object in ipairs(self.flockmates) do
      love.graphics.line(position.x, position.y, object.position.x, object.position.y)
    end
  end
end

return Boid