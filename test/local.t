#!/usr/bin/env bash

source test/init slow

prefix=$SCRATCH/prefix

out=$(PREFIX=$prefix bin/in-1 --local jq 2>&1)
has "$out" 'command wrappers' "--local reports wrapper creation"

if [[ -x $prefix/bin/jq ]]; then
  pass "wrapper $prefix/bin/jq exists and is executable"
else
  fail "wrapper $prefix/bin/jq exists and is executable"
fi

has "$(head -2 "$prefix/bin/jq")" '# in-1 wrapper' \
  "wrapper has the in-1 marker comment"

out=$("$prefix/bin/jq" --version)
has "$out" 'jq-1.' "wrapper runs the real jq"

out=$(PREFIX=$prefix bin/in-1 --local jq 2>&1) &&
  pass "rerunning --local succeeds" ||
  fail "rerunning --local succeeds"

# A pre-existing non-wrapper file must not be overwritten
mkdir -p "$prefix/bin"
echo 'not a wrapper' > "$prefix/bin/jq"
out=$(PREFIX=$prefix bin/in-1 --local jq 2>&1)
has "$out" "Skipping existing non-wrapper file" \
  "existing non-wrapper file is preserved"
is "$(cat "$prefix/bin/jq")" 'not a wrapper' \
  "existing non-wrapper file content untouched"

done-testing
