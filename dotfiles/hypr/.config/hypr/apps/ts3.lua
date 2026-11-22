-- TeamSpeak 3: hold the mouse's forward side button (BTN_EXTRA, evdev 276)
-- to talk.
--
-- TS3 is an X11 app, so its own hotkeys only see input while an XWayland
-- window has focus, and a button handed to it with Hyprland's `pass` doesn't
-- register as its push-to-talk hotkey. Instead the button turns TS3's
-- microphone on and off through its ClientQuery plugin (ts3-ptt.sh), whatever
-- window has focus. Leave TS3's capture mode on Voice Activation or
-- Continuous Transmission, not Push-To-Talk: each server connection starts
-- with the mic on, until the first release of the button turns it off.
local ptt = (os.getenv("HOME") or "") .. "/.config/hypr/apps/ts3-ptt.sh"

o.bind_hold("mouse:276", "TeamSpeak 3: talk", ptt .. " on", "TeamSpeak 3: stop talking", ptt .. " off")
