# Contributing

Issues and pull requests are welcome. Keep changes small and focused.

- The plugin is deliberately minimal: one skill and one wrapper script. Open an issue before adding a new component.
- Never commit credentials, tokens, personal data, or absolute home-directory paths.
- Scripts must stay dependency-free beyond `bash`, `jq` and `git`.
- Check before opening a PR: `bash -n bin/agy-run` and a manual run of `agy-run` in `read-only` mode.
- For security issues, follow [SECURITY.md](SECURITY.md) instead of opening an issue.
