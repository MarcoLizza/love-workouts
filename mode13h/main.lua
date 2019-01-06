local _canvas = nil
local _palette = {}
local _shader = nil

function love.load(args)
  love.graphics.setDefaultFilter('nearest', 'nearest')

  for i = 1, 256 do
    local v = (i - 1) / 255;
    _palette[#_palette + 1] = { v, 0, v }
  end

  _canvas = love.graphics.newCanvas(320, 240)

  _shader = love.graphics.newShader([[
uniform vec3 _palette[256];

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = texture2D(texture, texture_coords);

    int index = int(pixel.r * 255.0);

    return vec4(_palette[index], 1.0);
}
    ]])

  _shader:send('_palette', unpack(_palette))
end

function love.update(dt)
end

function love.draw()
  love.graphics.push('all')
    love.graphics.setCanvas(_canvas)
    local c = love.math.random()
    local x = love.math.random(0, love.graphics.getWidth() - 1)
    local y = love.math.random(0, love.graphics.getHeight() - 1)
    love.graphics.setColor(c, c, c)
    love.graphics.points(x, y)
  love.graphics.pop()

  love.graphics.push('all')
    love.graphics.setShader(_shader)
    love.graphics.draw(_canvas, 0, 0, 0, 2)
  love.graphics.pop()

  love.graphics.setColor(1.0, 1.0, 1.0, 0.5)
  love.graphics.print(string.format('%d FPS', love.timer.getFPS()), 0, 0)
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'f1' then
    _canvas:clear(0.0, 0.0, 0.0)
  end
end
