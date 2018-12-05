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
--[[
local function Bus()
  local listeners = {}
  return {
      register = function(self, event, cb)
          listeners[event] = listeners[event] or {}
          table.insert(listeners[event], cb)
        end,
      emit = function(self, event, ...)
          for _, cb in ipairs(listeners[event]) do
            cb(...)
          end
        end
    }
end
]]
local function shader_compile(shader, defines, variables)
  local code = love.filesystem.getInfo(shader) and love.filesystem.read(shader) or shader

  if defines then
    local found = {}
    code = code:gsub('(#define%s+)([^%s]+)(%s+)([^%s]+)', -- Match existing macros, replace value and mark as found.
      function(define, identifier, spaces, value)
        local v = defines[identifier]
        if not v then
          return define .. identifier .. spaces .. value
        end
        found[identifier] = true
        return define .. identifier .. spaces .. v
      end)
    for identifier, value in pairs(defines) do -- Pre-prend unknow defines.
      if not found[identifier] then
        code = string.format('#define %s %s\n', identifier, value) .. code
      end
    end
  end

  if variables then
    for identifier, value in pairs(variables) do -- Replace custom variables.
      code = code:gsub(string.format('${%s}', identifier), value)
    end
  end

  return love.graphics.newShader(code)
end

function love.load(args)
  _noise = generate(_granularity, love.graphics.getDimensions())

  _shader = shader_compile([[
#define THRESHOLD 0.05

const vec4 EDGE_COLOR = vec4(1.0, 1.0, 1.0, 1.0);

uniform Image _top;
uniform Image _bottom;
uniform float _threshold;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
#ifdef ALPHA
    vec4 noise = texture2D(texture, texture_coords);

    vec4 top = texture2D(_top, texture_coords);
    vec4 bottom = texture2D(_bottom, texture_coords);

    float alpha = _threshold - noise.r;
    return mix(top, bottom, alpha);
#else
    vec4 noise = texture2D(texture, texture_coords);
    float delta = _threshold - noise.r;
    if (delta < 0.0) {
      return texture2D(_bottom, texture_coords);
    }
    if (delta > THRESHOLD) {
      return texture2D(_top, texture_coords);
    }
  #ifdef MIX
    float alpha = delta / THRESHOLD;
    return mix(texture2D(_bottom, texture_coords), EDGE_COLOR, alpha);
  #else
    return EDGE_COLOR;
  #endif
#endif
}
    ]], { ['MIX'] = '1' })
--    ]], { ['ALPHA'] = '1' })

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
