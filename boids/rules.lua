local Arrays = require('lib/collections/arrays')
local Vector = require('lib/math/vector')

local Rules = {}

function Rules.find_neighbours(self, boids, radius)
  local radius_squared = radius * radius
  return Arrays.filter(boids, function(value, index, length, array)
                                if self ~= value then
                                  local distance_squared = self.position:distance_from_squared(value.position)
                                  if distance_squared <= radius_squared then
                                    return true
                                  end
                                end
                              end)
end

function Rules.separation(self, neighbours, params)
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
  return velocity:normalize_if_not_zero(params.weight)
end

function Rules.alignment(self, neighbours, params)
  local velocity = Vector.new()
  if #neighbours == 0 then
    return velocity
  end
  for _, boid in ipairs(neighbours) do
    velocity:add(boid.velocity)
  end
  return velocity:normalize_if_not_zero(params.weight)
end

function Rules.cohesion(self, neighbours, params)
  local position = Vector.new()
  if #neighbours == 0 then
    return position
  end
  for _, boid in ipairs(neighbours) do
    position:add(boid.position)
  end
  local velocity = position:clone():sub(self.position)
  return velocity:normalize_if_not_zero(params.weight)
end

function Rules.stay_visible(self, neighbours, params)
  local velocity = Vector.new(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
  velocity:sub(self.position)
  return velocity:normalize_if_not_zero(params.weight)
end

function Rules.avoid_obstacle(self, neighbours, params)
  local velocity = Vector.new()
  if #params.obstacles == 0 then
    return velocity
  end
  for _, obstacle in ipairs(params.obstacles) do
    if obstacle:distance_from(self.position) <= 16 then
      velocity:add(self.position)
      velocity:sub(obstacle)
    end
  end
  return velocity:normalize_if_not_zero(params.weight)
end

return Rules