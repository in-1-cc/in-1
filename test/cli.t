#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2016
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
has "$out" 'bb (babashka)' "--list labels the bb alias with its tool"
for alias in alr bb cargo clj gfortran glj lg rustc yaml ys ysd; do
  if grep -qE "^$alias( \([^)]+\))?$" <<< "$out"; then
    pass "--list includes the $alias alias"
  else
    fail "--list includes the $alias alias"
  fi
done

is "$out" "$(sort -u <<< "$out")" "--list is sorted with no duplicates"
is "$(grep -cE '^ys( \([^)]+\))?$' <<< "$out")" 1 \
  "--list shows ys once (tool or labeled alias)"

if have-in1-mk "--list"; then
  if grep -qx in-1 <<< "$out"; then
    pass "--list includes in-1 itself"
  else
    fail "--list includes in-1 itself"
  fi
fi

out=$(bin/in-1 --version)
has "$out" 'in-1 ' "--version prints a version"

out=$(bin/in-1 --rc)
is "$out" "source '$ROOT/.rc'" "--rc prints the source line for its .rc"
out=$(env -u IN1_ROOT bash -c '
  source <(bin/in-1 --rc)
  echo "type=$(type -t in-1)"
  echo "root=$IN1_ROOT"
')
has "$out" 'type=function' "source <(in-1 --rc): defines the function"
has "$out" "root=$ROOT" "source <(in-1 --rc): IN1_ROOT is the clone"

out=$(bin/in-1 --help)
has "$out" 'in-1 --rc' "--help documents --rc"
has "$out" 'Usage' "--help prints usage"
has "$out" 'IN1_ROOT' "--help documents IN1_ROOT"
has "$out" '--update [ARGS]' "--help documents --update"
has "$out" '--uninstall TOOL...' "--help documents --uninstall"
has "$out" '--reset [ARGS]' "--help documents --reset"
has "$out" '-q|--quiet' "--help documents -q and --quiet"
hasnt "$out" '-U TOOL...' "--help does not document -U"
hasnt "$out" '-R, --reset' "--help does not document -R"
has "$out" '--local in-1' "--help documents installing in-1 itself"

out=$(bin/in-1 --complete bash)
has "$out" '--reset' "--complete bash offers --reset"
has "$out" '--uninstall' "--complete bash offers --uninstall"
has "$out" '--rc' "--complete bash offers --rc"
has "$out" '-q' "--complete bash offers -q"
has "$out" '--quiet' "--complete bash offers --quiet"
hasnt "$out" '-U' "--complete bash does not offer -U"
hasnt "$out" '-R' "--complete bash does not offer -R"

out=$(bin/in-1 --complete zsh)
has "$out" '-q' "--complete zsh offers -q"
has "$out" '--quiet' "--complete zsh offers --quiet"
hasnt "$out" '-U' "--complete zsh does not offer -U"
hasnt "$out" '-R' "--complete zsh does not offer -R"

out=$(bin/in-1 --complete fish)
has "$out" '-s q' "--complete fish offers -q"
has "$out" '-l quiet' "--complete fish offers --quiet"
hasnt "$out" '-s U' "--complete fish does not offer -U"
hasnt "$out" '-s R' "--complete fish does not offer -R"

out=$(bin/in-1 --no-such-option 2>&1 || true)
has "$out" "Unknown option '--no-such-option'" "bad option error"
hasnt "$out" 'Usage' "bad option does not print usage"

out=$(bin/in-1 --env bash 2>&1 || true)
has "$out" 'Try: in-1 --help' "--env without tools points at help"
hasnt "$out" 'Usage' "--env without tools does not print usage"

out=$(bin/in-1 --local 2>&1 || true)
has "$out" 'Try: in-1 --help' "--local without tools points at help"
hasnt "$out" 'Usage' "--local without tools does not print usage"

out=$(bin/in-1 --upgrade 2>&1 || true)
has "$out" "Unknown option '--upgrade'" "--upgrade is gone"

out=$(bin/in-1 -q --version)
has "$out" 'in-1 ' "--quiet preserves explicit --version output"

out=$(bin/in-1 -U jq 2>&1 || true)
has "$out" "Unknown option '-U'" "-U is gone"

out=$(bin/in-1 -R 2>&1 || true)
has "$out" "Unknown option '-R'" "-R is gone"

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

all=$(bin/in-1 --list)
is "$(bin/in-1 --list '')" "$all" '--list empty pattern lists everything'
is "$(bin/in-1 --list '^(rust|node)$')" $'node\nrust' \
  '--list supports extended regex alternation'
is "$(bin/in-1 --list '^bb [(]babashka[)]$')" 'bb (babashka)' \
  '--list matches the displayed alias label'
is "$(bin/in-1 --list '^RUST$')" '' '--list matching is case sensitive'
is "$(bin/in-1 --list -- -missing)" '' '--list allows leading dash patterns'
is "$(bin/in-1 -q --list '^rust$')" rust '--list quiet retains matches'
status=0
out=$(bin/in-1 --list '[' 2>&1) || status=$?
is "$status" 1 '--list invalid regex fails'
has "$out" 'X Invalid --list pattern' '--list reports invalid regex'
status=0
out=$(bin/in-1 --list rust node 2>&1) || status=$?
is "$status" 1 '--list rejects excess patterns'
has "$out" 'at most one pattern' '--list explains excess arguments'
status=0
out=$(bin/in-1 --show --list 2>&1) || status=$?
is "$status" 1 '--show and --list cannot be combined'
for shell in bash zsh fish; do
  command -v "$shell" >/dev/null || continue
  code=$(bin/in-1 --env "$shell" --list '^rust$')
  if [[ $shell == fish ]]; then
    out=$(fish --no-config -c "$code")
  else
    out=$("$shell" -c "$code")
  fi
  is "$out" rust "$shell: filtered --list is sourceable"
  is "$(bin/in-1 --env "$shell" --list '^no-such-tool$')" '' \
    "$shell: empty --list emits no shell code"
done

out=$(bin/in-1 --complete elvish 2>&1 || true)
has "$out" "Unsupported shell 'elvish'" "--complete rejects unknown shells"

done-testing
