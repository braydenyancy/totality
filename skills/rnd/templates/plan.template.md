# <Feature Description> — Implementation Plan

## Bootstrap

> Run these before touching code to load full context.

- Read: knowledge/<feature-slug>/current.md
- Read: knowledge/<feature-slug>/plan.md (this file)
- Run: gitnexus_impact({target: "<primary symbol>", direction: "downstream"})
- (any other commands the executor needs)

## Architecture References

[<PREFIX>-001] path/to/file.ts:LINE
[<PREFIX>-002] path/to/other.ts:LINE

## Implementation Steps

1. <description> — touches [<PREFIX>-001], [<PREFIX>-003]
   - Specific change: ...
   - Risk: ...
2. ...

## Validation

- Browser test: <specific behaviors to verify>
- GitNexus post-check: gitnexus_detect_changes()
- (any other validation steps)
