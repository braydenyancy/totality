# Tag Format

Every discovered symbol gets a tag in `current.md`. Tags are how the plan references discovered code without copying snippets.

## Format

```markdown
### [<PREFIX>-001] SymbolName
- File: path/to/file.ts:LINE
- Does: one-line purpose
- Connected to: [<PREFIX>-003] (consumer), [<PREFIX>-007] (dependency)
- Gaps: known unknowns, missing capabilities, open questions
```

## Rules

- **Prefix** is the 2–4 letter feature abbreviation chosen in Phase 2 (e.g., `AMM` for "add minimap").
- **Number** increments in discovery order. If `current.md` already has tags up to `[AMM-014]`, your next tag is `[AMM-015]`. Never re-number.
- **One tag per symbol**, not per file. A file with two relevant exports gets two tags.
- **Only tag after reading the actual file.** GitNexus listing a symbol does not justify a tag — read the code first.
- **Connections** point to other tags in `current.md`. If you reference a symbol you haven't read yet, leave the connection out and add it later when you tag that symbol.
- **Gaps** capture honest unknowns: "unclear whether X handles concurrent calls", "no tests for the empty-input case", "may interact with Y but didn't verify". The plan addresses these explicitly.

## Example

```markdown
### [AMM-001] AudioAnalyzer
- File: packages/client/src/audio/analyzer.ts:42
- Does: FFT-based frequency band extraction from microphone input, runs in Web Audio worklet
- Connected to: [AMM-003] (consumer — VisualizerCanvas reads its output), [AMM-007] (dependency — uses MicrophoneStream)
- Gaps: only handles mono input; stereo behavior undefined. No teardown when component unmounts.
```
