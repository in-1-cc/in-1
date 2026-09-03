#!/usr/bin/env bash

source test/init

# Syntax checks for the sourceable files
if bash -n rc && bash -n .rc; then
  pass "rc and .rc pass 'bash -n'"
else
  fail "rc and .rc pass 'bash -n'"
fi

if command -v zsh >/dev/null 2>&1; then
  if zsh -n rc && zsh -n .rc; then
    pass "rc and .rc pass 'zsh -n'"
  else
    fail "rc and .rc pass 'zsh -n'"
  fi
else
  pass "zsh not available; check skipped"
fi

if command -v fish >/dev/null 2>&1; then
  if fish -n rc && fish -n .rc; then
    pass "rc and .rc pass 'fish -n'"
  else
    fail "rc and .rc pass 'fish -n'"
  fi
else
  pass "fish not available; check skipped"
fi

# Sourcing with no args fails but must not kill the shell
out=$(bash -c 'source ./rc 2>&1; echo "status=$? alive"')
has "$out" 'status=1 alive' "no args: returns 1, shell survives"
has "$out" 'No tools specified' "no args: prints an error"
has "$out" 'Usage' "no args: prints usage"

# Unknown tool points at --list without dumping every tool
out=$(bash -c 'source ./rc no-such-tool 2>&1; echo "status=$?"')
has "$out" "Unknown tool 'no-such-tool'" "unknown tool: error message"
has "$out" 'in-1 --list' "unknown tool: points at --list"
has "$out" 'status=1' "unknown tool: returns 1"

# No _in1* variables or functions may remain after sourcing
out=$(bash -c '
  source ./rc no-such-tool >/dev/null 2>&1
  set | grep -c "^_in1" || true
')
is "$out" 0 "no _in1 residue in shell after sourcing"

done-testing
