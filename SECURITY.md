# Security policy

## Reporting a vulnerability
Please report vulnerabilities privately through GitHub's
["Report a vulnerability"](../../security/advisories/new) form on this repository
(Security tab). Do not open a public issue for security problems.

## What this plugin can do
`agy-hands` lets Claude Code run the Antigravity CLI (`agy`) on your machine. In
`write` mode `agy` edits files in its working directory without asking. Treat it
like any agent with file access:

- run write tasks only in the isolated git worktree the `agy-worker` subagent gets, and review the diff before merging;
- do not run it in directories that contain credentials or production data;
- the Bash guard (`hooks/guard-bash.py`) limits the `agy-worker` subagent to `agy-run`, `git status` and `git diff`. It protects against the subagent drifting off task, not against a hostile prompt;
- briefs and agy replies are untrusted text: do not paste secrets into them.

## Supported versions
Only the latest release on `main`.
