# Plugin Matrix

Source of truth for what totality needs to function. The doctor skill reads this file. Update versions here when you change requirements.

## Required plugins (hard deps)

These must be installed for any totality flow to run. Doctor halts if any are missing.

| Plugin | Min version | Source | Why |
|---|---|---|---|
| gitnexus | 0.1.0 | https://github.com/gitnexus/gitnexus | Codebase graph powers the rnd agent's discover phase. |

## Recommended plugins (soft deps)

Doctor warns if missing but does not halt. Useful for downstream handoffs.

| Plugin | Min version | Source | Why |
|---|---|---|---|
| code-review | latest | claude-plugins-official marketplace | Used after a feature ships. |
| commit-commands | latest | claude-plugins-official marketplace | Standardizes commit messages for executor handoff. |
| security-guidance | latest | claude-plugins-official marketplace | Security review pass on R&D output. |
| skill-creator | latest | claude-plugins-official marketplace | Useful for extending totality itself. |
| superpowers | latest | (TBD — confirm source) | `/superpowers:brainstorming` is a documented R&D handoff target. |

## External tooling

Not plugins, but doctor verifies these exist on PATH or as MCP servers.

| Tool | Check | Why |
|---|---|---|
| GitNexus MCP server | `mcp__gitnexus__list_repos` returns | Required for graph queries. |
| Fresh GitNexus index | `gitnexus://repo/<repo>/context` not stale | Stale index produces wrong answers. Halt and instruct re-index. |

## Self-check

Doctor compares the installed totality version (from `.claude-plugin/plugin.json`) against the latest version available in the marketplace this plugin was installed from. If behind, prompts user to run `/plugin update totality`.
