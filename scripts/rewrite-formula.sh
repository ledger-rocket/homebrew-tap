#!/usr/bin/env bash
# Point a formula at a different release. Exits non-zero, loudly, if it did not.
#
# Extracted from the bump workflow so it can be tested: the same shell inline in a
# scheduled job is only ever exercised in production, which is how an inverted guard
# once aborted every successful run for a day before anyone saw it.
set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "usage: $0 <formula-path> <url> <sha256>" >&2
    exit 2
fi

formula=$1
url=$2
sha=$3

[ -f "$formula" ] || { echo "no such formula: $formula" >&2; exit 2; }
[ -n "$url" ] && [ -n "$sha" ] || { echo "url and sha256 are both required" >&2; exit 2; }

before=$(cat "$formula")
sed -i.bak \
    -e "s|^  url \".*\"|  url \"$url\"|" \
    -e "s|^  sha256 \".*\"|  sha256 \"$sha\"|" \
    "$formula"
rm -f "$formula.bak"

# The guard the whole script exists for. `cmp` rather than `git diff` because this must
# work on a bare file, and because a bare non-zero from git under `set -e` is exactly
# the trap that made the original inline version abort on the path where it had worked.
if [ "$before" = "$(cat "$formula")" ]; then
    echo "$formula was not modified — check that its url and sha256 lines match" \
         "the expected two-space-indented form" >&2
    exit 1
fi
