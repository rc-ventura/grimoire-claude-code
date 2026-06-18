# SDD Plugin Marketplace — Specification

> Firetop Mountain · Claude Code Plugin Registry

---

## 1. Vision

A **private plugin marketplace** for the team, themed after the Fighting Fantasy gamebook *The Warlock of Firetop Mountain* (Steve Jackson & Ian Livingstone). Hosts Claude Code skills, commands, and plugins that extend the SDD (Software-Driven Development) workflow with multi-agent review pipelines.

The flagship plugin — `sdd-final-review` — replaces the manual workflow of switching to Devin CLI after each implementation to run QA, Security, and Tech Leader reviews. The pipeline runs automatically, saves versioned artifacts, and posts verdicts directly to GitHub PRs.

---

## 2. Core Plugin: `sdd-final-review`

### 2.1 Workflow

```
Claude Code implements
        ↓
/sdd-final-review [spec-id]
        ↓
[PARALLEL]
QA Engineer ←→ Security Engineer
(Claude sub-agent)  (Claude sub-agent + Devin CLI optional)
        ↓              ↓
        └──────┬────────┘
               ↓
        Tech Leader (sequential — needs both reports)
        reads: ADRs + Learning Lessons + QA report + Security report
               ↓
        APPROVED / NEEDS WORK / BLOCKED
        + dispatch instructions for next cycle
               ↓
        Claude Code (main session) adjusts code
               ↓
        Cycle repeats until APPROVED
```

### 2.2 Architecture Decisions

| Decision | Choice | Reason |
|---|---|---|
| Sub-agents vs Agent Teams | Sub-agents | Workflow is sequential after parallel phase; Agent Teams for peer autonomy not needed |
| Parallel vs Sequential | Hybrid | QA + Security independent → parallel; Tech Leader needs both → sequential |
| Who adjusts code | Claude Code main session | Has full implementation context; sub-agents are reviewers not implementers |
| External providers | Devin CLI via Bash | Simpler than LangChain; no MCP server needed; CLI already installed |
| LangChain deep agents | Not used | Claude sub-agents ARE deep agents — they explore codebase autonomously with tools |
| GitHub MCP | Existing plugin | `github@claude-plugins-official` already enabled in settings.json |

### 2.3 Dispatch Logic (Tech Leader)

The Tech Leader acts as **dispatcher**, not just reviewer. Their verdict determines the scope of the next cycle:

- **APPROVED** → no next cycle, ready for production
- **NEEDS WORK** → sends ONLY the relevant agents back (targeted, saves tokens)
  - Example: "Next cycle: QA only — coverage on AuthService < 80%"
  - Example: "Next cycle: Security only — confirm SQL injection fix at db/query.ts:87"
- **BLOCKED** → full cycle required after significant rework

### 2.4 Report Artifacts

Saved at: `reports/sdd-final-review/<spec-id>/cycle-<N>-<YYYYMMDD-HHmm>.md`

Each report contains:
- QA Engineer Report (full)
- Security Engineer Report (full, includes Devin CLI output if available)
- Tech Leader Verdict (with ADR compliance, Learning Lessons applied)
- Next Cycle Dispatch instructions

### 2.5 GitHub PR Integration

When a PR exists for the current branch (detected automatically):
- **APPROVED** → `create_pull_request_review` with `event: APPROVE`
- **NEEDS WORK / BLOCKED** → `create_pull_request_review` with `event: REQUEST_CHANGES`
- CRITICAL/HIGH findings → `add_pull_request_review_comment` inline on specific file:line

---

## 3. Skills (Slash Commands)

### `/sdd-final-review [spec-id]`
Full pipeline orchestrator. Spawns QA + Security in parallel, waits, then spawns Tech Leader. Saves report artifact and posts to GitHub PR.

### `/sdd-qa`
Standalone QA Engineer review. Explores codebase autonomously. Optional Devin CLI second opinion. Returns structured report with coverage, bugs, SDD compliance, edge cases.

### `/sdd-security`
Standalone Security Engineer review. OWASP Top 10 analysis, secrets scan, dependency CVEs. Optional Devin CLI second opinion from external provider. Returns structured security report.

### `/sdd-tech`
Standalone Tech Leader review. Reads all ADRs from `docs/adrs/` and Learning Lessons from `docs/learning_lessons/`. Synthesizes QA + Security reports if provided. Issues verdict + dispatch. Posts to GitHub PR if standalone.

---

## 4. Agent Personas

### QA Engineer
- **Mindset**: Detail-oriented, systematic, user-empathy focused
- **Focus**: Test coverage, SDD compliance, bugs, edge cases, TODO/FIXME scan
- **External tool**: Devin CLI for second opinion on missed edge cases and bugs
- **Output format**: Coverage %, bugs table (severity/description/location), SDD compliance checklist, PASS/FAIL verdict

### Security Engineer
- **Mindset**: Adversarial — thinks like an attacker
- **Focus**: OWASP Top 10, hardcoded secrets, dependency CVEs, input validation, auth/authz
- **External tool**: Devin CLI for independent security perspective from different provider
- **Output format**: Critical/High findings table (OWASP category/description/location), secrets scan result, PASS/FAIL verdict

### Tech Leader
- **Mindset**: Synthesis + pragmatic judgment + executive clarity
- **Focus**: ADR compliance, Learning Lessons application, architectural robustness, dispatch
- **Context loaded**: All ADRs (`docs/adrs/*.md`), all Learning Lessons (`docs/learning_lessons/*.md`), QA + Security reports
- **Output format**: Architecture assessment, ADR compliance list, lessons applied list, cross-report synthesis, APPROVED/NEEDS WORK/BLOCKED verdict, next cycle dispatch

---

## 5. External Provider Integration

### Devin CLI (current approach)
Used by QA Engineer and Security Engineer as an optional second opinion from a different AI provider:

```bash
which devin   # check if available
devin "role-specific prompt with code context"
```

Output included as "External [QA/Security] Opinion" section in the report. Claude sub-agent synthesizes the external output with its own analysis — doesn't just relay it.

### Why not LangChain deep agents?
Claude sub-agents spawned by the Agent tool already are deep agents:
- Autonomous codebase exploration (Read, Bash, Grep, Glob tools)
- No manual context passing required
- Same capability as a LangChain agent with file tools

LangChain adds complexity only if you need a completely different model (GPT-4o, Gemini) as the core reasoning engine, not just as a tool call.

---

## 6. MCP Configuration

### GitHub MCP (already active)
```json
"enabledPlugins": {
  "github@claude-plugins-official": true
}
```
Available globally. No additional setup needed. Used by Tech Leader skill to post PR reviews and inline comments.

### Cowork `.plugin` MCP (for distribution)
The `.plugin` file includes a `.mcp.json` for users who don't have GitHub configured:
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}" }
    }
  }
}
```

---

## 7. Hooks

### Stop Hook
Triggers when Claude finishes a session where implementation work happened. Reminds user to run `/sdd-final-review` if it hasn't been run yet.

```json
{
  "Stop": [{
    "type": "prompt",
    "prompt": "If an implementation task was completed in this session and /sdd-final-review has not been run yet, suggest that the user run /sdd-final-review. Only suggest on real implementation work — not reviews, questions, or non-coding tasks."
  }]
}
```

---

## 8. File Locations

### Claude Code CLI (global, current)
```
~/.claude/commands/
├── sdd-final-review.md   ✅ installed
├── sdd-qa.md             ✅ installed
├── sdd-security.md       ✅ installed
└── sdd-tech.md           ✅ installed
```

### Cowork Plugin (built, ready to install)
```
/tmp/sdd-final-review.plugin   ✅ packaged
```

### Project structure expected by the plugin
```
your-project/
├── docs/
│   ├── adrs/                  ← read by Tech Leader
│   └── learning_lessons/      ← read by Tech Leader
└── reports/
    └── sdd-final-review/      ← created automatically
        └── <spec-id>/
            └── cycle-N-timestamp.md
```

---

## 9. Marketplace: Firetop Mountain Plugin Registry

### Concept
A GitHub Pages site themed after *The Warlock of Firetop Mountain* serving as the team's internal Claude Code plugin marketplace. Plugins are listed as "tomes", install steps as numbered book paragraphs, commands as "incantations".

### Interactive elements
- Animated torch flames flanking the title (CSS keyframe animations)
- SVG dragon that breathes fire when clicked
- D6 dice with Fighting Fantasy-themed roll quotes
- Plugin cards with top accent border per category color

### Repository structure
```
github.com/yourteam/claude-plugins
├── commands/
│   ├── manifest.json              ← maps plugin → list of .md files
│   ├── sdd-final-review.md
│   ├── sdd-qa.md
│   ├── sdd-security.md
│   └── sdd-tech.md
├── plugins/
│   └── sdd-final-review.plugin    ← Cowork format
├── docs/
│   └── index.html                 ← GitHub Pages (Firetop Mountain theme)
├── registry.json                  ← plugin metadata index
├── install.sh                     ← installer script
└── README.md
```

### `manifest.json`
Maps plugin name to its command files:
```json
{
  "sdd-final-review": {
    "version": "0.2.0",
    "commands": ["sdd-final-review.md", "sdd-qa.md", "sdd-security.md", "sdd-tech.md"]
  }
}
```

### `registry.json`
Full plugin metadata for the marketplace page:
```json
{
  "plugins": [{
    "name": "sdd-final-review",
    "version": "0.2.0",
    "description": "Multi-agent review pipeline: QA + Security + Tech Leader",
    "author": "Rafael Ventura",
    "commands": ["/sdd-final-review", "/sdd-qa", "/sdd-security", "/sdd-tech"],
    "requires": ["github@claude-plugins-official"],
    "plugin_file": "plugins/sdd-final-review.plugin"
  }]
}
```

### `install.sh` — what it does
```bash
curl -fsSL https://yourteam.github.io/claude-plugins/install.sh | bash -s sdd-final-review
```
1. Downloads `install.sh` from GitHub Pages
2. Reads `commands/manifest.json` to find which `.md` files belong to the plugin
3. Downloads each `.md` file to `~/.claude/commands/`
4. Prints confirmation per file installed
5. Plugin available on next Claude Code session

Available commands:
```bash
bash install.sh --list                  # list available plugins
bash install.sh sdd-final-review        # install plugin
bash install.sh sdd-final-review update # update to latest
bash install.sh sdd-final-review remove # uninstall
```

---

## 10. Build Roadmap

### Phase 1 — GitHub repo setup (~5 min)
- [ ] Create repo `yourteam/claude-plugins`
- [ ] Create folder structure: `commands/`, `docs/`, `plugins/`
- [ ] Enable GitHub Pages (Settings → Pages → source: `/docs`)

### Phase 2 — Plugin files (~10 min)
- [x] 4 command `.md` files (already in `~/.claude/commands/`)
- [ ] `commands/manifest.json`
- [ ] `registry.json`

### Phase 3 — Installer script (~15 min)
- [ ] `install.sh` with list/install/update/remove
- [ ] Test locally: `bash install.sh sdd-final-review`
- [ ] Test via curl after push

### Phase 4 — Marketplace page (~20 min)
- [x] Page design (Firetop Mountain theme, dragon, torches, dice)
- [ ] Save as `docs/index.html` with real repo URLs
- [ ] Push and verify at `yourteam.github.io/claude-plugins`
- [ ] Share URL with team

---

## 11. Prerequisites

| Requirement | Purpose | Status |
|---|---|---|
| Claude Code CLI | Run skills/commands | Required |
| `github@claude-plugins-official` | Post PR reviews | ✅ Active |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | GitHub API access | Required (env var) |
| `devin` CLI | External AI second opinion | Optional |
| Node.js | GitHub MCP via npx (Cowork) | Optional |
| `docs/adrs/` in project | Tech Leader reads ADRs | Recommended |
| `docs/learning_lessons/` in project | Tech Leader reads lessons | Recommended |

---

*"Your adventure continues at paragraph 1 — or until the Tech Leader approves your PR."*
