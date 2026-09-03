# IN-1 1 "September 2026" "in-1" "User Commands"

# NAME

in-1 - instant dev tools for your current shell

# SYNOPSIS

**source <(curl -sL in-1.cc)** *TOOL*[**=***VERSION*]...

**in-1** *TOOL*[**=***VERSION*]...

**in-1** **--local** *TOOL*...

**in-1** **--list** | **--upgrade** | **--version** | **--help**

**in-1** **--env** *SHELL* *TOOL*...

**in-1** **--complete** *SHELL*

# DESCRIPTION

**in-1** installs development tools and languages under a temp root
and puts a single directory, *<root>/bin*, on **PATH** for the
current shell session (plus **MANPATH** and completions).
Nothing else on the system changes.

Each tool version installs into *<root>/share/<tool>/<version>*, and
in-1 writes a small wrapper for every command it provides into
*<root>/bin*.  The wrapper carries the tool's own environment
(CARGO_HOME, ...), so `which <cmd>` is always *<root>/bin/<cmd>* and
the shell itself stays clean.  Multiple versions coexist: the primary
command of a tool also gets a version-specific wrapper,
*<cmd>-<version>*.

For a session the root is *IN1_ROOT*; for **--local** it is *PREFIX*.

It works in bash, zsh and fish, on Linux and macOS (Intel and ARM),
and needs only **git**(1), **curl**(1), GNU **make**(1) and
**bash**(1) to be installed.

Tools are installed by the makes project
(https://github.com/makeplus/makes); any tool with a *TOOL*.mk file
there is available.  A tool may also be requested by an alias command
name (e.g. **cargo** installs rust, **bb** installs babashka).
Run **in-1 --list** to see tools and aliases.

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

**--upgrade**
  Update the in-1 repo clone to the latest version (or to
  *IN1_VERSION* if set).

**--version**
  Print the in-1 version.

**--help**
  Print usage help.

# ENVIRONMENT

**IN1_ROOT**
  Session install root.
  Default: *$TMPDIR/in-1*, falling back to */tmp/in-1*.

**IN1_CACHE**
  Download cache directory.
  Default: *$IN1_ROOT/.cache*.

**PREFIX**
  Install root override.
  Session default: *IN1_ROOT*; **--local** default: *~/.local*, or
  */usr/local* when root.  A relative path is anchored to the current
  directory.

**IN1_VERSION**
  The in-1 git ref to use.

**IN1_REPO**
  The in-1 repo URL to clone.
  Default: *https://github.com/in-1-cc/in-1*.

**IN1_MAKES_REPO**
  The makes repo URL to clone.
  Default: *https://github.com/makeplus/makes*.

**IN1_UPDATE**
  Set to 1 to update the makes clone before installing.

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

    source <(curl -sL in-1.cc) go=1.23.4

Install a tool by an alias command name:

    source <(curl -sL in-1.cc) cargo

Install the in-1 command permanently:

    git clone https://github.com/in-1-cc/in-1 ~/.in-1
    echo 'source ~/.in-1/.rc' >> ~/.bashrc

Keep jq around for good:

    in-1 --local jq

# SEE ALSO

**make**(1)

https://in-1.cc/ and https://github.com/in-1-cc/in-1

https://github.com/makeplus/makes

# AUTHOR

Ingy dot Net <ingy@ingy.net>
