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

local Easing = require('lib/easing')
local Iterators = require('lib/iterators')

local _config = {
  scale_factor = 10,
  delay = 1,
  direction = 'out',
  draw_background = true,
  draw_foreground = true,
  mode = 'Back'
}

local _state = {
  background = nil,
  stencil = nil,
  foreground = nil,
  time = nil,
  easing = nil,
  next = Iterators.circular({ 'Quad', 'Cubic', 'Quart', 'Quint', 'Sine', 'Expo', 'Circ', 'Elastic', 'Back', 'Bounce' }, 10)
}

function love.load(args)
  if args[#args] == '-debug' then require('mobdebug').start() end

  love.graphics.setDefaultFilter('nearest', 'nearest', 1)

  _state.background = love.graphics.newImage('assets/background.png')
  _state.stencil = love.graphics.newImage('assets/stencil.png')
  _state.foreground = love.graphics.newImage('assets/foreground.png')
  _state.time = 0
  _state.direction = true
  _state.easing = Easing[_config.direction .. _config.mode]
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'f1' then
    _config.direction = _config.direction == 'out' and 'in' or 'out'
    _state.easing = Easing[_config.direction .. _config.mode]
    _state.time = 0
  elseif key == 'f2' then
    _config.mode = _state.next()
  elseif key == 'f3' then
    _config.draw_background = not _config.draw_background
  elseif key == 'f4' then
    _config.draw_foreground = not _config.draw_foreground
  end
end

function love.update(dt)
  _state.time = _state.time + dt
end

function love.draw()
  local scale
  if _config.direction == 'out' then
    scale = _state.time < _config.delay and _state.easing(_state.time, _config.scale_factor, -_config.scale_factor, _config.delay) or 0
  else
    scale = _state.time < _config.delay and _state.easing(_state.time, 0, _config.scale_factor, _config.delay) or _config.scale_factor
  end
  scale = math.abs(scale)

  love.graphics.push('all')
    if _config.draw_background then
      love.graphics.draw(_state.background, 0, 0)
    else
      love.graphics.setColor(1, 1, 1)
      love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
  love.graphics.pop()

  love.graphics.push('all')
    love.graphics.stencil(function()
                            -- ! the shader should be created only once outside to stencil-function, to reduce
                            -- ! resource usage and speed up the fader. However, we keep it here for sake of
                            -- ! clarity.
                            local mask_shader = love.graphics.newShader([[
                               vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
                                  if (Texel(texture, texture_coords).a == 0) {
                                     discard; // Discarded pixels won't be applied as the stencil.
                                  }
                                  return vec4(1.0); // Any value will do as long as is not discarded.
                               }
                            ]])
                            local w, h = _state.stencil:getDimensions() -- Center the stencil on screen, according to current scaling factor.
                            local x = (love.graphics.getWidth() - w * scale) / 2
                            local y = (love.graphics.getHeight() - h * scale) / 2
                            love.graphics.push('all')
                              love.graphics.setShader(mask_shader)
                              love.graphics.draw(_state.stencil, x, y, 0, scale, scale, 0, 0, 0, 0)
                            love.graphics.pop()
                          end,
                          'replace', 1, false)
    love.graphics.setStencilTest('notequal', 1) -- Draw through the *trasparent* zones of the stencil
    if _config.draw_foreground then
      love.graphics.draw(_state.foreground, 0, 0)
    else
      love.graphics.setColor(0, 0, 0)
      love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
  love.graphics.pop()

  love.graphics.print(love.timer.getFPS() .. " FPS", 0, 0)
  love.graphics.print('easing mode is ' .. _config.mode, 0, 12)
  love.graphics.print('F1 = invert transition | F2 = change easing mode | F3 = hide/show background | F3 = hide/show foreground', 0, 24)
end
