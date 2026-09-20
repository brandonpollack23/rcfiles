local M = {}

-- `hyprctl binds` reports every Lua bind as an opaque `__lua` handler, so the
-- searchable list (scripts/keybind-search.sh) is recorded here instead.
-- `opts.command` is the searchable command name, and `opts.prefix` the key that
-- opens the submap a bind lives in; both are stripped before hl.bind.
local entries = {}

function M.bind(keys, dispatcher, opts)
	opts = opts or {}
	local command, prefix = opts.command, opts.prefix
	opts.command, opts.prefix = nil, nil
	table.insert(entries, {
		keys = prefix and (prefix .. " then " .. keys) or keys,
		command = command or "",
		description = opts.description or "",
		dispatcher = dispatcher,
		runnable = not opts.mouse,
	})
	return hl.bind(keys, dispatcher, opts)
end

-- Bind a shell command; the command line doubles as the searchable command name.
function M.bindExec(keys, cmd, opts)
	opts = opts or {}
	opts.command = "exec " .. cmd
	return M.bind(keys, hl.dsp.exec_cmd(cmd), opts)
end

-- Bind a layout message, see https://wiki.hypr.land/configuring/layouts/master-layout/
function M.bindLayout(keys, msg, description)
	return M.bind(keys, hl.dsp.layout(msg), { description = description, command = "layout " .. msg })
end

local function menuLine(entry)
	return entry.keys .. "  |  " .. entry.description .. "  |  " .. entry.command
end

-- Newline-separated "keys | description | command" list for a dmenu-style picker.
function M.menu()
	local lines = {}
	for _, entry in ipairs(entries) do
		table.insert(lines, menuLine(entry))
	end
	return table.concat(lines, "\n")
end

-- Run the bind whose menu line was picked.
function M.run(line)
	for _, entry in ipairs(entries) do
		if entry.runnable and menuLine(entry) == line then
			return hl.dispatch(entry.dispatcher)
		end
	end
end

return M
