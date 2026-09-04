# in-1 tool metadata.
#
# Flat make ':=' variables.  Values are literal; in-1 reads them
# directly, so make never expands '*' and friends.
#
#   <tool>-bin   primary command shown and version-wrapped
#                (default: the tool name)
#   <tool>-also  literal note shown after "also: " on the success line
#   <name>-isa   make `in-1 <name>` install this tool (an alias)
#   <name>-bin   the command shown for that alias

babashka-bin := bb

bb-isa := babashka

cargo-isa := rust
cargo-bin := cargo

clj-isa := clojure

clojure-also := clj

fortran-bin := fpm
fortran-also := gfortran

glj-isa := glojure

glojure-bin := glj

let-go-bin := lg

lg-isa := let-go

rust-bin := rustc
rust-also := cargo* and rust* commands

yaml-isa := yamlstar

yamlstar-bin := yaml

ys-isa := yamlscript
