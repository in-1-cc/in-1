#!/usr/bin/env bash

# ShellCheck cannot see the writer's use of its globals through this source.
# shellcheck disable=SC1090,SC1091,SC2016,SC2034
source test/init

# Load the wrapper writer without running the command or downloading tools.
source <(perl -ne 'print unless /^main "\$@"$/' "$ROOT/bin/in-1")
self_root=$ROOT
install_root=$SCRATCH/prefix
mkdir -p "$install_root/bin"
out_names=(); out_values=(); wrap_count=0

install-fixture() {
  local version=$1 name=${2:-bb}
  local dir=$install_root/share/$name/$version/bin
  mkdir -p "$dir"
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" %q\n' "$version" > "$dir/$name"
  chmod +x "$dir/$name"
  added_dirs=("$dir")
  write-wrappers "$version" "$name" "$name"
}

install-fixture 1
is "$(readlink "$install_root/bin/bb")" bb-1 'Primary is a relative symlink'
if [[ -f $install_root/bin/bb-1 && ! -L $install_root/bin/bb-1 ]]; then
  pass 'Versioned command is a regular wrapper'
else
  fail 'Versioned command is a regular wrapper'
fi
is "$("$install_root/bin/bb")" 1 'Primary runs the versioned wrapper'

install-fixture 2
is "$(readlink "$install_root/bin/bb")" bb-2 'Installing a version updates the link'
is "$("$install_root/bin/bb-1")" 1 'Old version remains runnable and unchanged'
is "$("$install_root/bin/bb")" 2 'Primary runs the new version'
install-fixture 2
is "$(readlink "$install_root/bin/bb")" bb-2 'Reinstall preserves the link layout'

# Existing duplicate wrappers are replaced without changing their version.
rm "$install_root/bin/bb"
cp "$install_root/bin/bb-1" "$install_root/bin/bb"
install-fixture 3
is "$(readlink "$install_root/bin/bb")" bb-3 'Legacy wrapper becomes a symlink'
is "$("$install_root/bin/bb-1")" 1 'Migration preserves old versions'

install-fixture main in-1
is "$(readlink "$install_root/bin/in-1")" in-1-main 'in-1 uses the same layout'

# A skipped version wrapper must never become the active command.
printf 'foreign file\n' > "$install_root/bin/bb-4"
out=$(install-fixture 4 2>&1)
has "$out" 'Skipping existing non-wrapper file' 'Version conflict is reported'
is "$(readlink "$install_root/bin/bb")" bb-3 'Version conflict keeps active link'

rm "$install_root/bin/bb"
ln -s missing-foreign-command "$install_root/bin/bb"
out=$(install-fixture 5 2>&1)
has "$out" 'Skipping existing non-wrapper file' 'Dangling foreign link is reported'
is "$(readlink "$install_root/bin/bb")" missing-foreign-command \
  'Dangling foreign link is preserved'

done-testing
