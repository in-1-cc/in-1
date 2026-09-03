# shellcheck shell=bash
# Extra setup for rust: cargo and rustup tab completion

if command -v rustup >/dev/null 2>&1; then
  eval "$(rustup completions bash cargo 2>/dev/null || true)"
  eval "$(rustup completions bash rustup 2>/dev/null || true)"
fi
