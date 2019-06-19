local MESSAGE = '... a simple old school sine scroller, implemented with fragment shaders... life was a bit more difficult back in the days...'
local SECONDS_PER_CHARACTER = 0.25
local PERIOD = #MESSAGE * SECONDS_PER_CHARACTER

local MESSAGE_WIDTH = nil
local MESSAGE_HEIGHT = nil
local MESSAGE_X = nil
local MESSAGE_Y = nil

local _image = nil
local _canvas = nil
local _font = nil
local _shader = nil
local _time = 0

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
  _canvas = love.graphics.newCanvas()
  _image = love.graphics.newImage('background.png')
--  _font = love.graphics.newFont('upheavtt.ttf', 20, 'normal')
  _font = love.graphics.newFont('compyx-regular-svg.ttf', 32, 'normal')
--  _font = love.graphics.newFont('04B_30__.TTF', 16, 'normal')
  _shader = shader_compile([[
const vec3 TOP = vec3(0.0, 1.0, 0.5);
const vec3 MIDDLE = vec3(0.5, 0.0, 1.0);
const vec3 BOTTOM = vec3(1.0, 0.0, 1.0);

uniform float u_time;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec2 resolution = vec2(love_ScreenSize);

    float amplitude = resolution.y / 200.0;
    float period = 3.0;

    vec2 uv = texture_coords;
    uv.y += sin((uv.x + u_time) * period) / amplitude;
    vec4 texel = texture2D(texture, uv) * color;

    float bar_ratio_1 = abs(fract(texture_coords.y * 8.0) - 0.5) * 2.0;
    float bar_ratio_2 = abs(fract(texture_coords.y * 8.0) - 0.5) * 2.0;
    vec4 pixel = vec4(mix(TOP, mix(MIDDLE, BOTTOM, bar_ratio_1), bar_ratio_2), texel.a);

//    return pixel;
    vec2 center = resolution / 2.0;
    float delta = abs(center.x - screen_coords.x);
    float fade_ratio = delta / (resolution.x / 2.0);
    return mix(pixel, vec4(0.0), pow(fade_ratio, 3.0));
}
    ]], { })

  MESSAGE_WIDTH = _font:getWidth(MESSAGE)
  MESSAGE_HEIGHT = _font:getHeight()
  MESSAGE_X = -(MESSAGE_WIDTH + love.graphics.getWidth())
  MESSAGE_Y = (love.graphics.getHeight() - MESSAGE_HEIGHT) / 2
end

function love.update(dt)
  _time = _time + dt
  _shader:send('u_time', _time)
end

local function position(time, period)
  local i, f = math.modf(time / period)
  return f
end

function love.draw()
  love.graphics.push('all')
    love.graphics.setCanvas(_canvas)
    love.graphics.clear()
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
    love.graphics.setFont(_font)
    love.graphics.print(MESSAGE, position(_time, PERIOD) * MESSAGE_X + love.graphics.getWidth(), MESSAGE_Y)
  love.graphics.pop()

  love.graphics.push('all')
--    love.graphics.draw(_image, 0, 0)
    love.graphics.setShader(_shader)
    love.graphics.draw(_canvas, 0, 0)
  love.graphics.pop()

  love.graphics.print(string.format('%d FPS', love.timer.getFPS()), 0, 0)
end

function love.keypressed(key, scancode, isrepeat)
end
