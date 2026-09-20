# Waybar taskbar daemon -- done

The 39 waybar module scripts are one daemon now:
`~/.config/waybar/brpol-waybard/`, whose README covers what it is, how to run
and inspect it, and how to add a dependency.

What the plan set out to fix, measured on a live session before and after:

| | before | after |
|---|---|---|
| processes | 39 python | 1 daemon + 39 `cat` |
| memory | ~228 MB PSS (575 MB RSS) | 14 MB PSS (9 daemon + 5 for the 39 `cat`) |
| socket2 subscriptions | 39 | 1 |
| `j/...` round trips per event | ~129 | 5 |
| `lockedAddresses()` per event | 12 | 1 |

Two things the design changed along the way:

- The refresh signal is gone entirely rather than retargeted. `conf/wm/taskbar.lua`
  writes `refresh` to a control FIFO, which also carries the clicks, so
  `SIGRTMIN+8`, the `scripts/windows[.]py [0-9]` cmdline regex and the
  `set_wakeup_fd` self-pipe all went with it, and a click no longer starts a
  Python process.
- A pipe is not a file: whoever reads a line takes it, so a button waybar
  restarted had nothing to draw until the next event. Each button asks for its
  current line with `ctl.sh prime <name>` as it comes up.

The open question about porting to Rust is settled: the argument for it was
dropping `python` from `DEPENDENCIES.md` so Arch rolling Python majors could
not break the bar, and the pinned interpreter in `uv.lock` does that without a
build step in a config repo.
