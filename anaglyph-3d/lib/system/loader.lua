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

local Timer = require('lib/system/timer')

local Loader = {}

Loader.__index = Loader

local function load(type, ...)
  if type == 'image' then
    return love.graphics.newImage(...)
  elseif type == 'font' then
    return love.graphics.newFont(...)
  elseif type == 'shader' then
    return love.graphics.newShader(...)
--  elseif type == 'source' then
--    return love.graphics.newSource(...)
  else
    return nil
  end
end

local function has_changed(resource)
  local info = love.filesystem.getInfo(resource.file)
  if not resource.modtime or resource.modtime < info.modtime then -- Check if the timestamp has changed
    resource.modtime = info.modtime
    local digest = love.data.encode('string', 'base64', love.data.hash('sha256', love.filesystem.read(resource.file)))
    if resource.digest ~= digest then -- Check if the content has changed, too.
      resource.digest = digest
      return true
    end
  end
  return false
end

function Loader.new(period, burst_count)
  local self = {
    resources = {},
    period = period,
    burst_count = burst_count,
    timer = nil
  }
  self.timer = Timer.new(period, function() self:refresh() end, true)
  return setmetatable(self, Loader)
end

function Loader:purge()
  self.resources = {}
end

function Loader:set(type, file, arguments, on_loaded)
  if self.resources[file] ~= nil then -- The entry already exists, skip!
    -- TODO: manage the `on_loaded` event as multi-entries, and enable registration?
    print(string.format('resource "%s" already loaded', file))
    return
  end

  local args = { file, unpack(arguments or {}) }

  local value = load(type, unpack(args)) -- Don't trap error on first load, resource is required!

  if on_loaded and value then
    on_loaded(value)
  end

  self.resources[file] = {
    type = type,
    file = file,
    args = args,
    on_loaded = on_loaded, -- on_loaded = {},
    value = value,
    modtime = 0,
    digest = nil
  }
end

function Loader:get(file)
  return self.resources[file:lower()].value
end

function Loader:call_if(file, lambda)
  local value = self:get(file)
  if value then
    lambda(value)
  end
end

function Loader:refresh()
  local count = self.burst_count or math.huge
  for _, resource in pairs(self.resources) do
    local changed = has_changed(resource)
    if changed then
      print(string.format('> %s "%s" has changed', resource.type, resource.file))
      local success, value = xpcall(function()
          return load(resource.type, unpack(resource.args))
        end, function(...)
          print(...)
          print(debug.traceback())
        end)
      if success and value then
        print(string.format('- "%s" reloaded', resource.file))
        resource.value = value
        if resource.on_loaded then
          resource.on_loaded(resource.value)
        end

        count = count - 1
        if count <= 0 then
          print('! resource(s) refresh count reached, yielding...')
          break
        end
      end
    end
  end
end

function Loader:update(dt)
  self.timer:update(dt)
end

return Loader