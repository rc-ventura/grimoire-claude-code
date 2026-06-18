Creates an Architecture Decision Record (ADR) in the current project and updates CLAUDE.md with an ADR index. Trigger this whenever the user asks to document a technical or architectural decision — phrases like "create an ADR", "document this decision", "record this architectural choice", "new ADR about", or any request to register a technical decision. Auto-detects the next ADR number, creates the file in ./docs/adrs/, and keeps the CLAUDE.md index up to date.

$ARGUMENTS

## Process

### 1. Detect the next ADR number

Check existing files in `./docs/adrs/`:

```bash
ls ./docs/adrs/ 2>/dev/null | grep -E '^ADR-[0-9]+' | sort | tail -1
```

- If the folder doesn't exist, create it (`mkdir -p ./docs/adrs/`)
- The new ADR number is the highest found + 1, zero-padded to 3 digits (e.g. `ADR-014`)
- If no ADRs exist yet, start at `ADR-001`

### 2. Collect information

Extract as much as possible from the user's message. Ask iteratively for what's missing — one or two questions at a time, never a full form at once.

| Field | Required | Default |
|---|---|---|
| Title | ✅ | — |
| Status | ✅ | `Accepted` |
| Date | ✅ | Today (YYYY-MM-DD) |
| Related spec | ❌ | *(omit if not provided)* |
| Code reference (file:line) | ❌ | *(omit if not provided)* |
| Context | ✅ | — |
| Decision | ✅ | — |
| Alternatives considered | ❌ | *(ask if worth including)* |
| Consequences | ❌ | *(ask if worth including)* |
| References | ❌ | *(omit if not provided)* |

**When not to ask**: if the user provided title + context + decision, generate without asking — use defaults for the rest. Only ask about missing required fields.

### 3. Generate the ADR file

File name: `ADR-NNN-title-in-kebab-case.md` inside `./docs/adrs/`.

Template:

```markdown
# ADR-NNN: [Title]

**Status**: [Accepted | Proposed | Deprecated | Superseded]
**Date**: YYYY-MM-DD
[**Related spec**: [name](relative/path/) — only if provided]
[**Code**: `file:line` — only if provided]

---

## Context

[Describe the problem, the forces at play, and why a decision was needed.
Include technical and business constraints, and the scenario that motivated the decision.]

## Decision

[The decision taken, stated directly. E.g. "Use X as Y" or "Adopt Z instead of W".]

[Code block or configuration illustrating the decision, if relevant]

## Alternatives considered

### Alternative A: [Name]

[Brief description of the alternative]

**Why not chosen**:
- [Reason 1]
- [Reason 2]

**Advantages** (not leveraged):
- [...]

[Repeat block for each alternative]

## Consequences

### Accepted

- [Direct benefits and advantages of the decision]

### Trade-offs

- [What is lost or risks consciously accepted]

### Conditions that invalidate this decision

This decision should be **revisited** if:

1. [Condition 1]
2. [Condition 2]

### Migration path when needed

[Steps ordered from simplest to most complex to undo or evolve the decision]

## References

- [Links, PRs, specs, related ADRs]
```

**Important**: Omit entire sections (Alternatives, Consequences, References) if the user provided no content for them. Never invent content.

### 4. Update CLAUDE.md

After creating the ADR file, update `CLAUDE.md` at the project root to maintain a decision index.

**If `CLAUDE.md` doesn't exist**: create it at the root with only the ADRs section.

**Find the section**: look for `## ADRs` in CLAUDE.md.

- If it **exists**: add the new row to the end of the existing table.
- If it **doesn't exist**: append to the end of the file:

```markdown

## ADRs — Technical Decisions

> Folder: `./docs/adrs/`

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-NNN](./docs/adrs/ADR-NNN-name.md) | Decision title | Accepted | YYYY-MM-DD |
```

Always add the new ADR at the **end of the table**.

### 5. Confirm to the user

Report:
- Path of the created file (e.g. `./docs/adrs/ADR-014-redis-as-cache.md`)
- That CLAUDE.md was updated
- ADR status
