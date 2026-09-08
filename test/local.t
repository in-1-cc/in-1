#!/usr/bin/env bash

source test/init slow

prefix=$SCRATCH/prefix

run() (
  "$@" 2>&1 && echo "status=$?" || echo "status=$?"
)

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
out=$(PREFIX=$prefix bin/in-1 -q --local jq 2>&1)
is "$out" '' "--quiet --local suppresses successful output"

# Through --env (the one-liner) the caller's shell forgets stale
# command paths; fish has none to forget
out=$(PREFIX=$prefix bin/in-1 --env bash --local jq 2>/dev/null)
is "$out" 'hash -r 2>/dev/null || true' "--env bash --local: emits hash -r"
out=$(PREFIX=$prefix bin/in-1 --env fish --local jq 2>/dev/null)
is "$out" '' "--env fish --local: emits nothing"
out=$(PREFIX=$prefix bin/in-1 --env csh --local jq 2>&1 || true)
has "$out" "Unsupported shell 'csh'" "--env csh --local: rejects the shell"

# --uninstall removes the wrappers (jq and jq-<version>) and share/jq
version=$(ls "$prefix/share/jq")
out=$(run bin/in-1 --uninstall jq PREFIX="$prefix")
has "$out" 'Uninstalled jq' "--uninstall jq: reports the uninstall"
has "$out" 'removed 2 command wrappers' \
  "--uninstall jq: removed both wrappers"
has "$out" 'status=0' "--uninstall jq: returns 0"
for path in bin/jq "bin/jq-$version" share/jq; do
  if [[ -e $prefix/$path ]]; then
    fail "--uninstall jq: $path is gone"
  else
    pass "--uninstall jq: $path is gone"
  fi
done

# A pre-existing non-wrapper file must not be overwritten
mkdir -p "$prefix/bin"
echo 'not a wrapper' > "$prefix/bin/jq"
out=$(PREFIX=$prefix bin/in-1 --local jq 2>&1)
has "$out" "Skipping existing non-wrapper file" \
  "existing non-wrapper file is preserved"
is "$(cat "$prefix/bin/jq")" 'not a wrapper' \
  "existing non-wrapper file content untouched"

# ... nor removed by --uninstall, which still takes out the rest
out=$(run bin/in-1 --uninstall jq PREFIX="$prefix")
has "$out" 'removed 1 command wrappers' \
  "--uninstall jq: removes only the wrapper"
has "$out" 'status=0' \
  "--uninstall jq: returns 0 with a foreign bin/jq"
is "$(cat "$prefix/bin/jq")" 'not a wrapper' \
  "--uninstall jq: foreign bin/jq untouched"
if [[ -e $prefix/share/jq ]]; then
  fail "--uninstall jq: share/jq is gone"
else
  pass "--uninstall jq: share/jq is gone"
fi

done-testing
