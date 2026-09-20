-- Looking up windows and groups.
--
-- Everything here works from addresses rather than window objects: an object
-- goes stale as soon as the window closes, an address can be re-resolved (and
-- come back nil, which is the answer callers need).

local M = {}

function M.at(address)
	for _, window in pairs(hl.get_windows()) do
		if window.address == address then
			return window
		end
	end
end

-- The group `window` is really in, plus its index among the tabs.
-- `window.group` sometimes reports a group the window is not actually in, so
-- trust it only when the members include the window itself.
function M.groupOf(window)
	if not window or not window.group then
		return nil
	end
	for index, member in ipairs(window.group.members) do
		if member.address == window.address then
			return window.group, index
		end
	end
	return nil
end

-- Every member's address, in tab order, for putting a group back together.
function M.memberAddresses(group)
	local addresses = {}
	for index, member in ipairs(group.members) do
		addresses[index] = member.address
	end
	return addresses
end

-- Some other member of `group`, as the handle on a group that `address` may be
-- about to leave: groups have no identity of their own to hold on to.
function M.anchorFor(group, address)
	for _, member in ipairs(group.members) do
		if member.address ~= address then
			return member.address
		end
	end
end

return M
