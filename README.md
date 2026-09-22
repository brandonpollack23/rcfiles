![Hand of Zeus](hand_of_zeus.png "My Logo")

# rcfiles

My dotfiles, linked into `$HOME` with [GNU Stow](https://www.gnu.org/software/stow/)
and driven by [mise](https://mise.jdx.dev) tasks written in
[Amber](https://amber-lang.com).

## Setup

```sh
git clone https://github.com/brandonpollack23/rcfiles ~/rcfiles
cd ~/rcfiles
./install.sh
```

`install.sh` installs mise (Homebrew on the Mac, installing Homebrew first if
needed; pacman on Arch; mise's own installer on Debian and Fedora), trusts this
repo's `mise.toml`, has mise install amber and yq (`mise install`), then runs
`mise run install`. It's safe to run again.

### By hand

1. Install mise: `brew install mise`, `sudo pacman -S mise`, or `curl https://mise.run | sh`.
2. `mise trust && mise install` (fetches amber, which runs the tasks, and yq)
3. `mise run install`, which depends on these tasks and runs them in order (each works on its own):

| task             | does                                                          |
| ---------------- | ------------------------------------------------------------- |
| `deps`           | installs the programs in `packages.toml` (Homebrew, casks and the App Store on the Mac, pacman + yay/paru on Arch, Homebrew on Debian and Fedora, cargo binstall everywhere), Rust (rustup), and the latest Erlang and Elixir (`mise use -g`). It asks which groups this machine gets (see below) |
| `stow`           | links every package in `dotfiles/` into `$HOME`               |
| `plugins`        | installs zsh (antidote), tmux (tpm) and neovim (lazy.nvim) plugins |
| `fonts`          | copies `fonts/*.ttf` to the user font directory               |
| `sops-bootstrap` | lets this machine decrypt the secrets (asks for the master password) |
| `gdrive`         | on Linux, mounts the personal and univalent Google Drives under `/mnt/google_drive` (rclone, systemd mount units, config in `/etc/rclone` from the `GDRIVE_*` secrets); skipped until the secrets are there |
| `setup`          | logs in to GitHub (`gh auth login`, git credentials in `~/.gitconfig.local`) and checks git, jj and neovim are ready, running `deps`, `stow` or `plugins` for anything missing |

`packages.toml` groups the packages: `core` (the shell, editor and git tools;
every machine), `mac` (every Mac), and `dev`, `embedded`, `tools`, `desktop`,
`communication` and `gaming`, which `deps` asks about the first time and remembers in
`~/.config/rcfiles/groups`. `mise run deps dev desktop` (or `all`) picks again;
`mise run deps -n` prints the install commands without running them.

If files already exist where the links go, `stow` stops and names them. Delete
them, or pull them into the repo with `mise run adopt <package>`.

## Layout

| path                  | what it is                                                        |
| --------------------- | ----------------------------------------------------------------- |
| `dotfiles/<package>/` | stow packages; each mirrors `$HOME` (`dotfiles/nvim/.config/nvim` → `~/.config/nvim`) |
| `scripts/`            | the mise tasks, one Amber script each (`mise run <name>`); shared code in `scripts/lib/`, tests in `scripts/lib/tests/` |
| `packages.toml`       | what `deps` installs, in groups, with each package's name per OS |
| `mise.toml`           | env, task config, and the amber and yq versions                   |
| `install.sh`          | bash bootstrap: installs mise, `mise install` (amber, yq), then `mise run install` |
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
mise run lint                 # amber check on every script (after editing one)
mise run test                 # the Amber tests in scripts/lib/tests
```

The tasks are Amber scripts run from source (`amber run`, no build step);
mise installs the pinned amber. `AGENTS.md` has the conventions and the
compiler quirks to know about when editing them.

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
