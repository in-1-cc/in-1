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
  source ./.rc
  type -t in-1
  in-1 jq >/dev/null 2>&1
  command -v jq
' 2>/dev/null)
has "$out" 'function' "fish: .rc defines the in-1 function"
has "$out" "$IN1_ROOT/local/bin/jq" "fish: in-1 function installs jq"

done-testing
