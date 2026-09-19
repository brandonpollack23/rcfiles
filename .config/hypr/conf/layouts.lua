-- See https://wiki.hypr.land/configuring/layouts/master-layout/ for more
hl.config({
	master = {
		mfact = 0.6,
		orientation = "center",
		slave_count_for_center_master = 0,

		new_status = "slave",
		always_keep_position = true,
		smart_resizing = true,
	},
})

-- See https://wiki.hypr.land/configuring/layouts/dwindle-layout/ for more
hl.config({
	dwindle = {
		preserve_split = true, -- You probably want this
	},
})

-- See https://wiki.hypr.land/configuring/layouts/scrolling-layout/ for more
hl.config({
	scrolling = {
		fullscreen_on_one_column = true,
	},
})
