# agy-hands

A Claude Code plugin that lets Claude delegate work to the [Antigravity CLI](https://antigravity.google/docs/cli/headless/) (`agy`). Claude plans and verifies; agy does the reading and editing.

Community project, not affiliated with Google or Anthropic. See [SECURITY.md](SECURITY.md) before using `write` mode.

## What is in it

| file | role |
|---|---|
| `skills/agy-hands/SKILL.md` | when to delegate, how to brief and run, how to read results and failures |
| `bin/agy-run` | wrapper around `agy -p`: read/write modes, resume, status line, exit codes |

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
- **Verification stays with the caller.**

## Status
Early. `agy-run`'s detection of quota, auth and timeout errors is heuristic (agy documents no error codes).

## License
[MIT](LICENSE)
