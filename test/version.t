#!/usr/bin/env bash

# The sourced parser uses these globals, and Make expands its own expression.
# shellcheck disable=SC1090,SC1091,SC2016,SC2034,SC2153,SC2154
source test/init

# Load the argument parser without running the command or installing tools.
source <(perl -ne 'print unless /^main "\$@"$/' "$ROOT/bin/in-1")
self_root=$ROOT
makes=$IN1_MAKES_REPO
root=$IN1_ROOT

make-args() (IFS=' '; printf '%s' "${make_args[*]}")

parse-tool-args bb BB-VERSION=1.12.209
is "$(make-args)" 'BB-VERSION=1.12.209' \
  'BB-VERSION remains a Make argument'
is "$(tool-version babashka bb)" 1.12.209 \
  'The generated Makefile maps BB-VERSION to BABASHKA-VERSION'

parse-tool-args babashka BB-VERSION=1.12.209
is "$(tool-version babashka bb)" 1.12.209 \
  'The abbreviation works with the canonical tool name'

parse-tool-args bb BABASHKA-VERSION=1.12.209
is "$(tool-version babashka bb)" 1.12.209 \
  'The canonical version variable stays unchanged'

default=$(perl -ne \
  'print $1 if /^BABASHKA-VERSION \?= (\S+)/' "$makes/babashka.mk")
parse-tool-args bb
is "$(tool-version babashka bb)" "$default" \
  'An unset abbreviation preserves the module default'

parse-tool-args bb BB-VERSION=abbreviated BABASHKA-VERSION=canonical
is "$(tool-version babashka bb)" canonical \
  'The canonical variable takes precedence over its abbreviation'

parse-tool-args bb BABASHKA-VERSION=canonical BB-VERSION=abbreviated
is "$(tool-version babashka bb)" canonical \
  'Canonical precedence does not depend on argument order'

parse-tool-args clj CLJ-VERSION=1.12.0
is "$(tool-version clojure clj)" 1.12.0 \
  'The tools metadata drives other abbreviations'

parse-tool-args bb OTHER-VERSION=unchanged
is "$(make-args)" 'OTHER-VERSION=unchanged' \
  'An unrelated version variable stays unchanged'

done-testing
