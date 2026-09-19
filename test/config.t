#!/usr/bin/env bash

# shellcheck disable=SC1091
source test/init

generated=$SCRATCH/tools.mk
"$YS" config.yaml -- tools-make > "$generated"

if cmp -s "$generated" share/tools.mk; then
  pass 'tools-make reproduces share/tools.mk'
else
  fail 'tools-make reproduces share/tools.mk'
fi

status=0
out=$("$YS" config.yaml -- no-such-command 2>&1) || status=$?
is "$status" 1 'Unknown config command fails'
has "$out" "Unknown config command 'no-such-command'" \
  'Unknown config command explains the failure'

done-testing
