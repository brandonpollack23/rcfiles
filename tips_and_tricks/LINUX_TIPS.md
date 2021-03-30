# Finding Help (Debian biased)
* man pages
    * If you wanna see these in a browser, install man2html, turn on cgi, and start apache.  This works by calling into cgi by default in `/lib/` (with the explicit subpath `cgi-bin/man/man2html`)
* `(p)info`
* `/usr/share/doc/*package*/README`
* `/usr/share/doc/*package*/examples/`
* `dpkg` -s *package* -- look through the package metadata for a site
* `dpkg` -L *package* -- look through the package contents to see what docs included
* `apt source *package* --` Lots of times you can get more handbooks with the source (bash or emacs for example)
* `dpkg-src` also exists similar to dpkg
* Debian handbook /usr/share/doc/debian-handbook

# Getting Package Dependencies
On Debian the rcfiles installer will get devscripts which includes a lot of useful tools like
* `whodepends`
* `mk-build-deps`
    - use it by going into the extracted package and calling `sudo mk-build-deps -i`

# Program logs

## How it is done
Logs are collected by a special daemon called rsyslogd.
Depending on subsystem and priority, decides if it should be logged, where, and if it should be sent to the administrator console (tty0)
(they actually go to systemd first.  systemd may or may not persist those logs. systemd's journal has it as well, journalctl).

some things log manage themselves (eg samba)

## Where
`/vars/logs/`

## Helper utilities that exist

### Alerting utils
`logcheck`

### Analysis
analog, awstats, webalizer, etc

# systemd

## Unit locations
`/lib/systemd/system/`

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
Debian Manual 9.2.1.3, TLDR: you can forward a port via ssh

# GUIS for administration
* webmin -- first in the debian manual and mentioned all throughout reddit.com/r/homelab, must be good.  I'd bet Trinity uses it, too
    * Unfortunately you have to get this one manually from their website.
* RHEL/systemd reccomend cockpit and people say its better.
* debconf -- configuring packages.  `dpkg-reconfigure`

# Wake On Lan

1) install the right tools to do it (wakeonlan).
2) gotta know the mac address
3) `wakeonlan -i IP MAC`
[accross the webz](https://wiki.archlinux.org/index.php/Wake-on-LAN#Across_the_internet)

# update-alternatives
to see available alternatives for a binary
`update-alternatives --query`

to add one
`update-alternatives --install ALTERNATIVE_LINK_PATH ALTERNATIVE_NAME NEW_EXECUTABLE_PATH PRIORITY`

the alternative is usually linked to by the `/usr/bin` directory or some built in. That never changes, the alternatives does.

ALTERNATIVE_LINK_PATH in debian starts as `/etc/alternatives/*`

you can change which alternative dynamically
`update-alternatives --config ALTERNATIVE_NAME`
