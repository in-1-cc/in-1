#!/usr/bin/env bash

source test/init

out=$(bin/in-1 --list)
has "$out" 'rust' "--list contains rust"
has "$out" 'node' "--list contains node"

if grep -qE '^(init|shell|local)$' <<< "$out"; then
  fail "--list filters out makes infrastructure files"
else
  pass "--list filters out makes infrastructure files"
fi

out=$(bin/in-1 --version)
has "$out" 'in-1 ' "--version prints a version"

out=$(bin/in-1 --help)
has "$out" 'Usage' "--help prints usage"
has "$out" 'IN1_ROOT' "--help documents IN1_ROOT"

out=$(bin/in-1 --no-such-option 2>&1 || true)
has "$out" "Unknown option '--no-such-option'" "bad option error"

if bin/in-1 --complete bash | bash -n; then
  pass "--complete bash emits valid bash"
else
  fail "--complete bash emits valid bash"
fi

if command -v zsh >/dev/null 2>&1; then
  if bin/in-1 --complete zsh | zsh -n /dev/stdin; then
    pass "--complete zsh emits valid zsh"
  else
    fail "--complete zsh emits valid zsh"
  fi
else
  pass "zsh not available; check skipped"
fi

if command -v fish >/dev/null 2>&1; then
  if bin/in-1 --complete fish | fish -n; then
    pass "--complete fish emits valid fish"
  else
    fail "--complete fish emits valid fish"
  fi
else
  pass "fish not available; check skipped"
fi

out=$(bin/in-1 --complete elvish 2>&1 || true)
has "$out" "Unsupported shell 'elvish'" "--complete rejects unknown shells"

done-testing
