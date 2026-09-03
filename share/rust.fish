# Extra setup for rust: rustup tab completion

if command -q rustup
    rustup completions fish rustup 2>/dev/null | source
end
