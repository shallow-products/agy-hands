# Security policy

## Reporting a vulnerability
Please report vulnerabilities privately through GitHub's
["Report a vulnerability"](../../security/advisories/new) form on this repository
(Security tab). Do not open a public issue for security problems.

## What this plugin can do
`agy-hands` lets Claude Code run the Antigravity CLI (`agy`) on your machine. In
`write` mode `agy` edits files in your current checkout without asking. Treat it
like any agent with file access:

- review the diff after every write run, and use a separate git worktree (`--dir`) when changes must stay apart;
- nothing in this plugin confines `agy` or Claude to a directory or a command set;
- allowing `Bash(agy-run:*)` lets write runs start without a prompt;
- do not run it in directories that contain credentials, personal data or production data;
- `CLAUDE.md` files in the working directory and its parents below `$HOME` are sent with every task; the rules in them are instructions to `agy`, not an enforced limit;
- briefs, anything `agy` reads, and its replies leave your machine or are untrusted text: do not put secrets in them.

## Supported versions
Only the latest release on `main`.
