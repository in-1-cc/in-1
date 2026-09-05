#!/usr/bin/env bash

source test/init slow

if ! command -v fish >/dev/null 2>&1; then
  pass "fish not available; tests skipped"
  done-testing
  exit 0
fi

out=$(fish -c '
  source ./rc jq >/dev/null 2>&1; or echo "status=$status"
  command -v jq
  jq --version
  set -l p1 "$PATH"
  source ./rc jq >/dev/null 2>&1
  test "$PATH" = "$p1"; and echo "PATH-IDEMPOTENT"
  echo "TOOLS=$IN1_TOOLS"
' 2>/dev/null)

has "$out" "$IN1_ROOT/local/bin/jq" "fish: jq resolves under IN1_ROOT"
has "$out" 'jq-1.' "fish: jq runs"
has "$out" 'PATH-IDEMPOTENT' "fish: re-sourcing does not grow PATH"
has "$out" 'TOOLS=jq' "fish: IN1_TOOLS is set"

# The piped form documented for fish
out=$(fish -c '
  cat ./rc | source - jq >/dev/null 2>&1
  command -v jq
' 2>/dev/null)
has "$out" "$IN1_ROOT/local/bin/jq" "fish: piped source form works"

# Installed mode: .rc provides a working in-1 function
out=$(fish -c '
  source "$IN1_ROOT/.rc"
  type -t in-1
  in-1 jq >/dev/null 2>&1
  command -v jq
  in-1 --update jq 2>&1 >/dev/null
  command -v jq
' 2>/dev/null)
has "$out" 'function' "fish: .rc defines the in-1 function"
has "$out" "$IN1_ROOT/local/bin/jq" "fish: in-1 function installs jq"
has "$out" 'makes is now at' "fish: in-1 --update jq goes through --env"

# The --rc line sets up the same function
out=$(fish -c '
  bin/in-1 --rc | source
  type -t in-1
  echo "root=$IN1_ROOT"
' 2>/dev/null)
has "$out" 'function' "fish: in-1 --rc | source defines the function"
has "$out" "root=$IN1_ROOT" "fish: in-1 --rc | source keeps IN1_ROOT"

# -U (uninstall) goes straight to the command
out=$(fish -c '
  source "$IN1_ROOT/.rc"
  in-1 -U nope PREFIX='"$SCRATCH/pfx"' 2>&1; echo "status=$status"
' 2>/dev/null)
has "$out" "'nope' is not installed" "fish: in-1 -U runs the command"
has "$out" 'status=1' "fish: in-1 -U returns 1 for a missing tool"

# Through the one-liner, --local in-1 sets up the current shell too
if have-in1-mk "fish: one-liner --local in-1"; then
  make-in1-repo "$SCRATCH/repo"
  pfx=$SCRATCH/pfx
  out=$(fish -c '
    cat ./rc | source - --local in-1 PREFIX='"$pfx"' '"$in1_args"' 2>&1
    echo "status=$status"
    echo "type="(type -t in-1)
    in-1 --version
  ' 2>/dev/null)
  has "$out" 'status=0' "fish: one-liner --local in-1 returns 0"
  has "$out" 'This shell is set up now' \
    "fish: one-liner --local in-1 says the shell is set up"
  has "$out" 'type=function' "fish: one-liner --local in-1 defines in-1"
  has "$out" $'\nin-1 ' "fish: one-liner --local in-1: in-1 --version runs"
fi

done-testing
