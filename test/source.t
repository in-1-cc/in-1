#!/usr/bin/env bash

source test/init slow

# Full session install of jq in bash via the curl stub
out=$(bash -c '
  export LANG=C
  source ./rc jq >/dev/null 2>&1 || echo "status=$?"
  command -v jq
  jq --version
  path1=$PATH
  source ./rc jq >/dev/null 2>&1
  [[ $PATH == "$path1" ]] && echo "PATH-IDEMPOTENT"
  echo "TMPDIR=$TMPDIR"
  echo "LANG=$LANG"
  echo "TOOLS=$IN1_TOOLS"
')

has "$out" "$IN1_ROOT/local/bin/jq" "which jq resolves to local/bin"
has "$out" 'jq-1.' "jq runs and reports its version"
has "$out" 'PATH-IDEMPOTENT' "re-sourcing does not grow PATH"
has "$out" "TMPDIR=$TMPDIR" "TMPDIR does not change in the shell"
has "$out" 'LANG=C' "LANG does not leak into the shell"
has "$out" 'TOOLS=jq' "IN1_TOOLS is set"

# The real binary lives in a versioned share tree, wrapped in bin/
version=$(
  grep '^JQ-VERSION ?=' "$IN1_MAKES_REPO/jq.mk" | head -1
)
version=${version##* }
if [[ -x $IN1_ROOT/local/share/jq/$version/bin/jq ]]; then
  pass "real jq under local/share/jq/$version"
else
  fail "real jq under local/share/jq/$version"
fi
if [[ -x $IN1_ROOT/local/bin/jq-$version ]]; then
  pass "primary gets a versioned wrapper jq-$version"
else
  fail "primary gets a versioned wrapper jq-$version"
fi
has "$(cat "$IN1_ROOT/local/bin/jq")" '# in-1 wrapper' \
  "local/bin/jq is an in-1 wrapper"

# A version is pinned by passing the tool's makes variable as an arg
alt=1.7
out=$(bash -c "
  source ./rc jq JQ-VERSION=$alt >/dev/null 2>&1
  jq --version
  command -v jq-$alt
")
has "$out" "jq-$alt" "make-var arg pins the version"
if [[ -x $IN1_ROOT/local/share/jq/$alt/bin/jq ]]; then
  pass "pinned version installs under local/share/jq/$alt"
else
  fail "pinned version installs under local/share/jq/$alt"
fi

# A NAME=VALUE arg with no tool is a friendly error
out=$(bash -c 'source ./rc JQ-VERSION=1.7 2>&1; echo "rc=$?"')
has "$out" 'sets a make variable' "bare make-var arg explains itself"

# Quiet progress output (non-tty variant)
out=$(bash -c 'source ./rc jq >/dev/null' 2>&1)
has "$out" '… jq v' "progress: installing line shown"
has "$out" '√ jq v' "progress: success line shown"
has "$out" "installed to $IN1_ROOT/local/bin/jq" \
  "progress: reports the wrapper path"
has "$out" 's)' "progress: reports elapsed time"

# A failed install shows an X line and the shell survives
froot=$SCRATCH/fail
make-in1-root "$froot"
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

# A PREFIX=DIR argument sets the prefix instead of a make variable
out=$(bash -c "
  source ./rc jq PREFIX=$SCRATCH/argpfx >/dev/null 2>&1; command -v jq
")
has "$out" "$SCRATCH/argpfx/bin/jq" "PREFIX=DIR argument sets the prefix"

# eval interface works directly too
out=$(bash -c '
  eval "$(bin/in-1 --env bash jq 2>/dev/null)"
  command -v jq
')
has "$out" "$IN1_ROOT/local/bin/jq" "eval of in-1 --env works"

# An alias installs the tool it names and labels itself
out=$(bash -c 'source ./rc bb >/dev/null; command -v bb' 2>&1)
has "$out" '√ bb v' "alias 'bb' reports itself, not babashka"
has "$out" "$IN1_ROOT/local/bin/bb" \
  "alias 'bb' installs and wraps babashka"

# A share/<tool>.wrap snippet goes into the primary's wrappers
out=$(bash -c 'source ./rc jolt >/dev/null 2>&1; jolt --version')
has "$out" 'jolt' "jolt installs and runs through its wrapper"
version=$(
  grep '^JOLT-VERSION ?=' "$IN1_MAKES_REPO/jolt.mk" | head -1
)
version=${version##* }
for w in jolt jolt-$version; do
  has "$(cat "$IN1_ROOT/local/bin/$w")" 'exec rlwrap "$cmd" "$@"' \
    "local/bin/$w carries the jolt.wrap snippet"
done
if grep -q rlwrap "$IN1_ROOT/local/bin/jq"; then
  fail "the jolt snippet stays out of other wrappers"
else
  pass "the jolt snippet stays out of other wrappers"
fi
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck "$IN1_ROOT/local/bin/jolt" "$IN1_ROOT/local/bin/jq"; then
    pass "generated wrappers pass shellcheck"
  else
    fail "generated wrappers pass shellcheck"
  fi
else
  pass "shellcheck not available; check skipped"
fi

# --reset wipes the root first, then installs; IN1_TOOLS starts over
out=$(bash -c '
  source ./rc jq bb >/dev/null 2>&1
  source ./rc --reset jq >/dev/null 2>&1 || echo "status=$?"
  command -v jq
  jq --version
  echo "TOOLS=$IN1_TOOLS"
' 2>&1)
has "$out" "$IN1_ROOT/local/bin/jq" \
  "--reset jq: jq is back on PATH"
has "$out" 'jq-1.' "--reset jq: jq runs after the reset"
has "$out" 'TOOLS=jq' "--reset jq: IN1_TOOLS lists only jq"
if [[ -e $IN1_ROOT/local/bin/bb ]]; then
  fail "--reset jq: the bb wrapper is gone"
else
  pass "--reset jq: the bb wrapper is gone"
fi

# Installed mode: the in-1 function from .rc, with and without --update
out=$(bash -c '
  source "$IN1_ROOT/.rc"
  in-1 jq >/dev/null 2>&1
  command -v jq
  in-1 --update jq 2>&1 >/dev/null
  command -v jq
')
has "$out" "$IN1_ROOT/local/bin/jq" "in-1 function installs jq"
has "$out" 'not updating in-1' "in-1 --update jq: goes through --env"
has "$out" 'makes is now at' "in-1 --update jq: updates makes"

# The in-1 function removes repeated PATH entries without changing
# their order or masking the command's exit status.
out=$(bash -c '
  source "$IN1_ROOT/.rc"
  PATH=/one:/two:/one:/three:/two:$PATH
  in-1 --version >/dev/null
  echo "path=$PATH"
  in-1 --uninstall nope PREFIX='"$SCRATCH/pfx"' >/dev/null 2>&1
  echo "status=$?"
')
has "$out" 'path=/one:/two:/three:' "in-1 function deduplicates PATH"
has "$out" 'status=1' "PATH deduplication preserves command status"

# Without Perl the function leaves PATH untouched.
no_perl=$SCRATCH/no-perl
mkdir -p "$no_perl"
printf '#!/bin/bash\nexit 0\n' > "$no_perl/in-1"
chmod +x "$no_perl/in-1"
out=$(NO_PERL=$no_perl bash -c '
  source "$IN1_ROOT/.rc"
  PATH=$NO_PERL:/one:/one
  hash -r
  in-1 --version
  echo "path=$PATH"
')
is "$out" "path=$no_perl:/one:/one" \
  "in-1 function keeps PATH when Perl is unavailable"

# in-1 itself as a tool, next to another tool; installs through the
# resulting function land in the one-liner's root, not in the
# installed copy
if have-in1-mk "in-1 as a tool"; then
  make-in1-repo "$SCRATCH/repo"
  out=$(bash -c '
    source ./rc in-1 jq '"$in1_args"' >/dev/null 2>&1; echo "status=$?"
    echo "type=$(type -t in-1)"
    jq --version
    in-1 bb >/dev/null 2>&1
    echo "bb=$(command -v bb)"
    echo "tools=$IN1_TOOLS"
  ')
  has "$out" 'status=0' "in-1 jq: returns 0"
  has "$out" 'type=function' "in-1 jq: in-1 is a shell function"
  has "$out" 'jq-1.' "in-1 jq: jq runs"
  has "$out" "bb=$IN1_ROOT/local/bin/bb" "in-1 bb via the function: one root"
  has "$out" 'tools=in-1 jq bb' "IN1_TOOLS lists all three"
  if ls -d "$IN1_ROOT"/local/share/in-1/*/cache/in-1-*/local \
      >/dev/null 2>&1; then
    fail "the installed in-1 starts no root of its own"
  else
    pass "the installed in-1 starts no root of its own"
  fi

  # --local in-1 installs the command for keeps and prints only the
  # concise shell setup hint after the progress line
  pfx=$SCRATCH/pfx
  # shellcheck disable=SC2086  # in1_args holds two make args
  out=$(
    bin/in-1 --local in-1 PREFIX="$pfx" $in1_args 2>&1 &&
      echo "status=$?" || echo "status=$?"
  )
  has "$out" 'status=0' "--local in-1: returns 0"
  if [[ -x $pfx/bin/in-1 ]]; then
    pass "--local in-1: writes PREFIX/bin/in-1"
  else
    fail "--local in-1: writes PREFIX/bin/in-1"
  fi
  has "$out" "source <($pfx/bin/in-1 --rc)" "--local in-1: prints the --rc line"
  has "$out" "$pfx/bin/in-1 --rc | source" "--local in-1: and the fish one"
  hasnt "$out" 'Installed in-1:' "--local in-1: omits the install summary"
  hasnt "$out" 'command wrappers' "--local in-1: omits the wrapper count"
  hasnt "$out" 'Session installs' "--local in-1: omits the root explanation"
  rc=$(ls -d "$pfx"/share/in-1/*/cache/in-1-*/.rc 2>/dev/null | head -1)
  out=$("$pfx/bin/in-1" --rc)
  is "$out" "source '$rc'" "installed in-1 --rc: points at its own .rc"

  # Sourcing that line: the function, the stable root, and session
  # installs (plus --reset) under it
  stable=$pfx/share/in-1/local
  out=$(env -u IN1_ROOT bash -c '
    source <("'"$pfx"'/bin/in-1" --rc)
    echo "type=$(type -t in-1)"
    echo "root=$IN1_ROOT"
    in-1 --version
    in-1 jq >/dev/null 2>&1
    echo "jq=$(command -v jq)"
    in-1 --reset 2>&1
  ')
  has "$out" 'type=function' "source <(in-1 --rc): in-1 is a function"
  has "$out" "root=$stable" "source <(in-1 --rc): IN1_ROOT is the stable root"
  has "$out" $'\nin-1 ' "source <(in-1 --rc): in-1 --version runs"
  has "$out" "jq=$stable/local/bin/jq" "in-1 jq: installs under the stable root"
  has "$out" "reset: removed makes/, log/, local/ and cache/ from '$stable'" \
    "in-1 --reset: resets the stable root"
  if ls -d "$pfx"/share/in-1/*/cache/in-1-*/local >/dev/null 2>&1; then
    fail "the installed copy starts no root of its own"
  else
    pass "the installed copy starts no root of its own"
  fi

  # Through the one-liner, --local in-1 sets up the current shell as
  # well: stale command paths are forgotten and the installed copy's
  # .rc is sourced (IN1_ROOT is set here, so .rc keeps it)
  # shellcheck disable=SC2086  # in1_args holds two make args
  out=$(
    bin/in-1 --env bash --local in-1 PREFIX="$pfx" $in1_args 2>/dev/null
  )
  is "$out" $'hash -r 2>/dev/null || true\n'"source '$rc'" \
    "--env bash --local in-1: emits hash -r and the source line"
  out=$(bash -c '
    source ./rc --local in-1 PREFIX="'"$pfx"'" '"$in1_args"' 2>&1
    echo "status=$?"
    echo "type=$(type -t in-1)"
    in-1 --version
    echo "root=$IN1_ROOT"
  ')
  has "$out" 'status=0' "one-liner --local in-1: returns 0"
  hasnt "$out" 'This shell is set up now' \
    "one-liner --local in-1: omits the current-shell notice"
  hasnt "$out" 'in-1: For the in-1 shell function' \
    "one-liner --local in-1: prints the hint without a prefix"
  hasnt "$out" 'command wrappers' \
    "one-liner --local in-1: omits the wrapper count"
  hasnt "$out" 'Session installs' \
    "one-liner --local in-1: omits the root explanation"
  has "$out" 'every new Bash shell' \
    "one-liner --local in-1: gives Bash-specific guidance"
  has "$out" 'to ~/.bashrc:' \
    "one-liner --local in-1: names the Bash rc file"
  hasnt "$out" 'bash / zsh' \
    "one-liner --local in-1: does not mention Zsh"
  hasnt "$out" '| source' \
    "one-liner --local in-1: does not mention Fish"
  has "$out" 'type=function' "one-liner --local in-1: in-1 is a function"
  has "$out" $'\nin-1 ' "one-liner --local in-1: in-1 --version runs"
  has "$out" "root=$IN1_ROOT" "one-liner --local in-1: keeps a set IN1_ROOT"

  # The shell function honors the locally installed .rc root, but a
  # later one-liner always uses a new temporary root.
  session_tmp=$SCRATCH/session-tmp
  out=$(
    env -u IN1_ROOT TMPDIR="$session_tmp" \
      IN1_REPO="$SCRATCH/repo" bash -c '
      source <("'"$pfx"'/bin/in-1" --rc)
      echo "local-root=$IN1_ROOT"
      in-1 in-1 '"$in1_args"' >/dev/null 2>&1
      echo "function-root=$IN1_ROOT"
      echo "function-command=$(type -P in-1)"
      source ./rc in-1 '"$in1_args"' >/dev/null 2>&1
      echo "session-root=$IN1_ROOT"
      echo "session-command=$(type -P in-1)"
      in-1 jq >/dev/null 2>&1
      in-1 --uninstall jq 2>&1
      echo "function-uninstall-status=$?"
      [[ ! -e $IN1_ROOT/local/share/jq ]] && echo function-uninstalled
    '
  )
  stable=$pfx/share/in-1/local
  session_root=$session_tmp/in-1
  has "$out" "local-root=$stable" \
    "installed .rc selects its stable root"
  has "$out" "function-root=$stable" \
    "the in-1 function honors the stable root"
  has "$out" "function-command=$stable/local/" \
    "the in-1 function selects its stable in-1"
  has "$out" "session-root=$session_root" \
    "a later one-liner selects its temporary root"
  has "$out" "session-command=$session_root/local/" \
    "the later one-liner selects its temporary in-1"
  has "$out" "from '$session_root/local/bin'" \
    "the session function uninstalls from its session prefix"
  has "$out" 'function-uninstall-status=0' \
    "the session function uninstall returns 0"
  has "$out" 'function-uninstalled' \
    "the session function removes its session install"
  hasnt "$out" 'ignored null byte' \
    "the session function uninstall produces no NUL warnings"

  # --uninstall in-1 takes the command and its root with it
  out=$(
    "$pfx/bin/in-1" --uninstall in-1 PREFIX="$pfx" 2>&1 ||
      echo "status=$?"
  )
  has "$out" 'Uninstalled in-1:' \
    "--uninstall in-1: reports the uninstall"
  hasnt "$out" 'status=' "--uninstall in-1: returns 0"
  if [[ ! -e $pfx/share/in-1 && ! -e $pfx/bin/in-1 ]]; then
    pass "--uninstall in-1: the command and its root are gone"
  else
    fail "--uninstall in-1: the command and its root are gone"
  fi
fi

# --uninstall must be run through the in-1 command, and the rejected
# one-liner does not clone in-1 first.
reject_tmp=$SCRATCH/reject-tmp
out=$(
  env -u IN1_ROOT TMPDIR="$reject_tmp" bash -c '
    source ./rc --uninstall ys 2>&1
    echo "status=$?"
  '
)
has "$out" '--uninstall must be run by the in-1 command' \
  "one-liner --uninstall explains the error"
has "$out" 'Try: in-1 --uninstall TOOL...' \
  "one-liner --uninstall gives the command to run"
has "$out" 'status=1' "one-liner --uninstall returns 1"
if [[ ! -e $reject_tmp/in-1 ]]; then
  pass "one-liner --uninstall does not clone in-1"
else
  fail "one-liner --uninstall does not clone in-1"
fi

done-testing
