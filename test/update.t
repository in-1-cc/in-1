#!/usr/bin/env bash

# The is-it-behind notice and --update/--update, against local clones so no
# network is needed.  IN1_ROOT is a clone of a clone of this working
# copy; makes likewise.  The working copy's bin/in-1 drives it.

source test/init

if ! git -C "$ROOT" symbolic-ref -q HEAD >/dev/null; then
  pass "working copy is on a detached HEAD; tests skipped"
  done-testing
  exit 0
fi

origin=$SCRATCH/in1-origin
clone=$SCRATCH/in1-clone
morigin=$SCRATCH/makes-origin
git clone -q "$ROOT" "$origin"
git clone -q "$origin" "$clone"
git clone -q "$IN1_MAKES_REPO" "$morigin"
export IN1_ROOT=$clone
export IN1_MAKES_REPO=$morigin

commit() {  # $1=repo $2=message
  git -C "$1" -c user.name=t -c user.email=t@t \
    commit -q --allow-empty -m "$2"
}
head-of() { git -C "$1" rev-parse HEAD; }
mclone=$clone/makes

out=$(bin/in-1 no-such-tool 2>&1 || true)
has "$out" 'Unknown tool' "install attempt runs"
hasnt "$out" 'behind' "up to date: no notice"

commit "$origin" 'Newer in-1'
commit "$morigin" 'Newer makes'
out=$(bin/in-1 no-such-tool 2>&1 || true)
has "$out" "in-1 is 1 commit(s) behind; run 'in-1 --update' to update" \
  "behind: in-1 notice"
has "$out" "makes is 1 commit(s) behind; run 'in-1 --update' to update" \
  "behind: makes notice"
has "$out" 'Unknown tool' "behind: install still proceeds"

out=$(bin/in-1 --list 2>&1)
hasnt "$out" 'behind' "--list does not check"

out=$(IN1_OFFLINE=1 bin/in-1 no-such-tool 2>&1 || true)
hasnt "$out" 'behind' "IN1_OFFLINE=1 skips the check"

out=$(bin/in-1 --update 2>&1)
has "$out" 'in-1 is now at version' "--update: reports the in-1 version"
has "$out" 'makes is now at' "--update: reports the makes commit"
is "$(head-of "$clone")" "$(head-of "$origin")" "--update: in-1 up to date"
is "$(head-of "$mclone")" "$(head-of "$morigin")" "--update: makes up to date"
out=$(bin/in-1 no-such-tool 2>&1 || true)
hasnt "$out" 'behind' "after --update: no notice"

commit "$origin" 'Newer in-1 again'
out=$(bin/in-1 --update no-such-tool 2>&1 || true)
has "$out" 'in-1 is now at version' "--update TOOL: updates first"
has "$out" 'Unknown tool' "--update TOOL: then continues"
is "$(head-of "$clone")" "$(head-of "$origin")" "--update TOOL: in-1 updated"

commit "$origin" 'Newer in-1 once more'
out=$(IN1_UPDATE=1 bin/in-1 no-such-tool 2>&1 || true)
has "$out" 'in-1 is now at version' "IN1_UPDATE=1 acts like --update"
is "$(head-of "$clone")" "$(head-of "$origin")" "IN1_UPDATE=1 updates"

sha=$(git -C "$origin" rev-parse HEAD~1)
out=$(IN1_VERSION=$sha bin/in-1 --update 2>&1)
is "$(head-of "$clone")" "$sha" "IN1_VERSION with --update checks out that ref"
if git -C "$clone" symbolic-ref -q HEAD >/dev/null; then
  fail "IN1_VERSION with --update leaves HEAD detached"
else
  pass "IN1_VERSION with --update leaves HEAD detached"
fi

done-testing
