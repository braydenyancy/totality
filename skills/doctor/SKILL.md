---
name: doctor
description: Health check for the totality plugin pack. Verifies required plugins are installed and current, checks totality itself for updates, and confirms external tools (GitNexus MCP, fresh index) are ready. Used standalone for diagnostics, and called by the totality orchestrator before dispatching any agent.
---

# Doctor — Health Check

Verify the totality stack is ready to work. Halt with actionable instructions when anything fails.

## Transparency rule

**Always print the full report**, regardless of how doctor was invoked. Every plugin in the matrix gets a line — pass, warn, or fail — so the user can see what was checked. Silent passes are forbidden: a check that wasn't reported is a check that wasn't run.

This applies whether doctor is run standalone (`/totality:doctor`) or called internally by `/totality`. The orchestrator must not suppress, summarize, or replace the report — it should appear verbatim before any next-phase action.

## Checks (in order)

You must execute **every** numbered check below and emit a result line for each row in each matrix table. Do not collapse, skip, or shortcut steps even if a prior step suggests the system is healthy — partial reports hide real gaps (e.g., a reachable MCP server does not prove the plugin manifest exists).

### 1. Read the plugin matrix

Read [`plugin-matrix.md`](plugin-matrix.md) — the source of truth for required plugins, minimum versions, and external tooling. All subsequent checks reference this file. List every row you found from each table at the start of your run, so the user can see what's about to be probed.

### 2. Required plugins installed

For each plugin in the **Required plugins** table:

- Check whether it's installed (e.g., does `~/.claude/plugins/marketplaces/<source>/plugins/<name>/.claude-plugin/plugin.json` exist, or use `/plugin` listing if available).
- If missing, fail with the exact install command:

  ```
  /plugin marketplace add <source>
  /plugin install <name>
  ```

- Compare installed version against minimum. If behind, surface upgrade command.

If any required plugin is missing or behind, **halt** — use `AskUserQuestion`:

> "Required plugin `<name>` is missing/outdated. Install/update now?"
> Options:
> - "I'll install it — wait" (pause; user re-invokes when done)
> - "Skip and continue anyway" (only allowed if user explicitly accepts the risk)
> - "Abort"

### 3. Recommended plugins

For each plugin in the **Recommended plugins** table, run the same install + version probe used for required plugins. Collect the missing/outdated ones into a list.

If the list is empty, continue silently to step 4.

If any are missing or outdated, **prompt the user** — do not skip past it. Use `AskUserQuestion`:

> "Recommended plugins missing or outdated: `<name1>`, `<name2>`, … . Want to install/update them before continuing?"
> Options:
> - "Install all — wait" — print every install/upgrade command in one block, then pause: *"Run those, then re-invoke `/totality` (or `/totality:doctor`) to re-check."* Halt.
> - "Pick which to install" — for each missing plugin, ask a follow-up `AskUserQuestion` (Install / Skip). Print install commands only for the picks. Halt for the user to run them.
> - "Skip all — continue without them" — log the skip, list what was skipped in the report, continue to step 4. **Non-blocking.**

This is the only difference from required plugins: the user is allowed to opt out and proceed. They must still be offered the choice — never silently warn and continue.

### 4. External tooling

For each entry in **External tooling**:

- **GitNexus MCP server** — call `mcp__gitnexus__list_repos`. If the tool fails to load or returns nothing, surface the install link and halt (rnd agent depends on this).
- **Fresh GitNexus index** — read `gitnexus://repo/<repo>/context` if available. If stale, halt with: *"GitNexus index is stale (last indexed: <commit>). Run `npx gitnexus analyze` in your terminal, then re-invoke."*

### 5. Self-update

Read totality's own version from `.claude-plugin/plugin.json` (resolve via `${CLAUDE_SKILL_DIR}/../../.claude-plugin/plugin.json`).

Compare against the latest version in the marketplace totality was installed from. If behind:

> "Totality v<installed> is behind v<latest>. Update now?"
> Options:
> - "Update — wait" → instruct: `/plugin update totality`
> - "Skip"

(For v0.1, if the marketplace lookup is not yet available, log "self-check skipped — marketplace lookup not implemented" and continue. Do not halt.)

## Report format (always emitted)

```
totality doctor

Required plugins:
  ✓ gitnexus 0.3.1 (≥ 0.1.0)

Recommended plugins:
  ✓ code-review 1.2.0
  ✗ superpowers — not installed
    install: /plugin marketplace add <source> && /plugin install superpowers

External tooling:
  ✓ GitNexus MCP server reachable
  ✓ Index fresh (last commit: 2026-05-07)

Self:
  ✓ totality 0.1.0 (latest)

Result: PASS (1 recommended plugin missing — non-blocking)
```

## Rules

- **Always print the full report** — every required plugin, every recommended plugin, every external tool, and the self-check. No silent passes, ever. If a check was performed, the user sees the result.
- **Run every check** — do not infer one check from another (e.g., MCP reachability does not satisfy the plugin manifest probe). Each row in the matrix gets its own probe and its own line.
- **Halt on hard failures only** — required plugins, GitNexus MCP, stale index.
- **Prompt on soft failures** — recommended plugins and self-update offer the user an explicit install/skip choice via `AskUserQuestion`. Never silently skip past missing recommendations.
- **User can always opt out of soft failures** — if they pick skip, log it in the report and continue.
- **Always actionable** — every install/upgrade prompt includes a copy-pasteable command.
- **Idempotent** — running doctor twice in a row produces the same report; running after the user fixes a problem reflects the fix.
