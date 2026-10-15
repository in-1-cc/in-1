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

For silent use in a script, pass `-q` or `--quiet`:

```bash
source <(curl -sL in-1.cc) -q rust node
```

Successful notes, progress and status output are suppressed.
Failure diagnostics remain visible.

Each bare argument is a tool name (or an [alias](#aliases)).
Append `@VERSION` to select a specific version:

```bash
source <(curl -sL in-1.cc) go@1.23.4 jq
in-1 bb@1.13.220
in-1 jolt@0.8.20 jolt@0.8.19
```

Each pin applies only to that request, so several versions of the same tool
can be installed together.
Requests run in argument order; the last listed version becomes active.
Other versions remain available through their versioned command wrappers.

A `NAME=VALUE` argument is passed through to makes as a variable.
`PREFIX=DIR` is the exception: it sets the
[install prefix](#environment-variables) instead of going to makes.

The one-liner clones in-1 to `${TMPDIR:-/tmp}/in-1/bootstrap`, independently
of inherited `IN1_ROOT`.
The install prefix follows an installed in-1, or defaults to
`${TMPDIR:-/tmp}/in-1` on a fresh machine.
Each version installs under `$PREFIX/share/<tool>/<version>`, with wrappers
in `$PREFIX/bin`.
So `which node` is `$PREFIX/bin/node`, the wrapper carries the tool's own
environment (`CARGO_HOME`, ...), and your shell itself stays clean.
Your shell also gets `MANPATH` entries and completions.

Multiple versions coexist.  The primary command of a tool also gets a
version-specific wrapper, so `go@1.23.4` gives you both
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
Aliases are shown as `bb (babashka)`; direct tool names are unannotated.
Tab completion shows alias targets when there are multiple matches,
but inserts only the command name.

## Installed mode

in-1 is itself one of the tools, so the one-liner installs it too:

```bash
source <(curl -sL in-1.cc) in-1     # bash / zsh
curl -sL in-1.cc | source - in-1    # fish
```

For keeps, `in-1 --local in-1` installs it under `~/.local`
(`source <(curl -sL in-1.cc) --local in-1` does that and sets up the
current shell too); then let the command point your shell rc file at
its own `.rc`, so the line survives upgrades:

```bash
echo 'source <(in-1 --rc)' >> ~/.bashrc          # or .zshrc
echo 'in-1 --rc | source' >> ~/.config/fish/config.fish
```

Or clone the repo once and source its `.rc` from your shell rc file:

```bash
git clone https://github.com/in-1-cc/in-1 ~/.in-1
echo 'source ~/.in-1/.rc' >> ~/.bashrc  # or .zshrc, or config.fish
```

Each way puts the `in-1` command, its man page and its tab completion
in your shell, and wraps the command in a small shell function so
that session installs work directly.
`.rc` also sets `IN1_ROOT`, unless it is already set: to the clone it
lives in, or for a `--local` installed in-1 to the stable
`~/.local/share/in-1/local`, which survives version changes.

```bash
in-1 rust node            # install alongside in-1
in-1 -T jq                # force a temporary install
in-1 --list               # all available tools
in-1 --update             # update in-1
man in-1
```

## Persistent installs

```bash
in-1 --local rust node
```

Selects an existing persistent prefix, otherwise `~/.local` (or
`/usr/local` when root), with each tool installed into
`$PREFIX/share/<tool>/<version>`, and writes a wrapper for each
command into `$PREFIX/bin`.
The wrappers bake in the environment the tools need, so they work
from any shell with no setup, and `$PREFIX/bin/<cmd>` is what `which`
resolves.

in-1 never overwrites a file in `$PREFIX/bin` that it did not create.

## Temporary installs

`-T` or `--temp` forces `${TMPDIR:-/tmp}/in-1`, ignoring inherited
`PREFIX` and `IN1_ROOT`.
It rejects `PREFIX=DIR` arguments and cannot be combined with `--local`.
It also works with `--show`, `--uninstall`, `--prune`, and `--reset`.
If an old temporary checkout conflicts, move it aside before retrying;
in-1 will not overwrite or automatically migrate it.

## Uninstalling

```bash
in-1 --uninstall rust node
```

removes the installs of the named tools from `PREFIX`:
`$PREFIX/share/<tool>` with every version in it, and the wrappers in
`$PREFIX/bin` that in-1 wrote for it.
Files in `$PREFIX/bin` that in-1 did not create stay.
The shell function and direct command use the same prefix as installation:

```bash
source <(curl -sL in-1.cc) in-1
in-1 rust node
in-1 --uninstall rust node
```

The curl one-liner rejects `--uninstall`; install the `in-1` command
into the session first, as above.
An explicit `PREFIX` overrides normal and local defaults.
Aliases work here too (`in-1 --uninstall bb` removes babashka), and
`in-1 --uninstall in-1` removes the command itself.
`--reset`, below, removes other managed tools while preserving in-1 itself.

Remove specific versions with `@VERSION`:

```bash
in-1 --uninstall jolt@0.8.20
in-1 --uninstall jolt@0.8.20 jolt@0.8.19
```

Other installed versions and their wrappers stay.
If the active version is removed, its current command and shell support are
removed too, without automatically activating another version.
Reinstall a remaining version to select it again.
Bare tool names still remove all versions of those tools.

## Showing installed versions

```bash
in-1 --show
in-1 --show bb jolt
in-1 --show bb@1.13.226 jolt@0.8.20 jolt@0.8.19
in-1 --show '^(babashka|node)'
```

The aligned columns show tool name, version, disk usage, and installation path.
Pass tool names or aliases to select multiple tools, and append `@VERSION`
to select exact installed versions.
Rows matching any selector are shown once, even when selectors overlap.
A single regex pattern can also filter whole rows; installed tool names and
known aliases take precedence over patterns.
Regex patterns cannot be combined with tool selectors.
Tool names are alphabetical; each tool's versions run from most recently
installed to oldest.
Successful-install markers supply the timestamps, with managed wrapper
timestamps used for legacy command installs.
Equal timestamps retain version-name order.
Sizes match `du -sh` run separately on each installation directory, including
libraries and any build caches inside that directory.
On a terminal, the highest installed version is bold.
Other versions of a tool are grey when its selected version can be identified
using the same links and markers as `--prune`.
Filtering matches names, versions, sizes and paths, and does not change which
versions count as newest or selected.
Piped output is plain; `NO_COLOR` or `TERM=dumb` disables styling.

## Pruning versions

```bash
in-1 --prune                 # all installed tools, including in-1
in-1 --prune bb node         # selected tools; aliases work too
in-1 --temp --prune          # temporary installations
in-1 --prune PREFIX=~/.local # an explicit prefix
```

Pruning keeps the currently selected version and removes other managed
versions and their wrappers.
Pinned older versions and prereleases stay selected.
The retained version, shell support, unrelated files, and in-1 state,
logs and download caches are preserved.
Active-version links or current primary-command wrappers identify the
version to keep.
Otherwise, the newest successful-install marker selects it, including for
libraries without commands.
If selection is ambiguous, that tool stays unchanged and an error is reported.
Missing explicitly requested tools also report errors; other tools continue.
An empty prefix or an already-pruned tool succeeds.

Pruning runs independently, without initializing Makes, installing anything,
or checking for updates, and ignores `IN1_UPDATE`.
It rejects make variables and combinations with `--uninstall`, `--reset`,
`--update`, `--list`, or `--show`.
Use the installed command; the curl one-liner rejects `--prune`.
Summaries go to stderr and `--quiet` suppresses successful output.

## Updating

Before an install, in-1 checks whether its own clone is behind its
origin, and says so.
It also checks its makes clone and updates that automatically when it
is behind:

```text
√ makes is now at 1a2b3c4
```

Use `--update` to update in-1 as well as makes before carrying on with
whatever else you asked for:

```bash
in-1 --update                             # just update
in-1 --update node                        # update, then install node
source <(curl -sL in-1.cc) --update node  # same, from the one-liner
```

The in-1 clone moves to the latest default branch (or to
`IN1_VERSION` if set).  The one-liner pins a fresh clone to the
version it was published with, but leaves a clone that is already on
a branch alone, so an update sticks.

For a persistent install, `--update` updates the clone containing the
running command when `IN1_ROOT` is its state directory.
Makes and logs stay under `IN1_ROOT`; tools live in the selected prefix.

Set `IN1_OFFLINE=1` to skip both update checks, including the
automatic makes update, for instance on a flaky connection.

## Resetting

`--reset` removes managed versions and wrappers from the selected prefix,
except in-1 itself, and clears `makes/`, `log/` and `cache/` under `IN1_ROOT`.
Unrelated files, old nested installations, and external caches stay. Alone it
does just that; with anything else it resets first and then carries
on:

```bash
in-1 --reset                              # just reset
in-1 --reset node                         # reset, then install node
in-1 --reset --update node                # reset, update, then install
source <(curl -sL in-1.cc) --reset node   # same, from the one-liner
```

After a reset `IN1_TOOLS` lists only the tools installed since.

## Command reference

```text
in-1 TOOL... [VAR=VALUE]...  Install tools for this shell session
in-1 -L|--local TOOL...      Install tools under PREFIX for keeps
in-1 -T|--temp TOOL...       Use $TMPDIR/in-1, ignoring inherited PREFIX
in-1 --uninstall TOOL...     Remove tools from their install prefix
in-1 --prune [TOOL...]       Remove versions except the current install
in-1 --list [PATTERN]        List available tools, optionally filtered
in-1 --show [TOOL...]        Show installed versions and locations
in-1 --env SHELL TOOL...     Print env setup code for SHELL
in-1 --complete SHELL        Print in-1 command completion for SHELL
in-1 --rc                    Print the shell setup line (source it)
in-1 -q|--quiet ARGS...      Suppress output on success
in-1 --update [ARGS]         Update in-1 and makes, then continue
in-1 --reset [ARGS]          Remove managed tools and state; keep in-1
in-1 --version               Print the in-1 version
in-1 --help                  Show help
```

`in-1 --env` is the plumbing everything else uses; you can call it
yourself:

```bash
eval "$(in-1 --env bash rust)"     # bash / zsh
in-1 --env fish rust | source      # fish
```

## Environment variables

`IN1_ROOT`
:   State directory for Makes, logs and downloads.
    Default: `$PREFIX/share/in-1/local`.
    The one-liner and `--temp` ignore an inherited value.
    A sourced development checkout may use its own directory for state.
    This variable does not choose the installation prefix.
    Sourcing `.rc` exports it.

`IN1_CACHE`
:   Download cache directory.
    Default: `$IN1_ROOT/cache`.
    Point this somewhere persistent to keep downloads across reboots.

`PREFIX`
:   Install prefix.
    Normally the public prefix of the installed in-1, otherwise
    `${TMPDIR:-/tmp}/in-1`.
    `-L` or `--local` falls back to `~/.local` or `/usr/local` when root.
    `-T` or `--temp` ignores this variable and rejects an argument override.
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
:   Set to `1` for the same effect as `--update`.

`IN1_OFFLINE`
:   Set to `1` to skip update checks before installs, including the
    automatic makes update.

`IN1_VERBOSE`
:   Set to `1` to stream the full install output instead of the
    quiet per-tool progress lines.
    `-q` and `--quiet` take precedence when either is used.

## Requirements

`git`, `curl`, GNU `make` and `bash` on `PATH`.
Everything else is auto-installed.
