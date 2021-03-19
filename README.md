# Initialize system prefs

## What do
```sh
git clone --recursive https://github.com/brandonpollack23/rcfiles
./install
```


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
