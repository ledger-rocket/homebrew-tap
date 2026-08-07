#!/usr/bin/env bash
# Exercises scripts/rewrite-formula.sh against a fixture. Runs on every PR that touches
# the bump workflow or these scripts, which is the coverage the tap's formula CI cannot
# give: `brew style/audit/install/test` check the formula, never the code that edits it.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
rewrite="$here/rewrite-formula.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

OLD_URL="https://files.pythonhosted.org/packages/aa/bb/rocket_review-0.0.1.tar.gz"
OLD_SHA="1111111111111111111111111111111111111111111111111111111111111111"
NEW_URL="https://files.pythonhosted.org/packages/cc/dd/rocket_review-9.9.9.tar.gz"
NEW_SHA="2222222222222222222222222222222222222222222222222222222222222222"

fixture() {
    cat > "$1" <<FORMULA
class RocketReview < Formula
  include Language::Python::Virtualenv

  desc "Fixture"
  homepage "https://example.invalid"
  url "$OLD_URL"
  sha256 "$OLD_SHA"
  license "Apache-2.0"
end
FORMULA
}

fail() { echo "FAIL: $1" >&2; exit 1; }

# 1. The happy path actually rewrites both fields and reports success.
f="$work/a.rb"; fixture "$f"
"$rewrite" "$f" "$NEW_URL" "$NEW_SHA" || fail "rewrite exited non-zero on a formula it changed"
grep -qF "$NEW_URL" "$f" || fail "url was not rewritten"
grep -qF "$NEW_SHA" "$f" || fail "sha256 was not rewritten"
grep -qF "$OLD_URL" "$f" && fail "old url survived"
grep -qF "$OLD_SHA" "$f" && fail "old sha256 survived"
echo "ok: rewrite lands and exits 0"

# 2. A no-op rewrite must fail. This is the case the original inline guard got backwards,
#    aborting when the edit HAD landed and staying silent when it had not.
f="$work/b.rb"; fixture "$f"
"$rewrite" "$f" "$OLD_URL" "$OLD_SHA" && fail "guard stayed silent when nothing changed"
echo "ok: guard fires when the rewrite is a no-op"

# 3. A formula whose lines do not match the expected shape must fail rather than pass a
#    silently-unmodified file to a release.
f="$work/c.rb"; printf 'class X < Formula\n    url "%s"\nend\n' "$OLD_URL" > "$f"
"$rewrite" "$f" "$NEW_URL" "$NEW_SHA" && fail "guard stayed silent on an unmatched formula"
echo "ok: guard fires when the patterns match nothing"

# 4. Usage errors are distinguishable from a failed rewrite (exit 2, not 1).
set +e; "$rewrite" "$work/missing.rb" "$NEW_URL" "$NEW_SHA" >/dev/null 2>&1; rc=$?; set -e
[ "$rc" -eq 2 ] || fail "expected exit 2 for a missing formula, got $rc"
echo "ok: usage errors exit 2"

echo "all rewrite-formula checks passed"
