#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2016
source test/init

ambient=$SCRATCH/ambient
mkdir -p "$ambient/bin" "$ambient/share/in-1/main"
cat > "$ambient/bin/in-1" <<'...'
#!/usr/bin/env bash
# in-1 wrapper
exit 99
...
chmod +x "$ambient/bin/in-1"

# Reinitialize a separate child test with a contaminated caller environment.
out=$(PATH="$ambient/bin:$PATH" PREFIX="$ambient" IN1_TOOLS=outside \
  bash -c '
    source test/init
    echo "command=$(type -P in-1)"
    echo "prefix=${PREFIX-unset}"
    echo "tools=${IN1_TOOLS-unset}"
    echo "config=$ZDOTDIR"
    bin/in-1 --show
  ' "$ROOT/test/isolation-child.t")
has "$out" '/isolation-child/launcher/bin/in-1' \
  'Test checkout shadows ambient in-1'
has "$out" 'prefix=unset' 'Caller prefix is cleared'
has "$out" 'tools=unset' 'Caller installed-tool list is cleared'
has "$out" '/isolation-child/zsh-config' 'Zsh configuration is isolated'
hasnt "$out" "$ambient" 'Ambient installation is not discovered'
is "$(wc -l < "$ambient/bin/in-1" | tr -d ' ')" 3 \
  'Ambient command is left unchanged'

done-testing
