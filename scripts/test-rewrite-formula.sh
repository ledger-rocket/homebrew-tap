#!/usr/bin/env bash
# Exercises scripts/rewrite-formula.sh against fixtures. Runs on every PR, which is the
# coverage the tap's formula CI cannot give: `brew style/audit/install/test` check the
# formula and never the code that edits it.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
rewrite="$here/rewrite-formula.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

OLD_URL="https://files.pythonhosted.org/packages/aa/bb/rocket_review-0.0.1.tar.gz"
OLD_SHA=$(printf '1%.0s' {1..64})
NEW_URL="https://files.pythonhosted.org/packages/cc/dd/rocket_review-9.9.9.tar.gz"
NEW_SHA=$(printf '2%.0s' {1..64})

fixture() {
    cat > "$1" <<FORMULA
class RocketReview < Formula
  desc "Fixture"
  url "${2:-$OLD_URL}"
  sha256 "${3:-$OLD_SHA}"
end
FORMULA
}

fail() { echo "FAIL: $1" >&2; exit 1; }

# Exact codes, not "non-zero": REFUSED(1) and USAGE(2) are a contract the workflow reads,
# and a test that accepts either cannot tell a refused rewrite from a mistyped call.
expect_exit() {
    local want=$1 desc=$2; shift 2
    local got=0
    "$@" >/dev/null 2>&1 || got=$?
    [ "$got" -eq "$want" ] || fail "$desc: expected exit $want, got $got"
    echo "ok: $desc (exit $want)"
}

# 1. The happy path rewrites both fields and succeeds.
f="$work/a.rb"; fixture "$f"
"$rewrite" "$f" "$NEW_URL" "$NEW_SHA" || fail "rewrite exited non-zero on a formula it changed"
grep -qF "$NEW_URL" "$f" || fail "url was not rewritten"
grep -qF "$NEW_SHA" "$f" || fail "sha256 was not rewritten"
grep -qF "$OLD_URL" "$f" && fail "old url survived"
grep -qF "$OLD_SHA" "$f" && fail "old sha256 survived"
echo "ok: rewrite lands and exits 0"

# 2. Asking for what the formula already says succeeds. The guard asserts the OUTCOME
#    ("does it now say this?") rather than the delta ("did anything change?"), so this is
#    idempotent rather than an error — and asserting the outcome is what makes case 3 fail.
f="$work/b.rb"; fixture "$f"
"$rewrite" "$f" "$OLD_URL" "$OLD_SHA" || fail "an already-correct formula was refused"
grep -qF "$OLD_URL" "$f" || fail "an idempotent call altered the url"
echo "ok: already-correct formula is accepted unchanged"

# 3. A HALF rewrite must be refused. Checking only that the file changed would pass this,
#    leaving a new url beside a stale sha256 — the state that breaks `brew install`.
f="$work/c.rb"
printf 'class X < Formula\n  url "%s"\n   sha256 "%s"\nend\n' "$OLD_URL" "$OLD_SHA" > "$f"
expect_exit 1 "half rewrite is refused" "$rewrite" "$f" "$NEW_URL" "$NEW_SHA"
grep -qF "$OLD_SHA" "$f" || fail "fixture 3 no longer exercises a stale sha256"

# 4. Nothing matching at all is refused.
f="$work/d.rb"; printf 'class X < Formula\nend\n' > "$f"
expect_exit 1 "unmatched formula is refused" "$rewrite" "$f" "$NEW_URL" "$NEW_SHA"

# 5. Bad inputs are usage errors, distinct from a refused rewrite.
f="$work/e.rb"; fixture "$f"
expect_exit 2 "missing formula" "$rewrite" "$work/missing.rb" "$NEW_URL" "$NEW_SHA"
expect_exit 2 "sed metacharacter in url" "$rewrite" "$f" 'https://x.invalid/a&b.tar.gz' "$NEW_SHA"
expect_exit 2 "non-https url" "$rewrite" "$f" 'http://x.invalid/a.tar.gz' "$NEW_SHA"
expect_exit 2 "short sha256" "$rewrite" "$f" "$NEW_URL" "abc123"
expect_exit 2 "uppercase sha256" "$rewrite" "$f" "$NEW_URL" "$(printf 'A%.0s' {1..64})"
expect_exit 2 "wrong argument count" "$rewrite" "$f" "$NEW_URL"

# A refused or mistyped call must never leave the formula half-edited.
grep -qF "$OLD_URL" "$f" || fail "a refused call still modified the formula"

echo "all rewrite-formula checks passed"
