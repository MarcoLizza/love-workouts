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

local Renderer = {}

Renderer.__index = Renderer

local function depth_sorter(lhs, rhs)
  return lhs.depth < rhs.depth
end

function Renderer.new()
  return setmetatable({
      buffers = nil,
      pre_effects = {},
      post_effects = {},
      post_draw = {},
      effects = {},
      time = 0
    }, Renderer)
end

function Renderer:initialize(width, height, scale_to_fit)
  self.width = width
  self.height = height
  self.scale = 1

  if scale_to_fit then
    local _, _, flags = love.window.getMode()
    local desktop_width, desktop_height = love.window.getDesktopDimensions(flags.display)
    desktop_width = desktop_width * 0.95
    desktop_height = desktop_height * 0.95

    for s = 1, 9999 do
      local w, h = width * s, height * s
      if w > desktop_width or h > desktop_height then
        break
      end

      self.scale = s
    end
  end

  print(string.format('window-width=%d, window-height=%d', width * self.scale, height * self.scale))
  print(string.format('width=%d, height=%d, scale=%d', self.width, self.height, self.scale))

  -- Pixel-perfect filter when scaling.
  love.graphics.setDefaultFilter('nearest', 'nearest', 1)

  -- We don't pass any specific flag since we want to keep the ones we
  -- chose at the beginning.
  love.window.setMode(width * self.scale, height * self.scale)

  self.buffers = {
      fore = love.graphics.newCanvas(self.width, self.height),
      back = love.graphics.newCanvas(self.width, self.height)
    }
end

function Renderer:update(dt)
  self.time = self.time + dt
end

function Renderer:chain(shader, initialize, update)
  self.effects[#self.effects + 1] = { shader = shader, initialize = initialize, update = update }
  if initialize then
    initialize(shader)
  end
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

  for _, effect in ipairs(self.effects) do
    local shader = effect.shader

    if shader:hasUniform('_time') then
      shader:send('_time', self.time)
    end

    local update = effect.update
    if update then
      update(shader)
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