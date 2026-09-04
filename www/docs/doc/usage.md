# Usage

## One-liner (session install)

Install tools into your current shell session:

=== "Bash / Zsh"

    ```bash
    source <(curl -sL in-1.cc) rust node
    ```

=== "Fish"

    ```fish
    curl -sL in-1.cc | source - rust node
    ```

Each bare argument is a tool name (or an [alias](#aliases)).  A
`NAME=VALUE` argument is passed through to makes as a variable, so you
pin a version with the tool's makes variable:

```bash
source <(curl -sL in-1.cc) go GO-VERSION=1.23.4 jq
```

`PREFIX=DIR` is the exception: it sets the
[install prefix](#environment-variables) instead of going to makes.

The one-liner clones in-1 to `$IN1_ROOT` (default `/tmp/in-1`) and
everything else lives under that clone.  Each tool version installs
under `$IN1_ROOT/local/share/<tool>/<version>`, and in-1 writes a
wrapper for every command it provides into `$IN1_ROOT/local/bin` (the
one directory put on your `PATH`).  So `which node` is always
`$IN1_ROOT/local/bin/node`, the wrapper carries the tool's own
environment (`CARGO_HOME`, ...), and your shell itself stays clean.
Your shell also gets `MANPATH` entries and completions.

Multiple versions coexist.  The primary command of a tool also gets a
version-specific wrapper, so `go GO-VERSION=1.23.4` gives you both
`go` and `go-1.23.4` on `PATH`.

Sourcing again is idempotent; `PATH` never collects duplicates.
`IN1_TOOLS` in the environment lists what is active.

## Aliases

Some tools can be requested by a command name they provide:

```bash
source <(curl -sL in-1.cc) cargo   # installs rust
source <(curl -sL in-1.cc) bb      # installs babashka
```

`in-1 --list` shows the available aliases along with the tools.

## Installed mode

Clone the repo once and source its `.rc` from your shell rc file:

```bash
git clone https://github.com/in-1-cc/in-1 ~/.in-1
echo 'source ~/.in-1/.rc' >> ~/.bashrc  # or .zshrc, or config.fish
```

This sets `IN1_ROOT` to that clone, puts the `in-1` command, its man
page and its tab completion in your shell, and wraps the command in a
small shell function so that session installs work directly:

```bash
in-1 rust node            # session install, same as the one-liner
in-1 --list               # all available tools
in-1 -U                   # update in-1 and makes
man in-1
```

## Persistent installs

```bash
in-1 --local rust node
```

Installs the tools under `PREFIX` (default `~/.local`, or
`/usr/local` when run as root), into
`$PREFIX/share/<tool>/<version>`, and writes a wrapper for each
command into `$PREFIX/bin`.
The wrappers bake in the environment the tools need, so they work
from any shell with no setup, and `$PREFIX/bin/<cmd>` is what `which`
resolves.

in-1 never overwrites a file in `$PREFIX/bin` that it did not create.

## Updating

Before an install, in-1 checks whether its own clone or its makes
clone is behind its origin, and says so:

```text
in-1: makes is 3 commit(s) behind; run 'in-1 -U' to update
```

Nothing is updated unless you ask.  `-U` (or `--update`) updates both
clones first and then carries on with whatever else you asked for:

```bash
in-1 -U                              # just update
in-1 -U node                         # update, then install node
source <(curl -sL in-1.cc) -U node   # same, from the one-liner
```

The in-1 clone moves to the latest default branch (or to
`IN1_VERSION` if set).  The one-liner pins a fresh clone to the
version it was published with, but leaves a clone that is already on
a branch alone, so an update sticks.

Set `IN1_OFFLINE=1` to skip the check, for instance on a flaky
connection.

## Resetting

`-R` (or `--reset`) removes everything in-1 put under `IN1_ROOT`:
`makes/`, `local/`, `log/` and `cache/`.  The in-1 clone itself
stays, as does a cache placed elsewhere with `IN1_CACHE`.  Alone it
does just that; with anything else it resets first and then carries
on:

```bash
in-1 -R                              # just reset
in-1 -R node                         # reset, then install node
in-1 -R -U node                      # reset, update, then install
source <(curl -sL in-1.cc) -R node   # same, from the one-liner
```

After a reset `IN1_TOOLS` lists only the tools installed since.

## Command reference

```text
in-1 TOOL... [VAR=VALUE]...  Install tools for this shell session
in-1 --local TOOL...      Install tools under PREFIX for keeps
in-1 --list               List available tools
in-1 --env SHELL TOOL...  Print env setup code for SHELL
in-1 --complete SHELL     Print in-1 command completion for SHELL
in-1 -U, --update [ARGS]  Update in-1 and makes, then continue
in-1 -R, --reset [ARGS]   Remove makes/, log/, local/ and cache/
                          from IN1_ROOT, then continue
in-1 --version            Print the in-1 version
in-1 --help               Show help
```

`in-1 --env` is the plumbing everything else uses; you can call it
yourself:

```bash
eval "$(in-1 --env bash rust)"     # bash / zsh
in-1 --env fish rust | source      # fish
```

## Environment variables

`IN1_ROOT`
:   The in-1 clone.
    Holds the makes clone (`makes/`), the session installs
    (`local/`), logs (`log/`) and the download cache (`cache/`).
    Default: the clone the `in-1` command runs from; the one-liner
    uses `/tmp/in-1` (`$TMPDIR/in-1` when `TMPDIR` is set).
    Sourcing `.rc` exports it.

`IN1_CACHE`
:   Download cache directory.
    Default: `$IN1_ROOT/cache`.
    Point this somewhere persistent to keep downloads across reboots.

`PREFIX`
:   Install prefix.
    Session default: `$IN1_ROOT/local`; `--local` default: `~/.local`,
    or `/usr/local` when root.
    A relative path is anchored to the current directory.
    A `PREFIX=DIR` argument sets it too, so the one-liner can pick a
    prefix: `source <(curl -sL in-1.cc) jq PREFIX=/opt/tools`.

`IN1_VERSION`
:   The in-1 git ref to use.
    The script served by in-1.cc pins a fresh clone to the version it
    was published with; set this to override.

`IN1_REPO`
:   The in-1 repo URL to clone.
    Default: `https://github.com/in-1-cc/in-1`.

`IN1_MAKES_REPO`
:   The makes repo URL to clone.
    Default: `https://github.com/makeplus/makes`.

`IN1_UPDATE`
:   Set to `1` for the same effect as `-U`.

`IN1_OFFLINE`
:   Set to `1` to skip the is-it-behind check before installs.

`IN1_VERBOSE`
:   Set to `1` to stream the full install output instead of the
    quiet per-tool progress lines.

Any makes version variable can also be passed in the environment,
e.g. `NODE-VERSION=22.11.0 in-1 node` does what the `NAME=VALUE`
argument does.

## Requirements

`git`, `curl`, GNU `make` and `bash` on `PATH`.
Everything else is auto-installed.
