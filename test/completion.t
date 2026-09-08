#!/usr/bin/env bash

source test/init

# A small catalog gives deterministic single and multiple matches.
mkdir -p "$SCRATCH/bin"
printf '%s\n' '#!/usr/bin/env bash' \
  "printf '%s\\n' babashka 'bb (babashka)' 'bbb (example)' beta" \
  > "$SCRATCH/bin/in-1"
chmod +x "$SCRATCH/bin/in-1"
export PATH=$SCRATCH/bin:$PATH
export ROOT

out=$(bash -c '
  eval "$("$ROOT/bin/in-1" --complete bash)"
  COMP_WORDS=(in-1 bbb); COMP_CWORD=1; COMP_TYPE=63
  _in_1_complete
  printf "%s\n" "${COMPREPLY[@]}"
' 2>&1)
is "$out" bbb "Bash: a single match inserts only its name"

out=$(bash -c '
  eval "$("$ROOT/bin/in-1" --complete bash)"
  COMP_WORDS=(in-1 bb); COMP_CWORD=1; COMP_TYPE=9
  _in_1_complete
  printf "%s\n" "${COMPREPLY[@]}"
' 2>&1)
is "$out" $'bb\nbbb' "Bash: insertion candidates never contain labels"

out=$(bash -c '
  eval "$("$ROOT/bin/in-1" --complete bash)"
  COMP_WORDS=(in-1 bb); COMP_CWORD=1; COMP_TYPE=63
  _in_1_complete
  test ${#COMPREPLY[@]} -eq 0
' 2>&1)
is "$out" $'\n  bb (babashka)\n  bbb (example)' \
  "Bash: multiple-match listing displays alias labels"

if command -v zsh >/dev/null; then
  # Observe the distinct insertion and display arrays sent to Zsh.
  out=$(zsh -c '
    eval "$("$ROOT/bin/in-1" --complete zsh)"
    compadd() {
      if [[ $1 == -d ]]; then printf "label=%s\n" "${labels[@]}"; fi
      printf "value=%s\n" "${names[@]}"
    }
    PREFIX=bb; _in_1_complete
    PREFIX=bbb; _in_1_complete
  ' 2>&1)
  is "$out" 'label=bb (babashka)
label=bbb (example)
value=bb
value=bbb
value=bbb' "Zsh: labels are separate and only used for multiple matches"
fi

if command -v fish >/dev/null; then
  out=$(fish --no-config -c '
    "$ROOT/bin/in-1" --complete fish | source
    complete -C "in-1 bb"
  ' 2>&1)
  is "$out" $'bb\tbabashka\nbbb\texample' \
    "Fish: multiple matches have separate alias descriptions"
  out=$(fish --no-config -c '
    "$ROOT/bin/in-1" --complete fish | source
    complete -C "in-1 bbb"
  ' 2>&1)
  is "$out" bbb "Fish: a single match has no alias description"
fi

done-testing
