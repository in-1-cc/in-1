#!/usr/bin/env bash

# shellcheck disable=SC1091
source test/init slow

if [[ $OSTYPE == msys* || $OSTYPE == cygwin* ]]; then
  pass 'Skipping bbin.t on Windows'
  done-testing
  exit 0
fi

export IN1_OFFLINE=1
unset BABASHKA_BBIN_DIR BABASHKA_BBIN_BIN_DIR BABASHKA_BBIN_JARS_DIR
unset XDG_DATA_HOME

# Exercise the working Makes module, including changes not yet committed.
ln -s "$IN1_MAKES_REPO" "$IN1_ROOT/makes"
prefix=$SCRATCH/prefix

# Keep bbin's defaults and dependency caches inside the test directory.
export BBIN_TEST_HOME=$SCRATCH/home
export CLJ_CONFIG=$SCRATCH/clojure
export CLJ_CACHE=$SCRATCH/clj-cache
export XDG_CACHE_HOME=$SCRATCH/cache
export BABASHKA_PRELOADS='
(System/setProperty "user.home" (System/getenv "BBIN_TEST_HOME"))'
mkdir -p "$BBIN_TEST_HOME" "$CLJ_CONFIG"

# Installation-time settings must not become permanent wrapper overrides.
BABASHKA_BBIN_DIR=$SCRATCH/install-legacy \
BABASHKA_BBIN_BIN_DIR=$SCRATCH/install-bin \
BABASHKA_BBIN_JARS_DIR=$SCRATCH/install-jars \
  bin/in-1 -q --local bbin PREFIX="$prefix"

is "$("$prefix/bin/bbin" bin)" "$BBIN_TEST_HOME/.local/bin" \
  'Installed bbin wrapper uses the default application directory'
hasnt "$(cat "$prefix/bin/bbin")" 'BABASHKA_BBIN_' \
  'Installed wrapper does not bake in bbin directory settings'

export BABASHKA_BBIN_DIR=$SCRATCH/custom-legacy
export BABASHKA_BBIN_BIN_DIR="$SCRATCH/custom bin"
export BABASHKA_BBIN_JARS_DIR="$SCRATCH/custom jars"
is "$("$prefix/bin/bbin" bin)" "$BABASHKA_BBIN_BIN_DIR" \
  'Installed bbin wrapper honors the caller application directory'

printf '#!/usr/bin/env bb\n(println "Hello from bbin")\n' > "$SCRATCH/hello.clj"
"$prefix/bin/bbin" install "$SCRATCH/hello.clj" --as bbin-hello >/dev/null
is "$(PATH=$prefix/bin:$BABASHKA_BBIN_BIN_DIR:$PATH bbin-hello)" \
  'Hello from bbin' 'A script installed through bbin runs from the caller PATH'
has "$("$prefix/bin/bbin" ls)" 'bbin-hello' \
  'Installed bbin lists the script from the caller application directory'

mkdir -p "$BABASHKA_BBIN_DIR/bin"
is "$("$prefix/bin/bbin" bin 2>/dev/null)" "$BABASHKA_BBIN_DIR/bin" \
  'Installed bbin honors the caller legacy directory'

done-testing
