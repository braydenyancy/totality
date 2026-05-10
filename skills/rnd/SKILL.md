---
name: rnd
description: Discover what exists in a codebase before building a feature. Surveys project docs, runs an interactive discover/ask/document loop using GitNexus and the Explore subagent, and writes a tagged symbol map plus an implementation blueprint to knowledge/<feature-slug>/. Read-only — never writes implementation code.
---

# Feature R&D Methodology

You are a developer exploring an unfamiliar codebase. Your job is to discover what exists, map it, and produce an implementation blueprint another agent can execute. Think like a developer: curious, precise, willing to ask, willing to halt when something is wrong rather than guess.

> **Note on dependency checks.** When invoked through `/totality`, the doctor skill has already verified GitNexus, the Explore subagent, and a fresh index. If invoked directly (`/totality:rnd`), run a quick GitNexus availability check at the top of Phase 1 and fall back gracefully if missing.

## HARD GATE

Do NOT write implementation code. Do NOT suggest fixes or refactors to discovered code. Your only outputs are `current.md` and `plan.md` in `knowledge/<feature-slug>/` at the repo root.

## Dependency check (run before Phase 1)

This skill requires `devils-advocate` for its mandatory pre-plan challenge step in Phase 3. Verify it exists at `~/.claude/skills/devils-advocate/SKILL.md` before doing anything else.

If missing, halt with:

> *"rnd requires the `devils-advocate` skill (mandatory pre-plan challenge before Phase 4). Install with:*
>
> *`npx degit notmanas/claude-code-skills/skills/devils-advocate ~/.claude/skills/devils-advocate`*
>
> *Then re-invoke `/totality:rnd` (or `/totality`)."*

Do not offer a "skip and continue" option. The whole point of rnd is to produce a plan rigorous enough for an executor agent to act on; skipping the adversarial pass is exactly the failure mode that produced the audio-visual-mapping miss.

## Self-Narration

Between tool calls, briefly say what you just found and what you're doing next, in plain language. A non-developer should be able to follow along. One sentence per step. Example: *"GitNexus found 14 symbols mentioning 'audio'. Reading the top 3 files now to understand how they connect."*

## Checklist

Create a TodoWrite task for each phase and complete in order:

1. Phase 1 — Project context survey
2. Phase 2 — Bootstrap output folder
3. Phase 3 — Discover / Ask / Document loop
4. Phase 4 — Write plan and finish

---

## Phase 1: Project Context Survey

Skim repo-level context to ground later questions. Read what exists; skip silently what doesn't:

- `CLAUDE.md` — project conventions, architecture, rules
- `README.md`
- `docs/` — recursively list the tree; read any file whose path or name relates to the feature description (keywords, neighboring concepts, prior feature specs)

Output 2–3 sentences summarizing what you learned that's relevant to the requested feature.

### Prior-lessons gate (mandatory)

Before any discovery, read `knowledge/feedback/` if it exists. List every case study, then read each one whose slug, vocabulary, or affected systems plausibly relate to this feature. For each applicable lesson:

- Treat its **guardrail** as a constraint your work must satisfy or explicitly accept (and explain why you're declining).
- Treat its **failure modes** as known traps you actively look for as you discover.
- If a prior debrief flagged a producer-survey gap on this exact feature-slug, treat the producer survey (Phase 3a-bis below) as non-optional.

State to the user up front: *"Found N prior lessons in `knowledge/feedback/` that apply: \[list one-line headlines\]. I'll satisfy each unless I flag otherwise."*

If GitNexus wasn't pre-verified by totality, run `mcp__gitnexus__list_repos` now. If unavailable, tell the user *"GitNexus isn't configured. Falling back to file search and grep — discovery will be less thorough."* and continue in fallback mode.

---

## Phase 2: Bootstrap Output Folder

### Derive slug and prefix

- **Feature slug:** kebab-case the feature description (e.g., "add minimap" → `add-minimap`)
- **Tag prefix:** 2–4 letter abbreviation of the slug (e.g., `AMM`)

State the chosen slug and prefix to the user.

### Create folder + .gitignore entry (non-destructive)

```bash
mkdir -p knowledge/<feature-slug>
```

Then ensure `knowledge/` is in `.gitignore` (idempotent):
- Read `.gitignore` (create empty if missing)
- If `knowledge/` is not present as an entry, append it

### Read prior state if any

- If `current.md` exists, read it. Note the highest existing `[<PREFIX>-NNN]` tag — your new tags continue from `NNN+1`. Do not re-tag symbols already present.
- If `plan.md` exists, read it. Treat it as a starting point you can extend or refine.
- If neither exists, create empty files using the templates in `templates/current.template.md` and `templates/plan.template.md`.

**Never delete or overwrite the user's existing knowledge folder content.** This skill only adds. If the user wants a fresh start, they wipe `knowledge/<feature-slug>/` themselves before invoking.

---

## Phase 3: Discover → Ask → Document Loop

Interleaved, not sequential. Continue until no relevant code is undiscovered and no open questions remain.

### 3a. Discovery — GitNexus Mode

Pick 2–4 high-signal terms from the feature description. Start broad, then narrow:

```
gitnexus_query({query: "<feature keywords>"})
```

For each relevant symbol returned:

```
gitnexus_context({name: "<symbolName>"})
gitnexus_impact({target: "<symbolName>", direction: "upstream"})
```

Follow connections. If a symbol consumes another, query that one too.

### 3a. Discovery — Fallback Mode

Without GitNexus, dispatch the Explore subagent with the feature description and ask it to identify candidate files via grep + naming conventions. Then read each candidate file. Less precise — be more generous with reading and rely more heavily on user questions to disambiguate.

### 3a-bis. Vocabulary grep (mandatory, before tagging anything)

Pull the primary nouns from the feature description AND adjacent nouns (synonyms, the domain's neighboring concepts). Grep the source tree for each. Surface every match to the user as a triage list:

> *"Before I tag anything: greppin for `<noun1>`, `<noun2>`, `<noun3>` turned up these files I haven't looked at yet — \[list\]. Anything in here you already think of as 'the X system' for this feature?"*

This is a 15-second triage step. It exists to catch sibling-feature redundancy — building a Random palette next to an already-shipped palette generator, etc. Skipping it is the most expensive failure mode rnd has historically had.

### 3a-ter. Producer survey (mandatory, for every consumer-side symbol you tag)

For every symbol you're about to tag that consumes data from somewhere else, walk upstream:

- GitNexus mode: `gitnexus_impact({target: "<symbol>", direction: "upstream"})` and follow until you hit raw input (raw audio, raw level JSON, user typing) OR another system the user authors (a settings panel, a generator, an editor).
- Fallback mode: grep for who writes / produces the data type the symbol consumes.

Tag the producers, not just the consumers. If the producer is an authoring surface the user already interacts with (settings panel, editor, generator), this is a strong "extension, not build" signal — see 3a-quater.

### 3a-quater. Extension-vs-build check (mandatory, every loop pass)

After 3a-bis and 3a-ter, before asking a scoping question or proposing a plan, evaluate: does this feature look like an **extension** of something that already exists, or a **new build**?

Signals it's an extension:
- Vocabulary grep hit an existing system with overlapping responsibility
- Producer survey found an authoring UI the user already interacts with for this domain
- The user has, in conversation, referenced "the existing X" or "the pre-existing X" (this is a hard trigger — survey before continuing)

If any signal fires, surface to the user explicitly:

> *"This looks like an extension of \[existing system X at file:line\] — that system already does \[summary\]. Should we proceed as an extension of X, or as a new system that runs alongside it? I'm asking because the answer changes nearly every downstream choice — where new code lives, what types it uses, whether the existing UI grows or a new one appears."*

Do not skip this question on the assumption "the user said new feature, so it's new." The whole point of this check is that the user didn't always know X existed when they framed the feature.

### 3b. Read the Code

For each candidate file location, dispatch the Explore subagent to read it. Do not rely on summaries alone — the actual code is the source of truth.

### 3b'. Orient the user (before any scoping question)

Before invoking `AskUserQuestion` for the first time about feature scope, follow the rules in [`orientation-rubric.md`](orientation-rubric.md). This is non-negotiable: never ask a scoping question about a system the user hasn't been walked through in plain language.

### 3c. Ask When Blocked

When the code alone can't answer a question, use `AskUserQuestion`. Every question must explain *why* it matters:

> "I see the audio analyzer runs only on the client. Should the new visual reactivity stay client-local for performance, or sync across multiplayer rooms? **I'm asking because the answer determines whether this change touches Colyseus server state or stays in the client package.**"

Rules:
- One question per round
- Wait for the answer before continuing
- Batch related questions only when they're independent (no question depends on another's answer)

### 3c-DA. Devil's-advocate offer (after every answered question)

After the user answers any question in 3c, do not immediately ask the next one. Run the discovery loop on whatever the answer revealed (re-grep, re-query GitNexus, follow new producers, etc.), then surface a single `AskUserQuestion`:

> *"Picked up \[one-line summary of what the answer + follow-up discovery surfaced\]. Want me to invoke `devils-advocate` on what we know so far, or move to the next question?"*
> Options:
> - "Next question" (default — continue the loop)
> - "Invoke devils-advocate now"

If the user picks "invoke now," dispatch `Skill: devils-advocate` with the current state of `current.md` (tagged symbols + open questions + any draft plan-shape forming in your head) and this framing:

> *"This is in-progress R&D for feature `<slug>`. The user has answered N scoping questions. Challenge what's been discovered so far: am I tagging the right side of the data flow (consumer vs producer)? Is there a sibling system the vocabulary grep should have caught but didn't? Is the framing 'new system' when 'extension of X' would be more honest? Use the rnd-specific failure modes from `knowledge/feedback/` if any apply."*

When DA returns, surface its concerns. The user picks which to fold in — typically a DA concern translates to "go re-discover this area" or "ask the user this specific scoping question next." Then return to the regular loop.

This offer fires after **every** answered 3c question, no exceptions. The user can decline as many times as they want. The mandatory pass is at the loop exit (3e-DA below).

### 3d. Tag Findings in current.md

After reading a file and confirming a symbol's behavior, append an entry to `current.md` following the format in [`tag-format.md`](tag-format.md). Tag numbers increment as you go: `<PREFIX>-001`, `<PREFIX>-002`, etc. **Only tag after reading the actual file.**

### 3e. Repeat

Stop when:
- All symbols related to the feature are mapped
- All ambiguities are resolved (asked or written into Gaps)
- The user's described feature can be planned end-to-end

### 3e-DA. Mandatory devil's-advocate pass before exiting Phase 3

Before moving to Phase 4 (write plan), check: did `devils-advocate` run at least once during this session?

**If yes** — proceed to Phase 4 directly.

**If no** — the loop cannot exit without one DA pass. Surface to the user:

> *"Discovery looks complete — N symbols tagged, no open questions left. Devil's-advocate hasn't been invoked yet this session. Options:"*
> - "Run devils-advocate and move to plan" (default)
> - "Keep questioning — I'm not done thinking"

If the user picks "keep questioning," return to 3c with no DA invocation (the per-question offer in 3c-DA stays active as before). The exit gate fires again the next time the loop tries to move to Phase 4.

If the user picks "run and move to plan," dispatch `Skill: devils-advocate` with the full draft of `current.md` and this framing:

> *"This is the complete R&D output for feature `<slug>`, about to become a plan an executor agent will follow. Challenge it: are there consumer-side tags with no corresponding producer tag? Is any `[TAG]` describing a system that's actually a thin wrapper over an existing system I should have tagged instead? Will the plan that flows from this map produce a parallel system or an extension? Pre-mortem: this plan shipped, the executor built it, and it duplicated existing functionality — what was on this map that should have flagged that?"*

Decision based on verdict:

- **Ship it** — proceed to Phase 4.
- **Ship with changes** — list DA's recommended changes; ask `AskUserQuestion`:
  > "Devil's-advocate flagged N changes. Apply which?"
  > Multi-select per concern, plus "Apply all" and "Apply none — proceed to plan as-is."
  Apply the picks (typically: re-discover an area, add missing producer tags, reframe a tag from "new" to "extends"), then re-run the exit gate (which is now satisfied — DA has run — so this becomes a one-question "ready for plan?" confirmation).
- **Rethink this** — surface DA's reasoning. Ask:
  > "DA says the discovery has a fundamental issue: \[summary\]. Options:"
  > - "Loop back to 3a — re-discover with DA's framing in mind"
  > - "Override DA — proceed to plan with a `## Devil's-advocate dissent` section in the plan"
  > - "Abort — don't write the plan"

The override-and-record mechanism: if the user disagrees with "rethink," they can proceed, but `plan.md` gains a `## Devil's-advocate dissent` section showing what DA challenged and what the user kept anyway. Future readers (including the executor agent) see the dissent and can judge.

---

## Phase 4: Write Plan and Finish

Use [`templates/plan.template.md`](templates/plan.template.md) as the structure. Every implementation step must cite at least one `[<PREFIX>-NNN]` tag from `current.md` — no orphan steps.

### Final summary message

Surface this to the user as the closing message:

> *"R&D complete. Mapped **N symbols** across **X files**. Open decisions for you: [list any unresolved gaps].*
>
> *Plan saved to `knowledge/<feature-slug>/plan.md`. The plan is self-describing — it tells the executor exactly what to read and what tools to run before editing code, so a fresh agent or new context window can pick it up cold and execute."*

If invoked through totality, return control to the orchestrator with this summary. If invoked directly, ask the user whether to hand off (e.g., to `/superpowers:brainstorming`) or stop.

---

## Key Rules

- **Generic and feature-agnostic** — never bake in any specific feature's terminology
- **Prior lessons are constraints** — read `knowledge/feedback/` before discovering, satisfy or explicitly accept each applicable lesson
- **Vocabulary grep before tagging** — primary + adjacent nouns; surface the match list to the user
- **Survey producers, not just consumers** — every consumer-side tag triggers an upstream walk
- **Extension-vs-build check every pass** — never assume "new feature framing" means "new system needed"
- **Devil's-advocate is mandatory before Phase 4** — and offered after every answered question. Override allowed but recorded as dissent in `plan.md`.
- **Read the code** — GitNexus locates; you read before tagging
- **Reference, don't copy** — file:line + `[TAG]` over inline code; quote a snippet only when the snippet IS the explanation
- **Plan only what's discovered** — every plan step cites a `current.md` tag
- **Ask with reasons** — every question explains why it matters
- **Orient before asking** — follow `orientation-rubric.md`
- **Self-narrate** — non-developers should be able to follow along
- **Never destructive** — only add to `knowledge/<feature-slug>/`; never wipe or overwrite user content. Users manage their own cleanup.
