#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2016
source test/init

# Exercise shell output without downloads. The generator has a wrapper's
# private PATH; the caller has its own PATH plus previously leaked entries.
export ROOT SCRATCH
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
done

done-testing
