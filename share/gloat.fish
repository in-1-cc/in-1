# Extra setup for gloat: its shell default and tab completion

set -gx GLOAT_SHELL fish

if command -q gloat
    gloat --complete fish 2>/dev/null | source
end
