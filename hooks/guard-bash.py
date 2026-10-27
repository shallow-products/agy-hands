#!/usr/bin/env python3
"""PreToolUse guard (plugin-level hook) for the agy-worker subagent.

Applies only when the hook input names agy-worker as the calling agent; every
other agent and the main session pass through untouched. For agy-worker, Bash is
limited to `agy-run ...` and read-only `git status` / `git diff`. Exit 2 blocks.
"""
import json
import re
import sys

WORKER = "agy-worker"
ALLOWED = (
    re.compile(r"^agy-run(\s|$)"),
    re.compile(r"^git (status|diff)(\s|$)"),
)
SINGLE = re.compile(r"'[^']*'")
QUOTED = re.compile(r"\"(?:[^\"\\]|\\.)*\"|'[^']*'")
CHAINING = re.compile(r"[;&|`<>\n]|\$\(")
SUBST = re.compile(r"`|\$\(")  # expanded by the shell even inside double quotes
# git flags that write files or run external programs
GIT_UNSAFE = re.compile(r"(^|\s)--(output|ext-diff|textconv|no-index|open-files-in-pager)\b|(^|\s)-O")


def is_worker(data: dict) -> bool:
    agent = data.get("agent_type") or ""
    return agent == WORKER or agent.endswith(":" + WORKER)


def main() -> int:
    try:
        data = json.load(sys.stdin)
        command = data.get("tool_input", {}).get("command", "").strip()
    except (ValueError, AttributeError):
        return 2  # unreadable input: fail closed
    if not is_worker(data):
        return 0
    bare = QUOTED.sub("", command)
    unsafe = CHAINING.search(bare) or SUBST.search(SINGLE.sub("", command))
    if command.startswith("git ") and GIT_UNSAFE.search(command):
        unsafe = True
    if any(p.match(command) for p in ALLOWED) and not unsafe:
        return 0
    print(
        "agy-worker may only run `agy-run ...`, `git status`, or `git diff`. "
        "Do not do the task yourself; report back to the caller instead.",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
