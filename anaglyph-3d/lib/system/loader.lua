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

local function query(file, modtime, digest)
  local info = love.filesystem.getInfo(file)
  if modtime and modtime == info.modtime then
    return modtime, digest -- If the file modification time hasn't changed, don't recompute the digest!
  end
  return info.modtime, love.data.encode('string', 'base64', love.data.hash('sha256', love.filesystem.read(file)))
end

local function load(type, file, ...)
  if type == 'image' then
    return love.graphics.newImage(file, ...)
  elseif type == 'font' then
    return love.graphics.newFont(file, ...)
  elseif type == 'shader' then
    return love.graphics.newShader(file, ...)
--  elseif type == 'source' then
--    return love.graphics.newSource(file, ...)
  else
    return nil
  end
end

function Loader.new(period, burst_count)
  local self = {
    resources = {},
    period = period or 60,
    burst_count = burst_count or math.huge,
    timer = nil
  }
  self.timer = Timer.new(period, function() self:refresh() end, true)
  return setmetatable(self, Loader)
end

function Loader:preload(resources)
  for _, resource in resources do
    self:set(resource.type, resource.file, unpack(resource.args))
  end
end

function Loader:fetch(type, file, ...)
  if self.resources[file] ~= nil then -- The entry already exists, skip!
    print(string.format('! resource "%s" already loaded', file))
    return
  end

  local value = load(type, file, ...) -- Don't trap error on first load, resource is required!
  local modtime, digest = query(file) -- Detect the initial "digest"

  self.resources[file] = {
    type = type,
    file = file,
    args = { ... },
    listeners = {},
    value = value,
    modtime = modtime,
    digest = digest
  }
end

function Loader:dispose(file)
  if file then
    self.resources[file] = nil
  else
    self.resources = {}
  end
end

function Loader:get(file)
  return self.resources[file].value
end

function Loader:watch(file, on_loaded)
  local resource = self.resources[file]
  if not resource then
    print(string.format('! uknowwn resource "%s"', file))
    return
  end

  if resource.listeners[on_loaded] then
    print(string.format('> listener "%s" already registered for resource "%s"', on_loaded, file))
    return
  end

  resource.listeners[on_loaded] = true

  local value = resource.value
  if value then
    on_loaded(value)
  end
end

function Loader:unwatch(file, on_loaded)
  local resource = self.resources[file]
  if not resource then
    print(string.format('! uknowwn resource "%s"', file))
    return
  end

  if on_loaded then
    resource.listeners[on_loaded] = nil
  else
    resource.listeners = {}
  end
end

function Loader:refresh()
  local count = self.burst_count
  for _, resource in pairs(self.resources) do
    local modtime, digest = query(resource.file, resource.modtime, resource.digest)
    if resource.modtime ~= modtime or resource.digest ~= digest then
      print(string.format('> %s "%s" has changed', resource.type, resource.file))
      print(string.format('  modtime is %d, digest is "%s"', modtime, digest))

      resource.modtime = modtime
      resource.digest = digest

      local success, value = xpcall(function()
          return load(resource.type, resource.file, unpack(resource.args))
        end, function(...)
          print(...)
          print(debug.traceback())
        end)
      if success and value then
        print(string.format('- "%s" reloaded', resource.file))
        resource.value = value

        for on_loaded, _ in pairs(resource.listeners) do
          on_loaded(value)
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