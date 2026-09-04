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

# An IN1_ROOT that exists but is not an in-1 clone (the old layout,
# say) is an error, never touched
old=$SCRATCH/old
mkdir -p "$old/in-1"
out=$(
  IN1_ROOT=$old bash -c 'source ./rc jq 2>&1; echo "status=$? alive"'
)
has "$out" 'not an in-1 clone' "old layout: explains itself"
has "$out" 'status=1 alive' "old layout: returns 1, shell survives"
if [[ ! -e $old/bin ]]; then
  pass "old layout: root left untouched"
else
  fail "old layout: root left untouched"
fi

if command -v fish >/dev/null 2>&1; then
  out=$(
    IN1_ROOT=$old fish -c 'source ./rc jq 2>&1; echo "status=$status"'
  )
  has "$out" 'not an in-1 clone' "fish: old layout explains itself"
  has "$out" 'status=1' "fish: old layout returns 1"
else
  pass "fish not available; check skipped"
fi

# A missing or empty IN1_ROOT gets the clone (from IN1_REPO here)
for fresh in "$SCRATCH/fresh/root" "$SCRATCH/empty"; do
  [[ $fresh == */empty ]] && mkdir -p "$fresh"
  out=$(
    IN1_ROOT=$fresh bash -c 'source ./rc no-such-tool 2>&1; echo "s=$?"'
  )
  if [[ -x $fresh/bin/in-1 && -d $fresh/.git && -d $fresh/makes ]]; then
    pass "clone lands in ${fresh##*/}: bin/in-1, .git and makes/"
  else
    fail "clone lands in ${fresh##*/}: bin/in-1, .git and makes/"
  fi
  has "$out" 'Unknown tool' "the clone in ${fresh##*/} runs"
done

# Installed mode: .rc sets IN1_ROOT to the clone it lives in and the
# in-1 function sends -U to the command
out=$(bash -c '
  source "$IN1_ROOT/.rc"
  echo "root=$IN1_ROOT"
  in-1 -U 2>&1; echo "status=$?"
  in-1 -U --list 2>/dev/null | grep -c ^rust$
')
has "$out" "root=$IN1_ROOT" ".rc exports IN1_ROOT as its own dir"
has "$out" 'not updating in-1' "in-1 -U: warns on a non-clone root"
has "$out" 'makes is now at' "in-1 -U: updates makes"
has "$out" 'status=0' "in-1 -U: returns 0"
has "$out" '1' "in-1 -U --list: lists tools"

# The in-1 function sends -R to the command too
out=$(bash -c '
  source "$IN1_ROOT/.rc"
  in-1 -R 2>&1; echo "status=$?"
  in-1 -R --list 2>/dev/null | grep -c ^rust$
')
has "$out" 'reset: removed' "in-1 -R: resets the root"
has "$out" 'status=0' "in-1 -R: returns 0"
has "$out" '1' "in-1 -R --list: resets, then lists tools"

if command -v fish >/dev/null 2>&1; then
  out=$(fish -c '
    source "$IN1_ROOT/.rc"
    in-1 -R 2>&1; echo "status=$status"
    in-1 -R --list 2>/dev/null | grep -cx rust
  ')
  has "$out" 'reset: removed' "fish: in-1 -R resets the root"
  has "$out" 'status=0' "fish: in-1 -R returns 0"
  has "$out" '1' "fish: in-1 -R --list lists tools"
else
  pass "fish not available; check skipped"
fi

done-testing
