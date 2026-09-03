share/
======

Optional per-tool extras, sourced into the user's shell after a
session install of that tool.

For a tool named `<name>`, these files are looked up and sourced in
order, if they exist:

- bash: `<name>.sh` then `<name>.bash`
- zsh: `<name>.sh` then `<name>.zsh`
- fish: `<name>.fish`

They run in the user's interactive shell with `IN1_ROOT` set, so keep
them small, idempotent and side-effect free beyond env, aliases and
completion.
Most tools need no extras file at all; the generic environment diff
in `bin/in-1` covers PATH, MANPATH, tool env vars and installed
completion files.

## install.mk

`install.mk` is a makes fragment included into the generated
per-tool Makefile.
It lets you override `IN1-BIN`, the install directory in-1 reports on
its success line, for tools where the default (the bin directory of
the tool's primary makes target) is wrong.
Overrides are keyed on `IN1-TOOL`; see the comments in the file.
