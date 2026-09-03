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
