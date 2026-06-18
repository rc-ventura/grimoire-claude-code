# Firetop Mountain Plugin Registry

> A [Claude Code](https://claude.com/claude-code) plugin marketplace themed after the Fighting Fantasy gamebook *The Warlock of Firetop Mountain*.

Distributes the **SDD (Software-Driven Development)** multi-agent review pipeline as native Claude Code plugins.

**Marketplace site:** [rc-ventura.github.io/grimoire-claude-code](https://rc-ventura.github.io/grimoire-claude-code)

---

## Install via native Claude Code marketplace

```
/plugin marketplace add rc-ventura/grimoire-claude-code
/plugin install sdd-final-review@grimoire
/plugin install sdd-create-docs@grimoire
```

## Plugins

### `sdd-final-review`

Multi-agent code review pipeline. QA Engineer and Security Engineer run in parallel, then the Tech Leader synthesizes both reports and issues the final verdict.

| Command | Role |
|---|---|
| `/sdd-final-review:final-review [spec-id]` | Full pipeline orchestrator |
| `/sdd-final-review:qa [context]` | Standalone QA — coverage, bugs, SDD compliance |
| `/sdd-final-review:security [context]` | Standalone Security — OWASP, secrets, CVEs |
| `/sdd-final-review:tech [qa] [security]` | Tech Leader — ADR/Lessons compliance, verdict + dispatch |

Pipeline shape:

```
/sdd-final-review:final-review
        ↓
QA Engineer  ⇄  Security Engineer    (parallel sub-agents)
        └────────┬────────┘
                 ↓
          Tech Leader                (sequential — needs both reports)
   reads ADRs + Learning Lessons
                 ↓
   APPROVED / NEEDS WORK / BLOCKED
                 ↓
   Claude Code applies fixes → repeat until APPROVED
```

Saves versioned artifacts to `reports/sdd-final-review/<spec-id>/cycle-<N>-<timestamp>.md`.

---

### `sdd-create-docs`

SDD authoring tools for Architecture Decision Records and Learning Lessons. Both are auto-numbered, indexed in `CLAUDE.md`, and read by the Tech Leader on every review cycle.

| Command | Role |
|---|---|
| `/sdd-create-docs:adr [title and context]` | Create auto-numbered ADR in `docs/adrs/` |
| `/sdd-create-docs:learning-lesson [title and context]` | Create structured lesson in `docs/learning-lessons/` |

---

## Fallback install (curl)

For environments without native marketplace access:

```bash
bash install.sh sdd-final-review
bash install.sh sdd-create-docs

# or remotely
curl -fsSL https://raw.githubusercontent.com/rc-ventura/grimoire-claude-code/main/install.sh | bash -s sdd-final-review
```

## Requirements

| Requirement | Purpose | Status |
|---|---|---|
| Claude Code CLI | Run the commands | Required |
| `github@claude-plugins-official` | Post PR verdicts | Recommended |
| `docs/adrs/` in your project | Tech Leader ADR compliance | Recommended |
| `docs/learning-lessons/` in your project | Tech Leader lesson check | Recommended |
| `devin` CLI | External second opinion (QA/Security) | Optional |

## Repository layout

```
.claude-plugin/
  marketplace.json      # native marketplace catalog
plugins/
  sdd-final-review/
    .claude-plugin/plugin.json
    commands/           # final-review.md, qa.md, security.md, tech.md
  sdd-create-docs/
    .claude-plugin/plugin.json
    commands/           # adr.md, learning-lesson.md
commands/               # fallback copies + manifest.json for install.sh
pages/                  # index.html — GitHub Pages marketplace site
registry.json           # display metadata for marketplace page
install.sh              # fallback: list / install / update / remove
```

Full design and rationale: [`pages/sdd-plugin-spec.md`](pages/sdd-plugin-spec.md)

---

*"Your adventure continues at paragraph 1 — or until the Tech Leader approves your PR."*
