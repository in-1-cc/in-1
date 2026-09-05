---
hide:
- navigation
---

# Install

There are three ways to use in-1, from nothing-to-install to
permanent.
They all use the same machinery; pick the one that fits.

## Try it: nothing to install

Source the script served by `in-1.cc` with the tools you want:

=== "Bash / Zsh"

    ```bash
    source <(curl -sL in-1.cc) rust node
    ```

=== "Fish"

    ```fish
    curl -sL in-1.cc | source - rust node
    ```

That clones in-1 to `/tmp/in-1`, installs the tools under it and puts
them on `PATH` in your **current shell** only.
Open a new shell and they are gone; the downloads stay cached, so
asking again is instant.
Nothing else on your system changes.

Set `IN1_ROOT` first to clone somewhere other than `/tmp/in-1`.

## Install the `in-1` command

in-1 is itself one of the tools, so the same one-liner installs it:

=== "Bash / Zsh"

    ```bash
    source <(curl -sL in-1.cc) in-1
    ```

=== "Fish"

    ```fish
    curl -sL in-1.cc | source - in-1
    ```

Now you have the `in-1` command, its man page and tab completion in
this shell:

```bash
in-1 rust node    # install tools into this shell session
in-1 --list       # see all available tools
in-1 -U           # update in-1 and makes
in-1 --help       # or: man in-1
in-1 <TAB><TAB>   # tab completion
```

It lives under `/tmp/in-1` with everything else and installs tools
there too.
It can be asked for together with other tools:
`source <(curl -sL in-1.cc) in-1 rust node`.

### For keeps

Install it under `~/.local` like any other tool:

```bash
in-1 --local in-1
```

That writes `~/.local/bin/in-1` and prints a `source .../.rc` line;
add that line to your shell rc file (`.bashrc`, `.zshrc` or
`config.fish`) for the shell function, man page and tab completion in
every new shell.

### From a clone

Or clone the repo once and source its `.rc` from your shell rc file:

=== "Bash"

    ```bash
    git clone https://github.com/in-1-cc/in-1 ~/.in-1
    echo 'source ~/.in-1/.rc' >> ~/.bashrc
    ```

=== "Zsh"

    ```zsh
    git clone https://github.com/in-1-cc/in-1 ~/.in-1
    echo 'source ~/.in-1/.rc' >> ~/.zshrc
    ```

=== "Fish"

    ```fish
    git clone https://github.com/in-1-cc/in-1 ~/.in-1
    echo 'source ~/.in-1/.rc' >> ~/.config/fish/config.fish
    ```

`~/.in-1` is just a suggestion; any directory works.
`.rc` sets `IN1_ROOT` to wherever the clone is (unless `IN1_ROOT` is
already set), so session installs then live under that clone instead
of `/tmp/in-1`.

## Keep tools for good

```bash
in-1 --local rust node
```

installs the tools under `~/.local` (or `/usr/local` when root) and
writes a wrapper for each command into `~/.local/bin`, which is
normally already on `PATH`.
The wrappers carry the tools' own environment, so they work from any
shell with no setup.
Set `PREFIX` to install somewhere else.

in-1 never overwrites a file in the `bin` directory that it did not
create.

## Update

```bash
in-1 -U           # update in-1 and makes
in-1 -U node      # update, then install node
```

in-1 tells you when either clone is behind, but never updates on its
own.

## Uninstall

Everything in-1 does lives in a few directories; remove them and it is
gone:

```bash
rm -rf /tmp/in-1          # the one-liner's clone, installs and cache
rm -rf ~/.in-1            # a cloned command (and its installs)
```

and drop the `source` line from your shell rc file.
For `--local` installs, remove `~/.local/share/<tool>` and the
wrappers in `~/.local/bin` that start with `# in-1 wrapper`;
`in-1 --local in-1` is `~/.local/share/in-1` and `~/.local/bin/in-1`.

## Requirements

`git`, `curl`, GNU `make` and `bash` on `PATH`, on Linux or macOS
(Intel or ARM).
Everything else is auto-installed.

See [Usage](../doc/usage.md) for every option and environment
variable.
