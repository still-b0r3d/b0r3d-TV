#!/usr/bin/env bash
# The game-rule tests, run by .github/workflows/check.yml on every push: the BrightScript
# simulator (brs-node) plays each game's rules on the PC, test by test, and this fails when any
# test fails or a run crashes. Each game's tests run on their own (each has its own Main).
# From the repo's top folder:
#   bash tools/test-games.sh
# BRS_CLI can point at a brs-cli already installed; otherwise npx fetches brs-node 2.6.2.
set -u
cd "$(dirname "$0")/.."

SUITES=(
  "tests/stuck-tests.brs app/source/stuck.brs app/source/games.brs"
  "tests/tp-tests.brs app/source/testpattern.brs app/source/games.brs"
  "tests/snake-tests.brs app/source/snake.brs app/source/games.brs"
)
OUT=$(mktemp)
trap 'rm -f "$OUT"' EXIT
BAD=0

for FILES in "${SUITES[@]}"; do
  echo "test-games: ${FILES%% *}"
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
    BAD=1
    continue
  fi
  case "$SUMMARY" in
    *" 0 passed,"*) echo "test-games: no test ran" >&2; BAD=1 ;;
    *", 0 failed"*) ;;
    *) echo "test-games: some tests failed" >&2; BAD=1 ;;
  esac
done

if [ "$BAD" = 1 ]; then
  exit 1
fi
echo "test-games: all passed"
