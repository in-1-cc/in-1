# in-1

**Instant dev tools for your current shell.**

Want Rust and Node for a bit, without installing anything on your
system?
Run this in your shell:

=== "Bash / Zsh"

    ```bash
    source <(curl -sL in-1.cc) rust node
    ```

=== "Fish"

    ```fish
    curl -sL in-1.cc | source - rust node
    ```

That installs the tools under a temp directory and sets up `PATH`,
`MANPATH`, shell completion and any tool environment variables in your
**current shell**, for the duration of the shell session.

Nothing on your system changes.
Open a new shell and the tools are gone; the downloads stay cached, so
asking for them again is instant.

## What you get

* Over 100 [tools and languages](../doc/tools.md) from the
  [makes](https://github.com/makeplus/makes) project
* Works on Linux and macOS, Intel and ARM
* Works in Bash, Zsh and Fish
* No root, no system packages, no dotfile edits
* Version pinning: `source <(curl -sL in-1.cc) node NODE-VERSION=22.11.0`

## Keep it around

If you like it, install the `in-1` command properly:

```bash
git clone https://github.com/in-1-cc/in-1 ~/.in-1
echo 'source ~/.in-1/.rc' >> ~/.bashrc  # or .zshrc, or config.fish
```

Then you have:

```bash
in-1 rust node    # install tools into this shell session
in-1 --list       # see all available tools
in-1 --help       # or: man in-1
in-1 <TAB><TAB>   # tab completion
```

Want a tool to stick around for good?

```bash
in-1 --local rust node
```

installs it under `~/.local` (or `/usr/local` when root).

## Learn more

* [Usage](../doc/usage.md) covers every option and environment
  variable
* [Design](../doc/design.md) explains how it works under the hood
* The [in-1 source](https://github.com/in-1-cc/in-1) is a few hundred
  lines of shell on top of [makes](https://github.com/makeplus/makes)
