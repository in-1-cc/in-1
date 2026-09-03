#!/usr/bin/env bash

source test/init slow

if ! command -v zsh >/dev/null 2>&1; then
  pass "zsh not available; tests skipped"
  done-testing
  exit 0
fi

out=$(zsh -c '
  source ./rc jq >/dev/null 2>&1 || echo "status=$?"
  command -v jq
  jq --version
  path1=$PATH
  source ./rc jq >/dev/null 2>&1
  [[ $PATH == "$path1" ]] && echo "PATH-IDEMPOTENT"
  echo "TOOLS=$IN1_TOOLS"
')

has "$out" "$IN1_ROOT/local/bin/jq" "zsh: jq resolves under IN1_ROOT"
has "$out" 'jq-1.' "zsh: jq runs"
has "$out" 'PATH-IDEMPOTENT' "zsh: re-sourcing does not grow PATH"
has "$out" 'TOOLS=jq' "zsh: IN1_TOOLS is set"

# Installed mode: .rc provides a working in-1 function
out=$(zsh -c '
  source ./.rc
  whence -w in-1
  in-1 jq >/dev/null 2>&1
  command -v jq
')
has "$out" 'in-1: function' "zsh: .rc defines the in-1 function"
has "$out" "$IN1_ROOT/local/bin/jq" "zsh: in-1 function installs jq"

done-testing
