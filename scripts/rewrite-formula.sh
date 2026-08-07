#!/usr/bin/env bash
# Point a formula at a different release, or fail loudly having changed nothing useful.
#
# Extracted from the bump workflow so it can be tested: the same shell inline in a
# scheduled job is only ever exercised in production, which is how an inverted guard
# once aborted every successful run for a day before anyone noticed.
set -euo pipefail

readonly USAGE=2   # the caller invoked this wrong
readonly REFUSED=1 # the rewrite did not fully land

if [ "$#" -ne 3 ]; then
    echo "usage: $0 <formula-path> <url> <sha256>" >&2
    exit "$USAGE"
fi

formula=$1
url=$2
sha=$3

[ -f "$formula" ] || { echo "no such formula: $formula" >&2; exit "$USAGE"; }

# Validated before they reach sed, where `&`, `\` and the `|` delimiter are replacement
# metacharacters: an `&` in a url would expand to the whole match and write a corrupt
# line. These come from PyPI's API today, but a formula is executed on other people's
# machines, so the shape is checked rather than assumed.
# Patterns held in variables: an inline bracket expression containing `;` does not
# survive bash's conditional parser. The url set is RFC 3986 minus `&`, `\` and `|` —
# the three that mean something to sed here.
# shellcheck disable=SC2016  # the `$` here anchor the regex and sit inside a bracket
# expression; single quotes are what keeps them literal rather than a missing expansion.
sha_re='^[a-f0-9]{64}$'
# shellcheck disable=SC2016  # same: literal regex, not an unexpanded expression.
url_re='^https://[A-Za-z0-9._~:/?#@!$()*+,;=%-]+$'
[[ "$sha" =~ $sha_re ]] || {
    echo "sha256 must be 64 lowercase hex characters, got: $sha" >&2; exit "$USAGE"; }
[[ "$url" =~ $url_re ]] || {
    echo "url must be https and free of sed metacharacters, got: $url" >&2
    exit "$USAGE"; }

sed -i.bak \
    -e "s|^  url \".*\"|  url \"$url\"|" \
    -e "s|^  sha256 \".*\"|  sha256 \"$sha\"|" \
    "$formula"
rm -f "$formula.bak"

# Assert the outcome, not that "something changed". Checking for change alone passes a
# half-rewrite — one expression matching and the other not leaves the formula differing
# from its old self while still carrying a stale field, and a url paired with the wrong
# sha256 is exactly the state that breaks `brew install` for everyone.
missing=()
grep -qF "  url \"$url\"" "$formula" || missing+=("url")
grep -qF "  sha256 \"$sha\"" "$formula" || missing+=("sha256")
if [ "${#missing[@]}" -ne 0 ]; then
    echo "$formula: ${missing[*]} not set as requested — check that the line(s) match" \
         "the expected two-space-indented form" >&2
    exit "$REFUSED"
fi
