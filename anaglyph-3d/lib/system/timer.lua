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

local Timer = {}

Timer.__index = Timer

function Timer.new(duration, on_elapsed, periodic)
  return setmetatable({
      duration = duration,
      on_elapsed = on_elapsed,
      periodic = periodic,
      elapsed = 0
    }, Timer)
end

function Timer:reset()
  timer.elapsed = 0
end

function Timer:update(dt)
  if not self.elapsed then
    return
  end

  timer.elapsed = timer.elapsed + dt
  while timer.elapsed >= timer.duration do
    timer.elapsed = timer.elapsed - timer.duration
    local cancel = timer.on_elapsed()
    if cancel or not timer.periodic then
      self.elapsed = nil
      break
    end
  end
end

return Timer