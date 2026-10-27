---
name: agy-hands
description: How to delegate work to the Antigravity CLI through the agy-worker subagent. Use when a task is large, mechanical, read-heavy, or parallelizable, and when handling agy-worker results, questions, or failures.
---

Claude is the brain: design, decide, verify. agy (via `agy-worker`) is the hands: read, edit, generate.

## When to delegate
Delegate, and lean toward doing so:
- large reads or analysis where only the conclusion matters
- bulk or mechanical changes: migrations, renames, scaffolding, test generation
- web research; second-opinion review
- independent units that can run in parallel (one worker per unit)

Do it yourself:
- small edits, or anything faster to do than to brief
- design decisions and work that depends on this conversation's context
- edits to files another worker or you are changing

## Brief
The worker only knows the brief. Write it with:

```
Goal:        <one sentence>
Target:      <files/dirs, relative paths>
Done when:   <observable criteria, e.g. a test passes>
Off-limits:  <what must not change>
Questions:   decisions you could get wrong: report them, do not guess
```

Decide the design yourself first; the brief carries decisions, not open problems.

## Running
- Start `agy-worker` in the background and keep working. Wait only when the next step needs the result.
- Read-only jobs may share the checkout. Write jobs run in the worker's own worktree.
- One-shot `claude -p` sessions cannot collect background results later: delegate synchronously there.

## Reading the result
The reply ends in `===DIGEST===`, `===QUESTIONS===`, `===VERIFY===` and an `AGY_META` line.
- status `done`/`partial`: verify yourself (run the `VERIFY` items, read the diff). agy's own claim is not evidence.
- status `blocked` (exit 20): answer the questions (or ask the user), then start the worker again with `--resume <conversation_id>` and the answers. Keep that worktree until done.
- contract violated (exit 13): treat the reply as unreliable; re-run or take over.

## Failures (agy-run exit codes)
| code | meaning | do |
|---|---|---|
| 10 | quota / rate limit | use a normal subagent with the same brief, do it yourself, or wait |
| 11 | not signed in | ask the user to run `agy` once and sign in |
| 12 | timeout | narrow the task or raise `--timeout`; resume with `--resume` |
| 13 | return contract broken | see above |
| 20 | blocked on questions | see above |

Codes 10 and 11 are detected by matching error text and may be missed; treat an unexplained exit 1 the same way.

## After the work
Merge or discard the worktree, then delete its branch. Do not leave finished worktrees behind. Keep a worktree only while its job is `blocked`.
