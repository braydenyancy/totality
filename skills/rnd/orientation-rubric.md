# Orientation Rubric

Before invoking `AskUserQuestion` for the first time about feature scope, write a 2–4 paragraph plain-language explanation to the user.

## What to cover

1. **What currently exists end-to-end** — the system you found, in non-jargon terms a non-developer could follow. Name the major pieces, how they connect, what they're responsible for.
2. **Where the user's request maps** — which existing piece(s) the requested feature touches, what already supports it, what doesn't.
3. **The gaps** — what specifically is missing for the requested feature to work as imagined.

## Why this is non-negotiable

Multiple-choice options without prior explanation force the user to either:
- Pick blindly
- Ask "what does that mean?"
- Abandon the flow

All three waste turns. After the orientation, `AskUserQuestion` options will land — the user has the mental model to choose meaningfully.

## When the user pushes back

If they say *"explain X first"*, the orientation skipped a layer. Expand that piece and re-ask. Don't proceed to the question until they've signaled understanding.

## What this is NOT

- Not a literature review of the entire codebase. Stay scoped to the feature.
- Not a code listing. Plain language; file paths only when essential.
- Not a hedge. Make claims about how the system works, then ask the question.
