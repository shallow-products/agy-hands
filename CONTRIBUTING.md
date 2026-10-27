# Contributing

Issues and pull requests are welcome. Keep changes small and focused.

- The plugin is deliberately minimal: one subagent, one skill, one wrapper script, one guard hook. Open an issue before adding a new component.
- Never commit credentials, tokens, personal data, or absolute home-directory paths.
- Shell and Python must stay dependency-free beyond `bash`, `jq`, `git` and `python3`.
- Check before opening a PR: `bash -n bin/agy-run` and a manual run of `agy-run` in `read-only` mode.
- For security issues, follow [SECURITY.md](SECURITY.md) instead of opening an issue.
