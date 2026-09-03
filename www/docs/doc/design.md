# Design

## The pieces

`https://in-1.cc/` serves a small shell script (view source on this
very site: [in-1.cc/rc](https://in-1.cc/rc)).
It is a polyglot that works when sourced by bash, zsh or fish, and it
does only three things:

1. Clone the [in-1 repo](https://github.com/in-1-cc/in-1) into
   `$IN1_ROOT/in-1`, checked out at the version the script was
   published with (so the served endpoint and the code always agree).
2. Run `bin/in-1 --env <your-shell> <tools...>` from that clone.
3. Evaluate its output in your current shell.

`bin/in-1` is a plain strict-mode bash program; all the real logic
lives there, versioned, testable and shellcheckable.

## How installs work

in-1 stands on [makes](https://github.com/makeplus/makes), a GNU make
library where every tool has a `<tool>.mk` file that knows how to
download and locally install that tool (and its host language) on
Linux or macOS.

For each requested tool, bin/in-1 resolves the version, then writes a
Makefile like:

```make
MAKES-LOCAL-DIR := $IN1_ROOT/share/rust/1.98.0
include $IN1_ROOT/makes/init.mk
include $IN1_ROOT/makes/rust.mk
include $IN1_ROOT/makes/shell.mk
```

so every `(tool, version)` installs into its own tree and versions
never collide.  It runs `make shell CMD=:` to install (progress on
stderr), then `make -s shell CMD='exec env -0'` to capture the
environment make set up for that tool.

## Wrappers

The captured environment is diffed against in-1's own, isolating the
`PATH` dirs and variables (like `CARGO_HOME`) the tool needs.  in-1
then writes a wrapper into `<root>/bin` for every command the tool
provides:

```bash
#!/usr/bin/env bash
# in-1 wrapper
export CARGO_HOME=$IN1_ROOT/share/rust/1.98.0/cargo
export RUSTUP_HOME=$IN1_ROOT/share/rust/1.98.0/rustup
export PATH=$IN1_ROOT/share/rust/1.98.0/cargo/bin:$PATH
exec $IN1_ROOT/share/rust/1.98.0/cargo/bin/rustc "$@"
```

The wrapper prepends to the live `$PATH` (never a frozen snapshot),
so it works from any future shell.  The tool's primary command also
gets a `<cmd>-<version>` wrapper, so pinned versions stay reachable.

`<root>/bin` is the single directory in-1 puts on your `PATH`, so
`which <cmd>` is always `<root>/bin/<cmd>` and none of the tool's own
environment leaks into your interactive shell.

## Session vs --local

Both modes use the exact same install-and-wrap machinery; only the
root differs:

* A **session** install uses `$IN1_ROOT` and emits a tiny bit of
  shell code to put `$IN1_ROOT/bin` on `PATH` (plus `MANPATH` and
  completions).  This is what the sourced one-liner and the `in-1`
  shell function from `.rc` evaluate.
* **`in-1 --local`** uses `$PREFIX` (default `~/.local`), which is
  normally already on `PATH`, so it needs no shell setup at all.

in-1 never overwrites a file in `<root>/bin` it did not create.

## Caching

Everything lives under `$IN1_ROOT` (default `/tmp/in-1`): the makes
clone, the in-1 clone, `bin/` (wrappers), `share/<tool>/<version>`
(installs) and the download cache.
Re-running reuses all of it, so only the first request for a tool and
version is slow.
Set `IN1_CACHE` somewhere persistent to keep downloads across
reboots.

## Metadata

A tool's primary command, a human "also:" note, and command aliases
(so `in-1 cargo` installs rust) live in `share/tools.mk`, a file of
flat make variables in-1 reads directly.

Some tools also need shell-side setup (an alias, a completion hook)
that the wrappers cannot provide.  For those, an optional
`share/<tool>.{sh,bash,zsh,fish}` file is sourced in your shell after
a session install.
