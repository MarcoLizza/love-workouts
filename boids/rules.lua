local Vector = require('lib/math/vector')

local Rules = {}

function Rules.separation(self, flockmates, params)
  local velocity = Vector.new()
  for _, object in ipairs(flockmates) do
    if self:is_nearby(object) then
      -- TODO: should the "pulse" vector be proportial to the proximity? Nearer is stronger?
--      local distance = self.position:clone():sub(boid.position)
--      velocity:add(distance)
      velocity:add(self.position)
      velocity:sub(object.position)
    end
  end
  return velocity:normalize_if_not_zero(params.weight)
end

function Rules.alignment(self, flockmates, params)
  local velocity = Vector.new()
  for _, object in ipairs(flockmates) do
    if not object.is_obstacle and self:is_nearby(object) then
      velocity:add(object.velocity)
    end
  end
  return velocity:normalize_if_not_zero(params.weight)
end

function Rules.cohesion(self, flockmates, params)
  local velocity = Vector.new()
  -- Compute the centroid of the flockmates (sum of the position divided by
  -- the number of vectors)
  local count = 0
  for _, object in ipairs(flockmates) do
    if not object.is_obstacle and self:is_nearby(object) then
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

function Rules.follow(self, flockmates, params)
  local velocity = Vector.new()
  if self.aim.position then
    velocity = self.aim.position:clone():sub(self.position)
  end
  return velocity:normalize_if_not_zero(params.weight)
end

return Rules