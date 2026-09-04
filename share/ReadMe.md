share/
======

Optional per-tool extras, sourced into the user's shell after a
session install of that tool.

For a tool named `<name>`, these files are looked up and sourced in
order, if they exist:

- bash: `<name>.sh` then `<name>.bash`
- zsh: `<name>.sh` then `<name>.zsh`
- fish: `<name>.fish`

They run in the user's interactive shell with `IN1_ROOT` (the in-1
clone) set, so keep
them small, idempotent and side-effect free beyond env, aliases and
completion.
Most tools need no extras file at all; each installed command already
gets a wrapper on PATH that carries the tool's environment.

## Wrapper hooks

Two more optional files customize what goes into a tool's wrappers,
for a tool named `<tool>` (the makes module name, not an alias):

- `<tool>.mk` is included by the generated makefile right after
  makes' `<tool>.mk`.
  Anything it exports is captured into the wrappers, so it is the
  place for environment the tool needs at run time that makes does
  not set.
  `IN1-SHARE` is this directory, so one hook can include another.
- `<tool>.wrap` is a bash snippet copied into the primary command's
  wrappers (`<cmd>` and `<cmd>-<version>`) just before the `exec`.
  `$cmd` holds the real command and `"$@"` the arguments; return
  normally to let the exec happen.

Example: `clojure.mk` keeps `~/.clojure` and `~/.m2` inside the
install; `jolt.wrap` starts the REPL under `rlwrap` when it is found.

## tools.mk

`tools.mk` is a file of flat `make :=` variables that in-1 reads
directly (values are literal, so `*` and friends are never
expanded).  Keys:

- `<tool>-bin` - the primary command shown on the success line and
  given a version-specific wrapper (`<cmd>-<version>`).
  Defaults to the tool name.
- `<tool>-also` - literal text shown after `also: ` on the success
  line.
- `<name>-isa` - makes `<name>` an alias: `in-1 <name>` installs the
  named tool.
- `<name>-bin` - the command shown for an alias.

Example: `rust-bin := rustc` makes `in-1 rust` report rustc and write
`rustc` and `rustc-1.98.0`; `cargo-isa := rust` makes `in-1 cargo`
install rust.
