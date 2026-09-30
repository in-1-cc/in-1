#!/usr/bin/env bash

# Persistent completion and manual support needs no tool execution.

# shellcheck disable=SC1091
source test/init

pfx=$SCRATCH/pfx
active=$pfx/share/in-1/active
mkdir -p "$active"

fake-support() {  # $1=tool $2=version
  local tool=$1 version=$2 idir upper
  idir=$pfx/share/$tool/$version
  upper=$(printf '%s' "$tool" | tr '[:lower:]' '[:upper:]')
  mkdir -p \
    "$idir/share/bash-completion/completions" \
    "$idir/share/zsh/site-functions" \
    "$idir/share/fish/vendor_completions.d" \
    "$idir/share/man/man1" \
    "$idir/bin"
  printf 'in-1 command\nbin/%s\n' "$tool" > "$idir/.in-1-installed"
  printf 'IN1_%s_COMPLETION=loaded\n' "$upper" \
    > "$idir/share/bash-completion/completions/$tool"
  touch "$idir/share/zsh/site-functions/_$tool"
  touch "$idir/share/fish/vendor_completions.d/$tool.fish"
  printf '#!/usr/bin/env bash\ntouch %q\n' "$SCRATCH/tool-ran" \
    > "$idir/bin/$tool"
  chmod +x "$idir/bin/$tool"
  ln -s "../../$tool/$version" "$active/$tool"
}

fake-support gloat 1.0
touch "$pfx/share/gloat/1.0/share/man/man1/gloat.1"

old=$pfx/share/gloat/0.9
mkdir -p "$old/share/bash-completion/completions"
printf 'OLD_GLOAT_COMPLETION=loaded\n' \
  > "$old/share/bash-completion/completions/gloat"

out=$(PREFIX=$pfx bin/in-1 --shell-init bash)
has "$out" "$pfx/share/gloat/1.0/share/bash-completion/completions/gloat" \
  'Bash init sources the active Gloat completion'
has "$out" "$pfx/share/gloat/1.0/share/man" \
  'Bash init adds the active Gloat manual directory'
hasnt "$out" "$old" 'Shell init ignores inactive versions'

out=$(PREFIX=$pfx bash -c '
  eval "$(bin/in-1 --shell-init bash)"
  printf "%s\n%s\n" "$IN1_GLOAT_COMPLETION" "$MANPATH"
')
has "$out" loaded 'Bash completion file is usable'
has "$out" "$pfx/share/gloat/1.0/share/man" \
  'Bash MANPATH setup is usable'

out=$(PREFIX=$pfx bin/in-1 --shell-init zsh)
has "$out" "$pfx/share/gloat/1.0/share/zsh/site-functions" \
  'Zsh init prepends the active completion directory'

out=$(PREFIX=$pfx bin/in-1 --shell-init fish)
has "$out" "$pfx/share/gloat/1.0/share/fish/vendor_completions.d" \
  'Fish init prepends the active completion directory'
has "$out" "$pfx/share/gloat/1.0/share/man" \
  'Fish init adds the active manual directory'

if [[ -e $SCRATCH/tool-ran ]]; then
  fail 'Shell init does not execute installed tools'
else
  pass 'Shell init does not execute installed tools'
fi

PREFIX=$pfx bin/in-1 -q --uninstall gloat
if [[ ! -L $active/gloat ]]; then
  pass 'Uninstall removes active shell support'
else
  fail 'Uninstall removes active shell support'
fi

done-testing
