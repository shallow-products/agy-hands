#!/usr/bin/env bash
# Tests agy-run against a stub agy. Needs bash, git and jq; sends nothing anywhere.
set -u
script=$(CDPATH='' cd -- "$(dirname -- "$0")/../bin" && pwd)/agy-run
work=$(mktemp -d) && work=$(CDPATH='' cd -- "$work" && pwd -P) || exit 1
trap 'rm -rf "$work"' EXIT
home=$work/home
mkdir -p "$work/bin" "$work/tmp" "$work/empty" "$home/.claude" "$home/ws/repo/sub" "$home/ws/repo/.claude"

cat > "$work/bin/agy" <<'STUB'
#!/bin/sh
printf '%s' "$2" > "$STUB_DIR/prompt"
[ -n "${STUB_SLEEP:-}" ] && { echo $$ > "$STUB_DIR/pid"; exec sleep "$STUB_SLEEP"; }
echo '{"event":"init","conversation_id":"c1"}'
echo '{"event":"step_update","step_update":{"step_index":2,"state":"ACTIVE","step_type":"tool","tool_name":"read_file","tool_info":{"parameters":{"Path":"note.txt"}}}}'
[ -n "${STUB_ERR:-}" ] && echo "$STUB_ERR" >&2
[ -n "${STUB_NO_RESULT:-}" ] && exit 1
jq -cn --arg s "${STUB_STATUS:-SUCCESS}" --arg r "${STUB_REPLY:-STATUS: done}" \
  --argjson d "${STUB_DENIED:-[]}" \
  '{event:"result",result:{conversation_id:"c1",status:$s,response:$r,denied_actions:$d}}'
STUB
chmod +x "$work/bin/agy"

echo GLOBAL > "$home/.claude/CLAUDE.md"
echo HOMEFILE > "$home/CLAUDE.md"
echo OUTER > "$home/ws/CLAUDE.md"
echo REPO > "$home/ws/repo/CLAUDE.md"
echo DOTCLAUDE > "$home/ws/repo/.claude/CLAUDE.md"
echo LOCAL > "$home/ws/repo/CLAUDE.local.md"
echo SUB > "$home/ws/repo/sub/CLAUDE.md"
git -C "$home/ws/repo" init -q
git -C "$home/ws/repo" -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m init
git -C "$home/ws/repo" worktree add -q "$work/worktree" 2>/dev/null

failures=0
run() { # run [VAR=value ...] -- [agy-run args ...]
  local vars=()
  while [ "$1" != -- ]; do vars+=("$1"); shift; done; shift
  rm -f "$work/prompt"
  env HOME="$home" TMPDIR="$work/tmp" PATH="$work/bin:$PATH" STUB_DIR="$work" ${vars[@]+"${vars[@]}"} \
    "$BASH" "$script" "$@" >"$work/stdout" 2>"$work/stderr"
  rc=$?
}
check() { # check NAME COMMAND...
  local name=$1; shift
  if "$@"; then echo "ok   $name"; else echo "FAIL $name"; failures=$((failures + 1)); fi
}
rules() { grep -E '^(GLOBAL|HOMEFILE|OUTER|REPO|DOTCLAUDE|LOCAL|SUB)$' "$work/prompt" | tr '\n' ' '; }
out() { grep -qF -- "$2" "$work/$1"; }

run -- --dir "$home/ws/repo/sub" task
check "success exits 0" [ "$rc" -eq 0 ]
check "rules: parents up to HOME, outermost first" [ "$(rules)" = "OUTER REPO DOTCLAUDE SUB " ]
check "reply and meta on stdout" out stdout "AGY_META conversation_id=c1 status=done"
check "progress: conversation" out stderr "agy-run: conversation c1"
check "progress: tool call" out stderr "agy-run: step 2 read_file note.txt"
check "read-only note in prompt" out prompt "This run is read-only"

run -- --mode write --dir "$work/worktree" task
check "rules: main checkout of an outside worktree" [ "$(rules)" = "OUTER REPO DOTCLAUDE " ]
check "no read-only note in write mode" eval '! out prompt "This run is read-only"'

run -- --dir "$work/empty" task
check "no rules file" out stderr "no CLAUDE.md found"

run STUB_REPLY="STATUS: blocked" -- --dir "$work/empty" task
check "blocked exits 20" [ "$rc" -eq 20 ]
run STUB_REPLY="no status line" -- --dir "$work/empty" task
check "unknown exits 13" [ "$rc" -eq 13 ]

for c in "10:RESOURCE_EXHAUSTED" "11:please sign in" "12:DEADLINE_EXCEEDED" \
         "1:logging failed in blogin handler"; do
  run STUB_STATUS=ERROR STUB_ERR="${c#*:}" -- --dir "$work/empty" task
  check "error '${c#*:}' exits ${c%%:*}" [ "$rc" -eq "${c%%:*}" ]
done
run STUB_STATUS=ERROR STUB_REPLY="quota login timeout" -- --dir "$work/empty" task
check "reply text does not classify failures" [ "$rc" -eq 1 ]
run STUB_NO_RESULT=1 -- --dir "$work/empty" task
check "no result exits 1" [ "$rc" -eq 1 ]
check "no result keeps conversation id" out stdout "conversation_id=c1"

run STUB_DENIED='[{"action":"command"}]' -- --dir "$work/empty" task
check "denied permission is reported" out stderr "denied permission for: command"

run -- --dir "$work/empty" --resume c1 task
check "resume succeeds" [ "$rc" -eq 0 ]
run -- --dir "$work/empty" --resume other task
check "resume into a new conversation fails" [ "$rc" -eq 1 ]

if [ "$(id -u)" -ne 0 ]; then
  chmod 000 "$home/ws/CLAUDE.md"
  run -- --dir "$home/ws/repo" task
  check "unreadable rules exit 2" [ "$rc" -eq 2 ]
  check "unreadable rules: agy not run" [ ! -e "$work/prompt" ]
  chmod 644 "$home/ws/CLAUDE.md"
fi

check "temporary files removed" [ -z "$(ls -A "$work/tmp")" ]

env HOME="$home" TMPDIR="$work/tmp" PATH="$work/bin:$PATH" STUB_DIR="$work" STUB_SLEEP=30 \
  "$BASH" "$script" --dir "$work/empty" task >/dev/null 2>&1 &
wrapper=$!
n=0; while [ ! -s "$work/pid" ] && [ "$n" -lt 100 ]; do sleep 0.1; n=$((n + 1)); done
kill -TERM "$wrapper"; wait "$wrapper"; rc=$?
sleep 0.3
check "TERM exits 143" [ "$rc" -eq 143 ]
check "TERM stops agy" eval '! kill -0 "$(cat "$work/pid")" 2>/dev/null'
check "TERM removes temporary files" [ -z "$(ls -A "$work/tmp")" ]

[ "$failures" -eq 0 ] || { echo "$failures failed"; exit 1; }
echo "all passed"
