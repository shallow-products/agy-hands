# Contributing

Issues and pull requests are welcome. Keep changes small and focused.

- The plugin is deliberately minimal: one skill and one wrapper script. Open an issue before adding a new component.
- Never commit credentials, tokens, personal data, or absolute home-directory paths.
- Scripts must stay dependency-free beyond `bash`, `jq` and `git`.
- For security issues, follow [SECURITY.md](SECURITY.md) instead of opening an issue.

## Before opening a PR
- `bash -n bin/agy-run`
- `bash tests/agy-run.test.sh` (uses a stub `agy` and sends nothing anywhere)
- After changing `bin/agy-run`, one manual `read-only` run with the real `agy`
- After changing a manifest, `claude plugin validate . --strict`

## Releasing
Bump `version` in `.claude-plugin/plugin.json` and add an entry to [CHANGELOG.md](CHANGELOG.md). Installed copies update only when the version changes.
