#!/usr/bin/env bash

# -R/--reset removes makes/, log/, local/ and cache/ from the root and
# then carries on with whatever else was asked.  Offline: the makes
# clone comes from the local repo.

source test/init

export IN1_OFFLINE=1

seed-root() {
  mkdir -p "$IN1_ROOT/log" "$IN1_ROOT/local/bin" "$IN1_ROOT/cache"
  touch "$IN1_ROOT/log/x.log" "$IN1_ROOT/local/bin/x" "$IN1_ROOT/cache/y"
}

gone() {  # $1=label
  local d missing=1
  for d in makes log local cache; do
    [[ -e $IN1_ROOT/$d ]] && missing=''
  done
  if [[ $missing ]]; then
    pass "$1: makes/, log/, local/ and cache/ are gone"
  else
    fail "$1: makes/, log/, local/ and cache/ are gone"
  fi
  if [[ -x $IN1_ROOT/bin/in-1 && -e $IN1_ROOT/share ]]; then
    pass "$1: the clone itself stays"
  else
    fail "$1: the clone itself stays"
  fi
}

# Get a makes clone in place, then seed the other dirs
bin/in-1 --list >/dev/null
seed-root
[[ -d $IN1_ROOT/makes && -e $IN1_ROOT/cache/y ]] ||
  die "seeding the root failed"

out=$(bin/in-1 -R 2>&1 && echo "status=$?" || echo "status=$?")
has "$out" "reset: removed makes/, log/, local/ and cache/ from '$IN1_ROOT'" \
  "bare -R: reports what it removed"
has "$out" 'status=0' "bare -R: returns 0"
gone "bare -R"

# --reset resets, then lists (makes is cloned again)
seed-root
out=$(bin/in-1 --reset --list 2>/dev/null)
has "$out" 'rust' "-R --list: lists tools"
if [[ -d $IN1_ROOT/makes && ! -e $IN1_ROOT/cache/y ]]; then
  pass "-R --list: fresh makes clone, cache gone"
else
  fail "-R --list: fresh makes clone, cache gone"
fi

# -R with a tool resets first, then goes on to the install
seed-root
out=$(bin/in-1 -R no-such-tool 2>&1 || true)
has "$out" 'reset: removed' "-R TOOL: resets first"
has "$out" 'Unknown tool' "-R TOOL: then continues"
if [[ ! -e $IN1_ROOT/local/bin/x ]]; then
  pass "-R TOOL: seeded install is gone"
else
  fail "-R TOOL: seeded install is gone"
fi

# -R via --env with no tool prints nothing and succeeds
seed-root
out=$(
  bin/in-1 --env bash -R 2>/dev/null && echo "status=$?" || echo "status=$?"
)
is "$out" 'status=0' "--env bash -R: no output, returns 0"
gone "--env bash -R"

# A root that is not an in-1 clone is refused, untouched
notclone=$SCRATCH/notclone
mkdir -p "$notclone/local/bin" "$notclone/cache"
touch "$notclone/cache/y"
out=$(
  IN1_ROOT=$notclone bin/in-1 -R 2>&1 && echo "status=$?" ||
    echo "status=$?"
)
has "$out" 'not an in-1 clone' "not a clone: refused"
has "$out" 'status=1' "not a clone: returns 1"
if [[ -e $notclone/cache/y && -d $notclone/local/bin ]]; then
  pass "not a clone: nothing removed"
else
  fail "not a clone: nothing removed"
fi

done-testing
