local Vector = {}

Vector.__index = Vector

function Vector.new(x, y)
  return setmetatable({ x = x or 0, y = y or 0}, Vector)
end

function Vector:clone()
  return Vector.new(self.x, self.y)
end

function Vector.from_polar(a, l)
  return Vector.new(math.cos(a) * l, math.sin(a) * l)
end

function Vector:to_polar()
  return math.atan2(self.y, self.x), self:length()
end

function Vector:unpack()
  return self.x, self.y
end

function Vector:is_zero()
  return self.x == 0 and self.y == 0
end

function Vector:is_equal(v)
  return self.x == v.x and self.y == v.y
end

function Vector:assign(v)
  self.x = v.x
  self.y = v.y
  return self
end

function Vector:add(v)
  self.x = self.x + v.x
  self.y = self.y + v.y
  return self
end

function Vector:sub(v)
  self.x = self.x - v.x
  self.y = self.y - v.y
  return self
end

function Vector:scale(s)
  self.x = self.x * s
  self.y = self.y * s
  return self
end

-- | cos(a)  -sin(a) | | x |   | x' |
-- |                 | |   | = |    |
-- | sin(a)   cos(a) | | y |   | y' |
function Vector:rotate(a)
  local cos = math.cos(a)
  local sin = math.sin(a)
  self.x, self.y = cos * self.x - sin * self.y, sin * self.x + cos * self.y
  return self
end

function Vector:negate()
  self.x, self.y = -self.x, -self.y
  return self
end

-- COUNTER-CLOCKWISE perpendicular vector.
function Vector:perpendiculal()
  self.x, self.y = -self.y, self.x
  return self
end

-- a dot b
-- ------- b
-- b dot b
--
-- https://en.wikipedia.org/wiki/Vector_projection
function Vector:project(v)
  local s = self:dot(v) / v:dot(v)
  self.x, self.y = s * v.x, s * v.y
  return self
end

--       a dot b
-- a - 2 ------- b
--       b dot b
--
-- https://math.stackexchange.com/questions/2239169/reflecting-a-vector-over-another-line
function Vector:mirror(v)
  local s = 2 * self:dot(v) / v:dot(v)
  self.x, self.y = self.x - s * v.x, self.y - s * v.y
  return self
end

function Vector:dot(v)
  return (self.x * v.x) + (self.y * v.y)
end

-- Area of the parallelogram described by the vector, i.e. the DETERMINAND of
-- the matrix with the vectors as columns (or rows).
--
-- It is also (if scaled) the sine of the angle between the vectors. That means
-- that if NEGATIVE the second vector is CLOCKWISE from the first one, if
-- POSITIVE the second vector is COUNTER-CLOCKWISE from the first one.
--
-- NOTE: when on a 2D display, since the `y` component inverts it sign, also
--       the rule inverts! That is if NEGATIVE then is COUNTER-CLOCKWISE.
--
-- https://en.wikipedia.org/wiki/Exterior_algebra
function Vector:cross(v)
  return (self.x * v.y) - (self.y * v.x)
end

function Vector:length_squared()
  return self:dot(self)
end

function Vector:length()
  return math.sqrt(self:length_squared())
end

function Vector:distance_squared(v)
  local dx = self.x - v.x
  local dy = self.y - v.y
  return (dx * dx) + (dy * dy)
end

function Vector:distance(v)
  return math.sqrt(self:distance_squared(v))
end

function Vector:normalize(l)
  return self:scale((l or 1) / self:length())
end

-- Normalize to the give `l` length only when greater than it.
function Vector:trim(l)
  local s = l * l / self:length_squared()
  if s >= 1 then
    return self
  end
  return self:scale(math.sqrt(s))
end

function Vector:angle_to(v)
  if v then
    return math.atan(v.y- self.y, v.x - self.x)
  end
  return math.atan(self.y, self.x)
end

function Vector:angle_between(v)
  return math.atan(self.y, self.x) - math.atan(v.y, v.x)
end

Vector.ZERO = Vector.new(0, 0)

return Vector