#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2016
source test/init
export IN1_OFFLINE=1
pfx=$SCRATCH/persistent
tmp=$TMPDIR/in-1
clone=$pfx/share/in-1/main/cache/in-1-main
make-in1-root "$clone"

wrapper() {
  mkdir -p "${2%/*}"
  {
    printf '#!/usr/bin/env bash\n# in-1 wrapper\n'
    printf 'cmd=%q\n' "$1"
    printf 'exec "$cmd" "$@"\n'
  } > "$2"
  chmod +x "$2"
}

fake-tool() {
  mkdir -p "$1/share/$2/1/bin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$1/share/$2/1/bin/$2"
  wrapper "$1/share/$2/1/bin/$2" "$1/bin/$2"
}

wrapper "$clone/bin/in-1" "$pfx/bin/in-1"
fake-tool "$pfx" permanent-tool
fake-tool "$tmp" temporary-tool
fake-tool "$SCRATCH/explicit" explicit-tool

has "$(bin/in-1 --show)" temporary-tool 'Fresh checkout defaults to temp'
has "$("$pfx/bin/in-1" --show)" permanent-tool 'Installed command uses public prefix'
has "$(PATH="$pfx/bin:$PATH" bin/in-1 --show)" permanent-tool \
  'Bootstrap follows installed in-1 on PATH'
has "$(PREFIX=$SCRATCH/explicit "$pfx/bin/in-1" --show)" explicit-tool \
  'Environment PREFIX overrides installed prefix'
has "$(PREFIX=$pfx bin/in-1 --show PREFIX="$SCRATCH/explicit")" explicit-tool \
  'Argument PREFIX overrides environment'
has "$(PREFIX=$pfx "$pfx/bin/in-1" --temp --show)" temporary-tool \
  'Temp ignores inherited PREFIX and installed prefix'
has "$("$pfx/bin/in-1" --local --show)" permanent-tool \
  'Local keeps an existing persistent prefix'
has "$(bin/in-1 --local --show PREFIX="$SCRATCH/explicit")" explicit-tool \
  'Local accepts an explicit private prefix for Jus'

for args in '--local --temp' '--temp --local' '--temp PREFIX=/unused'; do
  status=0
  # Deliberately split the fixture arguments.
  # shellcheck disable=SC2086
  out=$(bin/in-1 $args --show 2>&1) || status=$?
  is "$status" 1 "$args is rejected"
  has "$out" 'X ' "$args prints an error"
done

export pfx clone
for shell in bash zsh fish; do
  command -v "$shell" >/dev/null || continue
  if [[ $shell == fish ]]; then
    out=$(fish --no-config -c '
      set -gx PATH $clone/bin $pfx/share/in-1/main/bin $pfx/bin $PATH
      source $clone/.rc
      command -s in-1
      in-1 --show permanent-tool
      in-1 --temp --show temporary-tool
      printf "%s\n" $PATH
    ')
  else
    out=$("$shell" -c '
      PATH=$clone/bin:$pfx/share/in-1/main/bin:$pfx/bin:$PATH
      source "$clone/.rc"
      command -v in-1 | tail -1
      type -p in-1 2>/dev/null || true
      in-1 --show permanent-tool
      in-1 --temp --show temporary-tool
      printf "%s\n" "$PATH"
    ')
  fi
  has "$out" "$pfx/bin" "$shell: public bin is used"
  hasnt "$out" "$clone/bin" "$shell: internal clone bin removed"
  hasnt "$out" "$pfx/share/in-1/main/bin" \
    "$shell: internal version bin removed"
  has "$out" permanent-tool "$shell: show follows persistent prefix"
  has "$out" temporary-tool "$shell: temp selection reaches command"
done

"$pfx/bin/in-1" -q --uninstall permanent-tool
[[ ! -e $pfx/bin/permanent-tool && -e $tmp/bin/temporary-tool ]] &&
  pass 'Uninstall uses persistent prefix without touching temp' ||
  fail 'Uninstall uses persistent prefix without touching temp'
"$pfx/bin/in-1" -q --temp --uninstall temporary-tool
[[ ! -e $tmp/bin/temporary-tool && -e $pfx/bin/in-1 ]] &&
  pass 'Temp uninstall preserves persistent in-1' ||
  fail 'Temp uninstall preserves persistent in-1'

legacy=$SCRATCH/legacy/in-1
mkdir -p "$legacy/.git"
out=$(TMPDIR=$SCRATCH/legacy bin/in-1 --temp --show 2>&1 || true)
has "$out" 'move it aside' 'Legacy temporary checkout is rejected'
if [[ -d $legacy/.git && ! -e $legacy/bootstrap ]]; then
  pass 'Legacy tree is preserved'
else
  fail 'Legacy tree is preserved'
fi

done-testing
