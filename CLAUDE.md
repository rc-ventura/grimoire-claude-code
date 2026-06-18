# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is the **Firetop Mountain Plugin Registry** — a private Claude Code plugin marketplace, themed after the Fighting Fantasy gamebook *The Warlock of Firetop Mountain*. It packages and distributes the **SDD (Software-Driven Development) multi-agent review pipeline** as installable Claude Code plugins/commands.

The repo is at an early build stage. The only authored content today is the full design in **`docs/sdd-plugin-spec.md`** — treat it as the source of truth for intended structure, file formats, and the build roadmap (Sections 9–10). Most files described below (`commands/`, `plugins/`, `registry.json`, `install.sh`, `docs/index.html`) do not exist yet and are to be created per that spec.

This repo distributes commands; it does not host an application. There is no build/test/lint toolchain — artifacts are Markdown command files, JSON manifests, a Bash installer, and a static GitHub Pages site. Validate changes by installing/running the commands, by `bash -n install.sh`, and by JSON-linting the manifests.

## The product being distributed: SDD review pipeline

The flagship plugin `sdd-final-review` orchestrates a code review as a multi-agent pipeline. The canonical, already-working implementations live in the user's global config at `~/.claude/commands/sdd-{final-review,qa,security,tech}.md`. When building this marketplace, those `.md` files are the artifacts copied into `commands/` and listed in `manifest.json` — keep the repo copies in sync with their behavior.

Pipeline shape (hybrid parallel → sequential):

1. **QA Engineer** and **Security Engineer** sub-agents run **in parallel** (independent concerns).
2. The orchestrator **waits for both**, then spawns the **Tech Leader** sub-agent **sequentially** (it needs both reports).
3. Tech Leader issues a verdict and **dispatches** the next cycle. The main Claude Code session — not a sub-agent — applies the code fixes. Cycle repeats until APPROVED.

Architecture decisions to preserve (rationale in spec §2.2):
- **Claude sub-agents, not Agent Teams / LangChain.** Sub-agents spawned via the Agent tool already explore the codebase autonomously (Read/Bash/Grep/Glob); they are the "deep agents." Do not add LangChain unless a genuinely different core model is required.
- **Devin CLI is an optional second opinion**, invoked via Bash by QA and Security only (`which devin` guard first). Sub-agents *synthesize* its output, never just relay it.
- **GitHub integration uses the existing `github@claude-plugins-official` plugin.** The bundled `.mcp.json` is only a fallback for users without it.

### Conventions the commands depend on (do not change casually)

These are contracts shared across the four commands and any project that consumes them:

- **Verdict vocabulary** is exactly `APPROVED` / `NEEDS WORK` / `BLOCKED`. Sub-agent verdicts are `PASS` / `FAIL`.
- **Targeted dispatch is the point.** On `NEEDS WORK`, the Tech Leader names *only* the agents needed next (e.g. "QA only") to save tokens; `BLOCKED` triggers a full cycle. Preserve this when editing prompts.
- **Report artifacts**: `reports/sdd-final-review/<spec-id>/cycle-<N>-<YYYYMMDD-HHmm>.md`. `<spec-id>` defaults to the sanitized current branch name; `<N>` is the highest existing cycle number + 1.
- **Tech Leader context inputs**: it reads *every* file in `docs/adrs/*.md` and `docs/learning-lessons/*.md` of the *consuming* project, lists each by title, and checks compliance. The `/adr` and `/learning-lesson` skills produce those files.
- Sub-agent reports use **fixed Markdown structures** (tables for bugs/findings with `severity | description | file:line`). The commands say "return this exact structure" — downstream parsing and the saved artifact assume it. Keep formats stable.

## Marketplace structure (target, per spec §9)

```
commands/         # the four sdd-*.md command files + manifest.json
plugins/          # sdd-final-review.plugin (Cowork format)
docs/             # index.html — GitHub Pages, Firetop Mountain theme  (+ this spec)
registry.json     # plugin metadata index for the marketplace page
install.sh        # list / install / update / remove
```

- **`manifest.json`** maps a plugin name → its version + list of command `.md` files.
- **`registry.json`** holds display metadata (name, version, description, commands, `requires`, `plugin_file`).
- **`install.sh`** reads `manifest.json` and downloads each command `.md` into `~/.claude/commands/`. Interface: `bash install.sh --list | <plugin> | <plugin> update | <plugin> remove`, also runnable via `curl -fsSL …/install.sh | bash -s <plugin>`.

When adding a command or plugin, update it in **three** places to stay consistent: the `.md` file in `commands/`, the entry in `commands/manifest.json`, and the metadata in `registry.json`.

## Marketplace page theme (spec §9)

`docs/index.html` is a self-contained static page themed as the gamebook: plugins as "tomes", install steps as numbered book paragraphs, commands as "incantations". Interactive bits are pure CSS/SVG/JS (animated torch flames, a fire-breathing dragon, themed D6 dice) — no framework or build step.
