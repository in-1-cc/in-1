in-1
====

Instant dev tools for your current shell


## Synopsis

```bash
$ node --version
Command 'node' not found
$ source <(curl -sL in-1.cc) rust node
$ node --version
v26.8.1
$ cargo --version
cargo 1.98.0
```

From fish:

```fish
curl -sL in-1.cc | source - rust node
```


## Description

in-1 installs tools and languages into a temp location and sets up
PATH, MANPATH, shell completion and tool environment variables
(CARGO_HOME, JAVA_HOME, ...) in your **current shell**, for the
duration of the shell session.

Nothing on your system changes.
Open a new shell and the tools are gone; downloads stay cached so
asking again is instant.

Tools are installed by [makes](https://github.com/makeplus/makes);
any tool with a `<tool>.mk` file there is available.
That is over 100 languages and tools.
Works on Linux and macOS, Intel and ARM, in bash, zsh and fish.

Requirements: `git`, `curl`, GNU `make` and `bash`.


## Installing the in-1 command

in-1 is itself one of the tools, so the one-liner installs it too:

```bash
source <(curl -sL in-1.cc) in-1      # bash / zsh
curl -sL in-1.cc | source - in-1     # fish
```

That gives you the `in-1` command, its man page and tab completion in
the current shell:

```bash
in-1 rust node    # session install into the current shell
in-1 --list       # all available tools
in-1 --local jq   # persistent install under ~/.local
in-1 --update     # update in-1 and makes
man in-1
```

To keep it, install it under `~/.local` like any other tool and add
the `source` line it prints to your shell rc file:

```bash
in-1 --local in-1
```

Or clone the repo anywhere and source its `.rc`:

```bash
git clone https://github.com/in-1-cc/in-1 ~/.in-1
echo 'source ~/.in-1/.rc' >> ~/.bashrc  # or .zshrc, or config.fish
```


## How it works

The script served at in-1.cc clones this repo (pinned to the
published version) to `$IN1_ROOT` (default `/tmp/in-1`), clones the
makes repo under it, generates a Makefile that includes the requested
`<tool>.mk` files, runs it, then diffs the resulting environment
against your shell's and applies the difference.
Installs go under `$IN1_ROOT/local`, so the clone stays clean.

See [doc/design](https://in-1.cc/doc/design/) for the full story and
`man in-1` (or [doc/usage](https://in-1.cc/doc/usage/)) for every
option and environment variable.


## Development

```bash
make test           # shellcheck + fast tests
slow=1 make test    # + end-to-end tests (network, zsh, fish)
make manpage        # regenerate man/man1/in-1.1 from doc/in-1.md
make -C www serve   # local docs site at http://localhost:8000
```

Everything (perl, prove, shellcheck, python, mkdocs, go-md2man)
auto-installs under `.cache/` via
[makes](https://github.com/makeplus/makes).


## Deployment

The site is GitHub Pages serving the `gh-pages` branch of this repo.

1. Tag a release: `git tag v0.1.0` (the served script pins itself to
   `git describe`).
2. `make -C www publish` builds the site, stamps the version into the
   served script, and force-pushes to `gh-pages`.
3. One-time GitHub setup: Settings > Pages > deploy from `gh-pages`
   branch, custom domain `in-1.cc`, Enforce HTTPS.
4. One-time DNS setup (Namecheap): remove URL-forwarding records and
   add:
   - A records for `@`: 185.199.108.153, 185.199.109.153,
     185.199.110.153, 185.199.111.153
   - CNAME for `www`: `in-1-cc.github.io`

The site root (`https://in-1.cc/`) IS the sourceable script; a
meta-refresh comment inside it bounces web browsers to the docs at
`https://in-1.cc/home/`.


## Copyright and License

Copyright 2026 by Ingy döt Net

This is free software, licensed under:

The MIT (X11) License
