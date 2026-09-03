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
Pin a different one per install:

```bash
source <(curl -sL in-1.cc) go=1.23.4
```

## Adding a tool

Add a `<tool>.mk` to the
[makes repo](https://github.com/makeplus/makes); in-1 picks it up
automatically.
