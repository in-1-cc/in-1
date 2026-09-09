# IN-1 1 "September 2026" "in-1" "User Commands"

# NAME

in-1 - instant dev tools for your current shell

# SYNOPSIS

**source <(curl -sL in-1.cc)** [**-q** | **--quiet**] *TOOL*...
[*VAR*=*VALUE*]...

**in-1** [**-q** | **--quiet**] *TOOL*... [*VAR*=*VALUE*]...

**in-1** **--local** *TOOL*...

**in-1** **--temp** *TOOL*...

**in-1** **--uninstall** *TOOL*... [*PREFIX*=*DIR*]

**in-1** **--show** [*PATTERN*] [*PREFIX*=*DIR*]

**in-1** **--list** [*PATTERN*]

**in-1** **--version** | **--help**

**in-1** **--env** *SHELL* *TOOL*...

**in-1** **--complete** *SHELL*

**in-1** **--rc**

**in-1** **--update** [*OPTIONS*] [*TOOL*...]

**in-1** **--reset** [*OPTIONS*] [*TOOL*...]

# DESCRIPTION

**in-1** installs development tools and languages under a prefix and
puts a single directory, *<prefix>/bin*, on **PATH** for the current
shell session (plus **MANPATH** and completions).
Nothing else on the system changes.

Each tool version installs into *<prefix>/share/<tool>/<version>*,
and in-1 writes a small wrapper for every command it provides into
*<prefix>/bin*.  The wrapper carries the tool's own environment
(CARGO_HOME, ...), so `which <cmd>` is always *<prefix>/bin/<cmd>*
and the shell itself stays clean.
Multiple versions coexist: the primary command is a relative symlink
to its version-specific wrapper, *<cmd>-<version>*.
Installing another version updates the symlink without changing older
version-specific wrappers.

The default prefix matches the public installation of in-1.
For example, *~/.local/bin/in-1* installs tools into *~/.local/bin*.
A fresh bootstrap or source checkout with no installed in-1 defaults to
*$TMPDIR/in-1* (*/tmp/in-1* when *TMPDIR* is unset).
The bootstrap clone lives separately in *$TMPDIR/in-1/bootstrap*.
**--local** selects a persistent prefix; **--temp** forces the temporary one.
Installation, **--show**, **--uninstall**, and **--reset** share this selection.

Before an install, in-1 checks whether its own clone is behind its
origin and prints a notice if so.
It automatically updates its makes clone when that clone is behind.
Use **--update** to update in-1 too, or set *IN1_OFFLINE* to skip both
update checks.
**--reset** removes managed tools in the selected prefix and clears state,
while preserving in-1 itself and unrelated files.

It works in bash, zsh and fish, on Linux and macOS (Intel and ARM),
and needs only **git**(1), **curl**(1), GNU **make**(1) and
**bash**(1) to be installed.

Tools are installed by the makes project
(https://github.com/makeplus/makes); any tool with a *TOOL*.mk file
there is available.  A tool may also be requested by an alias command
name (e.g. **cargo** installs rust, **bb** installs babashka).
Run **in-1 --list** to see tools and aliases.

**in-1** is itself one of the tools: **in-1** as a *TOOL* (the
one-liner with **in-1**, say) installs the in-1 command for the
current shell session, complete with its shell function, man page and
completion, and **in-1 --local in-1** installs it for keeps.
Then **source <(in-1 --rc)** (fish: **in-1 --rc | source**) in a shell
rc file gives every new shell the same.
**source <(curl -sL in-1.cc) --local in-1** does both the install and
the setup of the current shell in one go.

Any *VAR*=*VALUE* argument is passed through to makes as a variable.
Pin a version with the tool's makes variable, for example
**in-1 perl PERL-VERSION=5.42.0**.  A pinned version installs
alongside others and is reachable as both *perl* and its
version-specific wrapper.  *PREFIX*=*DIR* is the exception: it sets
the install prefix, like the *PREFIX* environment variable.

# OPTIONS

**-q**, **--quiet**
  Suppress notes, progress and status output from successful
  operations.
  Failure diagnostics remain visible, and explicit output options such
  as **--list**, **--show**, **--version** and **--help** still print output.
  Quiet takes precedence over *IN1_VERBOSE*.

**--local**
  Select the existing persistent in-1 prefix, otherwise *~/.local*
  (*/usr/local* when root).
  An explicit *PREFIX* overrides this default.
  These installs persist across shell sessions and need no shell
  setup, since the wrappers carry the tools' environment.
  Through the one-liner (**source <(curl -sL in-1.cc) --local** *TOOL*)
  the current shell also forgets any stale command paths, and a
  **--local in-1** sources the installed in-1's *.rc* right away.

**--temp**
  Always select *$TMPDIR/in-1* (default */tmp/in-1*), with command wrappers
  directly in its *bin* directory and state under *share/in-1/local*.
  Ignore inherited *PREFIX* and *IN1_ROOT*.
  Reject a *PREFIX*=*DIR* argument or **--local** in the same invocation.
  For example, **in-1 --temp --show** lists temporary installations.
  An old conflicting temporary checkout is left untouched; move it aside
  before retrying with the new layout.

**--uninstall** *TOOL*...
  Remove the installs of the given tools from *PREFIX*:
  *PREFIX/share/<tool>* with every version in it, and every wrapper
  in *PREFIX/bin* that in-1 wrote for it.
  Files in *PREFIX/bin* that in-1 did not write stay.
  Use the same prefix as installation, whether called directly or through
  the shell function.
  The curl one-liner rejects **--uninstall**; install the **in-1**
  command into the session first.
  Use **--temp** or an explicit *PREFIX* to select another installation.
  Aliases work here too (**in-1 --uninstall bb** removes babashka) and
  **in-1 --uninstall in-1** removes the command itself.
  **--reset** removes other managed tools but preserves in-1 itself.

**--list** [*PATTERN*]
  List all available tool names and command aliases.
  Aliases appear as **bb (babashka)**; direct tool names are unannotated.
  Tab completion displays alias targets when there are multiple matches,
  but inserts only the command name.
  The optional pattern filters displayed lines using case-sensitive
  **grep -E** syntax, including alias labels.
  Omit it to list everything; no matches succeed with no output.
  Invalid patterns fail.
  Use **--** before a pattern starting with a dash.

**--show** [*PATTERN*]
  Show installed tools as tab-separated rows: canonical tool name,
  version, and absolute installation directory, sorted by name and version.
  Only existing version directories referenced by an in-1 wrapper count;
  unrelated directories and unreferenced leftovers are omitted.
  The optional pattern filters whole rows using case-sensitive **grep -E**
  syntax, so names, versions and paths can all be matched.
  Omit it to show everything, or use **--** before a pattern starting with
  a dash.
  No matches produce no output and succeed; an invalid pattern fails.
  Prefix selection follows installation and **--uninstall**.
  *PREFIX*=*DIR* overrides the environment and default, except with **--temp**.
  This operation does not install or update anything, ignores *IN1_UPDATE*,
  and rejects **--update** and **--reset**.

**--env** *SHELL*
  Install the tools, then print environment setup code for *SHELL*
  (**bash**, **zsh** or **fish**) on stdout.
  This is the plumbing used by the sourced one-liner and by the
  **in-1** shell function; you can use it directly:
  **eval "$(in-1 --env bash rust)"**

**--complete** *SHELL*
  Print tab completion code for the **in-1** command itself.

**--rc**
  Print the line that sets up the shell: **source** followed by the
  path of this in-1's own *.rc*.
  Put **source <(in-1 --rc)** (bash, zsh) or **in-1 --rc | source**
  (fish) in your shell rc file to get the **in-1** shell function, man
  page and tab completion in every shell.
  Since it goes through the **in-1** on *PATH*, the line keeps working
  after **in-1 --local in-1** installs a newer version.

**--update**
  Update the in-1 clone and the makes clone under *IN1_ROOT* before
  doing anything else.
  When *IN1_ROOT* is a persistent install's state directory, update
  the clone containing the running command instead of that directory.
  Alone, that is all it does; with tools or other options it then
  continues with them, so **in-1 --update rust** gets the newest in-1 and
  makes and then installs rust.
  The in-1 clone moves to the latest default branch (or to
  *IN1_VERSION* if set) and the one-liner leaves it there from then
  on.

**--reset**
  Remove wrapper-backed tool versions and their wrappers from the selected
  prefix, and clear *makes/*, *log/* and *cache/* under *IN1_ROOT*.
  Preserve in-1's own installation, unrelated files, old nested installs,
  and a cache placed elsewhere with *IN1_CACHE*.
  The whole prefix is never removed.
  Alone, that is all it does; with tools or other options it then
  continues with them, so **in-1 --reset rust** installs rust from
  scratch and **in-1 --reset --update** resets and then updates.

**--version**
  Print the in-1 version.

**--help**
  Print usage help.

# ENVIRONMENT

**IN1_ROOT**
  State directory for Makes, logs and the download cache.
  Default: *PREFIX/share/in-1/local*, independent of tool versions.
  It does not determine where command wrappers are installed.
  The one-liner and **--temp** ignore an inherited value.
  A sourced development checkout may use its own directory for state.
  Sourcing *.rc* exports it.

**IN1_CACHE**
  Download cache directory.
  Default: *$IN1_ROOT/cache*.

**PREFIX**
  Install prefix.
  Default: the public prefix of an installed in-1, otherwise *$TMPDIR/in-1*.
  **--local** falls back to *~/.local* or */usr/local* when root.
  A relative path is anchored to the current directory.
  A *PREFIX*=*DIR* argument takes precedence over the environment.
  A trailing */bin* is stripped with a warning.
  **--temp** ignores the environment and rejects the argument form.

**IN1_VERSION**
  The in-1 git ref to use.

**IN1_REPO**
  The in-1 repo URL to clone.
  Default: *https://github.com/in-1-cc/in-1*.

**IN1_MAKES_REPO**
  The makes repo URL to clone.
  Default: *https://github.com/makeplus/makes*.

**IN1_UPDATE**
  Set to 1 for the same effect as **--update**.

**IN1_OFFLINE**
  Set to 1 to skip the update checks before installs, including the
  automatic makes update.

**IN1_VERBOSE**
  Set to 1 to stream the full install output instead of the quiet
  per-tool progress lines.
  **-q** and **--quiet** take precedence when either is used.

**IN1_TOOLS**
  Set by in-1 in the shell; lists the active tools.

# EXAMPLES

Try Rust and Node temporarily, even with a persistent in-1:

    source <(curl -sL in-1.cc) --temp rust node

Same, from fish:

    curl -sL in-1.cc | source - --temp rust node

Pin a version (both `go` and `go-1.23.4` end up on PATH):

    source <(curl -sL in-1.cc) go GO-VERSION=1.23.4

Install a tool by an alias command name:

    source <(curl -sL in-1.cc) cargo

Get the in-1 command itself in the current shell:

    source <(curl -sL in-1.cc) in-1

Install the in-1 command permanently, either way:

    in-1 --local in-1
    echo 'source <(in-1 --rc)' >> ~/.bashrc

    git clone https://github.com/in-1-cc/in-1 ~/.in-1
    echo 'source ~/.in-1/.rc' >> ~/.bashrc

Keep jq around for good:

    in-1 --local jq

And remove it again:

    in-1 --uninstall jq

Update in-1 and makes, then install the newest node:

    in-1 --update node

Remove other managed tools and start over with node, keeping in-1:

    in-1 --reset node

# SEE ALSO

**make**(1)

https://in-1.cc/ and https://github.com/in-1-cc/in-1

https://github.com/makeplus/makes

# AUTHOR

Ingy dot Net <ingy@ingy.net>
