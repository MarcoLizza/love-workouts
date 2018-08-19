local Vectors = require('vectors')

local Rules = {}

function Rules.find_neighbours(self, boids, radius)
  local neighbours = {}
  for _, boid in ipairs(boids) do
    if self ~= boid then
        local distance = Vectors.sub(boid.position, self.position)
        if Vectors.length(distance) <= radius then
          neighbours[#neighbours + 1] = boid
        end
      end
  end
  return neighbours
end

function Rules.separation(self, neighbours, weight)
  local velocity = Vectors.new()
  if #neighbours == 0 then
    return velocity
  end
  for _, boid in ipairs(neighbours) do
    local distance = Vectors.sub(self.position, boid.position)
    velocity = Vectors.add(velocity, distance)
  end
  return Vectors.normalize(velocity, weight)
end

function Rules.alignment(self, neighbours, weight)
  local velocity = Vectors.new()
  if #neighbours == 0 then
    return velocity
  end
  for _, boid in ipairs(neighbours) do
    velocity = Vectors.add(velocity, boid.velocity)
  end
  -- velocity = Vectors.scale(velocity, 1 / #neighbours)
  return Vectors.normalize(velocity, weight)
end

function Rules.cohesion(self, neighbours, weight)
  local position = Vectors.new()
  if #neighbours == 0 then
    return position
  end
  for _, boid in ipairs(neighbours) do
    position = Vectors.add(position, boid.position)
  end
  local velocity = Vectors.sub(position, self.position)
  -- velocity = Vectors.scale(velocity, 1 / #neighbours)
  return Vectors.normalize(velocity, weight)
end

function Rules.stay_visible(self, neighbours, weight)
  local center = Vectors.new(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
  local velocity = Vectors.sub(center, self.position)
  return Vectors.normalize(velocity, weight)
end

return Rules