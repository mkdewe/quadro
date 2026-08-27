#!/usr/bin/env bash
# Verify that the externally licensed dependencies are in place before building,
# and (with --audit) that none of them ever leaked into git.
#
#   tools/check-third-party.sh           check third_party/ is populated
#   tools/check-third-party.sh --audit   additionally verify nothing is tracked

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CYANA_DIR="${CYANA_DIR:-$REPO/third_party/cyana-2.1}"
XPLOR_DIR="${XPLOR_DIR:-$REPO/third_party/xplor-nih-2.39}"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }

errors=0
fail() { red "  ✗ $*"; errors=$((errors + 1)); }
ok()   { green "  ✓ $*"; }

echo "CYANA 2.1      → $CYANA_DIR"
if [ ! -d "$CYANA_DIR" ]; then
    fail "directory does not exist"
elif [ -z "$(ls -A "$CYANA_DIR" 2>/dev/null | grep -v '^\.gitkeep$')" ]; then
    fail "directory is empty — CYANA is a paid dependency you must supply yourself"
else
    [ -f "$CYANA_DIR/cyana" ] && ok "cyana" || fail "missing 'cyana'"
    [ -d "$CYANA_DIR/lib" ]   && ok "lib/"  || fail "missing 'lib/'"
    [ -d "$CYANA_DIR/macro" ] && ok "macro/" || fail "missing 'macro/'"
fi

echo
echo "Xplor-NIH 2.39 → $XPLOR_DIR"
if [ ! -d "$XPLOR_DIR" ]; then
    fail "directory does not exist"
elif [ -z "$(ls -A "$XPLOR_DIR" 2>/dev/null | grep -v '^\.gitkeep$')" ]; then
    fail "directory is empty — download it from https://nmr.cit.nih.gov/xplor-nih/"
else
    [ -d "$XPLOR_DIR/bin.Linux_x86_64" ] && ok "bin.Linux_x86_64/" \
        || fail "missing 'bin.Linux_x86_64/' — you need the Linux x86-64 build"
    [ -d "$XPLOR_DIR/toppar" ] && ok "toppar/" || fail "missing 'toppar/'"
    [ -d "$XPLOR_DIR/python" ] && ok "python/" || fail "missing 'python/'"
fi

# ── Audit: licensed material must never be tracked by git ────────────────────
if [ "${1:-}" = "--audit" ]; then
    echo
    echo "Audit: licensed files tracked by git"
    if ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
        fail "not a git repository — cannot audit"
    else
        tracked=$(git -C "$REPO" ls-files -- 'third_party/*' \
                  | grep -v '/\.gitkeep$' | grep -v '^third_party/README\.md$' || true)
        if [ -n "$tracked" ]; then
            fail "these are tracked and MUST be removed from history:"
            printf '      %s\n' $tracked
        else
            ok "nothing under third_party/ is tracked"
        fi
    fi
fi

echo
if [ "$errors" -gt 0 ]; then
    red "$errors problem(s). See docs/THIRD-PARTY.md for how to obtain and install both programs."
    exit 1
fi
green "All third-party dependencies present."
