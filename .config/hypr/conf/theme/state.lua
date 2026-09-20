-- The chosen theme id, kept outside the repo in $XDG_STATE_HOME/hypr/theme.
--
-- Its own module because both halves of the theme need it and neither should
-- depend on the other: palette.lua reads it at load time, select.lua writes it.

local M = {}

local dir = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/hypr"
local file = dir .. "/theme"

-- The saved id, or nil when nothing has been chosen yet.
function M.read()
	local f = io.open(file)
	if not f then
		return nil
	end
	local id = f:read("l")
	f:close()
	return id
end

function M.write(id)
	os.execute("mkdir -p '" .. dir .. "'")
	local f = assert(io.open(file, "w"))
	f:write(id, "\n")
	f:close()
end

return M
