# agy-hands

A Claude Code plugin that lets Claude delegate work to the [Antigravity CLI](https://antigravity.google/docs/cli/headless/) (`agy`). Claude plans and verifies; agy does the reading and editing.

Community project, not affiliated with Google or Anthropic. See [SECURITY.md](SECURITY.md) before using `write` mode.

## What is in it

| file | role |
|---|---|
| `skills/agy-hands/SKILL.md` | when to delegate, how to brief and run, how to read results and failures |
| `bin/agy-run` | wrapper around `agy -p`: read/write modes, progress, resume, status line, exit codes |
| `tests/agy-run.test.sh` | tests for `agy-run` with a stub `agy` |

## Install
```
/plugin marketplace add shallow-products/agy-hands
/plugin install agy-hands@agy-hands
```
Or from a clone: `claude --plugin-dir ./agy-hands`.

## Requirements
`agy` on `PATH` and signed in, `jq`, `bash`, `git`.

## Permissions
Claude calls `agy-run` through Bash, which Claude Code asks you to approve. To let read-only runs proceed unattended while still being asked about writes:

```json
{ "permissions": { "allow": ["Bash(agy-run --mode read-only:*)"] } }
```

`Bash(agy-run:*)` also allows write runs without asking; read [SECURITY.md](SECURITY.md) first.

## Design notes
- **No MCP server, no relay subagent.** Claude runs `agy-run` as a background Bash command and reads the reply directly.
- **Status only.** agy replies in free text and ends with `STATUS: done`, `partial` or `blocked`. A reply without one is reported as `unknown`, not discarded. Answer `blocked` questions and resume with `--resume`.
- **Modes.** `read-only` maps to agy `--mode plan`; `write` maps to `--mode accept-edits`. Neither uses `--dangerously-skip-permissions`.
- **Shared checkout.** agy works where Claude works. Use a separate worktree and `--dir` for parallel writes.
- **Rules travel with the task.** `agy-run` adds the `CLAUDE.md` and `.claude/CLAUDE.md` files of the working directory and its parents below `$HOME` to every prompt. `~/.claude/CLAUDE.md` and `CLAUDE.local.md` are left out. agy is asked to follow them; nothing enforces it.
- **Progress.** `agy-run` reads agy's event stream and prints the conversation id and each tool call to stderr.
- **Headless.** agy is told not to write a plan for approval, run commands or start subagents. Unless your agy settings allow them, commands are denied, and agy may have no tool to list or search directories, so briefs name the files.
- **Verification stays with the caller.**

## Status
Early. `agy-run`'s detection of quota, auth and timeout errors is heuristic (agy documents no error codes).

## License
[MIT](LICENSE)
