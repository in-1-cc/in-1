# Design

## The pieces

`https://in-1.cc/` serves a small shell script (view source on this
very site: [in-1.cc/rc](https://in-1.cc/rc)).
It is a polyglot that works when sourced by bash, zsh or fish, and it
does only three things:

1. Clone the [in-1 repo](https://github.com/in-1-cc/in-1) to
   `$TMPDIR/in-1/bootstrap` (default `/tmp/in-1/bootstrap`), at the version the
   script was published with (so the served endpoint and the code
   always agree). Do not inherit the installed shell function's state root.
2. Run `bin/in-1 --env <your-shell> <tools...>` from that clone.
3. Evaluate its output in your current shell.

`bin/in-1` is a plain strict-mode bash program; all the real logic
lives there, versioned, testable and shellcheckable.

## How installs work

in-1 stands on [makes](https://github.com/makeplus/makes), a GNU make
library where every tool has a `<tool>.mk` file that knows how to
download and locally install that tool (and its host language) on
Linux or macOS.  in-1 keeps its own clone of makes at
`$IN1_ROOT/makes`.

For each requested tool, bin/in-1 resolves the version, then writes a
Makefile like:

```make
MAKES-LOCAL-DIR := $PREFIX/share/rust/1.98.0
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
then writes a wrapper into `<prefix>/bin` for every command the tool
provides:

```bash
#!/usr/bin/env bash
# in-1 wrapper
export CARGO_HOME=$PREFIX/share/rust/1.98.0/cargo
export RUSTUP_HOME=$PREFIX/share/rust/1.98.0/rustup
export PATH=$PREFIX/share/rust/1.98.0/cargo/bin:$PATH
exec $PREFIX/share/rust/1.98.0/cargo/bin/rustc "$@"
```

The wrapper prepends to the live `$PATH` (never a frozen snapshot),
so it works from any future shell.  The tool's primary command also
gets a `<cmd>-<version>` wrapper, so pinned versions stay reachable.

`<prefix>/bin` is the single directory in-1 puts on your `PATH`, so
`which <cmd>` is always `<prefix>/bin/<cmd>` and none of the tool's
own environment leaks into your interactive shell.

## Prefix selection

All modes share the same install-and-wrap machinery:

* Normally the prefix follows the installed in-1's public bin directory.
  Without an installed in-1, it defaults to `${TMPDIR:-/tmp}/in-1`.
* `--local` selects a persistent prefix, falling back to `~/.local`.
* `PREFIX=DIR` overrides normal and local defaults.
* `--temp` forces the temporary prefix, ignoring inherited `PREFIX` and
  rejecting an explicit prefix argument or `--local`.

Sourced calls activate `PREFIX/bin`, man pages and completions in the caller.
The installed in-1's internal clone bin directory never replaces its wrapper
on the caller's PATH.

in-1 never overwrites a file in `<prefix>/bin` it did not create.

## State and installations

State defaults to `PREFIX/share/in-1/local`, independently of installed versions:

```text
PREFIX/bin/                         public wrappers
PREFIX/share/<tool>/<version>/       installed tools
IN1_ROOT/makes/                      the Makes clone
IN1_ROOT/log/                        logs and generated Makefiles
IN1_ROOT/cache/                      downloads (IN1_CACHE)
```

Re-running reuses all of it, so only the first request for a tool and
version is slow.  Set `IN1_CACHE` somewhere persistent to keep
downloads across reboots.
`in-1 --reset` removes managed tool versions and wrappers, except in-1 itself,
and clears Makes, logs and downloads.
Unrelated files, old nested installations, and external caches are preserved.

Before an install, in-1 fetches both clones, reports if its own clone
is behind its origin, and automatically updates makes when needed.
The one-liner pins a fresh clone to its published version but leaves a
clone that is already on a branch where it is, so after `--update` you
stay on the latest.

## Metadata

A tool's primary command, a human "also:" note, and command aliases
(so `in-1 cargo` installs rust) live in `share/tools.mk`, a file of
flat make variables in-1 reads directly.

Some tools also need shell-side setup (an alias, a completion hook)
that the wrappers cannot provide.  For those, an optional
`share/<tool>.{sh,bash,zsh,fish}` file is sourced in your shell after
a session install.  in-1 itself is the biggest user: it is an
ordinary makes tool (`in-1.mk` clones the repo), and its extra sources
the `.rc` of the copy just installed, which is where the `in-1` shell
function lives.  `.rc` keeps an `IN1_ROOT` that is already set, so the
installed copy shares the selected state directory.

A few tools want more in their wrappers than makes provides.
An optional `share/<tool>.mk` is included in the generated makefile,
so whatever it exports is captured into the wrappers (clojure keeps
`~/.clojure` and `~/.m2` inside its install this way).
An optional `share/<tool>.wrap` is a bash snippet copied into the
primary command's wrappers before the `exec` (jolt and phel start
their REPL under `rlwrap` when it is available).
