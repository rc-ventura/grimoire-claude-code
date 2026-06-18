Creates a Learning Lesson document in the current project and updates CLAUDE.md with a lessons index. Trigger this whenever the user asks to document a technical discovery, insight, or lesson learned — phrases like "create a lesson learned", "record a learning lesson", "document what I learned", "lesson learned", "register this insight", "document this discovery", or any request to capture a technical learning from development work. Creates the file in ./docs/learning-lessons/ and keeps the CLAUDE.md index updated.

$ARGUMENTS

## Process

### 1. Collect information

Extract as much as possible from the user's message. Ask iteratively for what's missing — never dump a full form at once.

| Field | Required | Default |
|---|---|---|
| Title | ✅ | — |
| Context (where/when discovered) | ✅ | — |
| Date | ✅ | Today (YYYY-MM-DD) |
| Future intent (what to do with it) | ❌ | *(omit)* |
| Mental model / conceptual diagram | ❌ | *(omit)* |
| Comparison table | ❌ | *(omit)* |
| API / code reference | ❌ | *(omit)* |
| Practical examples from the project | ❌ | *(omit)* |
| Relation to ADRs / next steps | ❌ | *(omit)* |

If the user already provided full content, generate directly without asking. Only ask about title and context if they're missing.

### 2. Generate the file

File name: `title_in_snake_case.md` inside `./docs/learning-lessons/` (create the folder if it doesn't exist).

Omit sections for which the user provided no content.

Template:

```markdown
# [Main Title]: [Optional subtitle]

**Context:** [Where/when discovered — e.g. "Discovered during B6 (Spec 005) while analyzing..."]
**Date:** YYYY-MM-DD
[**Future intent:** [what to do with this learning] — only if provided]

---

## Mental Model: [Model name]

[ASCII diagram or conceptual explanation]

[Comparison table if relevant]

| Layer | Where it acts | What it covers | What it doesn't cover |
|-------|--------------|----------------|----------------------|

---

## [Technical section — e.g. "LangGraph API (verified on v1.2.0)"]

[Code, configurations, annotated snippets]

---

## Examples for [Project Name]

### 1. [Example name]

[Real project code applying the learning]

**Responsibility split:**
- [Component A]: [role]
- [Component B]: [role]

---

## Relation to ADRs and next steps

- **ADR-XXX** — [how it relates]
- [Concrete next step]
```

### 3. Update CLAUDE.md

After creating the file, update `CLAUDE.md` at the project root.

Look for `## Learning Lessons` in CLAUDE.md:
- If it **exists**: add the new entry at the end of the existing list.
- If it **doesn't exist**: append to the end of the file:

```markdown

## Learning Lessons

> Folder: `./docs/learning-lessons/`

- [Lesson title](./docs/learning-lessons/file_name.md) — YYYY-MM-DD
```

If `CLAUDE.md` doesn't exist in the project, create it with only this section.

### 4. Confirm to the user

Report:
- Path of the created file
- That CLAUDE.md was updated with the new entry
