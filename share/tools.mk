# in-1 tool metadata.
#
# Flat make ':=' variables.  Values are literal; in-1 reads them
# directly, so make never expands '*' and friends.
#
#   <tool>-bin   command names separated by spaces; first is primary
#                (default: the tool name); all are aliases for the tool
#   <tool>-also  literal note shown after "also: " on the success line

alire-bin := alr

babashka-bin := bb

clojure-bin := clj
clojure-also := clj

fortran-bin := gfortran
fortran-also := fpm

glojure-bin := glj

let-go-bin := lg

rust-bin := rustc cargo
rust-also := cargo* rust*

uv-also := uvx

yamlstar-bin := yaml

yamlscript-bin := ys

yamlschema-bin := ysd
