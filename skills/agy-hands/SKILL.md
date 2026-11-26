---
name: agy-hands
description: How to delegate work to the Antigravity CLI (agy) the way you would to a subagent, by running agy-run. Use when a task is large, mechanical, read-heavy, or parallelizable, and when handling agy results, questions, or failures.
---

Claude is the brain: design, decide, verify. agy (via `agy-run`) is the hands: read, edit, generate.

## When to delegate
Delegate, and lean toward doing so:
- large reads or analysis where only the conclusion matters
- bulk or mechanical changes: migrations, renames, scaffolding, test generation
- web research; second-opinion review
- independent units that can run in parallel (one run per unit)

Do it yourself:
- small edits, or anything faster to do than to brief
- design decisions and work that depends on this conversation's context
- edits to files another run or you are changing

## Limits
- agy does not have this conversation, your MCP servers, or your skills.
- Unless the user's agy settings allow them, terminal commands are denied, and a denial ends the run with an empty reply. Run tests yourself.
- It may have no tool to list or search directories. Name every file in `Target` (get the list with `git ls-files` or a search first).
- Whatever agy reads is sent to an external service. Do not delegate work that touches secrets, personal data, or directories the user would not share.

## Brief
agy only knows the brief. Write it to a temporary file outside the repository:

```
Goal:        <one sentence>
Target:      <file paths, relative>
Done when:   <observable criteria, e.g. a test passes>
Off-limits:  <what must not change>
Rules:       <rules for this task that no attached file covers, or none>
```

`agy-run` attaches every `CLAUDE.md` and `.claude/CLAUDE.md` from the working directory and its parents below `$HOME` (and from the main checkout of a linked worktree), and lists them on stderr. Do not copy those into the brief.
- Not attached: `~/.claude/CLAUDE.md`, `CLAUDE.local.md`, `.claude/rules/`, `@` imports, memory. Put what bears on the task into `Rules`, leaving out personal details.
- Attached files leave your machine whole. If one holds secrets or personal data, do not delegate.

Decide the design yourself first; the brief carries decisions, not open problems.

## Running
Call `agy-run` with Bash and `run_in_background: true`, keep working, and read the output when you are notified.

Progress goes to stderr while agy works: the conversation id, then one line per tool call or tool failure. Read the background output to check on a run. Silence between lines is normal while agy thinks.

```
agy-run --mode read-only --brief-file <file>   # analysis, research, review
agy-run --mode write --brief-file <file>       # changes
```

- Put `--mode` first, so permission rules can match on it.
- Optional: `--model <name>`, `--effort low|medium|high|xhigh|max`, `--timeout <seconds>` (default 1800).
- One-shot `claude -p` sessions cannot collect background results later: run in the foreground with `--timeout 570` and a Bash timeout of 600000 ms.

## Working directory
agy works in your current checkout, like a subagent: it sees uncommitted changes, and in write mode edits files directly.
- Before a write run, note `git status` so you can tell agy's changes from existing ones.
- While it runs, do not edit the files it was given.
- For parallel write runs, give each its own worktree (`git worktree add`) and pass `--dir <worktree>`. A new worktree has no uncommitted changes. Review before merging (commit only if the user allows it), then remove the worktree and its branch.

## Reading the result
The reply is free text, followed by an `AGY_META` line with the conversation id and status.

| status | exit | meaning | do |
|---|---|---|---|
| `done` | 0 | criteria met, by agy's account | verify |
| `partial` | 0 | work remains | verify, then decide about the rest |
| `blocked` | 20 | the answer changes the result | answer (or ask the user), then resume |
| `unknown` | 13 | no readable status | read the reply and the diff, then judge |

Verify yourself: run the checks, and in write mode read `git diff` and check `git status` for new files, which `git diff` omits. agy's own claim is not evidence.

To resume, put the answers in a new brief file and run with the same `--mode` and `--dir`, adding `--resume <conversation_id>`.

## Failures
| exit | meaning | do |
|---|---|---|
| 1 | other failure, or `--resume` id not found (agy answered without the history) | read the error; check for partial edits before retrying |
| 2 | usage error | fix the command |
| 10 | quota / rate limit | use a normal subagent with the same brief, do it yourself, or wait |
| 11 | not signed in | ask the user to run `agy` once and sign in |
| 12 | timeout | narrow the task or raise `--timeout`; resume if there is a conversation id |

Codes 10 to 12 are detected by matching error text and may be missed; treat an unexplained exit 1 with that in mind.
