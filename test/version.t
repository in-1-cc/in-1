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

is "$(alias-pairs lg)" let-go \
  'A direct alias lookup does not leave an output producer'

parse-tool-args bb OTHER-VERSION=unchanged
is "$(make-args)" 'OTHER-VERSION=unchanged' \
  'An unrelated version variable stays unchanged'

parse-tool-args bb@1.12.209 bb@1.13.220
is "${req_tool[*]}" 'babashka babashka' 'Pinned aliases resolve to their tool'
is "$(tool-version babashka bb "${req_version[0]}")" 1.12.209 \
  'First alias request keeps its own version'
is "$(tool-version babashka bb "${req_version[1]}")" 1.13.220 \
  'Second alias request keeps its own version'

parse-tool-args bb@1.12.209 bb BABASHKA-VERSION=1.13.220
is "$(tool-version babashka bb "${req_version[0]}")" 1.12.209 \
  'An inline pin takes precedence over a shared version variable'
is "$(tool-version babashka bb "${req_version[1]}")" 1.13.220 \
  'An inline pin does not affect unpinned requests'

parse-tool-args jolt@0.8.20-alpha.1+build_2
is "${req_version[0]}" 0.8.20-alpha.1+build_2 \
  'Version pins support prereleases and build suffixes'

parse-tool-args babashka@1.12.209
qf=$SCRATCH/pinned.mk
gen-makefile "$SCRATCH/pinned" "$qf" babashka "${req_version[0]}"
printf '\npinned-version:\n\t@echo $(BB-VERSION)\n' >> "$qf"
is "$(make -s -C "$root" -f "$qf" pinned-version)" 1.12.209 \
  'Inline pin also sets the primary command version when its name differs'

for arg in jolt@ @0.8.20 jolt@../1 jolt@/tmp jolt@1@2 'jolt@$(false)'; do
  status=0
  out=$(parse-tool-args "$arg" 2>&1) || status=$?
  is "$status" 1 "Invalid pinned argument $arg is rejected"
done

done-testing
