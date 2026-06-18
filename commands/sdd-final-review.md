---
description: Full SDD review pipeline — QA Engineer + Security Engineer in parallel, then Tech Leader as dispatcher. Saves cycle report and posts verdict to GitHub PR.
---

Execute the full SDD final review pipeline for the current implementation.

## Step 1: Identify Review Context

- **Spec/Feature ID**: Use `$ARGUMENTS` if provided. Otherwise run `git branch --show-current` and sanitize the branch name (e.g., `feature/auth-refactor` → `auth-refactor`).
- **Timestamp**: Current date/time as `YYYYMMDD-HHmm`.

### Spec Resolution

Determine `<report-root>` using this order:

1. Check if `spec/` or `specs/` exists at the project root.
2. If it exists:
   - Search its subfolders for one whose name contains the sanitized branch/spec-id (e.g., `001-auth-refactor` matches `auth-refactor`).
   - If no match, pick the subfolder with the **highest numeric prefix** (most recent spec).
   - Set `<report-root>` = that subfolder (e.g., `spec/001-auth-refactor`).
3. If neither `spec/` nor `specs/` exists: set `<report-root>` = project root.

Report paths:
- QA reports → `<report-root>/reports/qa_engineer/`
- Security reports → `<report-root>/reports/security_engineer/`
- Tech Leader reports → `<report-root>/reports/tech_leader/`

**Cycle number**: count existing files in `<report-root>/reports/tech_leader/`, increment by 1 (or start at 1).

## Step 2: Parallel Review — QA Engineer + Security Engineer

Spawn two sub-agents simultaneously using the Agent tool.

### QA Engineer Sub-agent
Spawn with this prompt:

```
You are a senior QA Engineer — detail-oriented, systematic, focused on coverage and edge cases.

Analyze the current implementation:
1. Run `git diff --name-only HEAD~1` to find changed files
2. Locate test files (*.test.*, *.spec.*, __tests__/, tests/)
3. Run tests if possible: detect and execute npm test --coverage, pytest --cov, go test -cover, or equivalent
4. Check for: null/undefined handling, off-by-one errors, unhandled errors, missing input validation
5. Scan for TODO/FIXME/HACK comments
6. Compare implementation against spec doc in docs/ or specs/ if it exists
7. Check if `devin` CLI is available with `which devin`. If yes, prepare key implementation files and run:
   devin "Act as senior QA Engineer. Review for bugs, missing edge cases, test coverage gaps. Return structured report with severity levels: <implementation content>"
   Include output as "External QA Opinion" section.

Return this exact structure:
## QA Engineer Report

### Test Coverage
- Estimated coverage: X%
- Uncovered critical paths: [file:line]

### Bugs Found
| Severity | Description | Location |
|----------|-------------|----------|
| HIGH | description | file:line |

### SDD Compliance
- ✅ Implemented: [list]
- ❌ Missing: [list]
- ⚠️ Deviated: [description]

### External QA Opinion (Devin)
[output or "Not available"]

### Verdict: PASS / FAIL
**Confidence:** HIGH / MEDIUM / LOW
**Blocking action items:**
- [ ] item
```

### Security Engineer Sub-agent
Spawn with this prompt:

```
You are a senior Security Engineer — adversarial mindset, OWASP expert, think like an attacker.

Analyze the current implementation:
1. Run `git diff --name-only HEAD~1` to find changed files
2. Focus on: auth, authorization, data handling, API endpoints, external integrations
3. Read package.json, requirements.txt, go.mod, or equivalent for dependency CVEs
4. Check OWASP Top 10:
   - A01 Broken Access Control: missing auth checks, IDOR
   - A02 Cryptographic Failures: weak crypto, key storage
   - A03 Injection: SQL/NoSQL/command injection via string concat
   - A04 Insecure Design: missing rate limiting, fraud controls
   - A05 Misconfiguration: verbose errors, open CORS, debug mode
   - A06 Vulnerable Components: outdated packages with CVEs
   - A07 Auth Failures: session management, token expiration
   - A09 Logging Failures: missing security event logs
   - A10 SSRF: unvalidated URL fetching
5. Grep for hardcoded secrets:
   grep -rn "password\s*=" . --include="*.{js,ts,py,rb,go,java}"
   grep -rn "api_key\s*=\|secret\s*=\|token\s*=" . --include="*.{js,ts,py,rb,go,java}"
6. Check if `devin` CLI is available with `which devin`. If yes, run:
   devin "Act as security expert. Review for OWASP Top 10 vulnerabilities. Return structured report with severity levels: <sensitive code sections>"
   Include output as "External Security Opinion" section.

Return this exact structure:
## Security Engineer Report

### Critical & High Findings
| Severity | OWASP | Description | Location |
|----------|-------|-------------|----------|
| CRITICAL | A03 | description | file:line |

### Secrets Scan
- ✅ No hardcoded secrets / ❌ [finding]

### Dependency Vulnerabilities
- [package@version]: [CVE description]

### External Security Opinion (Devin)
[output or "Not available"]

### Verdict: PASS / FAIL
**Confidence:** HIGH / MEDIUM / LOW
**Blocking action items:**
- [ ] item
```

Wait for BOTH sub-agents to complete before Step 3.

## Step 3: Tech Leader — Sequential

Spawn a Tech Leader sub-agent with this prompt (include both full reports as context):

```
You are a senior Tech Leader — synthesis, architecture, pragmatic decisions. You are the final decision-maker and dispatcher.

Context provided:
- QA Engineer Report: <insert full QA report>
- Security Engineer Report: <insert full Security report>

Your tasks:
1. Read ALL ADR files from docs/adrs/*.md if directory exists — list each title
2. Read ALL Learning Lesson files from docs/learning_lessons/*.md if directory exists — list each title
3. Browse key implementation files flagged by QA and Security reports
4. Analyze:
   - Architecture alignment with ADRs
   - SOLID principles and robustness
   - Patterns across QA + Security findings (isolated vs systemic)
   - Whether past Learning Lessons were applied
   - Whether new ADRs should be created for decisions made in this implementation

Dispatch rules:
- APPROVED: all critical/high issues resolved, production-ready
- NEEDS WORK: targeted issues — specify EXACTLY which agents review next (QA only / Security only / QA + Security)
- BLOCKED: fundamental issues — full cycle required after rework

Return this exact structure:
## Tech Leader Verdict

### Architecture Assessment
[alignment with ADRs, SOLID, scalability, complexity]

### ADR Compliance
- ✅ [ADR title]: Compliant
- ❌ [ADR title]: Violation — [description]
- 📝 New ADR needed: [description]

### Learning Lessons Applied
- ✅ [Lesson]: Applied
- ❌ [Lesson]: Not applied — [what was repeated]

### Cross-Report Synthesis
[patterns across QA + Security + Architecture]

---

## Verdict: APPROVED / NEEDS WORK / BLOCKED

### Next Cycle Dispatch
**Agents:** [QA only | Security only | QA + Security | Full cycle | NONE]
**Focus:** [exactly what to verify]

### Mandatory Action Items
- [ ] [action — acceptance criteria]
```

## Step 4: Save Report Artifact

Create the report folders if they don't exist:
- `<report-root>/reports/qa_engineer/`
- `<report-root>/reports/security_engineer/`
- `<report-root>/reports/tech_leader/`

Save each report to its folder as `cycle-<N>-<timestamp>.md`:
- QA → `<report-root>/reports/qa_engineer/cycle-<N>-<timestamp>.md`
- Security → `<report-root>/reports/security_engineer/cycle-<N>-<timestamp>.md`
- Tech Leader → `<report-root>/reports/tech_leader/cycle-<N>-<timestamp>.md`

The Tech Leader file contains the full consolidated report:

```markdown
# SDD Final Review — <spec-id>
**Cycle:** <N> | **Date:** <timestamp> | **Status:** <APPROVED|NEEDS WORK|BLOCKED>

---

## QA Engineer Report
<full QA report>

---

## Security Engineer Report
<full Security report>

---

## Tech Leader Verdict
<full Tech Leader output>

---

## Next Cycle Dispatch
**Agents:** <agents or NONE>
**Focus:** <what to verify>
```

## Step 5: Post to GitHub PR (Optional)

The user already has the GitHub plugin active. Check for an open PR on the current branch and ask the user if they want to post the verdict.

If confirmed:
- Post a PR review: APPROVE if verdict is APPROVED, REQUEST_CHANGES otherwise
- Body: the full Tech Leader Verdict section
- For each CRITICAL or HIGH security finding with a file:line location, add an inline review comment

## Step 6: Present Verdict

Show a concise summary with verdict, action items, next cycle agents, and path to the saved report.
