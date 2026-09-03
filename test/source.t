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
')

has "$out" "$IN1_ROOT/bin/jq" "which jq resolves to IN1_ROOT/bin"
has "$out" 'jq-1.' "jq runs and reports its version"
has "$out" 'PATH-IDEMPOTENT' "re-sourcing does not grow PATH"
has "$out" 'TMPDIR=unset' "TMPDIR does not leak into the shell"
has "$out" 'LANG=C' "LANG does not leak into the shell"
has "$out" 'TOOLS=jq' "IN1_TOOLS is set"

# The real binary lives in a versioned share tree, wrapped in bin/
version=$(
  grep '^JQ-VERSION ?=' "$IN1_MAKES_REPO/jq.mk" | head -1
)
version=${version##* }
if [[ -x $IN1_ROOT/share/jq/$version/bin/jq ]]; then
  pass "real jq under share/jq/$version"
else
  fail "real jq under share/jq/$version"
fi
if [[ -x $IN1_ROOT/bin/jq-$version ]]; then
  pass "primary gets a versioned wrapper jq-$version"
else
  fail "primary gets a versioned wrapper jq-$version"
fi
has "$(cat "$IN1_ROOT/bin/jq")" '# in-1 wrapper' \
  "bin/jq is an in-1 wrapper"

# A version is pinned by passing the tool's makes variable as an arg
alt=1.7
out=$(bash -c "
  source ./rc jq JQ-VERSION=$alt >/dev/null 2>&1
  jq --version
  command -v jq-$alt
")
has "$out" "jq-$alt" "make-var arg pins the version"
if [[ -x $IN1_ROOT/share/jq/$alt/bin/jq ]]; then
  pass "pinned version installs under share/jq/$alt"
else
  fail "pinned version installs under share/jq/$alt"
fi

# A NAME=VALUE arg with no tool is a friendly error
out=$(bash -c 'source ./rc JQ-VERSION=1.7 2>&1; echo "rc=$?"')
has "$out" 'sets a make variable' "bare make-var arg explains itself"

# Quiet progress output (non-tty variant)
out=$(bash -c 'source ./rc jq >/dev/null' 2>&1)
has "$out" '… jq v' "progress: installing line shown"
has "$out" '√ jq v' "progress: success line shown"
has "$out" "installed to $IN1_ROOT/share/jq/$version/bin/jq" \
  "progress: reports the primary binary path"
has "$out" 's)' "progress: reports elapsed time"

# A failed install shows an X line and the shell survives
froot=$SCRATCH/fail
mkdir -p "$froot"
ln -s "$ROOT" "$froot/in-1"
out=$(
  IN1_ROOT=$froot bash -c '
    source ./rc jq JQ-VERSION=9.9.9 >/dev/null
    echo "status=$? alive"
  ' 2>&1
)
has "$out" 'X jq v9.9.9 NOT installed' "progress: failure line shown"
has "$out" 'Full log:' "progress: failure points at the log"
has "$out" 'status=1 alive' "failed install returns 1, shell survives"

# A relative PREFIX anchors to the caller's cwd, not the makes root
out=$(
  cd "$SCRATCH" &&
  PREFIX=relpfx bash -c "source $ROOT/rc jq >/dev/null 2>&1; command -v jq"
)
has "$out" "$SCRATCH/relpfx/bin/jq" "relative PREFIX anchors to cwd"

# eval interface works directly too
out=$(bash -c '
  eval "$(bin/in-1 --env bash jq 2>/dev/null)"
  command -v jq
')
has "$out" "$IN1_ROOT/bin/jq" "eval of in-1 --env works"

# An alias installs the tool it names and labels itself
out=$(bash -c 'source ./rc bb >/dev/null; command -v bb' 2>&1)
has "$out" '√ bb v' "alias 'bb' reports itself, not babashka"
has "$out" "$IN1_ROOT/bin/bb" "alias 'bb' installs and wraps babashka"

done-testing
