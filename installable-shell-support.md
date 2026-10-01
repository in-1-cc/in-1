# Installable completion and man-page support

Audit date: 2026-09-29

Source:
[installable shell support gist](https://gist.github.com/ingydotnet/39dcc6d3042fcf05e32d6d5e4a30d99c)

This report inventories shell completion and man-page support among the
installables exposed by in-1.
It is intended to guide automatic activation through `source <(in-1 --rc)`.

## Scope

The catalog snapshot contains 159 canonical installables.
Aliases reported by `in-1 --list`, such as `cargo`, `bb`, `yaml`, and `ys`,
are counted with the Makes module they install rather than as separate tools.

The source snapshots audited were:

- in-1 branch `fixes`, including its current working tree
- Makes branch `in-1-fixes` at
  `960186953ba8ebdd3a6ca49719cc8fdaa6a6e3be`

This is a source and packaging audit, not a successful installation of every
tool on every platform.
The positive list is deliberately conservative.
"Not confirmed" means that this pass found no sufficiently strong evidence;
it does not prove that a project has no such support.

Completion means command-line shell completion for Bash, Zsh, or Fish.
REPL completion, editor completion, and language-server completion do not
count.
A man page means an installable roff page usable with `man`, not web
documentation or a `--help` command.

## Summary

- 39 installables have confirmed shell-completion support.
- 29 installables have confirmed man pages.
- 13 installables have both.
- 55 installables have at least one of the two features.
- 104 installables remain unconfirmed.

During the install session, the current in-1 integration activates both
features for `buf`, `gloat`, and `in-1`.
It also activates generated Rust completion for Bash and Fish in that session.
No other command-generated completion is currently wired into in-1.
On a later shell startup, `source <(in-1 --rc)` restores only in-1's own man
page and completion; it does not yet reactivate support for other persistent
installs.

## Both completion and man pages

| Installable | Completion | Upstream form | Install-session result |
| --- | --- | --- | --- |
| `buf` | Bash, Zsh, Fish | Files and man pages in release tarball | Both active |
| `cmake` | Bash | Packaged files | Man path likely active; completion missed |
| `crystal` | Bash, Zsh, Fish | Packaged files | Man path likely active; completion missed |
| `dotnet` | Bash, Zsh | Packaged files | Both missed |
| `gh` | Bash, Zsh, Fish | Generator and packaged man pages | Man path likely active; completion missed |
| `gloat` | Bash, Zsh, Fish | Generator plus repository man pages | Both active |
| `hcloud` | Bash, Zsh, Fish | Generator; package man pages | Both missed by binary-only recipe |
| `helm` | Bash, Zsh, Fish | Generator and generated man pages | Both missed by binary-only recipe |
| `in-1` | Bash, Zsh, Fish | Generator plus repository man page | Both active |
| `pandoc` | Bash | Generator and packaged man page | Both missed by binary-only recipe |
| `rg` | Bash, Zsh, Fish | Files and man page in release tarball | Both discarded by recipe |
| `yamlschema` | Bash, Zsh, Fish | Repository files and man pages | Both discarded by recipe |
| `yq` | Bash, Zsh, Fish | Generator and man page in release tarball | Both missed by binary-only recipe |

`buf` is the clean model for data already laid out conventionally.
Its Makes recipe copies `bin`, `etc`, and `share` into the install prefix.
The current in-1 code then finds `etc/bash_completion.d`,
`share/zsh/site-functions`, `share/fish/vendor_completions.d`, and
`share/man` without a per-tool hook.

## Completion only

The shells shown are the in-1 shells confirmed by this audit.
Several tools support additional shells too.

| Installable | Shells | Form | Install-session result |
| --- | --- | --- | --- |
| `alire` | Bash | Repository file | Missed |
| `asdf` | Bash, Zsh, Fish | Generator | Missed |
| `bbin` | Bash, Zsh | Small static definitions | Missed |
| `bun` | Bash, Zsh, Fish | Packaged files | Discarded by recipe |
| `cairo` | Bash, Zsh, Fish | Scarb completion support | Missed |
| `defang` | Bash, Zsh, Fish | Generator | Missed |
| `ghc` | Bash | Repository file | Missed |
| `golangci-lint` | Bash, Zsh, Fish | Generator | Missed |
| `groovy` | Bash | Repository files | Missed |
| `jolt` | Bash, Zsh, Fish | Generator | Missed |
| `just` | Bash, Zsh, Fish | Generator and release files | Missed |
| `k3d` | Bash, Zsh, Fish | Generator | Missed |
| `lein` | Bash, Zsh | Repository files | Missed |
| `lgx` | Bash, Zsh, Fish | Generator | Missed |
| `luarocks` | Bash, Zsh, Fish | Generator | Missed |
| `nono` | Bash, Zsh, Fish | Generator | Missed |
| `ocaml` | Bash, Zsh | opam repository files | Missed |
| `phel` | Bash, Zsh, Fish | Generator | Missed |
| `pulumi` | Bash, Zsh, Fish | Generator | Missed |
| `rebar3` | Bash, Zsh, Fish | Repository files | Missed |
| `rust` | Bash, Zsh, Fish | rustup and Cargo generators | Bash and Fish active; Zsh missed |
| `scala` | Bash, Zsh, Fish | Scala CLI generator | Missed |
| `task` | Bash, Zsh, Fish | Generator and release files | Missed |
| `uv` | Bash, Zsh, Fish | Generators for `uv` and `uvx` | Missed |
| `vlang` | Bash, Zsh, Fish | Generator | Missed |
| `wasmtime` | Bash, Zsh, Fish | Generator | Missed |

Most entries in this table are suitable for install-time generation.
Generating their scripts once, into standard directories below the versioned
tool prefix, avoids running every tool during each new shell startup.

`bbin` is an exception.
Its documented completion consists of short shell definitions built from
`bbin commands`, so either install-time generation or a tiny activation hook
would be reasonable.

## Man pages only

| Installable | Confirmed pages | Install-session result |
| --- | --- | --- |
| `clojure` | `clojure`, `clj` | Installed and discoverable |
| `erlang` | Erlang/OTP command pages | Likely retained and discoverable |
| `fennel` | `fennel` | Discarded by binary-only recipe |
| `futhark` | Futhark command pages | Likely retained and discoverable |
| `graalvm` | JDK command pages | Likely retained and discoverable |
| `janet` | `jpm` | Likely retained; layout needs runtime check |
| `java` | JDK command pages | Likely retained and discoverable |
| `jq` | `jq` | Not installed by binary-only recipe |
| `lua` | `lua`, `luac` | Installed into a discoverable `man` directory |
| `nim` | Nim command pages | Retained outside a standard man directory |
| `node` | Node and npm pages | Likely retained and discoverable |
| `powershell` | `pwsh` | Retained layout needs runtime check |
| `prolog` | `trealla` | Discarded by binary-only recipe |
| `shellcheck` | `shellcheck` | Discarded by binary-only recipe |
| `swift` | `swift` | Swiftly layout needs runtime check |
| `unison` | `unison` | Discarded by binary-only recipe |

"Likely" is used where the Makes recipe retains the full upstream tree and
the expected man directory is adjacent to a directory added to `PATH`.
Those rows should be confirmed with an actual in-1 installation before being
turned into regression expectations.

## Not confirmed in this pass

No completion or man-page support was confirmed for these 104 canonical
installables:

arturo, autohotkey, babashka, ballerina, basilisp, berkeleydb, bison, bpan,
brotli, cabal, carp, cc-pulse, cfml, chezscheme, clang, clj-kondo, cljfmt,
cljgo, cljr, cobol, coffeescript, compose, csharp, cursor, d, dart,
delphi, docker-compose, elixir, elm, euphoria, factor, flex, forth, fortran,
fpc, freebasic, fsharp, gcc, gdscript, gleam, glojure, gmp, gnat, go,
go-yaml, gobb, grenadine, haxe, hy, j, joker, jsonschema, julia, jus, kotlin,
lean, let-go, libyamlstar, libys, luajit, maven, md2man, mips, moonbit,
moonscript, nbb, objective-c, odin, perl, pharo, php, processing, purescript,
pyret, python, r, racket, raku, reasonml, red, roc, ruby, sbcl, scheme,
scratch, sml, solidity, sqlite, squint, tcl, tinygo, ttyd,
typescript, typos, uiua, vimscript, wasm-opt, wren, yamlfmt, yamlscript,
yamlstar, zig, zprint.

Four of these are library-only in in-1: `berkeleydb`, `gmp`, `libyamlstar`,
and `libys`.
Several others are facade modules that install another toolchain, including
`csharp`, `delphi`, `fortran`, `fsharp`, `objective-c`, and `scheme`.
They need an alias and ownership decision rather than a separate completion
generator.

Traditional compiler and runtime projects in this section may ship man pages
in some source or distribution packages.
They remain unconfirmed because the exact artifact selected by the current
Makes recipe was not verified to retain an installable page.

## Current activation behavior

There are two distinct paths today:

- A session install through the shell function emits environment, completion,
  and `MANPATH` changes for the tools named in that invocation.
- A later `source <(in-1 --rc)` sources only in-1's own `.rc`.
  It restores the shared prefix `bin` directory and in-1's own man page and
  completion, but does not enumerate the other persistent installs.

During a session install, in-1 performs two useful generic searches:

1. For every directory added to `PATH`, it adds an adjacent `share/man` or
   `man` directory to `MANPATH` when present.
2. For each versioned tool prefix, it activates standard Bash, Zsh, and Fish
   completion directories when present.

It also has explicit per-tool completion hooks for Gloat and Rust.
The in-1 tool sources its own `.rc`, which provides in-1 completion.

The generic completion search is narrower than the man-page search.
It inspects the versioned prefix, but it does not inspect completion
directories adjacent to every tool-specific `bin` directory.
That is why full distributions such as CMake, Crystal, and `gh` can retain
useful files without having their completion activated.

## Recommended installation contract

At install time, normalize available support into these locations under each
versioned tool prefix:

```text
share/bash-completion/completions/<command>
share/zsh/site-functions/_<command>
share/fish/vendor_completions.d/<command>.fish
share/man/man<section>/<page>.<section>
```

The existing `source <(in-1 --rc)` path can be extended to activate them with
directory lookups only.
It should not run dozens of installed commands on every shell startup.

The practical priority order is:

1. Preserve files that current Makes recipes discard, especially for
   YAMLSchema, ripgrep, yq, Pandoc, ShellCheck, and Trealla Prolog.
2. Generate completion once after installation for the generator-based tools.
3. Expand generic discovery to completion directories adjacent to every
   captured `PATH` entry.
4. Add regression fixtures for Bash, Zsh, Fish, and `MANPATH` without starting
   the real tools during an ordinary `--rc` call.

## Evidence

Primary project documentation and source were preferred:

- [Buf installation](https://buf.build/docs/cli/installation/) documents the
  release tarball's Bash, Zsh, and Fish completion plus man pages.
- [GitHub CLI completion](https://cli.github.com/manual/gh_completion)
  documents its Bash, Zsh, and Fish generator.
- [Task installation](https://taskfile.dev/docs/installation) documents its
  generated and installed completion forms.
- [uv installation](https://docs.astral.sh/uv/getting-started/installation/)
  documents the `uv` and `uvx` generators.
- [Pulumi completion](https://www.pulumi.com/docs/iac/cli/command-line-completion/),
  [Golangci-lint integration](https://golangci-lint.run/docs/welcome/integrations/),
  [hcloud setup](https://github.com/hetznercloud/cli/blob/main/docs/tutorials/setup-hcloud-cli.md),
  [k3d completion](https://k3d.io/v5.0.1/usage/commands/k3d_completion/),
  and [Just completion](https://just.systems/man/en/shell-completion-scripts.html)
  document their generators.
- [Scarb installation](https://docs.swmansion.com/scarb/download.html)
  documents completion for the command installed by the `cairo` module.
- [Scala CLI installation](https://scala-cli.virtuslab.org/install/)
  documents its Bash, Zsh, and Fish completion generator.
- [Clojure installation](https://clojure.org/guides/install_clojure)
  documents the CLI man-page installation, and the exact installer selected
  by Makes installs `clojure.1` and `clj.1`.
- [YAMLSchema](https://github.com/yaml/yamlschema) documents its sourced
  completion and man-page setup.
- The tagged YAMLSchema v0.1.12 tree contains `share/complete.bash`,
  `share/complete.zsh`, `share/complete.fish`, `man/man1/ysd.1`, and three
  section 5 pages.
- The Gloat source tree contains three completion templates and six section 1
  man pages.
- The ripgrep 15.2.0 Linux release archive contains Bash, Zsh, and Fish
  completion files plus `doc/rg.1`.
- The yq 4.54.1 Linux release archive contains `yq.1`; the binary provides its
  completion generator.

Where upstream installation documentation did not expose the packaging
details, the current
[Homebrew core formulas](https://github.com/Homebrew/homebrew-core/tree/HEAD/Formula)
were used as secondary evidence that a project has a generator, completion
file, or buildable man page.
That evidence was used for the relevant rows above, but not to claim that the
current Makes recipe installs those files.

The current activation conclusions come from `bin/in-1`, `share/gloat.*`,
`share/rust.*`, and the corresponding module recipes under `repos/makes`.
