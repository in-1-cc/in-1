# IN-1 1 "September 2026" "in-1" "User Commands"

# NAME

in-1 - instant dev tools for your current shell

# SYNOPSIS

**source <(curl -sL in-1.cc)** *TOOL*... [*VAR*=*VALUE*]...

**in-1** *TOOL*... [*VAR*=*VALUE*]...

**in-1** **--local** *TOOL*...

**in-1** **--list** | **--version** | **--help**

**in-1** **--env** *SHELL* *TOOL*...

**in-1** **--complete** *SHELL*

**in-1** **-U** | **--update** [*OPTIONS*] [*TOOL*...]

# DESCRIPTION

**in-1** installs development tools and languages under a prefix and
puts a single directory, *<prefix>/bin*, on **PATH** for the current
shell session (plus **MANPATH** and completions).
Nothing else on the system changes.

Each tool version installs into *<prefix>/share/<tool>/<version>*,
and in-1 writes a small wrapper for every command it provides into
*<prefix>/bin*.  The wrapper carries the tool's own environment
(CARGO_HOME, ...), so `which <cmd>` is always *<prefix>/bin/<cmd>*
and the shell itself stays clean.  Multiple versions coexist: the
primary command of a tool also gets a version-specific wrapper,
*<cmd>-<version>*.

For a session the prefix is *$IN1_ROOT/local*, where *IN1_ROOT* is
the in-1 clone itself (*/tmp/in-1* for the one-liner); for **--local**
it is *PREFIX* (default *~/.local*).

Before an install, in-1 checks whether its own clone or its makes
clone is behind its origin and prints one line per repo if so.
Nothing is updated unless you ask with **-U**; set *IN1_OFFLINE* to
skip the check.

It works in bash, zsh and fish, on Linux and macOS (Intel and ARM),
and needs only **git**(1), **curl**(1), GNU **make**(1) and
**bash**(1) to be installed.

Tools are installed by the makes project
(https://github.com/makeplus/makes); any tool with a *TOOL*.mk file
there is available.  A tool may also be requested by an alias command
name (e.g. **cargo** installs rust, **bb** installs babashka).
Run **in-1 --list** to see tools and aliases.

Any *VAR*=*VALUE* argument is passed through to makes as a variable.
Pin a version with the tool's makes variable, for example
**in-1 perl PERL-VERSION=5.42.0**.  A pinned version installs
alongside others and is reachable as both *perl* and its
version-specific wrapper.  *PREFIX*=*DIR* is the exception: it sets
the install prefix, like the *PREFIX* environment variable.

# OPTIONS

**--local**
  Install the tools under *PREFIX* (default *~/.local*, or
  */usr/local* when run as root) and write a wrapper for each tool
  command into *PREFIX/bin*.
  These installs persist across shell sessions and need no shell
  setup, since the wrappers carry the tools' environment.

**--list**
  List all available tool names and command aliases.

**--env** *SHELL*
  Install the tools, then print environment setup code for *SHELL*
  (**bash**, **zsh** or **fish**) on stdout.
  This is the plumbing used by the sourced one-liner and by the
  **in-1** shell function; you can use it directly:
  **eval "$(in-1 --env bash rust)"**

**--complete** *SHELL*
  Print tab completion code for the **in-1** command itself.

**-U**, **--update**
  Update the in-1 clone (*IN1_ROOT*) and its makes clone before
  doing anything else.
  Alone, that is all it does; with tools or other options it then
  continues with them, so **in-1 -U rust** gets the newest in-1 and
  makes and then installs rust.
  The in-1 clone moves to the latest default branch (or to
  *IN1_VERSION* if set) and the one-liner leaves it there from then
  on.

**--version**
  Print the in-1 version.

**--help**
  Print usage help.

# ENVIRONMENT

**IN1_ROOT**
  The in-1 clone.
  It holds the makes clone (*makes/*), the session installs
  (*local/*), logs (*log/*) and the download cache (*cache/*).
  Default: the clone the **in-1** command runs from; the one-liner
  uses */tmp/in-1* (*$TMPDIR/in-1* when *TMPDIR* is set).
  Sourcing *.rc* exports it.

**IN1_CACHE**
  Download cache directory.
  Default: *$IN1_ROOT/cache*.

**PREFIX**
  Install prefix.
  Session default: *$IN1_ROOT/local*; **--local** default:
  *~/.local*, or */usr/local* when root.  A relative path is anchored
  to the current directory.  A *PREFIX*=*DIR* argument sets it too.

**IN1_VERSION**
  The in-1 git ref to use.

**IN1_REPO**
  The in-1 repo URL to clone.
  Default: *https://github.com/in-1-cc/in-1*.

**IN1_MAKES_REPO**
  The makes repo URL to clone.
  Default: *https://github.com/makeplus/makes*.

**IN1_UPDATE**
  Set to 1 for the same effect as **-U**.

**IN1_OFFLINE**
  Set to 1 to skip the is-it-behind check before installs.

**IN1_VERBOSE**
  Set to 1 to stream the full install output instead of the quiet
  per-tool progress lines.

**IN1_TOOLS**
  Set by in-1 in the shell; lists the active tools.

# EXAMPLES

Try Rust and Node in the current shell:

    source <(curl -sL in-1.cc) rust node

Same, from fish:

    curl -sL in-1.cc | source - rust node

Pin a version (both `go` and `go-1.23.4` end up on PATH):

    source <(curl -sL in-1.cc) go GO-VERSION=1.23.4

Install a tool by an alias command name:

    source <(curl -sL in-1.cc) cargo

Install the in-1 command permanently:

    git clone https://github.com/in-1-cc/in-1 ~/.in-1
    echo 'source ~/.in-1/.rc' >> ~/.bashrc

Keep jq around for good:

    in-1 --local jq

Update in-1 and makes, then install the newest node:

    in-1 -U node

# SEE ALSO

**make**(1)

https://in-1.cc/ and https://github.com/in-1-cc/in-1

https://github.com/makeplus/makes

# AUTHOR

Ingy dot Net <ingy@ingy.net>
