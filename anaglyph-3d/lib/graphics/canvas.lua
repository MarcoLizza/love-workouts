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

local Canvas = {}

Canvas.__index = Canvas

local function depth_sorter(lhs, rhs)
  return lhs.depth < rhs.depth
end

function Canvas.new()
  return setmetatable({
      buffers = nil,
      pre_effects = {},
      post_effects = {},
      effects = {},
      time = 0
    }, Canvas)
end

function Canvas:resize(width, height)
  self.buffers = {
      fore = love.graphics.newCanvas(width, height),
      back = love.graphics.newCanvas(width, height)
    }
end

function Canvas:update(dt)
  self.time = self.time + dt
end

function Canvas:chain(shader, initialize, update)
  self.effects[#self.effects + 1] = { shader = shader, initialize = initialize, update = update }
  if initialize then
    initialize(shader)
  end
end

function Canvas:enqueue(callback, depth, mode)
  local queue = mode == 'post-effects' and self.post_effects or self.pre_effects
  queue[#queue + 1] = { callback = callback, depth = depth or 0 }
end

function Canvas:draw(debug)
  local fore, back = self.buffers.fore, self.buffers.back

  table.sort(self.pre_effects, depth_sorter)
  table.sort(self.post_effects, depth_sorter)

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
  love.graphics.draw(back)
--  love.graphics.draw(back, 0, 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

return Canvas