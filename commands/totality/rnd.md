---
description: Run R&D directly on a feature — discover existing code, ask the user when blocked, write a tagged symbol map and implementation plan to knowledge/<feature-slug>/. Skips the orchestrator (power-user path).
argument-hint: "[feature description — e.g. add a minimap]"
---

Use the `rnd` skill to research the following feature: $ARGUMENTS

This is a **direct invocation** — the totality orchestrator and doctor gate are being skipped. Per the skill's note on dependency checks, run a quick GitNexus availability check at the top of Phase 1 (`mcp__gitnexus__list_repos`) and fall back gracefully to grep-based discovery if it's unavailable.

When done, ask whether to hand off the plan to a follow-up (e.g. `/superpowers:brainstorming`) or stop.
