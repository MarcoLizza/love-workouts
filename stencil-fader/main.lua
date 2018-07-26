--[[

Copyright (c) 2018 by Marco Lizza (marco.lizza@gmail.com)

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgement in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.

]]--

local Arrays = require('lib/arrays')
local Easings = require('lib/easings')
local Iterators = require('lib/iterators')

local _state = {
  background = nil,
  stencil = nil,
  mask = nil,
  level = 25,
  squares = 128
}

local function render_stencil(canvas, stencil, steps, factor)
  local cw, ch = canvas:getDimensions()
  local sw, sh = stencil:getDimensions()
  love.graphics.push('all')
  love.graphics.setCanvas(canvas)
  for i = steps, 0, -1 do
    local r = i / steps
    local scale = r * factor
    local w = sw * scale
    local h = sh * scale
    local x = (cw - w) / 2
    local y = (ch - h) / 2
    local c = r
    love.graphics.setColor(c, c, c)
    -- Beware, not to have antialiased stencil borders, or artifacts will appear!
    love.graphics.draw(stencil, x, y, 0, scale, scale, 0, 0, 0, 0)
  end
  love.graphics.pop()
end

local function render_squares(canvas, steps)
  local values = Arrays.shuffled(Arrays.generate(function(i) return i < 256 and i or nil end)) -- Skip 0 ("no coverage")
  local color = Iterators.circular(values, function(t) Arrays.shuffle(t) end)

  local cw, ch = canvas:getDimensions()
  local tw, th = cw / steps, ch / steps
  love.graphics.push('all')
  love.graphics.setCanvas(canvas)
  for y = 0, ch, th do
    for x = 0, cw, tw do
      local c = color() / 255
      love.graphics.setColor(c, c, c)
      love.graphics.rectangle('fill', x, y, tw, th)
      end
  end

  love.graphics.pop()
end

function love.load(args)
  if args[#args] == '-debug' then require('mobdebug').start() end

  love.graphics.setDefaultFilter('nearest', 'nearest', 1)

  love.mouse.setVisible(false)
  love.mouse.setGrabbed(true)

  _state.background = love.graphics.newImage('assets/background.png')
  _state.stencil = love.graphics.newImage('assets/inverted-stencil.png')
  _state.mask = love.graphics.newCanvas()
  _state.shader = love.graphics.newShader([[
    extern Image mask;
    extern number alpha;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      vec4 m = Texel(mask, texture_coords);
      if (m.r > alpha) {
        discard;
      }
      return Texel(texture, texture_coords);
     }
  ]])
  _state.shader:send('mask', _state.mask)
  _state.easing = Easings.inBack
  render_squares(_state.mask, _state.squares)
--  render_stencil(_state.mask, _state.stencil, 255, 2)
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'f1' then
    _state.level = math.max(_state.level - 1, 0)
  elseif key == 'f2' then
    _state.level = math.min(_state.level + 1, 255)
  elseif key == 'f3' then
    _state.squares = math.max(_state.squares - 1, 1)
    render_squares(_state.mask, _state.squares)
  elseif key == 'f4' then
    _state.squares = math.min(_state.squares + 1, 512)
    render_squares(_state.mask, _state.squares)
  elseif key == 'f12' then
    _state.mask:newImageData():encode('png', 'mask.png')
  end
end

function love.draw()
  love.graphics.push('all')
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle('fill', 0, 0, 800, 600)
  love.graphics.pop()
  love.graphics.push('all')
     local alpha = _state.easing(_state.level, 0, 1, 255)
     --local alpha = _state.level / 255
    _state.shader:send('alpha', alpha)
    love.graphics.setShader(_state.shader) -- Shaders works only with `draw()` calls!
    love.graphics.draw(_state.background, 0, 0)
  love.graphics.pop()

  local x, y = love.mouse.getX(), love.mouse.getY()
  local w, h = 16, 16
  local s = 2
  love.graphics.push('all')
    love.graphics.setColor(1.0, 1.0, 1.0)
    love.graphics.rectangle('fill', x - s/2, y - h/2, s, h)
    love.graphics.rectangle('fill', x - h/2, y - s/2, w, s)
  love.graphics.pop()

  love.graphics.print(love.timer.getFPS() .. " FPS", 0, 0)
  love.graphics.print(string.format("LEVEL %d | SQUARES %d", _state.level, _state.squares), 0, 12)
end
