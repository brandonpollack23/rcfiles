#!/usr/bin/python3
"""The bar popups l1p0-menus has no module for: PIA, weather and the Bing
wallpaper.

    popups.py pia | weather | bing     toggle that popup

Built the way l1p0-menus builds its own (GTK4 on gtk4-layer-shell, one
namespace per popup, same stylesheet and class names), so they look and animate
alike. The first call stays resident as the GApplication's primary instance;
later calls only hand it their argument and exit, which is what makes a click
on the bar a toggle; a hidden popup still counts as the application's window,
so it stays up between clicks. System python: PyGObject comes from pacman, as it does for
l1p0-menus itself.
"""

import json
import os
import sys
import threading
import time
import urllib.parse
import urllib.request
from ctypes import CDLL

CDLL("libgtk4-layer-shell.so")

import gi

gi.require_version("Gdk", "4.0")
gi.require_version("GdkPixbuf", "2.0")
gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gdk, GdkPixbuf, Gio, GLib, Gtk, Gtk4LayerShell as LayerShell  # noqa: E402

DIR = os.path.dirname(os.path.realpath(__file__))
WEATHER_TTL = 600  # seconds
BING = os.path.expanduser("~/.config/hypr/scripts/bing-wallpaper.sh")
# Where bing-wallpaper.sh keeps the image on screen and Bing's metadata for it.
BING_DIR = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"), "bing-wallpaper")
BING_WIDTH = 380

# OpenWeatherMap icon codes to icon-theme names, as l1p0-menus maps them.
WEATHER_ICONS = {
    "01d": "weather-clear-symbolic",
    "01n": "weather-clear-night-symbolic",
    "02d": "weather-few-clouds-symbolic",
    "02n": "weather-few-clouds-night-symbolic",
    "03": "weather-overcast-symbolic",
    "04": "weather-overcast-symbolic",
    "09": "weather-showers-symbolic",
    "10": "weather-showers-symbolic",
    "11": "weather-storm-symbolic",
    "13": "weather-snow-symbolic",
    "50": "weather-fog-symbolic",
}


def weather_icon(code):
    return WEATHER_ICONS.get(code) or WEATHER_ICONS.get(code[:2], "image-missing")


def run(argv, done=None):
    """Runs a command without blocking the UI; done(stdout) on the main loop."""
    try:
        proc = Gio.Subprocess.new(argv, Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_SILENCE)
    except GLib.Error:
        if done:
            done("")
        return

    def finished(proc, result):
        try:
            _, out, _ = proc.communicate_utf8_finish(result)
        except GLib.Error:
            out = ""
        if done:
            done((out or "").strip())

    proc.communicate_utf8_async(None, None, finished)


def label(text="", *classes, **props):
    widget = Gtk.Label(label=text, **props)
    for name in classes:
        widget.add_css_class(name)
    return widget


class Popup(Gtk.Window):
    """A layer-shell panel anchored to the bar (bottom edge)."""

    def __init__(self, app, name, side, margin):
        super().__init__(application=app, title=f"{name} popup")
        LayerShell.init_for_window(self)
        LayerShell.set_namespace(self, f"{name}-layer")
        LayerShell.set_layer(self, LayerShell.Layer.TOP)
        LayerShell.set_anchor(self, LayerShell.Edge.BOTTOM, True)
        LayerShell.set_anchor(self, side, True)
        LayerShell.set_margin(self, LayerShell.Edge.BOTTOM, 8)
        LayerShell.set_margin(self, side, margin)
        self.add_css_class(f"{name}-window")
        self.content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.content.add_css_class(f"{name}-layer")
        self.set_child(self.content)
        self.connect("close-request", lambda window: window.set_visible(False) or True)

    def toggle(self):
        if self.get_visible():
            self.set_visible(False)
        else:
            self.on_show()
            self.present()

    def on_show(self):
        pass


class PiaPopup(Popup):
    def __init__(self, app):
        super().__init__(app, "pia", LayerShell.Edge.RIGHT, 10)
        self.set_default_size(340, -1)
        self.state = ""
        self.region = ""
        self.region_rows = {}

        top = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        text = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, hexpand=True)
        self.state_label = label("…", "pia-state", halign=Gtk.Align.START)
        self.detail_label = label("", "pia-detail", halign=Gtk.Align.START)
        text.append(self.state_label)
        text.append(self.detail_label)
        self.switch = Gtk.Switch(valign=Gtk.Align.CENTER)
        self.switch.add_css_class("network-switch")
        self.switch_handler = self.switch.connect("state-set", self.on_switch)
        top.append(text)
        top.append(self.switch)
        self.content.append(top)

        self.content.append(label("REGION", "header-label", halign=Gtk.Align.START))
        self.scroller = Gtk.ScrolledWindow(min_content_height=260, max_content_height=260)
        self.scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.scroller.add_css_class("scrolled-menu")
        self.regions = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.scroller.set_child(self.regions)
        self.content.append(self.scroller)

        self.watch("connectionstate", self.set_state)
        self.watch("region", self.set_region)
        run(["piactl", "get", "regions"], self.set_regions)

    def watch(self, what, callback):
        """Follows `piactl monitor`, which prints the value now and on each change."""
        try:
            proc = Gio.Subprocess.new(
                ["piactl", "monitor", what], Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_SILENCE
            )
        except GLib.Error:
            self.state_label.set_label("piactl not found")
            return
        stream = Gio.DataInputStream.new(proc.get_stdout_pipe())

        def read(stream, result):
            line, _ = stream.read_line_finish_utf8(result)
            if line is None:
                return
            callback(line.strip())
            stream.read_line_async(GLib.PRIORITY_DEFAULT, None, read)

        stream.read_line_async(GLib.PRIORITY_DEFAULT, None, read)
        # Keep the process referenced for as long as the popup lives.
        setattr(self, f"_watch_{what}", proc)

    def set_state(self, state):
        self.state = state
        self.state_label.set_label(state)
        for name, on in (("connected", state == "Connected"), ("busy", state not in ("Connected", "Disconnected"))):
            if on:
                self.state_label.add_css_class(name)
            else:
                self.state_label.remove_css_class(name)
        self.switch.handler_block(self.switch_handler)
        self.switch.set_active(state != "Disconnected")
        self.switch.set_state(state != "Disconnected")
        self.switch.handler_unblock(self.switch_handler)
        self.update_detail()

    def update_detail(self):
        if self.state == "Connected":
            run(["piactl", "get", "vpnip"], lambda ip: self.detail_label.set_label(f"{self.region} · {ip}"))
        else:
            self.detail_label.set_label(self.region)

    def set_region(self, region):
        self.region = region
        for name, row in self.region_rows.items():
            if name == region:
                row.add_css_class("active")
            else:
                row.remove_css_class("active")
        self.update_detail()

    def set_regions(self, out):
        for name in out.split():
            row = Gtk.Button()
            row.set_child(label(name, halign=Gtk.Align.START))
            row.add_css_class("pia-region")
            row.connect("clicked", self.on_region, name)
            self.regions.append(row)
            self.region_rows[name] = row
        self.set_region(self.region)
        GLib.idle_add(self.scroll_to_region)

    def on_show(self):
        GLib.idle_add(self.scroll_to_region)

    def scroll_to_region(self):
        row = self.region_rows.get(self.region)
        found, bounds = row.compute_bounds(self.regions) if row else (False, None)
        if found:
            adjustment = self.scroller.get_vadjustment()
            adjustment.set_value(bounds.get_y() - (adjustment.get_page_size() - bounds.get_height()) / 2)

    def on_switch(self, switch, on):
        run(["piactl", "connect" if on else "disconnect"])
        return True  # the monitor moves the switch once PIA reports the change

    def on_region(self, button, name):
        # `connect` while connected is how piactl applies a new region.
        reconnect = self.state != "Disconnected"
        run(["piactl", "set", "region", name], lambda _: reconnect and run(["piactl", "connect"]))


class WeatherPopup(Popup):
    def __init__(self, app):
        super().__init__(app, "weather", LayerShell.Edge.LEFT, 240)  # centred on its module, right of the clock
        self.set_default_size(380, -1)
        self.fetched = 0

        self.status = label("Loading…", "pia-detail")
        self.content.append(self.status)

        self.now = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, visible=False)
        self.icon = Gtk.Image(icon_name="weather-clear-symbolic")
        self.icon.add_css_class("weather-icon")
        self.temp = label("", "weather-temp")
        self.description = label("", "weather-description")
        self.place = label("", "weather-city")
        self.extra = label("", "pia-detail")
        for widget in (self.icon, self.temp, self.description, self.place, self.extra):
            self.now.append(widget)
        self.content.append(self.now)

        self.hours = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, homogeneous=True, visible=False)
        self.hours.add_css_class("upcoming-container")
        self.content.append(self.hours)

        self.days = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, visible=False)
        self.days.add_css_class("upcoming-container")
        self.content.append(self.days)

    def on_show(self):
        if time.time() - self.fetched > WEATHER_TTL:
            threading.Thread(target=self.fetch, daemon=True).start()

    def fetch(self):
        try:
            # Both written by launch.sh, which l1p0-menus needs them from too.
            with open(os.path.join(DIR, "config.json")) as config:
                weather = json.load(config)["weather-clock"]
            key, city = weather.get("api_key"), weather.get("city")
            if not key or not city:
                raise RuntimeError("No API key: set OWM_API_KEY with `mise run secrets`, then restart waybar")
            query = urllib.parse.urlencode({"q": city, "appid": key, "units": "metric"})
            data = {}
            for kind in ("weather", "forecast"):
                with urllib.request.urlopen(f"https://api.openweathermap.org/data/2.5/{kind}?{query}", timeout=5) as reply:
                    data[kind] = json.load(reply)
            GLib.idle_add(self.show_weather, data["weather"], data["forecast"])
        except Exception as error:  # shown in the popup rather than lost in a log
            GLib.idle_add(self.show_error, str(error))

    def show_error(self, message):
        self.status.set_label(message)
        self.status.set_visible(True)

    def show_weather(self, now, forecast):
        self.fetched = time.time()
        self.status.set_visible(False)
        self.icon.set_from_icon_name(weather_icon(now["weather"][0]["icon"]))
        self.temp.set_label(f"{round(now['main']['temp'])}°")
        self.description.set_label(now["weather"][0]["description"].upper())
        self.place.set_label(f"{now['name']}, {now['sys']['country']}")
        self.extra.set_label(
            f"feels {round(now['main']['feels_like'])}°    "
            f"󰖝 {round(now['wind']['speed'] * 3.6)} km/h    󰖎 {now['main']['humidity']}%"
        )

        offset = forecast["city"]["timezone"]
        steps = [(time.gmtime(step["dt"] + offset), step) for step in forecast["list"]]

        self.clear(self.hours)
        for when, step in steps[:6]:
            card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
            card.add_css_class("upcoming-items-container")
            card.append(label(time.strftime("%H:%M", when), "upcoming-time"))
            image = Gtk.Image(icon_name=weather_icon(step["weather"][0]["icon"]))
            image.add_css_class("upcoming-icons")
            card.append(image)
            card.append(label(f"{round(step['main']['temp'])}°"))
            self.hours.append(card)

        # One row per day: its range, and the icon from the step nearest midday.
        by_day = {}
        for when, step in steps:
            by_day.setdefault(time.strftime("%Y-%m-%d", when), []).append((when, step))
        self.clear(self.days)
        for entries in list(by_day.values())[:5]:
            midday = min(entries, key=lambda entry: abs(entry[0].tm_hour - 13))[1]
            low = min(step["main"]["temp_min"] for _, step in entries)
            high = max(step["main"]["temp_max"] for _, step in entries)
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
            row.add_css_class("weather-day")
            row.append(label(time.strftime("%a", entries[0][0]), "weather-day-name", xalign=0))
            image = Gtk.Image(icon_name=weather_icon(midday["weather"][0]["icon"]))
            image.add_css_class("upcoming-icons")
            row.append(image)
            row.append(label(midday["weather"][0]["description"], hexpand=True, xalign=0))
            row.append(label(f"{round(low)}° / {round(high)}°", "weather-day-range"))
            self.days.append(row)

        for widget in (self.now, self.hours, self.days):
            widget.set_visible(True)

    @staticmethod
    def clear(box):
        while child := box.get_first_child():
            box.remove(child)


class BingPopup(Popup):
    def __init__(self, app):
        super().__init__(app, "bing", LayerShell.Edge.LEFT, 10)
        self.set_default_size(BING_WIDTH, -1)
        self.shown = None

        self.picture = Gtk.Picture(content_fit=Gtk.ContentFit.COVER, can_shrink=True)
        self.picture.set_size_request(BING_WIDTH, BING_WIDTH * 9 // 16)
        self.picture.add_css_class("bing-picture")
        self.picture.set_overflow(Gtk.Overflow.HIDDEN)  # so the corners round
        self.content.append(self.picture)

        self.title = label("No Bing wallpaper yet", "bing-title", halign=Gtk.Align.START, wrap=True, xalign=0)
        self.description = label("", "bing-description", halign=Gtk.Align.START, wrap=True, xalign=0)
        self.detail = label("", "pia-detail", halign=Gtk.Align.START, wrap=True, xalign=0)
        for widget in (self.title, self.description, self.detail):
            self.content.append(widget)

        buttons = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10, homogeneous=True)
        self.open_button = Gtk.Button(label="󰖟  Open on Bing")
        self.open_button.connect("clicked", self.on_open)
        refresh = Gtk.Button(label="󰑐  Refresh")
        refresh.connect("clicked", lambda _: run([BING, "refresh"]))
        for button in (self.open_button, refresh):
            button.add_css_class("popup-button")
            buttons.append(button)
        self.content.append(buttons)

        # A refresh (or the timer) repoints current.json; follow it while up.
        os.makedirs(BING_DIR, exist_ok=True)
        self.monitor = Gio.File.new_for_path(BING_DIR).monitor_directory(Gio.FileMonitorFlags.NONE, None)
        self.monitor.connect("changed", self.on_changed)

    def on_show(self):
        self.load()

    def on_changed(self, monitor, file, other, event):
        if file.get_basename() == "current.json" and self.get_visible():
            self.load()

    def load(self):
        try:
            with open(os.path.join(BING_DIR, "current.json")) as meta:
                meta = json.load(meta)
        except (OSError, ValueError):
            meta = {}
        # "Sea otters, Monterey Bay (© Someone/Agency)": the credit on its own line.
        about, _, credit = meta.get("copyright", "").partition(" (©")
        date = meta.get("startdate", "")
        if len(date) == 8:
            date = time.strftime("%A, %B %d %Y", time.strptime(date, "%Y%m%d"))
        self.title.set_label(meta.get("title") or "No Bing wallpaper yet")
        self.description.set_label(about)
        self.description.set_visible(bool(about))
        run([BING, "frequency"], lambda frequency: self.detail.set_label(
            "    ".join(part for part in (f"© {credit.strip(' )')}" if credit else "", date, f"checks {frequency}") if part)
        ))
        self.open_button.set_sensitive(bool(meta.get("copyrightlink")))

        image = os.path.realpath(os.path.join(BING_DIR, "current.jpg"))
        if image != self.shown:
            try:
                # The UHD original is 3840 wide; decode it at twice the popup's width.
                pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(image, BING_WIDTH * 2, -1, True)
                texture = Gdk.MemoryTexture.new(
                    pixbuf.get_width(),
                    pixbuf.get_height(),
                    Gdk.MemoryFormat.R8G8B8A8 if pixbuf.get_has_alpha() else Gdk.MemoryFormat.R8G8B8,
                    pixbuf.read_pixel_bytes(),
                    pixbuf.get_rowstride(),
                )
                self.picture.set_paintable(texture)
                self.shown = image
            except GLib.Error:
                self.picture.set_paintable(None)
                self.shown = None

    def on_open(self, button):
        run([BING, "open"])
        self.set_visible(False)


class App(Gtk.Application):
    POPUPS = {"pia": PiaPopup, "weather": WeatherPopup, "bing": BingPopup}

    def __init__(self):
        super().__init__(application_id="dev.brpol.BarPopups", flags=Gio.ApplicationFlags.HANDLES_COMMAND_LINE)
        self.windows = {}

    def do_startup(self):
        Gtk.Application.do_startup(self)
        # The icon names here are Adwaita's; breeze-dark draws some of them blank.
        Gtk.Settings.get_default().props.gtk_icon_theme_name = "Adwaita"
        provider = Gtk.CssProvider()
        provider.load_from_path(os.path.join(DIR, "style.css"))
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
        )

    def do_command_line(self, command_line):
        args = command_line.get_arguments()[1:]
        if len(args) != 1 or args[0] not in self.POPUPS:
            command_line.printerr_literal(f"usage: popups.py {' | '.join(self.POPUPS)}\n")
            return 1
        name = args[0]
        # One at a time, as l1p0-menus does for popups sharing a corner.
        for other, window in self.windows.items():
            if other != name:
                window.set_visible(False)
        if name not in self.windows:
            self.windows[name] = self.POPUPS[name](self)
        self.windows[name].toggle()
        return 0


if __name__ == "__main__":
    sys.exit(App().run(sys.argv))
