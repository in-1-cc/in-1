#!/usr/bin/env bash

# Offline pruning fixtures use the public wrapper and completion marker formats.
# shellcheck disable=SC1091,SC2016
source test/init

pfx=$SCRATCH/'prefix with spaces'
export pfx ROOT

fake-install() {  # $1=tool $2=version $3=primary command (optional)
  local tool=$1 version=$2 primary=${3:-$1} dir
  dir=$pfx/share/$tool/$version
  mkdir -p "$pfx/bin" "$dir/bin"
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" %q\n' "$version" \
    > "$dir/bin/$primary"
  chmod +x "$dir/bin/$primary"
  {
    printf '#!/usr/bin/env bash\n# in-1 wrapper\n'
    printf 'cmd=%q\n' "$dir/bin/$primary"
    printf 'exec "$cmd" "$@"\n'
  } > "$pfx/bin/$primary-$version"
  chmod +x "$pfx/bin/$primary-$version"
  rm -f "$pfx/bin/$primary"
  ln -s "$primary-$version" "$pfx/bin/$primary"
  printf 'in-1 command\n%s/bin/%s\n' "$pfx" "$primary" \
    > "$dir/.in-1-installed"
}

fake-library() {  # $1=version $2=marker timestamp
  local dir=$pfx/share/libys/$1
  mkdir -p "$dir/lib"
  printf library > "$dir/lib/libys.so"
  printf 'in-1 library\nlib/libys.so\n' > "$dir/.in-1-installed"
  touch -t "$2" "$dir/.in-1-installed"
}

prune() { bin/in-1 --prune "$@" PREFIX="$pfx"; }

fake-install foo 1
fake-install foo 2
cp "$pfx/bin/foo-1" "$pfx/bin/old-helper"
printf '\177ELF\0foreign\n' > "$pfx/bin/foreign"
printf 'foreign\n' > "$pfx/bin/foo-foreign"
mkdir -p "$pfx/share/foo/failed" "$pfx/share/unrelated/1"
touch "$pfx/share/foo/failed/keep" "$pfx/share/unrelated/1/keep"
mkdir -p "$pfx/share/foo/1/cache/pkg/mod/example"
touch "$pfx/share/foo/1/cache/pkg/mod/example/file"
chmod -R -w "$pfx/share/foo/1/cache"
before=$(cksum "$pfx/bin/foo-2" "$pfx/share/foo/2/.in-1-installed")
out=$(prune foo 2>&1)
has "$out" 'Pruned foo: kept 2, removed 1 version' \
  'Upgrade keeps current version'
if [[ ! -e $pfx/share/foo/1 && ! -e $pfx/bin/foo-1 &&
   ! -e $pfx/bin/old-helper ]]; then
  pass 'Old tree and all its wrappers removed'
else
  fail 'Old tree and all its wrappers removed'
fi
is "$("$pfx/bin/foo")" 2 'Retained primary command still runs'
is "$(cksum "$pfx/bin/foo-2" "$pfx/share/foo/2/.in-1-installed")" "$before" \
  'Retained wrapper and completion marker are unchanged'
if [[ -f $pfx/bin/foreign && -f $pfx/bin/foo-foreign &&
   -e $pfx/share/foo/failed/keep && -e $pfx/share/unrelated/1/keep ]]; then
  pass 'Foreign files and unreferenced leftovers preserved'
else
  fail 'Foreign files and unreferenced leftovers preserved'
fi
has "$(prune foo 2>&1)" 'removed 0 versions' 'Repeated prune succeeds'

fake-install foo 0.5
out=$(prune foo 2>&1)
has "$out" 'kept 0.5' 'Downgrade keeps selected older version'
if [[ ! -d $pfx/share/foo/2 ]]; then
  pass 'Downgrade removes higher version'
else
  fail 'Downgrade removes higher version'
fi
fake-install foo 3-alpha
has "$(prune foo 2>&1)" 'kept 3-alpha' 'Prerelease stays selected'
fake-install foo 4
fake-install foo 3-alpha
has "$(prune foo 2>&1)" 'kept 3-alpha' 'Reinstalling older version selects it'

fake-install babashka 1 bb
fake-install babashka 2 bb
out=$(prune bb babashka bb 2>&1)
is "$(printf '%s\n' "$out" | grep -c 'Pruned babashka:')" 1 \
  'Aliases resolve and duplicate tool requests are pruned once'
is "$("$pfx/bin/bb")" 2 'Alias primary command is retained'
fake-install ys 1
fake-install ys 2
has "$(prune ys 2>&1)" 'Pruned ys:' 'Direct installed tool wins over alias'

fake-install legacy 1
fake-install legacy 2
rm "$pfx/share/legacy/1/.in-1-installed" \
  "$pfx/share/legacy/2/.in-1-installed" "$pfx/bin/legacy"
cp "$pfx/bin/legacy-1" "$pfx/bin/legacy"
has "$(prune legacy 2>&1)" 'kept 1' \
  'Legacy regular primary wrapper selects version'
is "$("$pfx/bin/legacy")" 1 'Legacy primary is preserved'

fake-install unclear 1
fake-install unclear 2
rm "$pfx/bin/unclear" "$pfx/share/unclear/1/.in-1-installed" \
  "$pfx/share/unclear/2/.in-1-installed"
status=0
out=$(prune unclear 2>&1) || status=$?
is "$status" 1 'Legacy installs without a current wrapper are ambiguous'
if [[ -d $pfx/share/unclear/1 && -d $pfx/share/unclear/2 ]]; then
  pass 'Ambiguous legacy installs stay intact'
else
  fail 'Ambiguous legacy installs stay intact'
fi
ln -s unclear-1 "$pfx/bin/unclear"
prune unclear >/dev/null 2>&1

fake-install noexec 1
fake-install noexec 2
{
  printf '#!/usr/bin/env bash\n# in-1 wrapper\n'
  printf 'touch %q\n' "$SCRATCH/tool-ran"
  printf 'cmd=%q\nexec "$cmd" "$@"\n' "$pfx/share/noexec/2/bin/noexec"
} > "$pfx/bin/noexec-2"
prune noexec >/dev/null 2>&1
if [[ ! -e $SCRATCH/tool-ran ]]; then
  pass 'Pruning reads wrappers without executing their contents'
else
  fail 'Pruning reads wrappers without executing their contents'
fi

fake-install rust 1 cargo
fake-install rust 2 rustc
touch -t 202601010101 "$pfx/share/rust/1/.in-1-installed"
touch -t 202601020101 "$pfx/share/rust/2/.in-1-installed"
has "$(prune rust 2>&1)" 'kept 2' \
  'Different alias primaries fall back to successful-install timestamps'

fake-library 9 202601010101
fake-library 1-alpha 202601020101
touch -t 202601030101 "$pfx/share/libys/9"
has "$(prune libys 2>&1)" 'kept 1-alpha' \
  'Libraries use completion timestamps, ignoring version and directory times'
if [[ ! -d $pfx/share/libys/9 ]]; then
  pass 'Inactive library removed'
else
  fail 'Inactive library removed'
fi
fake-library 8 202601020101
status=0
out=$(prune libys 2>&1) || status=$?
is "$status" 1 'Tied library timestamps fail safely'
has "$out" 'Cannot determine the current version' 'Ambiguity is explained'
if [[ -d $pfx/share/libys/8 && -d $pfx/share/libys/1-alpha ]]; then
  pass 'Ambiguous library versions are unchanged'
else
  fail 'Ambiguous library versions are unchanged'
fi
touch -t 202601030101 "$pfx/share/libys/1-alpha/.in-1-installed"

fake-install gloat 1
fake-install gloat 2
fake-install gloat 1
mkdir -p "$pfx/share/in-1/active"
ln -s ../../gloat/1 "$pfx/share/in-1/active/gloat"
has "$(prune gloat 2>&1)" 'kept 1' 'Active registry version is retained'
if [[ -d $pfx/share/in-1/active/gloat ]]; then
  pass 'Active support link remains valid'
else
  fail 'Active support link remains valid'
fi

fake-install in-1 old
fake-install in-1 main
mkdir -p "$pfx/share/in-1/local/cache" "$pfx/share/in-1/local/log" \
  "$pfx/share/in-1/local/makes"
touch "$pfx/share/in-1/local/cache/keep" "$pfx/share/in-1/local/log/keep"
has "$(IN1_UPDATE=1 prune 2>&1)" 'Pruned in-1: kept main' \
  'Bare prune includes in-1 and ignores automatic updates'
if [[ ! -d $pfx/share/in-1/old && -d $pfx/share/in-1/main &&
   -d $pfx/share/in-1/local/makes && -d $pfx/share/in-1/active/gloat &&
   -f $pfx/share/in-1/local/cache/keep &&
   -f $pfx/share/in-1/local/log/keep ]]; then
  pass 'in-1 state and support preserved'
else
  fail 'in-1 state and support preserved'
fi
if [[ ! -d $IN1_ROOT/makes && ! -d $IN1_ROOT/log ]]; then
  pass 'Pruning never initializes Makes or logs'
else
  fail 'Pruning never initializes Makes or logs'
fi

fake-install foo 5
status=0
out=$(prune missing foo 2>&1) || status=$?
is "$status" 1 'Missing explicit tool fails overall'
has "$out" "'missing' has no managed installation" 'Missing tool is reported'
has "$out" 'Pruned foo:' 'Other requested tools still get pruned'

for flag in --reset --update --uninstall --show --list --shell-init; do
  for order in before after; do
    args=(--prune "$flag")
    [[ $order != before ]] || args=("$flag" --prune)
    # --shell-init requires a shell argument next to its flag.
    if [[ $flag == --shell-init ]]; then
      args=(--prune --shell-init bash)
      [[ $order != before ]] || args=(--shell-init bash --prune)
    fi
    status=0
    out=$(bin/in-1 "${args[@]}" PREFIX="$pfx" 2>&1) || status=$?
    is "$status" 1 "$flag $order prune is rejected"
    has "$out" 'cannot be combined' "$flag $order reports the conflict"
  done
done
for arg in FOO-VERSION=1 ../foo; do
  status=0
  out=$(prune "$arg" 2>&1) || status=$?
  is "$status" 1 "Invalid argument $arg is rejected"
done
is "$(bin/in-1 --prune PREFIX="$SCRATCH/empty" 2>&1)" '' \
  'Empty prefix succeeds quietly'
is "$(bin/in-1 -q --prune foo PREFIX="$pfx" 2>&1)" '' \
  'Quiet suppresses successful summaries'

fake-install foo 6
outside=$SCRATCH/outside
mkdir -p "$outside/1"
touch "$outside/1/keep"
ln -s "$outside" "$pfx/share/linked"
ln -s "$outside/1" "$pfx/share/foo/linked-version"
status=0
out=$(prune linked 2>&1) || status=$?
is "$status" 1 'Explicit linked tool is rejected'
prune foo >/dev/null 2>&1
if [[ -f $outside/1/keep && -L $pfx/share/foo/linked-version ]]; then
  pass 'Linked tool and version targets are untouched'
else
  fail 'Linked tool and version targets are untouched'
fi
for name in bin share; do
  linked=$SCRATCH/linked-$name
  mkdir -p "$linked"
  ln -s "$outside" "$linked/$name"
  status=0
  out=$(bin/in-1 --prune PREFIX="$linked" 2>&1) || status=$?
  is "$status" 1 "Linked public $name directory is rejected"
done
fake-install foo 7
status=0
out=$(IN1_ROOT=$pfx/share/foo/6/state prune foo 2>&1) || status=$?
is "$status" 1 'State inside a discarded version prevents pruning'
if [[ -d $pfx/share/foo/6 ]]; then
  pass 'Protected state version remains'
else
  fail 'Protected state version remains'
fi
status=0
out=$(IN1_CACHE=$pfx/share/foo/6/cache prune foo 2>&1) || status=$?
is "$status" 1 'External cache inside a discarded version prevents pruning'

mkdir -p "$pfx/share/foo/6/state"
ln -s "$pfx/share/foo/6/state" "$SCRATCH/linked-state"
status=0
out=$(IN1_ROOT=$SCRATCH/linked-state prune foo 2>&1) || status=$?
is "$status" 1 'State reached through a symlink is protected'

# Run the implementation from an old in-1 version that it will itself delete.
fake-install in-1 old
old_clone=$pfx/share/in-1/old/cache/in-1-old
mkdir -p "$old_clone/bin" "$old_clone/share"
cp bin/in-1 "$old_clone/bin/in-1"
cp share/tools.mk "$old_clone/share/tools.mk"
{
  printf '#!/usr/bin/env bash\n# in-1 wrapper\n'
  printf 'cmd=%q\nexec "$cmd" "$@"\n' "$old_clone/bin/in-1"
} > "$pfx/bin/in-1-old"
ln -sfn in-1-main "$pfx/bin/in-1"
out=$("$pfx/bin/in-1-old" --prune in-1 bb foo PREFIX="$pfx" 2>&1)
has "$out" 'Pruned in-1: kept main' 'Old running in-1 can prune itself'
has "$out" 'Pruned babashka:' 'Metadata remains available for later tools'
if [[ ! -d $pfx/share/in-1/old && ! -e $pfx/bin/in-1-old ]]; then
  pass 'Old executing copy and its wrapper are removed'
else
  fail 'Old executing copy and its wrapper are removed'
fi

# Restore the real command before testing shell-function dispatch.
rm "$pfx/bin/in-1"
export PREFIX=$pfx
for shell in bash zsh fish; do
  if ! command -v "$shell" >/dev/null; then
    pass "$shell unavailable; skipped"
    continue
  fi
  fake-install foo 8
  if [[ $shell == fish ]]; then
    out=$(fish --no-config -c 'source "$ROOT/.rc"; in-1 --prune foo' 2>&1)
  else
    out=$("$shell" -c '. "$ROOT/.rc"; in-1 --prune foo' 2>&1)
  fi
  has "$out" 'kept 8' "$shell function runs prune directly"
  is "$(bin/in-1 -q --env "$shell" --prune foo)" '' \
    "$shell env prune emits no shell code"
  has "$(bin/in-1 --complete "$shell")" prune "$shell completion offers prune"
  status=0
  if [[ $shell == fish ]]; then
    out=$(TMPDIR=$SCRATCH/bootstrap-reject fish --no-config -c \
      'source ./rc --prune foo' 2>&1) || status=$?
  else
    out=$(TMPDIR=$SCRATCH/bootstrap-reject "$shell" -c \
      'source ./rc --prune foo' 2>&1) || status=$?
  fi
  is "$status" 1 "$shell bootstrap rejects prune"
  has "$out" '--prune must be run by the in-1 command' \
    "$shell bootstrap explains prune rejection"
done
if [[ ! -e $SCRATCH/bootstrap-reject ]]; then
  pass 'Bootstrap rejects pruning before creating directories or cloning'
else
  fail 'Bootstrap rejects pruning before creating directories or cloning'
fi
unset PREFIX

session=$TMPDIR/in-1
persistent=$pfx
pfx=$session
fake-install session 1
fake-install session 2
pfx=$persistent
out=$(PREFIX=$persistent IN1_ROOT=$SCRATCH/persistent-state \
  bin/in-1 --temp --prune 2>&1)
has "$out" 'Pruned session: kept 2' 'Temp selects temporary installations'
if [[ -d $persistent/share/foo/8 ]]; then
  pass 'Temp preserves persistent installations'
else
  fail 'Temp preserves persistent installations'
fi
out=$(PREFIX=$pfx/bin bin/in-1 --local --prune foo 2>&1)
is "$(grep -c 'Pruned foo:' <<< "$out")" 1 \
  'Local placement and normalized environment prefix are supported'
status=0
out=$(bin/in-1 --temp --prune PREFIX="$pfx" 2>&1) || status=$?
is "$status" 1 'Temp rejects an explicit PREFIX argument'

has "$(bin/in-1 --help)" '--prune [TOOL...]' 'Help documents pruning'
done-testing
