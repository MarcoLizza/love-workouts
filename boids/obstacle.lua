local Vector = require('lib/math/vector')

local Obstacle = {}

Obstacle.__index = Obstacle

local unpack = unpack or table.unpack

function Obstacle.new(position, angle)
  return setmetatable({
    is_obstacle = true,
    color = { 1.0, 1.0, 1.0 },
    position = position,
    velocity = Vector.new() }, Obstacle)
end

function Obstacle:neighbours(Obstacles, radius)
  return {}
end

function Obstacle:update(velocity, dt)
end

function Obstacle:draw(debug, radius)
  local position = self.position
  local r, g, b = unpack(self.color)

  love.graphics.setColor(r, g, b, 0.25)
  love.graphics.circle('fill', position.x, position.y, 4)
end

return Obstacle