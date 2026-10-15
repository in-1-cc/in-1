#!/usr/bin/env bash

# Exercise the actual Makes install path using a tiny offline tool fixture.
# shellcheck disable=SC1091,SC2016
source test/init
export IN1_OFFLINE=1
export pin_prefix=$SCRATCH/prefix

git clone -q "$IN1_MAKES_REPO" "$IN1_ROOT/makes"
cat > "$IN1_ROOT/makes/jolt.mk" <<'MAKE'
JOLT-VERSION ?= 0.8.21
$(eval $(call include-local))
JOLT := $(LOCAL-BIN)/jolt
JOLT-COMP := \
  $(LOCAL-SHARE)/bash-completion/completions/jolt \
  $(LOCAL-SHARE)/zsh/site-functions/_jolt \
  $(LOCAL-SHARE)/fish/vendor_completions.d/jolt.fish
SHELL-DEPS += $(JOLT) $(JOLT-COMP)
override PATH := $(LOCAL-BIN):$(PATH)
export PATH
export JOLT_VERSION := $(JOLT-VERSION)

$(JOLT):
	mkdir -p $(@D)
	printf '#!/usr/bin/env bash\necho %s\n' '$(JOLT-VERSION)' > $@
	chmod +x $@

$(JOLT-COMP): $(JOLT)
	mkdir -p $(@D)
	printf '# jolt %s\n' '$(JOLT-VERSION)' > $@
MAKE

out=$(bin/in-1 -q --local jolt JOLT-VERSION=0.8.20 PREFIX="$pin_prefix" 2>&1)
is "$out" '' 'Existing version-variable syntax still installs quietly'
before=$(cksum "$pin_prefix/bin/jolt-0.8.20")
bin/in-1 -q --local jolt@0.8.20 PREFIX="$pin_prefix"
is "$(cksum "$pin_prefix/bin/jolt-0.8.20")" "$before" \
  'Inline syntax produces the same installed wrapper as a version variable'
is "$("$pin_prefix/bin/jolt" --version)" 0.8.20 'Inline pin installs its version'

bin/in-1 -q --local jolt@0.8.20 jolt@0.8.19 PREFIX="$pin_prefix"
is "$("$pin_prefix/bin/jolt-0.8.20" --version)" 0.8.20 \
  'First requested version remains runnable'
is "$("$pin_prefix/bin/jolt-0.8.19" --version)" 0.8.19 \
  'Second requested version is independently installed'
is "$("$pin_prefix/bin/jolt" --version)" 0.8.19 \
  'Last requested version becomes the active command'
is "$(readlink "$pin_prefix/share/in-1/active/jolt")" ../../jolt/0.8.19 \
  'Last requested version also provides active shell support'
has "$(cat "$pin_prefix/bin/jolt-0.8.20")" 'JOLT_VERSION=0.8.20' \
  'First wrapper keeps its own captured environment'
has "$(cat "$pin_prefix/bin/jolt-0.8.19")" 'JOLT_VERSION=0.8.19' \
  'Second wrapper keeps its own captured environment'

bin/in-1 -q --local jolt@0.8.20 jolt JOLT-VERSION=0.8.21 PREFIX="$pin_prefix"
is "$("$pin_prefix/bin/jolt-0.8.20" --version)" 0.8.20 \
  'Inline pin wins over a shared variable for that request'
is "$("$pin_prefix/bin/jolt" --version)" 0.8.21 \
  'Shared variable still applies to a later unpinned request'

export ROOT
for shell in bash zsh fish; do
  command -v "$shell" >/dev/null || continue
  if [[ $shell == fish ]]; then
    out=$(fish --no-config -c '
      source "$ROOT/.rc"
      in-1 -q jolt@0.8.20 jolt@0.8.19 PREFIX="$pin_prefix"
      jolt --version
      printf "tools=%s\n" "$IN1_TOOLS"
      in-1 -q --uninstall jolt@0.8.20 PREFIX="$pin_prefix"
      jolt --version
    ')
  else
    out=$("$shell" -c '
      source "$ROOT/.rc"
      in-1 -q jolt@0.8.20 jolt@0.8.19 PREFIX="$pin_prefix"
      jolt --version
      printf "tools=%s\n" "$IN1_TOOLS"
      in-1 -q --uninstall jolt@0.8.20 PREFIX="$pin_prefix"
      jolt --version
    ')
  fi
  is "$out" $'0.8.19\ntools=jolt\n0.8.19' \
    "$shell: pinned requests install and uninstall through the shell function"
  if [[ $shell == fish ]]; then
    out=$(fish --no-config -c '
      source ./rc -q --temp jolt@0.8.20 jolt@0.8.19
      jolt --version
    ')
  else
    out=$("$shell" -c '
      source ./rc -q --temp jolt@0.8.20 jolt@0.8.19
      jolt --version
    ')
  fi
  is "$out" 0.8.19 "$shell: bootstrap also accepts multiple pinned versions"
done

bin/in-1 -q --local jolt@0.8.20 PREFIX="$pin_prefix"
bin/in-1 -q --uninstall jolt@0.8.20 jolt@0.8.19 PREFIX="$pin_prefix"
if [[ ! -e $pin_prefix/share/jolt/0.8.20 &&
      ! -e $pin_prefix/share/jolt/0.8.19 &&
      ! -L $pin_prefix/bin/jolt &&
      ! -L $pin_prefix/share/in-1/active/jolt ]]; then
  pass 'Multiple exact uninstalls remove only their versions and active support'
else
  fail 'Multiple exact uninstalls remove only their versions and active support'
fi
is "$("$pin_prefix/bin/jolt-0.8.21" --version)" 0.8.21 \
  'Other versioned commands remain runnable without automatic activation'

bin/in-1 -q --uninstall jolt PREFIX="$pin_prefix"
if [[ ! -e $pin_prefix/share/jolt ]]; then
  pass 'Bare uninstall still removes all remaining versions'
else
  fail 'Bare uninstall still removes all remaining versions'
fi

done-testing
