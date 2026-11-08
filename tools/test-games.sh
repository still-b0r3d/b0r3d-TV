#!/usr/bin/env bash
# The game-rule tests, run by .github/workflows/check.yml on every push: the BrightScript
# simulator (brs-node) plays the games' rules on the PC, test by test, and this fails when any
# test fails or the run crashes. From the repo's top folder:
#   bash tools/test-games.sh
# BRS_CLI can point at a brs-cli already installed; otherwise npx fetches brs-node 2.6.2.
set -u
cd "$(dirname "$0")/.."

FILES="tests/stuck-tests.brs app/source/stuck.brs app/source/games.brs"
OUT=$(mktemp)
trap 'rm -f "$OUT"' EXIT

if [ -n "${BRS_CLI:-}" ]; then
  # shellcheck disable=SC2086
  "$BRS_CLI" --no-sg --colors 0 $FILES > "$OUT" 2>&1
else
  # shellcheck disable=SC2086
  npx --yes --package brs-node@2.6.2 brs-cli --no-sg --colors 0 $FILES > "$OUT" 2>&1
fi
STATUS=$?

# the simulator's own notes about the network on Windows say nothing about the tests
grep -v -i -e 'network gateway' -e 'wmic' -e 'operable program' -e '^[[:space:]]*$' "$OUT"

SUMMARY=$(grep -E '^game-rule tests: [0-9]+ passed, [0-9]+ failed' "$OUT" | tail -n 1)
if [ "$STATUS" -ne 0 ] || [ -z "$SUMMARY" ]; then
  echo "test-games: the tests didn't run to the end" >&2
  exit 1
fi
case "$SUMMARY" in
  *" 0 passed,"*) echo "test-games: no test ran" >&2; exit 1 ;;
  *", 0 failed"*) echo "test-games: all passed" ;;
  *) echo "test-games: some tests failed" >&2; exit 1 ;;
esac
