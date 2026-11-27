# (#| TMPL_VAR name |#)
### _(#| TMPL_VAR author |#)_
(#| TMPL_IF description |#)
(#| TMPL_VAR description |#)
(#| /TMPL_IF |#)
## Development

mise installs SBCL (from conda-forge) and [ICL](https://github.com/atgreen/icl);
the libraries come from Quicklisp (`~/quicklisp`).

| Task | |
|---|---|
| `mise run build` | The release executable, `bin/(#| TMPL_VAR name |#)` |
| `mise run run -- ARGS` | Run `main` from source, compiled for debugging, into the debugger on an error |
| `mise run test` | The FiveAM tests in `tests/` |
| `mise run repl` | ICL with the project loaded (`(in-package #:(#| TMPL_VAR name |#))` to work in it) |
| `mise run clean` | Delete `bin/` and the project's compiled files |

## License

(#| TMPL_VAR license |#)
