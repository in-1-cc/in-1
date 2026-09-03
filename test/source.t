#!/usr/bin/env bash

source test/init slow

# Full session install of jq in bash via the curl stub
out=$(bash -c '
  unset TMPDIR
  export LANG=C
  source ./rc jq >/dev/null 2>&1 || echo "status=$?"
  command -v jq
  jq --version
  path1=$PATH
  source ./rc jq >/dev/null 2>&1
  [[ $PATH == "$path1" ]] && echo "PATH-IDEMPOTENT"
  echo "TMPDIR=${TMPDIR-unset}"
  echo "LANG=$LANG"
  echo "TOOLS=$IN1_TOOLS"
  echo "MANPATH=$MANPATH"
')

has "$out" "$IN1_ROOT/local/bin/jq" "jq resolves under IN1_ROOT"
has "$out" 'jq-1.' "jq runs and reports its version"
has "$out" 'PATH-IDEMPOTENT' "re-sourcing does not grow PATH"
has "$out" 'TMPDIR=unset' "TMPDIR does not leak into the shell"
has "$out" 'LANG=C' "LANG does not leak into the shell"
has "$out" 'TOOLS=jq' "IN1_TOOLS is set"
has "$out" "MANPATH=$IN1_ROOT/local/man" "MANPATH gets the local man dir"

# Version pinning is passed through to the generated Makefile
version=$(
  grep '^JQ-VERSION ?=' "$IN1_MAKES_REPO/jq.mk" | head -1
)
version=${version##* }
out=$(bash -c "
  source ./rc jq=$version >/dev/null 2>&1 || echo 'status=\$?'
  command -v jq
")
has "$out" "$IN1_ROOT/local/bin/jq" "pinned install works"
has "$(cat "$IN1_ROOT/Makefile")" "JQ-VERSION := $version" \
  "pin lands in the generated Makefile"

# eval interface works directly too
out=$(bash -c '
  eval "$(bin/in-1 --env bash jq 2>/dev/null)"
  command -v jq
')
has "$out" "$IN1_ROOT/local/bin/jq" "eval of in-1 --env works"

done-testing
