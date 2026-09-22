![Hand of Zeus](hand_of_zeus.png "My Logo")

# Initialize system prefs

## What do
```sh
git clone --recursive https://github.com/brandonpollack23/rcfiles
cd rcfiles
./install.sh --dry-run   # see what it would do
./install.sh
```

## Scripts

The installer, the zsh environment and aliases, the Hacker News MOTD and the
secrets bootstrap are written in [Amber](https://amber-lang.com) under
`scripts/`, one project each, and compiled to shell that is committed (so
`install.sh` runs on a machine without amber). `AGENTS.md` has the details.

```sh
mise run test    # run every project's tests
mise run build   # recompile the committed shell
mise run hooks   # pre-commit hook that does both (install.sh sets it up)
```

## Anything else?
It turns on modcgi in apache so you can go to:
[man2html](http://localhost/cgi-bin/man/man2html)
[info2www](http://localhost/cgi-bin/info2www) 
for pretty docs


## What does it do
* dependencies
* symbolic linking of configs
* vim
* tmux
* zsh
* systemd user stuff (like timers)

## About systemd directory
User units in `.config/systemd/user` are linked one by one into
`~/.config/systemd/user`, which also holds units local to the machine. The
installer skips the systemd steps where there is no `systemctl`.

## How to add vim plugins
```sh
cd .vim/pack/brpol/start
git submodule add $PLUGIN
```

## How to add zsh plugins
If it isn't already in oh-my-zsh
```sh
cd zsh-custom/plugins
git submodule add $PLUGIN
```
then add its name to `plugins=(...)` in `.zshrc`.

## Fonts

I included a consolas font that has all nerd fonts as well as devicons.  Install it and use it.

## Bonus Utilities You May Want

### Printing
man cups (localhost:631)

### Applications
* Network/DNS/Internet utils
    * Debian: dnsutils -- dig/nslookup
    * Redhat: bind-utils -- dig/nslookup
    * traceroute -- find traceroute lol
    * nmap -- good enough for trinity!
        * `nmap -sP 192.168.1.0/24` -- scan everything on network
        * `nmap -sS -sU -T5 -A -v 192.168.1.0/24` -- find local network hostnames
* pandoc -- convert markdown to pdf/html and a bunch of other formats
    * texlive -- pdflatex comes with this and is required for the above
    * texlive-plain-generic -- more of the above
    * Fonts of interest: tug.org/FontCatalogue/
        * Inconsolata mono
        * Arev
    * Example command: `pandoc markdown_test.md -t latex -V mainfont=arev -V monofont=inconsolata -o markdown_test.pdf`
* netselect-apt -- find out the "best" mirror and auto switch!
