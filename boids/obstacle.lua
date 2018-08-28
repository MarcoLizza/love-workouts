local Vector = require('lib/math/vector')

local Obstacle = {}

Obstacle.__index = Obstacle

local unpack = unpack or table.unpack

function Obstacle.new(position, angle)
  return setmetatable({
    is_obstacle = true,
    color = { 1.0, 0.0, 0.0 },
    position = position,
    velocity = Vector.from_polar(angle, 0.0) }, Obstacle)
end

function Obstacle:find_flockmates(objects)
  return {}
end

function Obstacle:is_nearby(object)
  return false
end

function Obstacle:update(velocity, dt)
end

function Obstacle:draw(debug)
  local position = self.position
  local r, g, b = unpack(self.color)

  for i = 0, 5 - 1 do
    local ratio = (0.5 / 5) * i
    love.graphics.setColor(r, g, b, 0.5 - ratio)
    love.graphics.circle('fill', position.x, position.y, 32 * ratio)
  end
end

return Obstacle