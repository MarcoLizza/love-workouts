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

local Iterators = require('lib/collections/iterators')

local Renderer = {}

Renderer.__index = Renderer

local function depth_sorter(lhs, rhs)
  return lhs.depth < rhs.depth
end

function Renderer.new(loader)
  return setmetatable({
      loader = loader,
      time = 0,
      buffers = nil,
      pre_effects = {},
      post_effects = {},
      post_draw = {},
      effects = {},
    }, Renderer)
end

function Renderer:initialize(width, height, scale_to_fit)
  self.width = width
  self.height = height
  self.scale = 1

  local _, _, flags = love.window.getMode()
  local desktop_width, desktop_height = love.window.getDesktopDimensions(flags.display)

  if scale_to_fit then
    local safe_width = desktop_width * 0.95
    local safe_height = desktop_height * 0.95

    for s = 1, 9999 do
      local w, h = width * s, height * s
      if w > safe_width or h > safe_height then
        break
      end

      self.scale = s
    end
  end

--  print(string.format('window-width=%d, window-height=%d', width * self.scale, height * self.scale))
--  print(string.format('width=%d, height=%d, scale=%d', self.width, self.height, self.scale))

  -- Pixel-perfect filter when scaling.
  love.graphics.setDefaultFilter('nearest', 'nearest', 1)

  -- We need to pass the mode settings or the default values will kick-in (with, for example, vsync enabled). We
  -- build the new settings with a subset of the current ones.
  local settings = {
      fullscreen = flags.fullscreen,
      msaa = flags.msaa,
      stencil = flags.stencil,
      depth = flags.depth,
      resizable = flags.resizable,
      minwidth = flags.minwidth,
      minheight = flags.minheight,
      borderless = flags.borderless,
      centered = flags.centered,
      display = flags.display,
      highdpi = flags.highdpi,
      vsync = flags.vsync,
      x = (flags.x >= 0 and flags.x < desktop_width) and flags.x or nil,
      y = (flags.y >= 0 and flags.y < desktop_height) and flags.y or nil
    }
  love.window.setMode(width * self.scale, height * self.scale, settings)

  self.buffers = {
      fore = love.graphics.newCanvas(self.width, self.height),
      back = love.graphics.newCanvas(self.width, self.height)
    }
end

function Renderer:update(dt)
  self.time = self.time + dt
end

function Renderer:chain(file, on_updated)
  self.effects[#self.effects + 1] = {
      file = file,
      on_updated = on_updated
    }
end

function Renderer:defer(callback, depth, mode)
  local queue = self.pre_effects
  if mode == 'post-effects' then
    queue = self.post_effects
  elseif mode == 'post-draw' then
    queue = self.post_draw
  end
  queue[#queue + 1] = { callback = callback, depth = depth or 0 }
end

function Renderer:draw(debug)
  local fore, back = self.buffers.fore, self.buffers.back

  table.sort(self.pre_effects, depth_sorter)
  table.sort(self.post_effects, depth_sorter)
  table.sort(self.post_draw, depth_sorter)

  love.graphics.setCanvas(back)

  for _, drawer in ipairs(self.pre_effects) do
    love.graphics.push('all')
    drawer.callback(debug)
    love.graphics.pop()
  end
  self.pre_effects = {}

  for _, effect in Iterators.ipairs(self.effects, function(effect) return self.loader:get(effect.file) ~= nil end) do
    local shader = self.loader:get(effect.file)

    if shader:hasUniform('_time') then
      shader:send('_time', self.time)
    end

    local on_updated = effect.on_updated
    if on_updated then
      on_updated(shader)
    end

    love.graphics.setCanvas(fore) -- Don't restore, will be used for post-effects draws!
    love.graphics.setShader(shader)
    love.graphics.draw(back)
    love.graphics.setShader()

    fore, back = back, fore
  end

  for _, drawer in ipairs(self.post_effects) do
    love.graphics.push('all')
    drawer.callback(debug)
    love.graphics.pop()
  end
  self.post_effects = {}

  love.graphics.setCanvas()
  love.graphics.draw(back, 0, 0, 0, self.scale, self.scale)

  for _, drawer in ipairs(self.post_draw) do
    love.graphics.push('all')
    drawer.callback(debug)
    love.graphics.pop()
  end
  self.post_draw = {}
end

return Renderer