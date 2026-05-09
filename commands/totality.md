---
description: Orchestrator for the totality plugin pack. Runs the doctor gate, infers intent, dispatches the right agent, decides next step.
argument-hint: "[feature description or task — e.g. add audio reactivity]"
---

Use the `totality` skill to handle this request.

User input: $ARGUMENTS

Follow the skill's control loop exactly: doctor gate first, then intent inference, then dispatch, then assess, then offer the next step. Do not skip phases.
