-- Helpers for bindings.lua.

local M = {}

-- A timeout that starts over each time it's restarted: `fn` runs once
-- `timeout` ms have gone by since the last restart(), not the first. cancel()
-- stops the one pending. Each restart starts a new oneshot timer and only the
-- latest one's still counts when it fires, so an earlier one does nothing.
function M.restartable_timeout(timeout, fn)
  local generation = 0
  local handle = {}

  function handle.restart()
    generation = generation + 1
    local current = generation
    hl.timer(function()
      if current == generation then
        fn()
      end
    end, { timeout = timeout, type = "oneshot" })
  end

  function handle.cancel()
    generation = generation + 1
  end

  return handle
end

return M
