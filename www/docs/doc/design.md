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

For `in-1 rust node`, bin/in-1 writes a Makefile like:

```make
MAKES-LOCAL-DIR := $IN1_ROOT/local
include $IN1_ROOT/makes/init.mk
include $IN1_ROOT/makes/rust.mk
include $IN1_ROOT/makes/node.mk
include $IN1_ROOT/makes/shell.mk
```

and runs it twice:

1. `make shell CMD=:` installs everything, with progress on stderr.
2. `make -s shell CMD='exec env -0'` dumps the environment that make
   sets up for the tools.

## The env diff

The captured environment is diffed against your shell's environment.
Variables that make added or changed become `export` statements
(bash/zsh) or `set -gx` statements (fish) on stdout, with some rules:

* Make's own noise (`MAKEFLAGS`, ...) and vars that must not leak
  (`TMPDIR`, `LANG`) are dropped
* `PATH`-like variables are merged and deduped, never overwritten,
  so re-sourcing never grows them
* `MANPATH` additions are derived from the man dirs next to each new
  bin dir
* Completion files installed by the tools get sourced, best-effort

Because the output of `--env` is just text evaluated by your shell,
the same mechanism serves bash, zsh and fish, the sourced one-liner,
the `in-1` shell function from `.rc`, and your own
`eval "$(in-1 --env ...)"`.

## Wrappers for --local

A session install changes your current shell, which a normal command
cannot do.
`in-1 --local` instead writes one wrapper script per tool command
into `$PREFIX/bin`; each wrapper exports the tool's environment and
execs the real binary.
That is what makes the install survive into any future shell without
touching your dotfiles.

## Caching

Everything lives under `$IN1_ROOT` (default `/tmp/in-1`):
the makes clone, the in-1 clone, the installed tools and the download
cache.
Re-sourcing reuses all of it, so only the first request for a tool is
slow.
Set `IN1_CACHE` somewhere persistent if you want downloads to survive
reboots.

## Extras

Some tools need setup that cannot be derived from the environment
diff.
For those, an optional `share/<tool>.{sh,bash,zsh,fish}` file in the
in-1 repo is sourced in your shell after the env is applied.
