# Tools

in-1 installs anything that has a `<tool>.mk` file in the
[makes](https://github.com/makeplus/makes) repo; over 100 languages
and tools including:

* Languages: `rust`, `go`, `node`, `python`, `ruby`, `perl`, `java`,
  `zig`, `crystal`, `elixir`, `erlang`, `haskell` (`ghc`), `julia`,
  `nim`, `ocaml`, `raku`, `swift`, and many more
* Clojure family: `clojure`, `babashka`, `janet`, `joker`, `lein`
* Tools: `jq`, `yq`, `gh`, `cmake`, `shellcheck`, `pandoc`,
  `wasmtime`, `docker-compose`, ...

Browse the sortable [installables list](../installables/index.md) or see the
current list in your terminal with:

```bash
in-1 --list
```

You can also browse the `*.mk` files in the
[makes repo](https://github.com/makeplus/makes).

## Versions

Every tool has a default version defined in its `.mk` file.
Pin a different one with `@VERSION`:

```bash
source <(curl -sL in-1.cc) go@1.23.4
```

Versions coexist: each installs under
`<prefix>/share/<tool>/<version>`, and the pinned example above puts
both `go` and `go-1.23.4` on your `PATH`.

## Aliases

A tool can also be requested by a command name it provides, for
example `cargo` (installs rust) or `bb` (installs babashka).
`in-1 --list` shows the aliases along with the tools.

## Adding a tool

Add a `<tool>.mk` to the
[makes repo](https://github.com/makeplus/makes); in-1 picks it up
automatically.
Command aliases and a tool's primary command live in
[`config.yaml`](https://github.com/in-1-cc/in-1/blob/main/config.yaml), which
generates `share/tools.mk`.

## GitHub release installs

A GitHub `owner/repo` selector needs no catalog entry or dedicated Makes module:

```bash
source <(curl -sL in-1.cc) junegunn/fzf
in-1 junegunn/fzf@v0.75.0
in-1 --asset fzf-0.75.0-linux_amd64.tar.gz junegunn/fzf@v0.75.0
```

Repository selectors always use GitHub release discovery, even for projects
that also have catalog entries.
Unpinned requests use GitHub's latest stable release.
An exact `@TAG` can select a prerelease.
Tags must start with a letter or digit and contain only letters, digits,
periods, plus signs, underscores, or hyphens.

The installer supports public releases for Linux and macOS on x86-64 and ARM64.
It selects an asset matching the host platform, preferring musl builds on Linux
when available and avoiding specialized CPU builds.
If multiple candidates remain, it prompts through the controlling terminal.
Without a terminal it fails and lists candidates; use `--asset NAME` to select
an exact release filename.
That option requires exactly one repository selector, but catalog tools can
still appear in the same invocation.

Supported payloads are tar archives, ZIP archives, standalone native binaries,
and gzip/xz-compressed binaries.
A standalone binary is exposed under the repository basename.
The installer preserves bundled data and discovers native command executables.
It rejects unsafe archive paths, escaping links, duplicate command basenames,
and assets without compatible commands.
GitHub's SHA-256 asset digest is verified when provided.
Private repositories, operating-system package installers, universal macOS
binaries, script-only releases, and automatic man-page or completion discovery
are not supported in this first version.

All discovered commands receive wrappers.
The most recently installed provider becomes active when managed commands
share a name; unmanaged files are preserved and cause an installation error.
Repository versions live under `PREFIX/share/github+OWNER+REPO/TAG`.
Their versioned wrappers include the repository identity, for example
`fzf+github+junegunn+fzf+v0.75.0`.
Reinstalling the same release reselects it without replacing its payload.
If a release asset changes, uninstall that version before replacing it.

```bash
in-1 --show junegunn/fzf
in-1 --prune junegunn/fzf
in-1 --uninstall junegunn/fzf@v0.75.0
```

These lifecycle operations work from local installed state without GitHub access.
`--list` continues to show the curated tool catalog.
`IN1_OFFLINE` skips update checks; it does not disable release API requests.
