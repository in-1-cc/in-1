#!/usr/bin/env bash

# shellcheck disable=SC1091
source test/init
export IN1_OFFLINE=1
pfx=$TMPDIR/in-1

fake-install() (
  dir=$pfx/share/$1/$2
  mkdir -p "$pfx/bin" "$dir/bin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$dir/bin/$1"
  {
    printf '#!/usr/bin/env bash\n# in-1 wrapper\n'
    printf 'cmd=%q\n' "$dir/bin/$1"
    printf 'exec "$cmd" "$@"\n'
  } > "$pfx/bin/$1-$2"
  ln -sfn "$1-$2" "$pfx/bin/$1"
)

seed() {
  fake-install foo 1
  fake-install foo 2
  fake-install in-1 current
  mkdir -p "$IN1_ROOT/log" "$IN1_ROOT/cache" "$IN1_ROOT/local"
  mkdir -p "$pfx/share/foreign/1" "$pfx/share/empty"
  touch "$IN1_ROOT/log/x" "$IN1_ROOT/cache/y" "$IN1_ROOT/local/legacy"
  touch "$pfx/bin/foreign" "$pfx/share/foreign/1/keep"
}

check-reset() {
  if [[ ! -e $pfx/bin/foo-1 && ! -e $pfx/bin/foo-2 &&
        ! -L $pfx/bin/foo && ! -e $pfx/share/foo ]]; then
    pass "$1: managed versions and wrappers removed"
  else fail "$1: managed versions and wrappers removed"; fi
  if [[ -e $pfx/bin/in-1-current && -L $pfx/bin/in-1 &&
        -e $pfx/share/in-1/current ]]; then
    pass "$1: in-1 installation preserved"
  else fail "$1: in-1 installation preserved"; fi
  if [[ -e $pfx/bin/foreign && -e $pfx/share/foreign/1/keep &&
        -d $pfx/share/empty && -e $IN1_ROOT/local/legacy ]]; then
    pass "$1: unrelated files and legacy installs preserved"
  else fail "$1: unrelated files and legacy installs preserved"; fi
  if [[ ! -e $IN1_ROOT/cache && ! -e $IN1_ROOT/log && ! -e $IN1_ROOT/makes ]]; then
    pass "$1: state cleared"
  else fail "$1: state cleared"; fi
  if [[ -x $IN1_ROOT/bin/in-1 ]]; then pass "$1: source checkout preserved"
  else fail "$1: source checkout preserved"; fi
}

bin/in-1 --list >/dev/null
seed
out=$(bin/in-1 --reset 2>&1)
has "$out" "removed managed tools from '$pfx' (kept in-1)" 'Reset summary'
check-reset reset

seed
is "$(bin/in-1 -q --reset 2>&1)" '' 'Quiet reset prints nothing'
check-reset quiet

seed
out=$(bin/in-1 --reset --list 2>/dev/null)
has "$out" rust 'Reset continues to list'
[[ -d $IN1_ROOT/makes && ! -e $IN1_ROOT/cache ]] &&
  pass 'Listing recreates Makes after reset'

seed
out=$(bin/in-1 --reset no-such-tool 2>&1 || true)
has "$out" 'reset: removed' 'Reset precedes installation'
has "$out" 'Unknown tool' 'Installation runs after reset'

seed
is "$(bin/in-1 --env bash --reset 2>/dev/null)" '' 'Env reset emits no shell code'
check-reset env

seed
notstate=$SCRATCH/notstate
mkdir -p "$notstate/cache"
touch "$notstate/cache/keep"
out=$(IN1_ROOT=$notstate bin/in-1 --reset 2>&1 || true)
has "$out" 'not an in-1 state directory' 'Unrecognized state rejected'
[[ -e $notstate/cache/keep && -e $pfx/bin/foo-1 ]] &&
  pass 'Refusal happens before any tool deletion'

# --temp ignores inherited persistent state and PREFIX.
out=$(PREFIX=$SCRATCH/persistent IN1_ROOT=$notstate bin/in-1 --temp --reset 2>&1)
has "$out" "removed managed tools from '$pfx'" 'Temp reset selects temporary tools'
[[ -e $notstate/cache/keep ]] && pass 'Temp reset preserves persistent state'

seed
outside=$SCRATCH/external-cache
mkdir -p "$outside"
touch "$outside/keep"
IN1_CACHE=$outside bin/in-1 -q --reset
[[ -e $outside/keep ]] && pass 'External download cache preserved'

done-testing
