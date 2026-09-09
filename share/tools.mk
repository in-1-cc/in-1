# in-1 tool metadata.
#
# Flat make ':=' variables.  Values are literal; in-1 reads them
# directly, so make never expands '*' and friends.
#
#   <tool>-bin   command names separated by spaces; first is primary
#                (default: the tool name); all are aliases for the tool
#   <tool>-also  literal note shown after "also: " on the success line
#   <tool>-lib   Makes variable naming the required library artifact

alire-bin := alr

babashka-bin := bb

ballerina-bin := bal

berkeleydb-lib := BERKELEYDB-LIB

cairo-bin := scarb

cfml-bin := box

chezscheme-bin := scheme petite scheme-script

clojure-bin := clj
clojure-also := clj

cobol-bin := cobc

coffeescript-bin := coffee

compose-bin := docker-compose

d-bin := ldc2

delphi-bin := fpc

erlang-bin := erl

euphoria-bin := eui

fortran-bin := gfortran
fortran-also := fpm

freebasic-bin := fbc

fsharp-bin := dotnet

gdscript-bin := godot

glojure-bin := glj

gmp-lib := GMP-LIB

graalvm-bin := native-image

j-bin := jconsole

let-go-bin := lg

libyamlstar-lib := LIBYAMLSTAR

libys-lib := LIBYS

maven-bin := mvn

md2man-bin := go-md2man

moonbit-bin := moon

moonscript-bin := moon moonc

objective-c-bin := clang

pharo-bin := pharo-launcher

powershell-bin := pwsh

processing-bin := Processing

prolog-bin := tpl

purescript-bin := purs

r-bin := R

reasonml-bin := refmt

rust-bin := rustc cargo
rust-also := cargo* rust*

scala-bin := scala-cli

solidity-bin := solc

sqlite-bin := sqlite3

tcl-bin := tclsh

typescript-bin := tsc

unison-bin := ucm

uv-also := uvx

vimscript-bin := nvim

vlang-bin := v

wren-bin := wren_cli

yamlstar-bin := yaml

yamlscript-bin := ys

yamlschema-bin := ysd
