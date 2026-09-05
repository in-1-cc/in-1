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

# Informational options through the one-liner go to the user, not
# into the eval
out=$(bash -c 'source ./rc --list 2>&1 >/dev/null; echo "status=$? alive"')
has "$out" 'rust' "--list: lists tools on stderr"
has "$out" 'status=0 alive' "--list: returns 0, shell survives"
out=$(bash -c 'source ./rc --list 2>/dev/null; echo "status=$?"')
is "$out" 'status=0' "--list: nothing on stdout, nothing evaled"
out=$(bash -c 'source ./rc --help 2>&1 >/dev/null')
has "$out" 'Usage' "--help: prints usage on stderr"
out=$(bash -c 'source ./rc --version 2>&1 >/dev/null')
has "$out" 'in-1 ' "--version: prints the version on stderr"

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

# Installed mode: .rc sets IN1_ROOT to the clone it lives in (unless
# it is already set) and the in-1 function sends -U to the command
out=$(env -u IN1_ROOT bash -c '
  source "'"$IN1_ROOT"'/.rc"
  echo "root=$IN1_ROOT"
  in-1 -U 2>&1; echo "status=$?"
  in-1 -U --list 2>/dev/null | grep -c ^rust$
')
has "$out" "root=$IN1_ROOT" ".rc exports IN1_ROOT as its own dir"
has "$out" 'not updating in-1' "in-1 -U: warns on a non-clone root"
has "$out" 'makes is now at' "in-1 -U: updates makes"
has "$out" 'status=0' "in-1 -U: returns 0"
has "$out" '1' "in-1 -U --list: lists tools"

preset=$SCRATCH/preset
rcfile=$IN1_ROOT/.rc
out=$(IN1_ROOT=$preset bash -c "source $rcfile; echo root=\$IN1_ROOT")
has "$out" "root=$preset" ".rc keeps a preset IN1_ROOT"
if command -v fish >/dev/null 2>&1; then
  out=$(IN1_ROOT=$preset fish -c "source $rcfile; echo root=\$IN1_ROOT")
  has "$out" "root=$preset" "fish: .rc keeps a preset IN1_ROOT"
else
  pass "fish not available; check skipped"
fi

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

# in-1 itself as a tool: the one-liner installs it (a local clone of
# this working copy, no network) and its extra sources the installed
# copy's .rc, so the shell gets the in-1 function, man page and
# completion while IN1_ROOT stays the one-liner's root
if have-in1-mk "in-1 as a tool"; then
  make-in1-repo "$SCRATCH/repo"
  nested="$IN1_ROOT/local/share/in-1/*/cache/in-1-*"
  out=$(bash -c '
    source ./rc in-1 '"$in1_args"' 2>&1; echo "status=$?"
    echo "type=$(type -t in-1)"
    echo "bin=$(type -P in-1)"
    in-1 --version
    echo "root=$IN1_ROOT"
    echo "tools=$IN1_TOOLS"
    echo "man=$MANPATH"
    echo "list=$(in-1 --list 2>/dev/null | grep -cx in-1)"
    echo "residue=$(set | grep -c "^_in1" || true)"
  ')
  has "$out" '√ in-1 v' "in-1 tool: progress line"
  has "$out" 'status=0' "in-1 tool: returns 0"
  has "$out" 'type=function' "in-1 tool: in-1 is a shell function"
  has "$out" "bin=$IN1_ROOT/local/" "in-1 tool: the command is under local/"
  has "$out" $'\nin-1 ' "in-1 tool: in-1 --version runs"
  has "$out" "root=$IN1_ROOT" "in-1 tool: IN1_ROOT stays the one-liner root"
  has "$out" 'tools=in-1' "in-1 tool: IN1_TOOLS lists in-1"
  has "$out" "$IN1_ROOT/local/share/in-1/" "in-1 tool: man dir on MANPATH"
  has "$out" 'list=1' "in-1 tool: in-1 --list works through the function"
  has "$out" 'residue=0' "in-1 tool: no _in1 residue"
  # shellcheck disable=SC2086  # the glob is the point
  if ls -d $nested/local $nested/makes >/dev/null 2>&1; then
    fail "in-1 tool: the installed copy starts no root of its own"
  else
    pass "in-1 tool: the installed copy starts no root of its own"
  fi

  if command -v zsh >/dev/null 2>&1; then
    out=$(zsh -c '
      source ./rc in-1 '"$in1_args"' >/dev/null 2>&1; echo "status=$?"
      whence -w in-1
      echo "root=$IN1_ROOT"
      echo "tools=$IN1_TOOLS"
    ')
    has "$out" 'status=0' "zsh: in-1 tool returns 0"
    has "$out" 'in-1: function' "zsh: in-1 is a shell function"
    has "$out" "root=$IN1_ROOT" "zsh: IN1_ROOT stays the one-liner root"
    has "$out" 'tools=in-1' "zsh: IN1_TOOLS lists in-1"
  else
    pass "zsh not available; check skipped"
  fi

  if command -v fish >/dev/null 2>&1; then
    out=$(fish -c '
      source ./rc in-1 '"$in1_args"' 2>/dev/null; echo "status=$status"
      echo "type="(type -t in-1)
      in-1 --version
      echo "root=$IN1_ROOT"
      echo "tools=$IN1_TOOLS"
      echo "list="(in-1 --list 2>/dev/null | grep -cx in-1)
    ' 2>/dev/null)
    has "$out" 'status=0' "fish: in-1 tool returns 0"
    has "$out" 'type=function' "fish: in-1 is a shell function"
    has "$out" $'\nin-1 ' "fish: in-1 --version runs"
    has "$out" "root=$IN1_ROOT" "fish: IN1_ROOT stays the one-liner root"
    has "$out" 'tools=in-1' "fish: IN1_TOOLS lists in-1"
    has "$out" 'list=1' "fish: in-1 --list works through the function"
  else
    pass "fish not available; check skipped"
  fi
fi

done-testing
