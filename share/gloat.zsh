# Extra setup for gloat: its shell default and tab completion

export GLOAT_SHELL=zsh

# gloat's completion registers itself with compdef, so it needs compinit
if command -v gloat >/dev/null 2>&1 && (( $+functions[compdef] )); then
  eval "$(gloat --complete zsh 2>/dev/null || true)"
fi
