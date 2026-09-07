#!/usr/bin/env bash

# --uninstall removes --local installs from PREFIX: share/<tool>
# and the wrappers in bin that point into it.  The prefix is faked
# here, so this needs no network and no makes.

source test/init

pfx=$SCRATCH/pfx

# A wrapper in the shape write-one-wrapper produces
fake-wrapper() (  # $1=real command $2=wrapper path
  {
    printf '#!/usr/bin/env bash\n# in-1 wrapper\n'
    printf 'export PATH=%q${PATH:+:$PATH}\n' "${1%/*}"
    printf 'cmd=%q\nexec "$cmd" "$@"\n' "$1"
  } > "$2"
  chmod +x "$2"
)

# A fake --local install of $1 (tool dir $2, version $3) providing
# the commands $4...; the first gets the versioned wrapper too
fake-install() (
  name=$1 tool=$2 ver=$3 cmd=''
  shift 3
  dir=$pfx/share/$tool/$ver/bin
  mkdir -p "$pfx/bin" "$dir"
  for cmd; do
    printf '#!/usr/bin/env bash\necho %s\n' "$cmd" > "$dir/$cmd"
    chmod +x "$dir/$cmd"
    fake-wrapper "$dir/$cmd" "$pfx/bin/$cmd"
  done
  fake-wrapper "$dir/$1" "$pfx/bin/$name-$ver"
)

# Run a command, capturing its output and status (a failure must not
# trip errexit inside the command substitution)
run() (
  "$@" 2>&1 && echo "status=$?" || echo "status=$?"
)

gone() {
  if [[ -e $pfx/$1 ]]; then
    fail "$2: $1 is gone"
  else
    pass "$2: $1 is gone"
  fi
}

kept() {
  if [[ -e $pfx/$1 ]]; then
    pass "$2: $1 is kept"
  else
    fail "$2: $1 is kept"
  fi
}

fake-install foo foo 1.0 foo foo-helper
fake-install bar bar 2.0 bar
fake-install bb babashka 1.0 bb
echo 'not a wrapper' > "$pfx/bin/foo2"
fake-wrapper "$pfx/share/bar/2.0/bin/bar" "$pfx/bin/foo3"

out=$(run bin/in-1 --uninstall foo PREFIX="$pfx")
has "$out" 'Uninstalled foo:' "--uninstall foo: reports the uninstall"
has "$out" "removed 3 command wrappers from '$pfx/bin'" \
  "--uninstall foo: counts the wrappers"
has "$out" 'status=0' "--uninstall foo: returns 0"
for path in bin/foo bin/foo-helper bin/foo-1.0 share/foo; do
  gone "$path" "--uninstall foo"
done
for path in bin/bar bin/bar-2.0 bin/foo2 bin/foo3 share/bar bin/bb; do
  kept "$path" "--uninstall foo"
done

# An alias resolves to its tool's share dir
out=$(run bin/in-1 --uninstall bb PREFIX="$pfx")
has "$out" 'Uninstalled bb:' "--uninstall bb: reports the uninstall"
has "$out" 'status=0' "--uninstall bb: returns 0"
for path in bin/bb bin/bb-1.0 share/babashka; do
  gone "$path" "--uninstall bb"
done

# Not installed: says so, returns 1, and the rest still happens
out=$(run bin/in-1 --uninstall nope foo PREFIX="$pfx")
has "$out" "'nope' is not installed under '$pfx'" \
  "--uninstall nope: not installed"
has "$out" "'foo' is not installed under '$pfx'" \
  "--uninstall nope foo: both named"
has "$out" 'status=1' "--uninstall nope: returns 1"

# PREFIX from the environment, with a trailing /bin stripped
out=$(PREFIX=$pfx/bin run bin/in-1 --uninstall bar)
has "$out" 'Stripped trailing /bin' \
  "--uninstall: PREFIX env with /bin"
has "$out" 'Uninstalled bar:' \
  "--uninstall: PREFIX from the environment"
has "$out" 'status=0' "--uninstall bar: returns 0"
for path in bin/bar bin/bar-2.0 bin/foo3 share/bar; do
  gone "$path" "--uninstall bar"
done
kept bin/foo2 "--uninstall bar"

# Argument errors
out=$(bin/in-1 --uninstall foo JQ-VERSION=1 PREFIX="$pfx" 2>&1 || true)
has "$out" '--uninstall takes no make variables' \
  "--uninstall rejects VAR=VALUE"

out=$(bin/in-1 --uninstall 2>&1 || true)
has "$out" 'No tools specified' "--uninstall alone: no tools"
has "$out" 'Usage' "--uninstall alone: prints usage"

out=$(bin/in-1 --uninstall --reset foo PREFIX="$pfx" 2>&1 || true)
has "$out" '--uninstall takes no --reset or --update' \
  "--uninstall --reset: rejected"

out=$(bin/in-1 --update --uninstall foo PREFIX="$pfx" 2>&1 || true)
has "$out" '--uninstall takes no --reset or --update' \
  "--update --uninstall: rejected"

out=$(bin/in-1 --uninstall ../foo PREFIX="$pfx" 2>&1 || true)
has "$out" "Invalid tool name '../foo'" \
  "--uninstall rejects a path"

done-testing
