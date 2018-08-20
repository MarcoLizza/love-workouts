local Vector = require('vector')

local Rules = {}

function Rules.find_neighbours(self, boids, radius)
  local radius_squared = radius * radius
  local neighbours = {}
  for _, boid in ipairs(boids) do
    if self ~= boid then
        local distance_squared = self.position:distance_squared(boid.position)
        if distance_squared <= radius_squared then
          neighbours[#neighbours + 1] = boid
        end
      end
  end
  return neighbours
end

function Rules.separation(self, neighbours, weight)
  local velocity = Vector.new()
  if #neighbours == 0 then
    return velocity
  end
  for _, boid in ipairs(neighbours) do
--    local distance = self.position:clone():sub(boid.position)
--    velocity:add(distance)
    velocity:add(self.position)
    velocity:sub(boid.position)
  end
  return velocity:normalize(weight)
end

function Rules.alignment(self, neighbours, weight)
  local velocity = Vector.new()
  if #neighbours == 0 then
    return velocity
  end
  for _, boid in ipairs(neighbours) do
    velocity:add(boid.velocity)
  end
  return velocity:normalize(weight)
end

function Rules.cohesion(self, neighbours, weight)
  local position = Vector.new()
  if #neighbours == 0 then
    return position
  end
  for _, boid in ipairs(neighbours) do
    position:add(boid.position)
  end
  local velocity = position:clone():sub(self.position)
  return velocity:normalize(weight)
end

function Rules.stay_visible(self, neighbours, weight)
  local velocity = Vector.new(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
  velocity:sub(self.position)
  return velocity:normalize(weight)
end

return Rules