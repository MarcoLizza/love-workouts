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

]] --

local Loader = require('lib/system/loader')
local Renderer = require('lib/graphics/renderer')

local ANAGLYPH_MODES = {
  'LEFT', 'RIGHT',
  'RED-BLUE GREY', 'RED-GREEN GREY', 'BLUE-GREEN GREY',
  'RED-CYAN GREY', 'RED-CYAN COLOR', 'RED-CYAN HALF-COLOR', 'RED-CYAN DUBOIS',
  'AMBER-BLUE GREY', 'AMBER-BLUE COLOR', 'AMBER-BLUE HALF-COLOR (ColorCode-3D)', 'AMBER-BLUE DUBOIS',
  'MAGENTA-GREEN GREY', 'MAGENTA-GREEN COLOR', 'MAGENTA-GREEN HALF-COLOR (Trioscopics-3D)', 'MAGENTA-GREEN DUBOIS',
  'MAGENTA-YELLOW COLOR *', 'MAGENTA-CYAN COLOR *', 'YELLOW-CYAN COLOR *'
}

local COLOUR_BLINDNESS_TYPES = {
  'NORMAL', 'PROTANOPE (NO REDS)', 'DEUTERANOPE (NO GREENS)', 'TRITANOPE (NO BLUES)', 'ACHROMATOPSIA', 'BLUE-CONE MONOCHROMACY'
}

local _loader = Loader.new(1)
local _renderer = nil

local _debug = false

local _autoscroll = true
local _offset = 0.0
local _layers = {
  { file = 'data/layers/08.png', speed = 0.0000, image = nil },
  { file = 'data/layers/07.png', speed = 0.5000, image = nil },
  { file = 'data/layers/06.png', speed = 1.0000, image = nil },
  { file = 'data/layers/05.png', speed = 1.2500, image = nil },
  { file = 'data/layers/04.png', speed = 1.5000, image = nil },
  { file = 'data/layers/03.png', speed = 2.0000, image = nil },
  { file = 'data/layers/02.png', speed = 3.0000, image = nil },
  { file = 'data/layers/01.png', speed = 4.0000, image = nil },
}
local _images = {
    ['left'] = 0,
    ['right'] = 0
  }

local _mode = 0
local _type = 0

function love.load(args)
  love.keyboard.setKeyRepeat(true)

  love.mouse.setVisible(true)
  love.mouse.setGrabbed(false)

  if love.joystick and love.filesystem.getInfo("assets/mappings/gamecontrollerdb.txt") then
    love.joystick.loadGamepadMappings("assets/mappings/gamecontrollerdb.txt")
  end

  math.randomseed(os.time())
  for _ = 1, 1024 do
    math.random()
  end

-- 72×54	4:3
-- 81×54	3:2
-- 96×54	16:9
-- 100×54	1,85:1
-- 129×54	2.39:1
  _renderer = Renderer.new(_loader)
  _renderer:initialize(480, 270, true)

  for _, layer in pairs(_layers) do
    _loader:fetch('image', layer.file)
    _loader:watch(layer.file, function(image)
        image:setWrap('repeat', 'repeat') -- Using HORIZONTAL infinite wrap mode.
        layer.image = image
      end)
  end
  for key, _ in pairs(_images) do
    _images[key] = love.graphics.newCanvas(_renderer.width, _renderer.height)
  end

  _loader:fetch('shader', 'assets/shaders/parallax.glsl')
  _loader:fetch('shader', 'assets/shaders/anaglyph.glsl')
  _loader:fetch('shader', 'assets/shaders/colour-blindness.glsl')
--  _loader:fetch('shader', 'assets/shaders/stereoscopy.glsl')
  _loader:fetch('shader', 'assets/shaders/greyscale.glsl')
--  _loader:fetch('shader', 'assets/shaders/vignette.glsl')
  _loader:fetch('font', 'assets/fonts/m6x11.ttf', 32)

  _loader:watch('assets/shaders/parallax.glsl', function(shader)
      shader:send('_texture_size', { _renderer.width, _renderer.height })
    end)
  _loader:watch('assets/shaders/anaglyph.glsl', function(shader)
      shader:send('_left', _images.left)
      shader:send('_right', _images.right)
    end)
--[[
  _loader:watch('assets/shaders/stereoscopy.glsl', function(shader)
      shader:send('_left', _images.left)
      shader:send('_right', _images.right)
    end)
]]
--[[
  _loader:watch('assets/shaders/vignette.glsl', function(shader)
      shader:send('_step', { 1.0 / _renderer.width, 1.0 / _renderer.height })
    end)
]]

  _renderer:chain('assets/shaders/anaglyph.glsl', function(shader)
      shader:send('_mode', _mode)
    end)
  _renderer:chain('assets/shaders/colour-blindness.glsl', function(shader)
      shader:send('_type', _type)
    end)
--  _renderer:chain('assets/shaders/vignette.glsl')
  _renderer:chain('assets/shaders/greyscale.glsl')
end

function love.update(dt)
  _loader:update(dt)

  if _autoscroll then
    _offset = _offset + (dt * 16.0)
  end

  _renderer:update(dt)
end

function love.draw()
  _renderer:defer(function(debug)
      local parallax = _loader:get('assets/shaders/parallax.glsl')

      love.graphics.setShader(parallax)

      love.graphics.setCanvas(_images.left)
      parallax:send('_offset', _offset - 2) -- Don't invert direction
      for _, layer in ipairs(_layers) do
        parallax:send('_speed', layer.speed)
        love.graphics.draw(layer.image)
      end

      love.graphics.setCanvas(_images.right)
      parallax:send('_offset', _offset + 2)
      for _, layer in ipairs(_layers) do
        parallax:send('_speed', layer.speed)
        love.graphics.draw(layer.image)
      end
  end, 0)

  _renderer:defer(function(debug)
      love.graphics.rectangle('fill', 0, 0, _renderer.width, _renderer.height)
    end, 1)

  _renderer:defer(function(debug)
      love.graphics.setColor(1.0, 1.0, 1.0, 0.5)
      love.graphics.print(love.timer.getFPS() .. ' FPS', 0, 0)

      local font = _loader:get('assets/fonts/m6x11.ttf')
      love.graphics.setFont(font)
      love.graphics.setColor(1.0, 1.0, 1.0, 0.5)
      love.graphics.print(ANAGLYPH_MODES[_mode + 1], 0, love.graphics.getHeight() - 64)
      love.graphics.print(COLOUR_BLINDNESS_TYPES[_type + 1], 0, love.graphics.getHeight() - 32)
    end, nil, 'post-draw')

  _renderer:draw(_debug)
end

function love.mousepressed(x, y, button, istouch, presses)
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'f1' then
    _mode = math.max(_mode - 1, 0)
  elseif key == 'f2' then
    _mode = math.min(_mode + 1, #ANAGLYPH_MODES - 1)
  elseif key == 'f3' then
    _type = math.max(_type - 1, 0)
  elseif key == 'f4' then
    _type = math.min(_type + 1, #COLOUR_BLINDNESS_TYPES - 1)
  elseif key == 'f8' then
    _autoscroll = not _autoscroll
  elseif key == 'f12' then
    _debug = not _debug
  elseif key == 'left' then
    _offset = _offset - 1.0
  elseif key == 'right' then
    _offset = _offset + 1.0
  end
end
