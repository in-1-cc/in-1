#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2016
source test/init

pfx=$SCRATCH/'prefix with spaces'
export ROOT pfx

fake-install() (  # $1=prefix $2=tool $3=version $4=command
  dir=$1/share/$2/$3
  mkdir -p "$1/bin" "$dir/bin"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$dir/bin/$4"
  chmod +x "$dir/bin/$4"
  {
    printf '#!/usr/bin/env bash\n# in-1 wrapper\n'
    printf 'cmd=%q\n' "$dir/bin/$4"
    printf 'exit 99\n'
  } > "$1/bin/$4-$3"
)

fake-install "$pfx" babashka 1.0 bb
fake-install "$pfx" babashka 2.0 bb
fake-install "$pfx" jq 1.7 jq
cp "$pfx/bin/bb-2.0" "$pfx/bin/bb"
mkdir -p "$pfx/share/unrelated/1" "$pfx/share/babashka/failed"
printf '\177ELF\0binary\n' > "$pfx/bin/foreign"
printf '#!/usr/bin/env bash\ncmd=%q\n' \
  "$pfx/share/unrelated/1/bin/tool" > "$pfx/bin/unmarked"
fake-install "$TMPDIR/in-1" session 3.0 session

expected=$(printf 'babashka\t1.0\t%s/share/babashka/1.0\n' "$pfx"
  printf 'babashka\t2.0\t%s/share/babashka/2.0\n' "$pfx"
  printf 'jq\t1.7\t%s/share/jq/1.7\n' "$pfx")
out=$(bin/in-1 --show PREFIX="$pfx")
is "$out" "$expected" 'Lists sorted tool versions once, not aliases or leftovers'
is "$(PREFIX=$pfx bin/in-1 --show)" "$expected" 'Uses PREFIX environment'
is "$(PREFIX=/nonexistent bin/in-1 --show PREFIX="$pfx")" "$expected" \
  'PREFIX argument overrides environment'
is "$(bin/in-1 -q --show PREFIX="$pfx")" "$expected" \
  'Quiet preserves explicit output'
is "$(bin/in-1 --show '^(babashka|jq)' PREFIX="$pfx")" "$expected" \
  'Supports extended regular expressions'
is "$(bin/in-1 --show 'prefix with spaces' PREFIX="$pfx")" "$expected" \
  'Matches locations as well as names'
is "$(bin/in-1 --show '/jq/1[.]7$' PREFIX="$pfx")" \
  "$(printf 'jq\t1.7\t%s/share/jq/1.7' "$pfx")" 'Filters a version path'
is "$(bin/in-1 --show BABASHKA PREFIX="$pfx")" '' 'Matching is case sensitive'
is "$(bin/in-1 --show PREFIX="$pfx" -- -missing)" '' 'Allows leading dash patterns'
is "$(bin/in-1 --show PREFIX="$SCRATCH/missing")" '' 'Missing prefix is empty'
is "$(bin/in-1 --show '' PREFIX="$pfx")" "$expected" 'Empty pattern matches all'

for args in 'invalid' 'excess' 'update' 'reset'; do
  status=0
  case $args in
    invalid) out=$(bin/in-1 --show '[' PREFIX="$SCRATCH/missing" 2>&1) || status=$?;;
    excess) out=$(bin/in-1 --show one two PREFIX="$pfx" 2>&1) || status=$?;;
    update) out=$(bin/in-1 --update --show PREFIX="$pfx" 2>&1) || status=$?;;
    reset) out=$(bin/in-1 --show --reset PREFIX="$pfx" 2>&1) || status=$?;;
  esac
  is "$status" 1 "$args: fails"
  has "$out" 'X ' "$args: reports an error"
done

before=$(find "$SCRATCH" -type f -exec cksum {} + | sort)
is "$(IN1_UPDATE=1 bin/in-1 --show PREFIX="$pfx")" "$expected" \
  'Automatic update does not run'
is "$(find "$SCRATCH" -type f -exec cksum {} + | sort)" "$before" \
  'Listing leaves files unchanged'
[[ ! -e $IN1_ROOT/makes && ! -e $IN1_ROOT/log ]] &&
  pass 'Listing does not prepare a root'

session=$(printf 'session\t3.0\t%s/in-1/share/session/3.0' "$TMPDIR")
for shell in bash zsh fish; do
  if ! command -v "$shell" >/dev/null; then
    pass "$shell unavailable; skipped"
    continue
  fi
  if [[ $shell == fish ]]; then
    out=$(fish --no-config -c 'source "$ROOT/.rc"; in-1 --show')
    override=$(fish --no-config -c \
      'source "$ROOT/.rc"; in-1 -q --show PREFIX="$pfx"')
    encoded=$(bin/in-1 --env fish --show PREFIX="$pfx")
    decoded=$(fish --no-config -c "$encoded")
  else
    out=$("$shell" -c '. "$ROOT/.rc"; in-1 --show')
    override=$("$shell" -c '. "$ROOT/.rc"; in-1 -q --show PREFIX="$pfx"')
    encoded=$(bin/in-1 --env "$shell" --show PREFIX="$pfx")
    decoded=$("$shell" -c "$encoded")
  fi
  is "$out" "$session" "$shell: shell function uses session prefix"
  is "$override" "$expected" "$shell: shell function supports quiet and PREFIX"
  is "$decoded" "$expected" "$shell: --env output is safely sourceable"
  is "$(bin/in-1 --env "$shell" --show nonexistent PREFIX="$pfx")" '' \
    "$shell: empty sourceable output stays empty"
  has "$(bin/in-1 --complete "$shell")" show "$shell: completion includes show"
done

done-testing
