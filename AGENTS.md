# rcfiles

Dotfiles in stow packages under `dotfiles/`, installed by mise tasks.

## The tasks are Amber, run from source

Every task is `scripts/<name>.ab` ([Amber](https://amber-lang.com), pinned in
`mise.toml`), and mise runs it with the amber it installs; nothing is compiled
ahead of time or committed as shell. Shared code is in `scripts/lib/*.ab`
(not executable, so mise doesn't list it as a task), tests in
`scripts/lib/tests/`. The only bash is the root `install.sh`, which installs
mise and runs `mise install` before anything needs amber.

Every task starts with

    #!/usr/bin/env -S sh -c 'exec amber run --target bash-3.2 "$0" -- "$@"'

The `--` keeps amber from parsing the task's own flags (`deps -n`), and the
target keeps the tasks working on a fresh Mac, whose bash is 3.2. Task
metadata is `//MISE ...` and `//USAGE ...` comments right after the shebang
(amber rejects `#` lines); read arguments with `env_var_get("usage_<name>")`
or `usage_words` from `scripts/lib/run.ab` for `var=#true` ones.

## Always lint and test after a change

    mise run lint     # amber check on every .ab, with warnings
    mise run test     # amber test scripts/lib/tests

Keep both clean. `mise run deps -n <groups>` prints what `deps` would install
without doing it; `mise run check` is stow's dry run. Never run `install.sh`
or `mise run install` for real from an agent session.

## Amber 0.6.0-alpha gotchas

Each of these was hit writing this repo's scripts.

- **Order:** `main` goes last; it is compiled where it stands and can't call
  a function defined below it. Above it, order the functions top-down: what
  `main` calls first, their helpers after. Modules in `scripts/lib/` are the
  other way round: a function there can't call one defined below it once
  imported, so callees come before callers.
- **Tests:** write `assert(...)?` and `assert_eq(...)?`, always with `?`.
  Without it a failed assert is forgotten as soon as a later statement runs.
- **`len()` as an argument miscompiles.** `f(len(x))` breaks; bind it first
  (`const n = len(x)`) or compare inside the call (`if len(x) > 0`).
- **No `continue` in `for i, x in ...`:** the index increment sits at the end
  of the body, so the loop never gets past `i == 0`. Nest an `if` instead.
- **Module state is not shared.** A module imported from files at different
  depths is compiled once per import path, each copy with its own variables.
  Keep shared state in exported variables, as `scripts/lib/run.ab` does for
  the dry-run flag.
- **Escapes differ between text and commands.** In text `"..."` a bare `$` is
  literal, `\{` is `{`, `\"` a quote, `\t` a tab; `\$` keeps its backslash.
  In commands `$ ... $`, `\$` is a shell `$`, `\{` a brace, `\\` one backslash.
- **`split` drops trailing empty fields** (`"a|b||"` gives 3); use `field`
  from `scripts/lib/packages.ab` to read fields that may be missing.
- **`join` uses only the first character of its separator**: `"\n\n"` joins
  with one newline. Put `""` elements between the items instead.
- **Arrays word-split** when interpolated into a command, and a `Text` is one
  word. To pass several arguments, `join` them and go through `run()` (eval).
- Reserved words that bite as names: `lines`, `lock`, `sudo`, `failed`.
- `if { cond { } cond { } else { } }` is the if-chain; `status()` needs the
  parentheses; `echo_error(msg, code)` exits when `code` is not 0.
- Under `amber run`, `args[0]` is `bash`, not the script. Tasks get the repo
  root from `$MISE_CONFIG_ROOT` (`repo_root()` in `scripts/lib/run.ab`).
- A `$ ... $` statement runs in the task's own shell, so `source`, `export`
  and `eval "$(brew shellenv)"` stick for the statements after it.
