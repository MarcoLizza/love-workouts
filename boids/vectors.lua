local Vectors = {}

function Vectors.new(x, y)
  return { x = x or 0, y = y or 0}
end

function Vectors.add(v1, v2)
  return { x = v1.x + v2.x, y = v1.y + v2.y }
end

function Vectors.sub(v1, v2)
  return { x = v1.x - v2.x, y = v1.y - v2.y }
end

function Vectors.scale(v, s)
  return { x = v.x * s, y = v.y * s }
end

function Vectors.length_squared(v)
  return (v.x * v.x) + (v.y * v.y)
end

function Vectors.length(v)
  return math.sqrt(Vectors.length_squared(v))
end

function Vectors.normalize(v, l)
  return Vectors.scale(v, (l or 1) / Vectors.length(v))
end

function Vectors.from_polar(l, a)
  return { x = math.cos(a) * l, y = math.sin(a) * l }
end

function Vectors.to_polar(v)
  return Vectors.length(v), math.atan2(v.y, v.x)
end

return Vectors