# Finding Help (Arch)
* man pages
    * If you wanna see these in a browser, install man2html, turn on cgi, and start apache.  This works by calling into cgi by default in `/lib/` (with the explicit subpath `cgi-bin/man/man2html`)
* `(p)info`
* `/usr/share/doc/*package*/README`
* `/usr/share/doc/*package*/examples/`
* `pacman -Qi` *package* -- installed package metadata, including its upstream URL (`-Si` for one that isn't installed)
* `pacman -Ql` *package* -- list the package contents to see what docs are included
* `pacman -Qo` *path* -- which package owns a file; `pacman -F` *file* searches packages you don't have (after `sudo pacman -Fy`)
* `pkgctl repo clone` *package* (devtools) or `yay -G` *package* for AUR -- get the PKGBUILD, then `makepkg -o` downloads and extracts the source. Lots of times you can get more handbooks with the source (bash or emacs for example)
* The Arch Wiki offline: `arch-wiki-docs` (HTML in /usr/share/doc/arch-wiki/html), searchable from the terminal with `wikiman`

# Getting Package Dependencies
`pacman-contrib` has the useful tools:
* `pactree` *package* -- dependency tree; `pactree -r` *package* -- what depends on it (also "Required By" in `pacman -Qi`)
* `makepkg -s` -- installs a PKGBUILD's build dependencies before building (`-r` removes them afterwards)

# Program logs

## How it is done
Logs are collected by systemd's journald (see journalctl below). Arch has no syslog daemon by default; the journal is
persistent in `/var/log/journal/` and there are no plain-text logs unless you install one (syslog-ng or rsyslog).

some things log manage themselves (eg samba)

## Where
`journalctl`, and `/var/log/` for the few programs that write their own files (pacman.log, Xorg, samba)

## Helper utilities that exist

### Alerting utils
`logwatch`

### Analysis
analog, awstats, webalizer, etc

# systemd

## Unit locations
`/usr/lib/systemd/system/` (packages), `/etc/systemd/system/` (yours and overrides), `~/.config/systemd/user/` (user units)

## commands

### systemctl
controls services/units and can query info about them.

>Note, you can glob {}, etc in systemd and do multiple commands at once like:
>```
>systemctl {start,enable} apache2.service
>```
>HOW COOL IS THAT??

`systemctl` -- controls active services, alone it just lists them
`systemctl status` -- nice cgrouped view of all services, try to spot the pager this is listed in!
`systemctl status UNIT.NAME` -- even more info, docs info, unit directory, etc, even some logs
`systemctl start/stop SERVICE.NAME` -- start or stop a service (duh)
`systemctl enable/disable SERVICE.NAME` -- enable/disable a service (at boot)
`systemctl -t (service|...)` -- list RUNNING relevant units pertaining to query (eg list all running services)
`systemctl --failed` -- list FAILED units
`systemctl list-unit-files -t (service|...)` -- list all INSTALLED units pertaining to query
`systemd-delta` -- see overridden configurations in `/run` (ephermeral) or by user/maintainers in `/etc/systemd/system` or `/usr/lib/system`

### Run Targets
Essentially a barrier, like leves in init
you can
* `systemctl set-default TARGETNAME`
* `systemctl get-default`
* `systemctl isolate` -- This one changes between them (eg if your default is to go to everything before graphical, you can step up to graphical target with this command

### jourrnalctl
communicates with journald

`journalctl` -- vomits out all logs since boot
`journalctl -u SERVICE.NAME` -- vomits out all logs for a specific service
`journalctl -f` -- keeps following new messages, can be combined with others (like `tail -f FILE`)

### Timers
Yeah systemd has timers like cron, but it can do some cool stuff like:
* be seperated
* respond to system events or other services in systemd
    * do stuff at boot after a certain time 
    * read the `man systemd.timer`

# ssh
`ssh-keygen -t rsa`
``ssh-copy-id SERVER`

When using it on a client, make sure you activate ssh-agent
`eval $(ssh-agent)`

## X11 forwarding
turn it on by editing the ssh config
`/etc/ssh/sshd_config`
and adding
`X11Forwarding`
and connecting with the `-X` flag

## Port forwarding
`ssh -L 8080:localhost:80 SERVER` makes the server's port 80 available on local port 8080 (`-R` goes the other way).
See the Arch Wiki, OpenSSH#Forwarding other ports.

# GUIS for administration
* cockpit -- in the official repos (`cockpit`), recommended by RHEL/systemd and people say it's better.
* webmin -- mentioned all throughout reddit.com/r/homelab; it's in the AUR (`webmin`).
* Packages don't ask configuration questions on Arch. When an upgrade changes a config file you edited, pacman writes
  the new one as `.pacnew` next to it; `pacdiff` (pacman-contrib) finds them and merges.

# Wake On Lan

1) install the right tools to do it (`sudo pacman -S wakeonlan`).
2) gotta know the mac address
3) `wakeonlan -i IP MAC`
[accross the webz](https://wiki.archlinux.org/index.php/Wake-on-LAN#Across_the_internet)

# Alternatives (no update-alternatives)
Arch has no alternatives system. Instead:
* Several packages can `provide` the same thing (e.g. `java-runtime`); pacman asks which one to install.
* Java has its own switcher: `archlinux-java status` and `sudo archlinux-java set JAVA_ENV`.
* For anything else, put a symlink in `/usr/local/bin` (or `~/.local/bin`), which comes before `/usr/bin` in `$PATH`:
  `sudo ln -s /usr/bin/nvim /usr/local/bin/vi`
