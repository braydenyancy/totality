# Totality

A Claude Code plugin pack that orchestrates focused agents to take a feature from "I have an idea" to "here's a plan another agent can execute."

v0.1 ships with one capability — **R&D** (codebase discovery + planning). Future versions add an executor (writes the code) and a librarian (manages accumulated knowledge across features).

## What's inside

| Component | Purpose |
|---|---|
| `/totality` | Orchestrator. Runs doctor, infers intent, dispatches the right agent, decides next step. |
| `/totality:doctor` | Health check. Verifies required plugins, MCP tooling, and freshness. Halts on hard failures. |
| `/totality:rnd` | R&D methodology. Used by the rnd agent; also user-invocable for power users who want to skip the orchestrator. |
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

Recommended (warns but doesn't block):

- `code-review`, `commit-commands`, `security-guidance`, `skill-creator` from the official Anthropic marketplace
- `superpowers` (for `/superpowers:brainstorming` handoffs)

See [`skills/doctor/plugin-matrix.md`](skills/doctor/plugin-matrix.md) for the source of truth.

## Usage

```
/totality                              # ask me what you want
/totality add audio reactivity         # infer rnd, dispatch
/totality:rnd add audio reactivity     # skip the orchestrator (power user)
/totality:doctor                       # health check
```

Output lands at `knowledge/<feature-slug>/current.md` and `knowledge/<feature-slug>/plan.md` in your repo. The hook adds `knowledge/` to `.gitignore` automatically.

## How it fits together

```
User → /totality
         │
         ▼
   ┌─────────────────┐
   │ Doctor gate     │  hard fail → halt with install commands
   └────────┬────────┘
            ▼
   ┌─────────────────┐
   │ Intent infer    │  from $ARGUMENTS or AskUserQuestion
   └────────┬────────┘
            ▼
   ┌─────────────────┐
   │ Dispatch agent  │  Task tool → agents/rnd (forked)
   └────────┬────────┘
            ▼
   ┌─────────────────┐
   │ Agent runs      │  loads totality:rnd skill, writes knowledge/<slug>/
   └────────┬────────┘
            ▼
   ┌─────────────────┐
   │ Assess + offer  │  next step, refine, or stop
   │ next step       │
   └─────────────────┘
```

## Repository layout

```
totality/
├── .claude-plugin/plugin.json      # plugin manifest
├── skills/
│   ├── totality/SKILL.md           # orchestrator
│   ├── doctor/
│   │   ├── SKILL.md                # health check
│   │   └── plugin-matrix.md        # required deps + min versions
│   └── rnd/
│       ├── SKILL.md                # R&D methodology
│       ├── tag-format.md           # [PREFIX-NNN] tag rules
│       ├── orientation-rubric.md   # "explain before asking"
│       └── templates/
│           ├── current.template.md
│           └── plan.template.md
├── agents/
│   └── rnd.md                      # forked R&D worker
├── commands/
│   ├── totality.md                 # /totality
│   └── totality/
│       ├── doctor.md               # /totality:doctor
│       └── rnd.md                  # /totality:rnd
├── hooks/
│   └── hooks.json                  # SessionStart nudge
├── install.sh                      # symlink installer (script-based path)
└── README.md
```

## Extending totality

Adding a new capability (executor, librarian, etc.):

1. Create `agents/<name>.md` — frontmatter sets tools and (optionally) preloaded skills.
2. Optionally create `skills/<name>/SKILL.md` if there's reusable methodology.
3. Add the agent to the registry table in `skills/totality/SKILL.md` and a branch in Phase 2's intent inference.
4. Add any new dependencies to `skills/doctor/plugin-matrix.md`.

Two-skill surface (`/totality`, `/totality:doctor`) stays stable. Capabilities are additive.

## License

MIT (see LICENSE — TODO add)
