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

Each tool version installs under
`$IN1_ROOT/share/<tool>/<version>`, and in-1 writes a wrapper for
every command it provides into `$IN1_ROOT/bin` (the one directory put
on your `PATH`).  So `which node` is always `$IN1_ROOT/bin/node`, the
wrapper carries the tool's own environment (`CARGO_HOME`, ...), and
your shell itself stays clean.  Your shell also gets `MANPATH`
entries and completions.

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

This puts the `in-1` command, its man page and its tab completion in
your shell, and wraps the command in a small shell function so that
session installs work directly:

```bash
in-1 rust node            # session install, same as the one-liner
in-1 --list               # all available tools
in-1 --upgrade            # update the in-1 clone
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

## Command reference

```text
in-1 TOOL[=VERSION]...    Install tools for this shell session
in-1 --local TOOL...      Install tools under PREFIX for keeps
in-1 --list               List available tools
in-1 --env SHELL TOOL...  Print env setup code for SHELL
in-1 --complete SHELL     Print in-1 command completion for SHELL
in-1 --upgrade            Update the in-1 repo clone
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
:   Session root.
    Default: `$TMPDIR/in-1`, falling back to `/tmp/in-1`.
    Holds the makes clone, the in-1 clone, `bin/` (the wrappers) and
    `share/<tool>/<version>` (the installs).

`IN1_CACHE`
:   Download cache directory.
    Default: `$IN1_ROOT/.cache`.
    Point this somewhere persistent to keep downloads across reboots.

`PREFIX`
:   Install root override.
    `--local` default: `~/.local`, or `/usr/local` when root.
    A relative path is anchored to the current directory.

`IN1_VERSION`
:   The in-1 git ref to use.
    The script served by in-1.cc pins itself to the version it was
    published with; set this to override.

`IN1_REPO`
:   The in-1 repo URL to clone.
    Default: `https://github.com/in-1-cc/in-1`.

`IN1_MAKES_REPO`
:   The makes repo URL to clone.
    Default: `https://github.com/makeplus/makes`.

`IN1_UPDATE`
:   Set to `1` to `git pull` the makes clone before installing.

`IN1_VERBOSE`
:   Set to `1` to stream the full install output instead of the
    quiet per-tool progress lines.

Any makes version variable can also be passed in the environment,
e.g. `NODE-VERSION` is what `node=22.11.0` sets for you.

## Requirements

`git`, `curl`, GNU `make` and `bash` on `PATH`.
Everything else is auto-installed.
