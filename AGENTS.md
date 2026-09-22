# rcfiles

Dotfiles and the scripts that install them. Subdirectories with their own
rules have their own `AGENTS.md` (`.config/hypr`, `.config/waybar/brpol-waybard`).

## Shell scripts are Amber projects under `scripts/`

Every script family is its own [Amber](https://amber-lang.com) project,
compiled to plain shell that is committed, so a fresh machine runs it without
amber installed:

| Project | Entry | Committed output |
| --- | --- | --- |
| `scripts/installer` | `main.ab` | `scripts/installer/install.sh` (the root `install.sh` is a symlink to it) |
| `scripts/zshrc` | `env.ab`, `rc.ab` | `scripts/zshrc/build/env.zsh`, `rc.zsh` (zsh target, sourced by `.zshrc`) |
| `scripts/hacker-news` | `main.ab` | `scripts/hacker-news/hacker-news.sh` |
| `scripts/sops` | `main.ab` | `scripts/sops/sops-bootstrap.sh` |

Each project keeps its modules in `src/` and its tests in `tests/`.

- Never edit a generated file. Each says so on its second line. Change the
  `.ab` sources and rebuild.
- A new script is a new `scripts/<name>/` project, added to the `ENTRY_*` and
  `PROJECT_*` arrays in `scripts/build.ab`. Do not add hand-written shell.
- `scripts/build.ab` and `.githooks/pre-commit` are Amber too. They only run
  where amber is installed, so they run from source through the shebang
  `#!/usr/bin/env -S amber run` and are never compiled.

## Always test and build after a change

Any change to a `.ab` file is not done until both pass:

    mise run test     # amber test, every project
    mise run build    # recompile every output

Commit the rebuilt outputs with the sources. `mise run check` shows the
compiler's warnings; keep it quiet. The pre-commit hook runs test and build and
stages the outputs. `install.sh` installs the hook, and `mise run hooks` does it
by hand. jj does not run git hooks, so run `mise run build` yourself before
`jj commit`.

To try the installer, run `./install.sh --dry-run`: it prints every command
that would change the machine and runs none of them. Never run `install.sh`
for real from an agent session.

## `.zshrc` and `scripts/zshrc`

`.zshrc` stays hand-written, so programs that append to it keep working. It
holds what has to be zsh: oh-my-zsh and its settings, key bindings, the prompt,
functions called by name (`dates`, `jjws`), and anything that sources
third-party zsh (nix, asdf, tabtab), which must not run under Amber's ksh
emulation. Environment variables, PATH and aliases go in `scripts/zshrc`.

`rc_source_amber` in `.zshrc` sources the build output and then removes every
variable and function it created, except exported ones. So an Amber zsh file
must `export` whatever should survive; aliases survive too. No `main` block in
these files: it would run on every shell.

These files run on every new shell, so keep them cheap. In the generated
code every Amber comparison, `env_var_get` and `$(...)` expression forks a
subshell. Use inline `$ ... $` statements, `file_exists`/`dir_exists`, and
`has()` from `src/aliases.ab` rather than std's `is_command`. PATH
de-duplication is zsh's job (`typeset -U path`), not Amber's. Check startup
time before and after a change:

    for i in 1 2 3 4 5; do s=$(date +%s%N); zsh -i -c exit >/dev/null 2>&1; echo $(( ($(date +%s%N)-s)/1000000 ))ms; done

## Packages

The lists live in `scripts/installer/src/packages.ab`. `COMMON` only holds
names that Arch and Debian stable both use. Check a new name before adding it:
`pacman -Si <name>` for Arch, the AUR RPC
(`https://aur.archlinux.org/rpc/v5/info?arg[]=<name>`), and
`https://api.ftp-master.debian.org/madison?package=<name>&f=json` for Debian.

## Amber 0.6.0-alpha gotchas

Each of these was hit while writing this repo's projects.

- **Tests:** write `assert(...)?` and `assert_eq(...)?`, always with `?`.
  Without it a failed assert is forgotten as soon as a later statement runs, and
  the test passes.
- **`len()` as an argument miscompiles.** `f(len(x))` breaks; bind it first
  (`const n = len(x)`) or compare inside the call (`assert(len(x) == 2)?`).
- **No `continue` in `for i, x in ...`.** The index increment sits at the end
  of the body, so `continue` skips it and the loop never gets past `i == 0`.
  This made `--dry-run` a no-op once.
- **Module state is not shared.** A module imported from files at different
  depths (`./src/run.ab` from `main.ab`, `./run.ab` from `src/links.ab`) is
  compiled once per import path, each copy with its own variables. Keep shared
  state in exported variables or files, as `scripts/installer/src/run.ab` does.
- **Escapes differ between text and commands.** In text `"..."` a bare `$` is
  literal and `\$` keeps its backslash. In commands `$ ... $`, `\$` is a
  literal `$`, `\\033` is an escape for printf, and `\0...` becomes a NUL byte.
  `\{` is a literal brace in both.
- **Arrays word-split** when interpolated into a command. Loop over them.
- Reserved words that bite as names: `lines`, `lock`, `sudo`.
- `trust` ignores failure; `failed` and `succeeded` cannot both follow one
  command; `if { cond { } ... else { } }` is the if-chain.
- Under `amber run`, `args[0]` is the shell, not the script. In a compiled
  script it is `$0`.
- Amber writes the input path into the generated code's error messages, so
  `scripts/build.ab` builds from the repo root with relative paths. Build any
  other way and every output changes with the checkout's location.
- `amber test <dir>` hides a passing test's output. Add a failing
  `assert(false)?` to see it while debugging.
- shellcheck is not a useful gate on the outputs: its findings are in
  compiler-generated code. `bash -n` / `zsh -n` catch syntax errors.
