# shellcheck shell=bash
# Extra setup for gloat: its shell default and tab completion

export GLOAT_SHELL=bash

if command -v gloat >/dev/null 2>&1; then
  eval "$(gloat --complete bash 2>/dev/null || true)"
fi
