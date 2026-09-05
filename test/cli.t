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

has "$out" 'cargo' "--list includes the cargo alias"
has "$out" 'bb' "--list includes the bb alias"
for alias in clj glj lg; do
  if grep -qx "$alias" <<< "$out"; then
    pass "--list includes the $alias alias"
  else
    fail "--list includes the $alias alias"
  fi
done

is "$out" "$(sort -u <<< "$out")" "--list is sorted with no duplicates"
is "$(grep -cx ys <<< "$out")" 1 "--list shows ys once (tool and alias)"

if have-in1-mk "--list"; then
  if grep -qx in-1 <<< "$out"; then
    pass "--list includes in-1 itself"
  else
    fail "--list includes in-1 itself"
  fi
fi

out=$(bin/in-1 --version)
has "$out" 'in-1 ' "--version prints a version"

out=$(bin/in-1 --help)
has "$out" 'Usage' "--help prints usage"
has "$out" 'IN1_ROOT' "--help documents IN1_ROOT"
has "$out" '--update [ARGS]' "--help documents --update"
has "$out" '-U TOOL...' "--help documents -U"
has "$out" '(--uninstall)' "--help documents --uninstall"
has "$out" '-R, --reset' "--help documents -R"
has "$out" '--local in-1' "--help documents installing in-1 itself"

out=$(bin/in-1 --complete bash)
has "$out" '--reset' "--complete bash offers --reset"
has "$out" '--uninstall' "--complete bash offers --uninstall"

out=$(bin/in-1 --no-such-option 2>&1 || true)
has "$out" "Unknown option '--no-such-option'" "bad option error"

out=$(bin/in-1 --upgrade 2>&1 || true)
has "$out" "Unknown option '--upgrade'" "--upgrade is gone"

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
