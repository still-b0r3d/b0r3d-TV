#!/usr/bin/env bash
# The repo's own check, run by .github/workflows/check.yml on every push to main:
#   - every commit is authored and committed as still_b0r3d <still@b0r3d.org>,
#   - no private term appears in any commit message, any file or any file name.
# The terms come from the LEAK_TERMS secret, one per line; lines starting with # and blank
# lines are skipped. A term matches as a whole word in any case, as plain text. A hit is
# reported by the term's NUMBER in the list, never the term, so this output gives nothing away.
set -u

NAME='still_b0r3d'
EMAIL='still@b0r3d.org'
BAD=0
fail() { echo "check: $*" >&2; BAD=1; }

if [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ]; then
  echo "check: a pull request; the identity and term checks run once it reaches main"
  exit 0
fi

TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT
git rev-list HEAD > "$TMPD/commits"

while IFS= read -r c; do
  s=$(git rev-parse --short "$c")
  [ "$(git log -1 --format='%an|%ae' "$c")" = "$NAME|$EMAIL" ] || fail "commit $s: the author is not $NAME <$EMAIL>"
  [ "$(git log -1 --format='%cn|%ce' "$c")" = "$NAME|$EMAIL" ] || fail "commit $s: the committer is not $NAME <$EMAIL>"
done < "$TMPD/commits"

printf '%s\n' "${LEAK_TERMS:-}" | sed -e 's/\r$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
  | grep -v -e '^#' -e '^$' > "$TMPD/terms" || true
if [ ! -s "$TMPD/terms" ]; then
  echo "::warning::check: the LEAK_TERMS secret isn't set, so only the commit identity was checked"
else
  NT=$(wc -l < "$TMPD/terms" | tr -d ' ')
  while IFS= read -r c; do
    s=$(git rev-parse --short "$c")
    git log -1 --format='%B' "$c" > "$TMPD/msg"
    git ls-tree -r --name-only "$c" > "$TMPD/names"
    i=0
    while IFS= read -r term; do
      i=$((i + 1))
      grep -q -i -w -F -e "$term" "$TMPD/msg" && fail "commit $s: term #$i in its message"
      if git grep -q -I -i -w -F -e "$term" "$c" -- . 2>/dev/null; then
        where=$(git grep -l -I -i -w -F -e "$term" "$c" -- . 2>/dev/null | sed "s/^$c://" | tr '\n' ' ')
        fail "commit $s: term #$i in $where"
      fi
      grep -q -i -w -F -e "$term" "$TMPD/names" && fail "commit $s: term #$i in a file name"
    done < "$TMPD/terms"
  done < "$TMPD/commits"
  echo "check: $(wc -l < "$TMPD/commits" | tr -d ' ') commit(s) checked against $NT terms"
fi

if [ "$BAD" = 1 ]; then
  echo "check: failed" >&2
  exit 1
fi
echo "check: clean"
