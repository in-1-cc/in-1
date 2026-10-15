#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2016
source test/init

# Exercise shell output without downloads. The generator has a wrapper's
# private PATH; the caller has its own PATH plus previously leaked entries.
export ROOT SCRATCH
mkdir -p "$SCRATCH/older/bin"
cat > "$SCRATCH/older/bin/in-1" <<'...'
#!/usr/bin/env bash
[[ ${1-} != --shell-init ]] || exit 0
printf 'Older installed copy\n'
...
chmod +x "$SCRATCH/older/bin/in-1"

for shell in bash zsh fish; do
  command -v "$shell" >/dev/null || continue
  setup=$(bash -c '
    source <(perl -ne '\''print unless /^main "\$@"$/'\'' "$ROOT/bin/in-1")
    install_root=$SCRATCH/public
    PATH=$SCRATCH/private/bin:$PATH
    man_adds=""; comp_dirs=(); req_name=()
    if [[ $1 == fish ]]; then emit-session-fish
    else emit-session-sh "$1"; fi
  ' -- "$shell")
  export setup
  if [[ $shell == fish ]]; then
    out=$(fish --no-config -c '
      set -gx PATH $SCRATCH/caller/bin $SCRATCH/public/bin \
        $SCRATCH/public/share/in-1/main/cache/in-1-main/bin \
        $SCRATCH/public/share/in-1/main/bin $PATH
      eval $setup
      printf "%s\n" $PATH
    ')
  else
    out=$("$shell" -c '
      PATH=$SCRATCH/caller/bin:$SCRATCH/public/bin:$SCRATCH/public/share/in-1/main/cache/in-1-main/bin:$SCRATCH/public/share/in-1/main/bin:$PATH
      eval "$setup"
      printf "%s\n" "$PATH"
    ')
  fi
  has "$out" "$SCRATCH/public/bin" "$shell: public bin activated"
  has "$out" "$SCRATCH/caller/bin" "$shell: caller PATH preserved"
  hasnt "$out" "$SCRATCH/private/bin" "$shell: wrapper PATH stays private"
  hasnt "$out" '/share/in-1/main/' "$shell: old internal entries removed"

  # A previously sourced checkout can already be on PATH behind another copy.
  if [[ $shell == fish ]]; then
    out=$(fish --no-config -c '
      set -gx PATH $SCRATCH/older/bin $ROOT/bin $ROOT/bin $PATH
      source "$ROOT/.rc"
      printf "first=%s\n" "$PATH[1]"
      set -l before "$PATH"
      source "$ROOT/.rc"
      if test "$before" = "$PATH"
        echo stable
      end
      printf "entry=%s\n" $PATH
      in-1 --help
    ')
  else
    out=$("$shell" -c '
      PATH=$SCRATCH/older/bin:$ROOT/bin:$ROOT/bin:$PATH
      hash in-1
      source "$ROOT/.rc"
      printf "first=%s\n" "${PATH%%:*}"
      before=$PATH
      source "$ROOT/.rc"
      if test "$before" = "$PATH"; then echo stable; fi
      rest=$PATH
      while :; do
        printf "entry=%s\n" "${rest%%:*}"
        case $rest in *:*) rest=${rest#*:};; *) break;; esac
      done
      in-1 --help
    ')
  fi
  has "$out" "first=$ROOT/bin" "$shell: sourced checkout moves to PATH front"
  has "$out" 'stable' "$shell: sourcing twice leaves PATH unchanged"
  is "$(grep -Fxc "entry=$ROOT/bin" <<< "$out")" 1 \
    "$shell: sourced bin appears only once"
  has "$out" '--prune [TOOL...]' "$shell: function executes checkout command"
  hasnt "$out" 'Older installed copy' "$shell: installed copy is not selected"
done

done-testing
