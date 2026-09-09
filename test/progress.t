#!/usr/bin/env bash

# shellcheck disable=SC1090,SC1091,SC2016,SC2034
source test/init
source <(perl -ne 'print unless /^main "\$@"$/' "$ROOT/bin/in-1")
self_root=$ROOT

makes=$SCRATCH/makes
mkdir -p "$makes"
is "$(install-time-hint foo)" '' 'Missing catalog adds no hint'
cat > "$makes/langs.yaml" <<'...'
Foo:
  slug: foo
  time: 23.72s
Fast:
  slug: fast
  time: 9.99s
Boundary:
  slug: boundary
  time: 10.00s
Untimed:
  slug: untimed
Invalid:
  slug: invalid
  time: unknown
Reordered:
  time: 60s
  slug: reordered
Babashka:
  slug: babashka
  time: 23.72s
...

hint=' (may take 23secs or more)'
is "$(install-time-hint foo)" "$hint" 'Fractional seconds are truncated'
is "$(install-time-hint fast)" '' 'Below 10 seconds adds no hint'
is "$(install-time-hint boundary)" ' (may take 10secs or more)' \
  'Exactly 10 seconds adds a hint'
is "$(install-time-hint untimed)" '' 'Missing time does not inherit another entry'
is "$(install-time-hint invalid)" '' 'Invalid time adds no hint'
is "$(install-time-hint unknown)" '' 'Unknown slug adds no hint'
is "$(install-time-hint reordered)" ' (may take 60secs or more)' \
  'Field order does not matter'
is "$(install-time-hint "$(alias-tool bb)")" "$hint" \
  'Aliases use the resolved Makes slug'

out=$(progress-run 'foo v1.13.220' "$SCRATCH/log" '' '' "$hint" true 2>&1)
is "$out" '… foo v1.13.220 installing (may take 23secs or more)' \
  'Progress line has the requested wording'
out=$(progress-run 'fast v1' "$SCRATCH/log" '' '' '' true 2>&1)
is "$out" '… fast v1 installing' 'Untimed progress remains unchanged'
out=$(quiet=1 progress-run 'foo v1' "$SCRATCH/log" '' '' "$hint" true 2>&1)
is "$out" '' 'Quiet mode suppresses the hint'

done-testing
