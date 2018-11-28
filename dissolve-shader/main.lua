local _shader = nil
local _noise = nil
local _speed = 0.75

local _granularity = 40
local _threshold = 0

local function generate(granularity, width, height)
  local data = love.image.newImageData(width, height)
  local z = love.math.random() -- The third coordinate ensure a different "slice" of the noise.
  for y = 0, height -1 do
    for x = 0, width - 1 do
      local v = love.math.noise(x / granularity, y / granularity, z)
      data:setPixel(x, y, v, v, v, 1.0)
    end
  end
  return love.graphics.newImage(data)
end

function love.load(args)
  _noise = generate(_granularity, love.graphics.getDimensions())

  _shader = love.graphics.newShader([[

uniform Image _top;
uniform Image _bottom;
uniform float _threshold;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 noise = texture2D(texture, texture_coords);
    float delta = _threshold - noise.r;
    if (delta < 0.0) {
      return texture2D(_bottom, texture_coords);
    }
    if (delta > 0.025) {
      return texture2D(_top, texture_coords);
    }
    return vec4(1.0, 1.0, 1.0, 1.0);
}

    ]])

  _shader:send('_top', love.graphics.newImage('top.png'))
  _shader:send('_bottom', love.graphics.newImage('bottom.png'))
end

function love.update(dt)
  _threshold = _threshold + (_speed * dt)
  if _threshold > 1.0 then
    _threshold = 1.0
    _speed = -_speed
    _noise = generate(_granularity, love.graphics.getDimensions())
  end
  if _threshold < 0.0 then
    _threshold = 0.0
    _speed = -_speed
    _noise = generate(_granularity, love.graphics.getDimensions())
  end
end

function love.draw()
  _shader:send('_threshold', _threshold)

  love.graphics.push('all')
  love.graphics.setShader(_shader)
  love.graphics.draw(_noise)
  love.graphics.pop()

  love.graphics.print(string.format('%d FPS', love.timer.getFPS()), 0, 0)
  love.graphics.print(string.format('GRANULARITY = %d, THRESHOLD = %.3f', _granularity, _threshold), 0, 14)
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'f1' then
    _granularity = math.max(_granularity - 5, 0)
  elseif key == 'f2' then
    _granularity = math.min(_granularity + 5, 200)
  end
end
