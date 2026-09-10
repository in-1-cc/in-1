#!/usr/bin/env bash

# shellcheck disable=SC1091
source test/init

mkdir -p "$SCRATCH/prefix/bin"
cat > "$SCRATCH/prefix/bin/carp" <<'...'
#!/usr/bin/env bash
[[ $# == 1 && $1 == --help ]] || exit 1
printf 'Carp CLI works\n'
...
cat > "$SCRATCH/prefix/bin/moon" <<'...'
#!/usr/bin/env bash
[[ $# == 1 && -f $1 && $1 == *.moon ]] || exit 1
grep -Fx 'assert 2 + 2 == 4' "$1" >/dev/null || exit 1
grep -Fx 'print "in-1 smoke"' "$1" >/dev/null || exit 1
printf 'MoonScript file works\n'
...
chmod +x "$SCRATCH/prefix/bin/"{carp,moon}

out=$(bash util/smoke carp "$SCRATCH/prefix")
is "$out" 'Carp CLI works' 'Carp probe uses its supported help option'
out=$(bash util/smoke moonscript "$SCRATCH/prefix")
is "$out" 'MoonScript file works' 'MoonScript probe runs a script file'

done-testing
