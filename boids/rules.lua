local Vector = require('lib/math/vector')

local Rules = {}

function Rules.separation(self, objects, params)
  local velocity = Vector.new()
  for _, object in ipairs(objects) do
    -- TODO: should the "pulse" vector be proportial to the proximity? Nearer is stronger?
--    local distance = self.position:clone():sub(boid.position)
--    velocity:add(distance)
    velocity:add(self.position)
    velocity:sub(object.position)
  end
  return velocity:normalize_if_not_zero(params.weight)
end

function Rules.alignment(self, objects, params)
  local velocity = Vector.new()
  for _, object in ipairs(objects) do
    velocity:add(object.velocity)
  end
  return velocity:normalize_if_not_zero(params.weight)
end

function Rules.cohesion(self, objects, params)
  local velocity = Vector.new()
  -- Compute the centroid of the objects (sum of the position divided by
  -- the number of vectors)
  local count = 0
  for _, object in ipairs(objects) do
    if not object.is_obstacle then
      velocity:add(object.position)
      count = count + 1
    end
  end
  if count > 0 then
    -- Find the center-of-mass and convert to a "direction" vector.
    velocity:scale(1 / count):sub(self.position)
  end
  return velocity:normalize_if_not_zero(params.weight)
end

function Rules.follow(self, objects, params)
  local velocity = Vector.new()
  if self.aim then
    velocity = self.aim:clone():sub(self.position)
  end
  return velocity:normalize_if_not_zero(params.weight)
end

function Rules.stay_visible(self, objects, params)
  local velocity = Vector.new(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
  velocity:sub(self.position)
  return velocity:normalize_if_not_zero(params.weight)
end

return Rules