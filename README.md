# Initialize system prefs

## What do
```sh
git clone --recursive https://github.com/brandonpollack23/rcfiles
./install
```

### Bonus for administrators
If you want every user account created to default use these settings/configs/etc
you can run
```
install_skel
```
which copies the configs as is to skel

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
* tree

## How to add vim plugins
```sh
cd .vim/pack/brpol/start
git submodule add $PLUGIN
```

## How to add zsh plugins
If it isn't already oh-my-zh
```sh
cd zsh-plugins
git submodule add $PLUGIN
echo "source $PWD/$PLUGIN_PATH_TO_DOT_ZSH_FILE" > ${ZDOTDIR:-$HOME}/.zshrc
```
