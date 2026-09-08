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

has "$out" "$TMPDIR/in-1/bin/jq" "zsh: jq resolves under IN1_ROOT"
has "$out" 'jq-1.' "zsh: jq runs"
has "$out" 'PATH-IDEMPOTENT' "zsh: re-sourcing does not grow PATH"
has "$out" 'TOOLS=jq' "zsh: IN1_TOOLS is set"

out=$(zsh -c 'source ./rc -q jq' 2>&1)
is "$out" '' "zsh: -q one-liner is silent on success"
out=$(zsh -c 'source ./rc --quiet jq; command -v jq' 2>&1)
is "$out" "$TMPDIR/in-1/bin/jq" \
  "zsh: --quiet still updates the shell environment"

# Installed mode: .rc provides a working in-1 function
out=$(zsh -c '
  source "$IN1_ROOT/.rc"
  whence -w in-1
  in-1 jq >/dev/null 2>&1
  command -v jq
')
has "$out" 'in-1: function' "zsh: .rc defines the in-1 function"
has "$out" "$TMPDIR/in-1/bin/jq" "zsh: in-1 function installs jq"

# Through the one-liner, --local in-1 gives Zsh-specific rc guidance
if have-in1-mk "zsh: one-liner --local in-1"; then
  make-in1-repo "$SCRATCH/repo"
  pfx=$SCRATCH/pfx
  out=$(zsh -c '
    source ./rc --local in-1 PREFIX="'"$pfx"'" '"$in1_args"' 2>&1
    echo "status=$?"
  ')
  has "$out" 'status=0' "zsh: one-liner --local in-1 returns 0"
  has "$out" 'every new Zsh shell' \
    "zsh: one-liner --local in-1 gives Zsh-specific guidance"
  has "$out" 'to ~/.zshrc:' \
    "zsh: one-liner --local in-1 names the Zsh rc file"
  has "$out" "source <($pfx/bin/in-1 --rc)" \
    "zsh: one-liner --local in-1 gives Zsh syntax"
  hasnt "$out" '| source' \
    "zsh: one-liner --local in-1 does not mention Fish"
  hasnt "$out" 'in-1: For the in-1 shell function' \
    "zsh: one-liner --local in-1 prints the hint without a prefix"
  hasnt "$out" 'command wrappers' \
    "zsh: one-liner --local in-1 omits the wrapper count"
fi

done-testing
