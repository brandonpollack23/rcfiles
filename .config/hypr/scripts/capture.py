#!/usr/bin/python3
"""Capture panel for hyprcap: screenshot or record a region, a window or the
focused screen, and pick where the file goes.

    capture.py      toggle the panel

Keys: Tab switches between screenshot and record, R/W/S capture a region, a
window or the screen, O opens the options, Escape closes. While a recording is
running the panel leads with a stop button (Enter); the bar's recording
indicator (brpol-waybard, `custom/recording`) opens it for that.

GTK4 on gtk4-layer-shell, like ~/.config/l1p0-menu/popups.py. The colours are
the active Hyprland theme's, from $XDG_STATE_HOME/hypr/colors.css
(conf/gtk_colors.lua). Settings persist in $XDG_STATE_HOME/hypr/capture.json.
The first call stays resident as the GApplication's primary instance and a
second call closes it, which makes the bind a toggle.
"""

import json
import os
import subprocess
import sys
from ctypes import CDLL

CDLL("libgtk4-layer-shell.so")

import gi

gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
gi.require_version("Pango", "1.0")
from gi.repository import Gdk, Gio, GLib, Gtk, Pango, Gtk4LayerShell as LayerShell  # noqa: E402

HOME = os.path.expanduser("~")
STATE_DIR = os.path.join(os.environ.get("XDG_STATE_HOME") or os.path.join(HOME, ".local/state"), "hypr")
SETTINGS_PATH = os.path.join(STATE_DIR, "capture.json")
COLORS_PATH = os.path.join(STATE_DIR, "colors.css")
# Where hyprcap keeps the PID of a running recording.
REC_PID_PATH = os.path.join(os.environ.get("XDG_RUNTIME_DIR") or "/run", "hyprcap_rec.pid")

# How long to wait after hiding the panel before capturing, so it is not in the
# shot (or the frozen screen) while it fades out.
HIDE_MS = 250

DELAYS = [0, 3, 5, 10]

DEFAULTS = {
    "mode": "shot",
    "dirs": {
        "shot": os.path.join(HOME, "Pictures", "Screenshots"),
        "rec": os.path.join(HOME, "Videos", "Captures"),
    },
    "save": True,
    "copy": True,
    "freeze": True,
    "delay": 0,
    "options_open": False,
}

# (hyprcap selection, label, icon, key)
TARGETS = [
    ("region", "Region", "edit-select-all-symbolic", "r"),
    ("window", "Window", "focus-windows-symbolic", "w"),
    ("monitor:active", "Screen", "video-display-symbolic", "s"),
]

CSS = """
window.capture-window {
    background: transparent;
}

.capture-panel {
    background: alpha(@background, 0.85);
    color: @foreground;
    border: 1px solid alpha(@primary, 0.35);
    border-radius: 22px;
    padding: 16px;
}

.capture-panel label {
    color: @foreground;
}

.capture-panel .dim-label,
.capture-panel .hint {
    color: @muted;
    opacity: 1;
}

.hint {
    font-size: 10px;
}

.modes {
    background: alpha(@surface, 0.6);
    border-radius: 9999px;
    padding: 4px;
}

.modes button {
    background: transparent;
    border: none;
    box-shadow: none;
    border-radius: 9999px;
    padding: 4px 16px;
    color: @muted;
}

.modes button:hover {
    background: alpha(@primary, 0.2);
}

.modes button:checked {
    background: @primary;
    color: @on_primary;
}

.modes button:checked label,
.modes button:checked image {
    color: @on_primary;
}

.target {
    background: alpha(@surface, 0.6);
    border: 1px solid transparent;
    box-shadow: none;
    border-radius: 16px;
    padding: 12px 8px 8px 8px;
    min-width: 96px;
}

.target:hover,
.target:focus-visible {
    background: alpha(@primary, 0.2);
    border-color: alpha(@primary, 0.6);
}

.target image {
    -gtk-icon-size: 32px;
}

.target.record image {
    color: @error;
}

.recording {
    background: alpha(@error, 0.15);
    border: 1px solid alpha(@error, 0.5);
    border-radius: 14px;
    padding: 8px 8px 8px 14px;
}

.recording .dot {
    color: @error;
}

.stop {
    background: @error;
    color: @on_primary;
    border: none;
    box-shadow: none;
    border-radius: 9999px;
    padding: 4px 14px;
}

.stop label,
.stop image {
    color: @on_primary;
}

.options {
    background: alpha(@surface, 0.35);
    border-radius: 14px;
    padding: 10px 12px;
}

.options button {
    background: alpha(@surface, 0.8);
    border: none;
    box-shadow: none;
    border-radius: 10px;
}

.options button:hover {
    background: alpha(@primary, 0.25);
}

.options switch:checked {
    background: @primary;
}

.path {
    font-family: monospace;
}
"""


def load_settings():
    settings = json.loads(json.dumps(DEFAULTS))
    try:
        with open(SETTINGS_PATH) as file:
            saved = json.load(file)
    except (OSError, ValueError):
        return settings
    settings.update({key: value for key, value in saved.items() if key in DEFAULTS and key != "dirs"})
    settings["dirs"].update(saved.get("dirs") or {})
    return settings


def save_settings(settings):
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(SETTINGS_PATH, "w") as file:
        json.dump(settings, file, indent=2)


def recording():
    """Whether hyprcap has a recording running."""
    try:
        with open(REC_PID_PATH) as file:
            os.kill(int(file.read().strip()), 0)
        return True
    except (OSError, ValueError):
        return False


def tilde(path):
    return "~" + path[len(HOME) :] if path == HOME or path.startswith(HOME + "/") else path


def label(text="", *classes, **props):
    widget = Gtk.Label(label=text, **props)
    for name in classes:
        widget.add_css_class(name)
    return widget


def switch_row(text, active, on_change):
    row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
    row.append(label(text, hexpand=True, xalign=0))
    switch = Gtk.Switch(active=active, valign=Gtk.Align.CENTER)
    switch.connect("notify::active", lambda widget, _: on_change(widget.get_active()))
    row.append(switch)
    return row, switch


class Panel(Gtk.Window):
    def __init__(self, app):
        super().__init__(application=app, title="Capture")
        self.app = app
        self.settings = load_settings()
        self.recording = recording()

        LayerShell.init_for_window(self)
        LayerShell.set_namespace(self, "capture-layer")
        LayerShell.set_layer(self, LayerShell.Layer.OVERLAY)
        LayerShell.set_anchor(self, LayerShell.Edge.BOTTOM, True)
        LayerShell.set_margin(self, LayerShell.Edge.BOTTOM, 60)
        LayerShell.set_keyboard_mode(self, LayerShell.KeyboardMode.EXCLUSIVE)
        self.add_css_class("capture-window")

        panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        panel.add_css_class("capture-panel")
        self.set_child(panel)

        if self.recording:
            panel.append(self.build_recording())

        modes = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, halign=Gtk.Align.CENTER, spacing=2)
        modes.add_css_class("modes")
        self.mode_buttons = {}
        for mode, text, icon in (("shot", "Screenshot", "camera-photo-symbolic"), ("rec", "Record", "media-record-symbolic")):
            button = Gtk.ToggleButton(child=self.icon_label(icon, text))
            if self.mode_buttons:
                button.set_group(next(iter(self.mode_buttons.values())))
            button.connect("toggled", self.on_mode, mode)
            modes.append(button)
            self.mode_buttons[mode] = button
        panel.append(modes)

        targets = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10, homogeneous=True)
        self.target_buttons = []
        for selection, text, icon, key in TARGETS:
            box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            box.append(Gtk.Image(icon_name=icon))
            box.append(label(text))
            box.append(label(key.upper(), "hint"))
            button = Gtk.Button(child=box)
            button.add_css_class("target")
            button.connect("clicked", lambda _, selection=selection: self.capture(selection))
            targets.append(button)
            self.target_buttons.append(button)
        panel.append(targets)

        self.expander = Gtk.Expander(label="Options", expanded=self.settings["options_open"])
        self.expander.connect("notify::expanded", self.on_expanded)
        self.expander.set_child(self.build_options())
        panel.append(self.expander)

        panel.append(label("Tab mode · R W S capture · O options · Esc close", "hint"))

        keys = Gtk.EventControllerKey(propagation_phase=Gtk.PropagationPhase.CAPTURE)
        keys.connect("key-pressed", self.on_key)
        self.add_controller(keys)

        self.mode_buttons[self.settings["mode"]].set_active(True)
        self.update_mode()

    @staticmethod
    def icon_label(icon, text):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        box.append(Gtk.Image(icon_name=icon))
        box.append(label(text))
        return box

    def build_recording(self):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        row.add_css_class("recording")
        row.append(label("●", "dot"))
        row.append(label("Recording", hexpand=True, xalign=0))
        stop = Gtk.Button(child=self.icon_label("media-playback-stop-symbolic", "Stop  ⏎"))
        stop.add_css_class("stop")
        stop.connect("clicked", lambda _: self.run(["hyprcap", "rec-stop", "-q", "--disable-title"]))
        row.append(stop)
        return row

    def build_options(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8, margin_top=8)
        box.add_css_class("options")

        self.dir_title = label("", "dim-label", xalign=0)
        box.append(self.dir_title)
        folder = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        self.dir_label = label("", "path", hexpand=True, xalign=0, ellipsize=Pango.EllipsizeMode.MIDDLE, max_width_chars=28)
        folder.append(self.dir_label)
        browse = Gtk.Button(icon_name="folder-open-symbolic", tooltip_text="Choose a folder")
        browse.connect("clicked", self.on_browse)
        folder.append(browse)
        reset = Gtk.Button(icon_name="edit-undo-symbolic", tooltip_text="Back to the default folder")
        reset.connect("clicked", self.on_reset_dir)
        folder.append(reset)
        box.append(folder)

        self.save_row, self.save_switch = switch_row("Save to file", self.settings["save"], self.on_save)
        box.append(self.save_row)
        copy_row, self.copy_switch = switch_row("Copy to clipboard", self.settings["copy"], self.on_copy)
        box.append(copy_row)
        self.freeze_row, _ = switch_row("Freeze screen while selecting", self.settings["freeze"], self.setter("freeze"))
        box.append(self.freeze_row)

        delay_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        delay_row.append(label("Delay", hexpand=True, xalign=0))
        delay = Gtk.DropDown.new_from_strings([f"{seconds} s" if seconds else "None" for seconds in DELAYS])
        delay.set_selected(DELAYS.index(self.settings["delay"]) if self.settings["delay"] in DELAYS else 0)
        delay.connect("notify::selected", lambda widget, _: self.setter("delay")(DELAYS[widget.get_selected()]))
        delay_row.append(delay)
        box.append(delay_row)
        return box

    def setter(self, key):
        def set_value(value):
            self.settings[key] = value
            save_settings(self.settings)

        return set_value

    # A capture has to go somewhere, so turning off one of save and copy keeps
    # the other on.
    def on_save(self, active):
        self.setter("save")(active)
        if not active:
            self.copy_switch.set_active(True)

    def on_copy(self, active):
        self.setter("copy")(active)
        if not active and self.settings["mode"] == "shot":
            self.save_switch.set_active(True)

    def on_expanded(self, expander, _):
        self.setter("options_open")(expander.get_expanded())

    def on_mode(self, button, mode):
        if button.get_active():
            self.setter("mode")(mode)
            self.update_mode()

    def update_mode(self):
        mode = self.settings["mode"]
        record = mode == "rec"
        for button in self.target_buttons:
            button.set_sensitive(not (record and self.recording))
            if record:
                button.add_css_class("record")
            else:
                button.remove_css_class("record")
        # Recordings are always written to disk; the frozen screen only works
        # for screenshots.
        self.save_row.set_visible(not record)
        self.freeze_row.set_visible(not record)
        self.dir_title.set_label("Save recordings to" if record else "Save screenshots to")
        self.dir_label.set_label(tilde(self.settings["dirs"][mode]))
        self.dir_label.set_tooltip_text(self.settings["dirs"][mode])

    def set_dir(self, path):
        self.settings["dirs"][self.settings["mode"]] = path
        save_settings(self.settings)
        self.update_mode()

    def on_reset_dir(self, _):
        self.set_dir(DEFAULTS["dirs"][self.settings["mode"]])

    def on_browse(self, _):
        # The chooser is an ordinary window, which this overlay would cover and
        # keep the keyboard from, so the panel steps aside until it is done.
        current = self.settings["dirs"][self.settings["mode"]]
        dialog = Gtk.FileDialog(title="Save captures to", modal=True)
        if os.path.isdir(current):
            dialog.set_initial_folder(Gio.File.new_for_path(current))
        self.set_visible(False)

        def chosen(dialog, result):
            try:
                folder = dialog.select_folder_finish(result)
            except GLib.Error:
                folder = None
            if folder and folder.get_path():
                self.set_dir(folder.get_path())
            self.present()

        dialog.select_folder(None, None, chosen)

    def on_key(self, controller, keyval, keycode, state):
        name = (Gdk.keyval_name(keyval) or "").lower()
        if name == "escape":
            self.app.quit()
        elif name in ("tab", "iso_left_tab"):
            other = "rec" if self.settings["mode"] == "shot" else "shot"
            self.mode_buttons[other].set_active(True)
        elif name == "o":
            self.expander.set_expanded(not self.expander.get_expanded())
        elif name in ("return", "kp_enter") and self.recording:
            self.run(["hyprcap", "rec-stop", "-q", "--disable-title"])
        else:
            for selection, _, _, key in TARGETS:
                if name == key:
                    if self.target_buttons[0].get_sensitive():
                        self.capture(selection)
                    return True
            return False
        return True

    def capture(self, selection):
        settings = self.settings
        mode = settings["mode"]
        folder = settings["dirs"][mode]
        command = ["hyprcap", "shot" if mode == "shot" else "rec-start", "-s", selection, "-n", "-q", "--disable-title"]
        if mode == "rec" or settings["save"]:
            os.makedirs(folder, exist_ok=True)
            command += ["-w", "-o", folder]
        if settings["copy"]:
            command.append("-c")
        if mode == "shot" and settings["freeze"]:
            command.append("-z")
        if settings["delay"]:
            command += ["-d", str(settings["delay"])]
        self.run(command)

    def run(self, command):
        """Hides the panel, then hands over to hyprcap, which outlives us."""
        self.set_visible(False)

        def start():
            subprocess.Popen(
                command,
                start_new_session=True,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            self.app.quit()

        GLib.timeout_add(HIDE_MS, start)


class App(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="dev.brpol.Capture", flags=Gio.ApplicationFlags.HANDLES_COMMAND_LINE)
        self.panel = None

    def do_startup(self):
        Gtk.Application.do_startup(self)
        # The icon names here are Adwaita's; breeze-dark draws some of them blank.
        Gtk.Settings.get_default().props.gtk_icon_theme_name = "Adwaita"
        display = Gdk.Display.get_default()
        for load in (lambda provider: provider.load_from_path(COLORS_PATH), lambda provider: provider.load_from_string(CSS)):
            provider = Gtk.CssProvider()
            try:
                load(provider)
            except GLib.Error:
                continue
            Gtk.StyleContext.add_provider_for_display(display, provider, Gtk.STYLE_PROVIDER_PRIORITY_USER)

    def do_command_line(self, command_line):
        if self.panel:
            self.quit()
        else:
            self.panel = Panel(self)
            self.panel.present()
        return 0


if __name__ == "__main__":
    sys.exit(App().run(sys.argv))
