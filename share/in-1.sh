# shellcheck shell=bash
# Extra setup for in-1: the in-1 shell function, man page and tab
# completion come from the .rc of the copy just installed.  IN1_ROOT
# is already set (to this in-1's root), so .rc leaves it alone.

for _in1_rc in "$IN1_TOOL_DIR"/cache/in-1-*/.rc; do
  # shellcheck disable=SC1090  # the path is only known at run time
  [ -f "$_in1_rc" ] && source "$_in1_rc"
done
unset _in1_rc
