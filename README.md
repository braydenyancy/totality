# Totality

A Claude Code plugin pack that orchestrates focused agents to take a feature from "I have an idea" to "here's a plan another agent can execute."

v0.1 ships with one capability — **R&D** (codebase discovery + planning). Future versions add an executor (writes the code) and a librarian (manages accumulated knowledge across features).

## What's inside

| Component | Purpose |
|---|---|
| `/totality` | Orchestrator. Runs doctor, infers intent, dispatches the right agent, decides next step. |
| `/totality:doctor` | Health check. Verifies required plugins, MCP tooling, and freshness. Halts on hard failures. |
| `/totality:rnd` | R&D methodology. Used by the rnd agent; also user-invocable for power users who want to skip the orchestrator. Wired with a mandatory `devils-advocate` pass before plan write. |
| `/totality:debrief` | Postmortem capture. Walks through a structured debrief of a totality miss (or surprising win) one question at a time, verifies each answer against the codebase, and writes a case study to `knowledge/feedback/<slug>.md`. Future rnd runs ingest these as prior-lessons constraints. |
| `agents/rnd` | Forked worker that does discovery and writes `knowledge/<slug>/current.md` + `plan.md`. |
| SessionStart hook | Surfaces in-progress features (anything in `knowledge/`) at the start of each session. |

## Install

One-liner (clones to `~/.local/share/totality`, symlinks skills/agents into `~/.claude/`, merges the SessionStart hook into `~/.claude/settings.json`):

```bash
curl -fsSL https://raw.githubusercontent.com/braydenyancy/totality/main/install.sh | bash
```

Or from a local checkout:

```bash
git clone https://github.com/braydenyancy/totality.git
cd totality && ./install.sh
```

Update later: `~/.local/share/totality/install.sh --update`
Uninstall:    `~/.local/share/totality/install.sh --uninstall`

Override locations with `TOTALITY_DIR` (source repo) or `CLAUDE_HOME` (Claude config dir).

Restart Claude Code after install. Requires `git` and `node` (Claude Code already needs node).

### Via Claude Code plugin marketplace (alternative)

```
/plugin marketplace add braydenyancy/totality
/plugin install totality@totality
```

## Required dependencies

Doctor will halt until these are installed:

- **GitNexus** — codebase graph that powers R&D's discover phase.
  ```
  /plugin marketplace add gitnexus/gitnexus
  /plugin install gitnexus
  ```

- **devils-advocate** — adversarial pass over the rnd discovery before it becomes a plan. Not a Claude Code plugin (no marketplace install), so we vendor it via `degit`:
  ```
  npx degit notmanas/claude-code-skills/skills/devils-advocate ~/.claude/skills/devils-advocate
  ```
  The `install.sh` script checks for this and prints the command if missing. rnd halts at invocation time without it.

Recommended (warns but doesn't block):

- `code-review`, `commit-commands`, `security-guidance`, `skill-creator` from the official Anthropic marketplace
- `superpowers` (for `/superpowers:brainstorming` handoffs)

See [`skills/doctor/plugin-matrix.md`](skills/doctor/plugin-matrix.md) for the source of truth.

## Usage

```
/totality                              # ask me what you want
/totality add audio reactivity         # infer rnd, dispatch
/totality:rnd add audio reactivity     # skip the orchestrator (power user)
/totality:debrief audio-visual miss    # capture a postmortem case study
/totality:doctor                       # health check
```