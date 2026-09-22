![Hand of Zeus](hand_of_zeus.png "My Logo")

# rcfiles

My dotfiles, linked into `$HOME` with [GNU Stow](https://www.gnu.org/software/stow/)
and driven by [mise](https://mise.jdx.dev) tasks.

## Setup

```sh
git clone https://github.com/brandonpollack23/rcfiles ~/rcfiles
cd ~/rcfiles
./install.sh
```

`install.sh` installs mise with the OS package manager (Homebrew on the Mac,
pacman on Arch), trusts this repo's `mise.toml`, then runs `mise run install`.
It's safe to run again.

### By hand

1. Install mise: `brew install mise` or `sudo pacman -S mise`.
2. `mise trust`
3. `mise run install`, which runs these tasks in order (each works on its own):

| task             | does                                                          |
| ---------------- | ------------------------------------------------------------- |
| `deps`           | installs the programs the configs need (`Brewfile` on the Mac, pacman + yay/paru on Arch) |
| `stow`           | links every package in `dotfiles/` into `$HOME`               |
| `plugins`        | installs zsh (antidote), tmux (tpm) and neovim (lazy.nvim) plugins |
| `fonts`          | copies `fonts/*.ttf` to the user font directory               |
| `sops-bootstrap` | lets this machine decrypt the secrets (asks for the master password) |

If files already exist where the links go, `stow` stops and names them. Delete
them, or pull them into the repo with `mise run adopt <package>`.

## Layout

| path                  | what it is                                                        |
| --------------------- | ----------------------------------------------------------------- |
| `dotfiles/<package>/` | stow packages; each mirrors `$HOME` (`dotfiles/nvim/.config/nvim` → `~/.config/nvim`) |
| `scripts/`            | the mise tasks, one script each (`mise run <name>`)               |
| `mise.toml`           | env and task config                                               |
| `install.sh`          | bootstrap: installs mise, then runs `mise run install`            |
| `Brewfile`            | Mac packages                                                      |
| `fonts/`              | Consolas Nerd Font                                                |
| `docs/`               | reference notes (ANSI escapes, Linux/SSH/nmap/fio tips)           |
| `.sops.yaml`, `*.sops.*`, `.sops-master.key.age` | encrypted secrets (see below)          |

Packages: `claude`, `ghostty`, `git`, `iex`, `jj`, `nvim` (LazyVim), `starship`,
`systemd`, `tmux`, `zsh`. Machine-only settings go in the untracked
`~/.zshrc.local` and `~/.gitconfig.local`.

## Tasks

`mise tasks` lists them all. Day to day:

```sh
mise run stow [pkg…]          # link (all if none named); re-run after adding files
mise run check [pkg…]         # dry run: what would be linked, and conflicts
mise run unstow <pkg…>        # remove a package's links
mise run add <pkg> <path…>    # move files from $HOME into a package and link them back
mise run adopt <pkg…>         # stow over existing files, pulling them into the repo
mise run update               # update zsh, tmux and neovim plugins
mise run secrets              # edit secrets.sops.env
```

## Notes

- **Stow** links the highest directory it can, so `~/.config/nvim` is one link
  and files programs write there (like `lazy-lock.json`) show up in the repo.
  The `stow` task pre-creates shared dirs (`~/.config`, `~/.local/bin`, …) so
  other programs' files stay out.
- **Plugins** have no submodules or vendored copies. zsh plugins are listed in
  `dotfiles/zsh/.zsh_plugins.txt` (antidote; OMZ plugins via use-omz), tmux
  plugins in `.tmux.conf` (tpm), neovim plugins in `lua/plugins/` (pinned by
  `lazy-lock.json`). Completions come from plugins, system packages, or
  `lazy_completion` in the zshrc.
- **Prompt** is [starship](https://starship.rs) plus
  [starship-jj](https://gitlab.com/lanastara/starship-jj) for jj repos
  (installed with cargo by `deps`).
- **Secrets** are committed encrypted with [sops](https://github.com/getsops/sops)
  + [age](https://github.com/FiloSottile/age). Each machine has its own key in
  `~/.config/sops/age/keys.txt`. `sops-bootstrap` creates it, unlocks the
  master key with the master password, and re-encrypts every secret for the new
  machine; commit and push `.sops.yaml` and the secrets afterwards. Back up
  the machine key and the master password.
