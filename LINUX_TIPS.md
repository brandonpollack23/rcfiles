# Finding Help (Debian biased)
* man pages
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

`systemctl` -- controls active services, alone it just lists them
`systemctl status` -- nice cgrouped view of all services, try to spot the pager this is listed in!
`systemctl status UNIT.NAME` -- even more info, docs info, unit directory, etc, even some logs
`systemctl start/stop SERVICE.NAME` -- start or stop a service (duh)
`systemctl enable/disable SERVICE.NAME` -- enable/disable a service (at boot)

### jourrnalctl
communicates with journald

`journalctl` -- vomits out all logs since boot
`journalctl -u SERVICE.NAME` -- vomits out all logs for a specific service
`journalctl -f` -- keeps following new messages, can be combined with others (like `tail -f FILE`)

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
