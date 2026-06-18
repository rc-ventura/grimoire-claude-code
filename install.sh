#!/usr/bin/env bash
#
# Firetop Mountain Plugin Registry — installer
#
# Installs Claude Code SDD plugins by copying their command .md files into
# ~/.claude/commands/. Reads commands/manifest.json to know which files belong
# to each plugin.
#
#   bash install.sh --list                  # list available plugins
#   bash install.sh <plugin>                # install a plugin
#   bash install.sh <plugin> update         # reinstall / update to latest
#   bash install.sh <plugin> remove         # uninstall
#
# Remote bootstrap:
#   curl -fsSL <RAW_BASE>/install.sh | bash -s sdd-final-review
#
# Override the source repo without editing this file:
#   SDD_OWNER=me SDD_REPO=my-fork SDD_BRANCH=main bash install.sh sdd-final-review
#
set -euo pipefail

# --- Source location (placeholders — change once the GitHub repo exists) -----
OWNER="${SDD_OWNER:-rafaelventura}"
REPO="${SDD_REPO:-grimoire-claude-code}"
BRANCH="${SDD_BRANCH:-main}"
RAW_BASE="${SDD_RAW_BASE:-https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}}"

COMMANDS_DIR="${HOME}/.claude/commands"
MANIFEST_URL="${RAW_BASE}/commands/manifest.json"
REGISTRY_URL="${RAW_BASE}/registry.json"

# --- Pretty output -----------------------------------------------------------
c_dim=$'\033[2m'; c_red=$'\033[31m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_off=$'\033[0m'
say()  { printf '%s\n' "$*"; }
ok()   { printf '%s✓%s %s\n' "$c_grn" "$c_off" "$*"; }
warn() { printf '%s!%s %s\n' "$c_yel" "$c_off" "$*"; }
die()  { printf '%s✗ %s%s\n' "$c_red" "$*" "$c_off" >&2; exit 1; }

# --- Dependencies ------------------------------------------------------------
command -v curl >/dev/null 2>&1 || die "curl is required."
JSON=""
if command -v python3 >/dev/null 2>&1; then JSON="python3"
elif command -v python >/dev/null 2>&1; then JSON="python"
else die "python3 (or python) is required to parse the manifest."
fi

fetch() { curl -fsSL "$1" || die "Could not download: $1"; }

# Print the .md command filenames for a plugin from manifest JSON (stdin).
# Program passed via -c so stdin stays bound to the piped JSON data.
plugin_commands() {
  "$JSON" -c '
import json, sys
data = json.load(sys.stdin)
entry = data.get(sys.argv[1])
if not entry:
    sys.stderr.write("unknown plugin\n"); sys.exit(3)
for f in entry.get("commands", []):
    print(f)
' "$1"
}

plugin_version() {
  "$JSON" -c '
import json, sys
data = json.load(sys.stdin)
print(data.get(sys.argv[1], {}).get("version", "?"))
' "$1"
}

# --- Actions -----------------------------------------------------------------
do_list() {
  say "${c_dim}Firetop Mountain Plugin Registry${c_off}"
  say ""
  fetch "$REGISTRY_URL" | "$JSON" -c '
import json, sys
data = json.load(sys.stdin)
for p in data.get("plugins", []):
    print("  %s  (v%s)" % (p["name"], p.get("version", "?")))
    print("    " + p.get("description", "").strip())
    cmds = "  ".join(p.get("commands", []))
    if cmds:
        print("    commands: " + cmds)
    print()
'
}

do_install() {
  local plugin="$1" verb="${2:-install}"
  local manifest; manifest="$(fetch "$MANIFEST_URL")"
  local files; files="$(printf '%s' "$manifest" | plugin_commands "$plugin")" \
    || die "Plugin '$plugin' not found in manifest."
  local version; version="$(printf '%s' "$manifest" | plugin_version "$plugin")"

  mkdir -p "$COMMANDS_DIR"
  say "${c_dim}${verb} ${plugin} v${version} → ${COMMANDS_DIR}${c_off}"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    fetch "${RAW_BASE}/commands/${f}" > "${COMMANDS_DIR}/${f}"
    ok "$f"
  done <<< "$files"
  say ""
  ok "${plugin} ready — restart Claude Code, then use its slash commands."
}

do_remove() {
  local plugin="$1"
  local manifest; manifest="$(fetch "$MANIFEST_URL")"
  local files; files="$(printf '%s' "$manifest" | plugin_commands "$plugin")" \
    || die "Plugin '$plugin' not found in manifest."
  say "${c_dim}removing ${plugin} from ${COMMANDS_DIR}${c_off}"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ -f "${COMMANDS_DIR}/${f}" ]; then
      rm -f "${COMMANDS_DIR}/${f}"; ok "removed $f"
    else
      warn "not installed: $f"
    fi
  done <<< "$files"
}

usage() {
  cat <<EOF
Firetop Mountain Plugin Registry — installer

  bash install.sh --list                 list available plugins
  bash install.sh <plugin>               install a plugin
  bash install.sh <plugin> update        reinstall / update to latest
  bash install.sh <plugin> remove        uninstall

Source: ${RAW_BASE}
EOF
}

# --- Dispatch ----------------------------------------------------------------
case "${1:-}" in
  ""|-h|--help|help) usage ;;
  -l|--list|list)    do_list ;;
  *)
    plugin="$1"; action="${2:-install}"
    case "$action" in
      install|update) do_install "$plugin" "$action" ;;
      remove|uninstall) do_remove "$plugin" ;;
      *) die "Unknown action '$action'. Use install, update, or remove." ;;
    esac
    ;;
esac
