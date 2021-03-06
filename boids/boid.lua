local Vector = require('lib/math/vector')
local Palette = require('assets/palettes/pico8')

local Boid = {}

Boid.__index = Boid

local FOV = math.pi / 4 * 3
local SIZE = 8

local OBSTACLE_RANGE_MULTIPLIER = 8

local MINIMUM_SPEED = 8
local MAXIMUM_SPEED = 128

local MINIMUM_SPEED_SQUARED = MINIMUM_SPEED * MINIMUM_SPEED
local MAXIMUM_SPEED_SQUARED = MAXIMUM_SPEED * MAXIMUM_SPEED

local unpack = unpack or table.unpack

function Boid.new(position, angle, fov, radius)
  return setmetatable({
    color = Palette[math.random(2, #Palette)], -- Avoid the BLACK
    fov = fov,
    radius = radius,
    position = position,
    velocity = Vector.from_polar(angle, MINIMUM_SPEED),
    aim = { position = nil, timer = 0, reference = 0 },
    radius_squared = radius * radius}, Boid)
end

function Boid:find_flockmates(objects)
  local flockmates = {}
  for _, object in ipairs(objects) do
    if self:is_nearby(object) then
      flockmates[#flockmates + 1] = object
    end
  end
  return flockmates
end

function Boid:is_nearby(object)
  if self == object then
    return false
  end

  local angle = self.position:angle_to(object.position)
  if math.abs(angle) > self.fov then
    return false
  end

  local distance_squared = self.position:distance_from_squared(object.position)
  -- If the checked object is an obstacle, we detect if far more earlier.
  local range = object.is_obstacle and (self.radius_squared * OBSTACLE_RANGE_MULTIPLIER) or self.radius_squared
  if distance_squared > range then
    return false
  end

  return true
end

function Boid:update(velocity, dt)
  self.velocity:add(velocity)
  local speed_squared = self.velocity:magnitude_squared()
  if speed_squared > 0.0 and speed_squared < MINIMUM_SPEED_SQUARED then
    self.velocity = self.velocity:normalize(MINIMUM_SPEED)
  elseif speed_squared > MAXIMUM_SPEED_SQUARED then
    self.velocity = self.velocity:normalize(MAXIMUM_SPEED)
  end
  self.position:add(self.velocity:clone():scale(dt))

  self.aim.timer = self.aim.timer - dt

  local elapsed = self.aim.timer <= 0
  local reached = self.aim.position and self.position:distance_from_squared(self.aim.position) <= self.radius_squared
  local retarget = not self.aim.position and (self.position.x < 0 or
    self.position.x >= love.graphics.getWidth() or
    self.position.y < 0 or
    self.position.y >= love.graphics.getHeight())

  if elapsed or reached or retarget then
    if self.aim.position and not retarget then
      self.aim.position = nil
    else
      local set_aim = math.random() <= (retarget and 1.0 or 0.333)
      if set_aim then
        local x = math.random(32, love.graphics.getWidth() - 33)
        local y = math.random(32, love.graphics.getHeight() - 33)
        self.aim.position = Vector.new(x, y)
      end
    end
    self.aim.reference = math.random(5, 15)
    self.aim.timer = self.aim.reference
  end
end

function Boid:draw(debug)
  local angle, _ = self.velocity:to_polar()
  local x, y = self.position:unpack()

  local tip = Vector.from_polar(angle, SIZE, x, y)
  local left_tail = Vector.from_polar(angle - FOV, SIZE, x, y)
  local right_tail = Vector.from_polar(angle + FOV, SIZE, x, y)

  local r, g, b = unpack(self.color)
  love.graphics.setColor(r, g, b, 1.0)
  love.graphics.polygon('fill', tip.x, tip.y, right_tail.x, right_tail.y, left_tail.x, left_tail.y)

  if debug then
    love.graphics.setColor(0.5, 1.0, 0.5, 0.1)
    love.graphics.arc('fill', 'pie', x, y, self.radius, angle - self.fov, angle + self.fov, 16)

    love.graphics.setColor(1.0, 0.5, 0.5, 0.1)
    love.graphics.circle('line', x, y, self.radius)

    if self.aim.position then
      local ax, ay = self.aim.position:unpack()
      local alpha = self.aim.timer / self.aim.reference
      love.graphics.setColor(r, g, b, alpha * 0.5)
      love.graphics.line(x, y, ax, ay)
      love.graphics.circle('fill', ax, ay, 3)
    end
  end
end

return Boid