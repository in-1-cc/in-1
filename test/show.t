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
touch -t 202601010101 "$pfx/bin/bb-1.0"
touch -t 202601020101 "$pfx/bin/bb-2.0"
cp "$pfx/bin/bb-2.0" "$pfx/bin/bb"
mkdir -p "$pfx/share/unrelated/1" "$pfx/share/babashka/failed"
printf '\177ELF\0binary\n' > "$pfx/bin/foreign"
printf '#!/usr/bin/env bash\ncmd=%q\n' \
  "$pfx/share/unrelated/1/bin/tool" > "$pfx/bin/unmarked"
fake-install "$TMPDIR/in-1" session 3.0 session

# Derive expected allocation from du so filesystem block sizes may vary.
size-of() {
  local usage
  usage=$(du -sh "$1")
  printf %s "${usage%%[[:space:]]*}"
}

bb1_size=$(size-of "$pfx/share/babashka/1.0")
bb2_size=$(size-of "$pfx/share/babashka/2.0")
jq_size=$(size-of "$pfx/share/jq/1.7")

expected=$(printf 'babashka  2.0  %s  %s/share/babashka/2.0\n' "$bb2_size" "$pfx"
  printf 'babashka  1.0  %s  %s/share/babashka/1.0\n' "$bb1_size" "$pfx"
  printf 'jq        1.7  %s  %s/share/jq/1.7\n' "$jq_size" "$pfx")
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
  "$(printf 'jq  1.7  %s  %s/share/jq/1.7' "$jq_size" "$pfx")" 'Filters a version path'
is "$(bin/in-1 --show BABASHKA PREFIX="$pfx")" '' 'Matching is case sensitive'
is "$(bin/in-1 --show PREFIX="$pfx" -- -missing)" '' 'Allows leading dash patterns'
is "$(bin/in-1 --show PREFIX="$SCRATCH/missing")" '' 'Missing prefix is empty'
is "$(bin/in-1 --show '' PREFIX="$pfx")" "$expected" 'Empty pattern matches all'
is "$(bin/in-1 --show bb jq PREFIX="$pfx")" "$expected" \
  'Multiple selectors accept aliases and canonical tool names'
is "$(bin/in-1 --show jq bb bb babashka PREFIX="$pfx")" "$expected" \
  'Overlapping selectors show each matching row once in alphabetical tool order'
is "$(bin/in-1 --show bb@2.0 bb@1.0 jq@1.7 PREFIX="$pfx")" "$expected" \
  'Multiple pinned selectors match exact versions'
is "$(bin/in-1 --show bb@1.0 PREFIX="$pfx")" \
  "$(printf 'babashka  1.0  %s  %s/share/babashka/1.0' "$bb1_size" "$pfx")" \
  'Single pinned alias selects only its exact version'
is "$(bin/in-1 --show bb PREFIX="$pfx")" \
  "$(bin/in-1 --show '^babashka' PREFIX="$pfx")" \
  'Single alias selects every version of its tool'
is "$(bin/in-1 --show bb@missing no-such-tool PREFIX="$pfx")" '' \
  'Uninstalled selectors produce a successful empty listing'

for args in 'invalid' 'version' 'mixed' 'update' 'reset'; do
  status=0
  case $args in
    invalid) out=$(bin/in-1 --show '[' PREFIX="$SCRATCH/missing" 2>&1) || status=$?;;
    version) out=$(bin/in-1 --show bb@../1 PREFIX="$pfx" 2>&1) || status=$?;;
    mixed) out=$(bin/in-1 --show bb '^jq' PREFIX="$pfx" 2>&1) || status=$?;;
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

session=$(printf 'session  3.0  %s  %s/in-1/share/session/3.0' \
  "$(size-of "$TMPDIR/in-1/share/session/3.0")" "$TMPDIR")
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
    selected=$(fish --no-config -c \
      'source "$ROOT/.rc"; in-1 --show bb@2.0 bb@1.0 jq PREFIX="$pfx"')
    encoded=$(bin/in-1 --env fish --show bb jq PREFIX="$pfx")
    selected_env=$(fish --no-config -c "$encoded")
  else
    out=$("$shell" -c '. "$ROOT/.rc"; in-1 --show')
    override=$("$shell" -c '. "$ROOT/.rc"; in-1 -q --show PREFIX="$pfx"')
    encoded=$(bin/in-1 --env "$shell" --show PREFIX="$pfx")
    decoded=$("$shell" -c "$encoded")
    selected=$("$shell" -c \
      '. "$ROOT/.rc"; in-1 --show bb@2.0 bb@1.0 jq PREFIX="$pfx"')
    encoded=$(bin/in-1 --env "$shell" --show bb jq PREFIX="$pfx")
    selected_env=$("$shell" -c "$encoded")
  fi
  is "$out" "$session" "$shell: shell function uses session prefix"
  is "$override" "$expected" "$shell: shell function supports quiet and PREFIX"
  is "$decoded" "$expected" "$shell: --env output is safely sourceable"
  is "$selected" "$expected" "$shell: function supports multiple pinned selectors"
  is "$selected_env" "$expected" "$shell: multiple selectors work through --env"
  is "$(bin/in-1 --env "$shell" --show nonexistent PREFIX="$pfx")" '' \
    "$shell: empty sourceable output stays empty"
  has "$(bin/in-1 --complete "$shell")" show "$shell: completion includes show"
done

aligned=$SCRATCH/aligned
fake-install "$aligned" babashka 1.13.220 bb
fake-install "$aligned" in-1 main in-1
dd if=/dev/zero of="$aligned/share/babashka/1.13.220/payload" \
  bs=1024 count=256 >/dev/null 2>&1
big_size=$(size-of "$aligned/share/babashka/1.13.220")
small_size=$(size-of "$aligned/share/in-1/main")
size_width=${#big_size}
if [[ ${#small_size} -gt $size_width ]]; then size_width=${#small_size}; fi
expected=$(printf 'babashka  1.13.220  %*s  %s/share/babashka/1.13.220\n' \
  "$size_width" "$big_size" "$aligned"
  printf 'in-1      main      %*s  %s/share/in-1/main\n' \
    "$size_width" "$small_size" "$aligned")
is "$(bin/in-1 --show PREFIX="$aligned")" "$expected" \
  'Aligns name and version columns left and different-sized disk usage right'
has "$(bin/in-1 --show "$big_size"$'\t' PREFIX="$aligned")" babashka \
  'Size is included in the searchable row'

# These globals are used by the sourced renderer.
# shellcheck disable=SC2034
styled-show() (
  # Exercise rendering with terminal styling enabled, without needing a PTY.
  # shellcheck disable=SC1090
  source <(perl -ne 'print unless /^main "\$@"$/' "$ROOT/bin/in-1")
  self_root=$ROOT
  prefix=$1 show_color=1
  shift
  do-show "$@"
)

styled=$SCRATCH/styled
fake-install "$styled" babashka 1.9 bb
fake-install "$styled" babashka 1.10 bb
touch -t 202601020101 "$styled/bin/bb-1.9"
touch -t 202601010101 "$styled/bin/bb-1.10"
ln -s bb-1.9 "$styled/bin/bb"
out=$(styled-show "$styled")
has "$out" $'\033[90mbabashka  \033[1;39m1.10\033[22m\033[90m' \
  'Newest inactive version uses bold normal text, then restores grey'
has "${out%%$'\n'*}" 'babashka  1.9 ' \
  'Recently installed older version is first'
hasnt "${out%%$'\n'*}" $'\033[' 'Selected older version has normal brightness'
is "$(printf '%s' "$out" | perl -pe 's/\e\[[0-9;]*m//g')" \
  "$(bin/in-1 --show PREFIX="$styled")" \
  'Styling preserves alignment and plain row content'
filtered=$(styled-show "$styled" '/1[.]9$')
hasnt "$filtered" $'\033[1;39m' \
  'Filtering does not promote an older version to newest'
hasnt "$filtered" $'\033[90m' 'Filtered selected version remains at normal brightness'
filtered=$(styled-show "$styled" '/1[.]10$')
has "$filtered" $'\033[90m' 'Hidden selected version still identifies inactive rows'
is "$(styled-show "$styled" bb@1.9)" \
  "$(styled-show "$styled" '/1[.]9$')" \
  'Pinned selector preserves newest and selected status from hidden versions'

rm "$styled/bin/bb"
ln -s bb-1.10 "$styled/bin/bb"
out=$(styled-show "$styled")
has "$out" $'\033[90mbabashka  1.9 ' 'Inactive version is grey'
has "$out" $'babashka  \033[1;39m1.10\033[22m' 'Selected newest version is bold'

library=$SCRATCH/library
mkdir -p "$library/share/libys/0.3.1/lib"
printf library > "$library/share/libys/0.3.1/lib/libys.so"
printf 'in-1 library\nlib/libys.so\n' \
  > "$library/share/libys/0.3.1/.in-1-installed"
expected=$(printf 'libys  0.3.1  %s  %s/share/libys/0.3.1' \
  "$(size-of "$library/share/libys/0.3.1")" "$library")
is "$(bin/in-1 --show PREFIX="$library")" "$expected" \
  'Library installs also report disk usage'

shown-versions() {  # $1=prefix; remaining args=show pattern (optional)
  local pfx=$1 _tool version _rest
  shift
  bin/in-1 --show PREFIX="$pfx" "$@" |
    while read -r _tool version _rest; do printf '%s\n' "$version"; done
}

ordered=$SCRATCH/ordered
for version in 1.0 2.0 3.0; do
  fake-install "$ordered" babashka "$version" bb
  printf 'in-1 command\n%s/bin/bb\n' "$ordered" \
    > "$ordered/share/babashka/$version/.in-1-installed"
done
touch -t 202601030101 "$ordered/share/babashka/1.0/.in-1-installed"
touch -t 202601010101 "$ordered/share/babashka/2.0/.in-1-installed"
touch -t 202601020101 "$ordered/share/babashka/3.0/.in-1-installed"
touch -t 202601050101 "$ordered/share/babashka/2.0"
touch -t 202601060101 "$ordered/bin/bb-2.0"
is "$(shown-versions "$ordered")" $'1.0\n3.0\n2.0' \
  'Completion timestamps determine order, ignoring directory and wrapper times'
is "$(shown-versions "$ordered" '/(1[.]0|2[.]0)$')" $'1.0\n2.0' \
  'Filtering preserves installation order'
touch -t 202601070101 "$ordered/share/babashka/2.0/.in-1-installed"
is "$(shown-versions "$ordered")" $'2.0\n1.0\n3.0' \
  'Reinstalling a version moves it to the top'
touch -t 202601070101 "$ordered/share/babashka/3.0/.in-1-installed"
is "$(shown-versions "$ordered")" $'2.0\n3.0\n1.0' \
  'Timestamp ties retain deterministic version-name order'

mkdir -p "$library/share/libys/0.3.0/lib"
printf library > "$library/share/libys/0.3.0/lib/libys.so"
printf 'in-1 library\nlib/libys.so\n' \
  > "$library/share/libys/0.3.0/.in-1-installed"
touch -t 202601010101 "$library/share/libys/0.3.1/.in-1-installed"
touch -t 202601020101 "$library/share/libys/0.3.0/.in-1-installed"
is "$(shown-versions "$library")" $'0.3.0\n0.3.1' \
  'Library versions also follow installation order'
is "$(shown-versions "$library" libys@0.3.1 libys@0.3.0)" $'0.3.0\n0.3.1' \
  'Pinned library selectors retain installation order'

literal=$SCRATCH/literal
fake-install "$literal" literal 1.0+build literal
fake-install "$literal" literal 1x0build literal
is "$(shown-versions "$literal" literal@1.0+build)" 1.0+build \
  'Pinned versions treat dots and plus signs literally'
fake-install "$literal" ys 1 ys
fake-install "$literal" yamlscript 2 ys
is "$(shown-versions "$literal" ys@1)" 1 \
  'Installed direct tool takes precedence over alias metadata'

done-testing
