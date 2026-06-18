# 🐉 Firetop Mountain Plugin Registry

> A private [Claude Code](https://claude.com/claude-code) plugin marketplace, themed after the Fighting Fantasy gamebook *The Warlock of Firetop Mountain*.

Hosts skills, commands, and plugins that extend the **SDD (Software-Driven Development)** workflow with multi-agent review pipelines.

## Flagship plugin: `sdd-final-review`

A multi-agent code-review pipeline that replaces the manual loop of switching to an external CLI after each implementation:

```
Claude Code implements
        ↓
/sdd-final-review [spec-id]
        ↓
QA Engineer  ⇄  Security Engineer      (parallel — Claude sub-agents)
        └────────┬────────┘
                 ↓
          Tech Leader                  (sequential — needs both reports)
   reads ADRs + Learning Lessons + both reports
                 ↓
   APPROVED / NEEDS WORK / BLOCKED  + next-cycle dispatch
                 ↓
   Claude Code (main session) adjusts code → repeat until APPROVED
```

Each run saves a versioned artifact to `reports/sdd-final-review/<spec-id>/cycle-<N>-<timestamp>.md` and, if a PR exists for the branch, posts the verdict via the GitHub plugin.

### Commands

| Command | Role |
|---|---|
| `/sdd-final-review [spec-id]` | Full pipeline orchestrator (QA + Security → Tech Leader) |
| `/sdd-qa` | Standalone QA review — coverage, bugs, SDD compliance, edge cases |
| `/sdd-security` | Standalone Security review — OWASP Top 10, secrets, dependency CVEs |
| `/sdd-tech` | Standalone Tech Leader — ADR/Lessons compliance, verdict + dispatch |

## Install

```bash
# install / update / remove a plugin
bash install.sh sdd-final-review
bash install.sh sdd-final-review update
bash install.sh sdd-final-review remove
bash install.sh --list

# or bootstrap remotely
curl -fsSL https://raw.githubusercontent.com/rc-ventura/grimoire-claude-code/main/install.sh | bash -s sdd-final-review
```

The installer reads [`commands/manifest.json`](commands/manifest.json) to learn which
command `.md` files belong to a plugin and copies them into `~/.claude/commands/`.
Restart Claude Code afterwards to pick up the new slash commands.

> **Configure the source repo** by editing the `OWNER`/`REPO`/`BRANCH` defaults at the
> top of `install.sh`, or by overriding them per run:
> `SDD_OWNER=… SDD_REPO=… SDD_BRANCH=… bash install.sh sdd-final-review`.

## Requirements

| Requirement | Purpose | Status |
|---|---|---|
| Claude Code CLI | Run the commands | Required |
| `curl` + `python3` | Run `install.sh` | Required |
| `github@claude-plugins-official` | Post PR reviews | Recommended |
| `devin` CLI | External second opinion (QA/Security) | Optional |
| `docs/adrs/`, `docs/learning_lessons/` in your project | Tech Leader context | Recommended |

## Repository layout

```
commands/        # the four sdd-*.md command files + manifest.json
plugins/         # sdd-final-review.plugin (Cowork bundle)
docs/            # index.html (GitHub Pages marketplace) + sdd-plugin-spec.md
reports/         # generated review artifacts (created at runtime)
registry.json    # plugin metadata index
install.sh       # list / install / update / remove
```

Full design and rationale: [`docs/sdd-plugin-spec.md`](docs/sdd-plugin-spec.md).

---

*"Your adventure continues at paragraph 1 — or until the Tech Leader approves your PR."*
