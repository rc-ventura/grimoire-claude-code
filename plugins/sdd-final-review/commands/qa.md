---
description: Standalone QA Engineer review — test coverage, SDD compliance, bug identification, edge cases. Optional Devin CLI second opinion. Use /sdd-qa or /sdd-qa-review.
---

Act as a senior QA Engineer — detail-oriented, systematic, focused on coverage and edge cases. Perform a thorough quality analysis of the current implementation.

## Spec Resolution

Determine `<report-root>` before saving anything:

1. Check if `spec/` or `specs/` exists at the project root.
2. If it exists:
   - Get current branch: `git branch --show-current`, sanitize name.
   - Search subfolders for one whose name contains the sanitized branch name.
   - If no match, pick the subfolder with the **highest numeric prefix** (most recent spec).
   - Set `<report-root>` = that subfolder (e.g., `spec/001-auth-refactor`).
3. If neither exists: set `<report-root>` = project root.

Report path: `<report-root>/reports/qa_engineer/cycle-<N>-<timestamp>.md`
Cycle number: count existing files in that folder + 1 (start at 1 if empty).

## Exploration

1. Run `git diff --name-only HEAD~1` to identify changed files
2. Locate test files: `*.test.*`, `*.spec.*`, `__tests__/`, `tests/`
3. Look for spec/SDD doc in `<report-root>/`, `docs/`, or root markdown files

## Analysis

### Test Coverage
- Detect test runner and run with coverage: `npm test -- --coverage`, `pytest --cov`, `go test -cover`, `jest --coverage`
- Identify untested critical paths, public methods with zero coverage, error scenarios

### SDD Compliance
- Compare implementation against spec document line by line
- Flag missing features, behavioral deviations

### Bug Identification
- Check: null/undefined handling, off-by-one errors, unhandled promise rejections, missing error cases
- Review input validation at system boundaries
- Scan for `TODO`, `FIXME`, `HACK`, `XXX` comments
- Look for commented-out code indicating incomplete refactoring

### Edge Cases
- Empty inputs, null values, boundary values (min/max)
- Concurrent access and race conditions
- Error recovery and timeout handling

### External QA Opinion (Optional)
Check if Devin CLI is available: `which devin`

If available, prepare key implementation and test files, then run:
```bash
devin "Act as senior QA Engineer. Review for bugs, missing edge cases, test coverage gaps. Structured report with severity levels:\n\n<implementation content>"
```
Include full output as "External QA Opinion" section.

## Save Report

Create `<report-root>/reports/qa_engineer/` if it doesn't exist.
Save the report as `<report-root>/reports/qa_engineer/cycle-<N>-<timestamp>.md`.

## Report

```markdown
## QA Engineer Report

### Test Coverage
- Estimated coverage: X%
- Uncovered critical paths:
  - [description — file:line]

### Bugs Found
| Severity | Description | Location |
|----------|-------------|----------|
| HIGH | [description] | file.ts:42 |

### SDD Compliance
- ✅ Implemented: [list]
- ❌ Missing: [list]
- ⚠️ Deviated: [description]

### Code Quality Notes
- [TODO/FIXME, commented code, incomplete handling]

### External QA Opinion (Devin)
[output or "Not available — devin CLI not installed"]

### Verdict: PASS / FAIL
**Confidence:** HIGH / MEDIUM / LOW
**Blocking action items:**
- [ ] [specific, actionable item]
```
