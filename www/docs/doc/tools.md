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

See the full, current list with:

```bash
in-1 --list
```

or browse the `*.mk` files in the
[makes repo](https://github.com/makeplus/makes).

## Versions

Every tool has a default version defined in its `.mk` file.
Pin a different one by passing the tool's makes variable as a
`NAME=VALUE` argument:

```bash
source <(curl -sL in-1.cc) go GO-VERSION=1.23.4
```

The variable name is `<TOOL>-VERSION` in upper case (`GO-VERSION`,
`NODE-VERSION`, `RUST-VERSION`, ...).
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
[`share/tools.mk`](https://github.com/in-1-cc/in-1/blob/main/share/tools.mk).
