-- Confirmation dialogs.
--
-- A blocking prompt would hang the compositor, which cannot draw the window it
-- is waiting on, so the dialog runs detached and calls back in through
-- `hyprctl eval` once answered. zenity rather than hyprland-dialog because
-- Enter and Escape work natively there; `--no-markup` because the text carries
-- window titles.

local M = {}

-- Single-quotes a string for a shell command line.
function M.shellQuote(str)
	return "'" .. str:gsub("'", "'\\''") .. "'"
end
local shellQuote = M.shellQuote

-- `confirm` and `cancel` are Lua expressions, evaluated back in the config
-- state, so they name an entry point on `conf.wm` rather than a local.
function M.ask(opts)
	hl.exec_cmd(
		string.format(
			[=[if zenity --question --no-markup --title %s --ok-label %s --cancel-label Cancel --text %s; then hyprctl eval %s; else hyprctl eval %s; fi]=],
			shellQuote(opts.title),
			shellQuote(opts.ok),
			shellQuote(opts.text),
			shellQuote(opts.confirm),
			shellQuote(opts.cancel)
		),
		{ float = true }
	)
end

return M
