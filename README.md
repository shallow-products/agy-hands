# agy-hands

A Claude Code plugin that lets Claude delegate work to the [Antigravity CLI](https://antigravity.google/docs/cli/headless/) (`agy`). Claude plans and verifies; agy does the reading and editing.

Community project, not affiliated with Google or Anthropic. See [SECURITY.md](SECURITY.md) before using `write` mode.

## What is in it

| file | role |
|---|---|
| `agents/agy-worker.md` | thin subagent that runs `agy-run` in an isolated git worktree |
| `skills/agy-hands/SKILL.md` | when to delegate, how to brief, how to read results and failures |
| `bin/agy-run` | wrapper around `agy -p`: read/write modes, resume, return contract, exit codes |

## Requirements
`agy` on `PATH` and signed in, `jq`, `bash`, `git`.

## Permissions
`agy-worker` calls `agy-run` through Bash, which Claude Code asks you to approve. Allow it once in your settings so unattended and background runs do not stall:

```json
{ "permissions": { "allow": ["Bash(agy-run:*)"] } }
```

## Design notes
- **No MCP server.** `agy -p` plus Bash covers it.
- **Return contract.** agy must end with `===DIGEST===` / `===QUESTIONS===` / `===VERIFY===`. Open questions come back as `status: blocked`; answer and resume with `--resume`.
- **Modes.** `read-only` maps to agy `--mode plan`; `write` maps to `--mode accept-edits`. Neither uses `--dangerously-skip-permissions`.
- **Bash guard.** A plugin-level `PreToolUse` hook (`hooks/hooks.json` + `hooks/guard-bash.py`) restricts the `agy-worker` subagent to `agy-run`, `git status` and `git diff`. It keys on `agent_type`, so the main session and other subagents are unaffected. (Hooks declared in a plugin agent's own frontmatter are ignored by Claude Code, hence the plugin-level hook.)
- **Verification stays with the caller.** The worker never claims success.

## Status
Early. `agy-run`'s detection of quota and auth errors is heuristic (agy documents no error codes).

## License
[MIT](LICENSE)
