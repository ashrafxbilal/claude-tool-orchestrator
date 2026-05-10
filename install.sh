#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
AGENTS_DIR="$CLAUDE_HOME/agents"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$AGENTS_DIR" "$BIN_DIR"

backup_if_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    cp "$path" "$path.bak-$STAMP"
  fi
}

backup_if_exists "$AGENTS_DIR/orchestrator.md"
cp "$SCRIPT_DIR/orchestrator.md" "$AGENTS_DIR/orchestrator.md"

backup_if_exists "$BIN_DIR/claude-tool-orchestrator"
cp "$SCRIPT_DIR/claude-tool-orchestrator" "$BIN_DIR/claude-tool-orchestrator"
chmod +x "$BIN_DIR/claude-tool-orchestrator"

if [[ "${SKIP_AGENT_MODEL_UPDATE:-0}" != "1" ]]; then
  for agent_file in "$AGENTS_DIR"/*.md; do
    [[ -e "$agent_file" ]] || continue
    [[ "$(basename "$agent_file")" == "orchestrator.md" ]] && continue

    if grep -q '^model: inherit$' "$agent_file"; then
      backup_if_exists "$agent_file"
      perl -0pi -e 's/^model: inherit$/model: haiku/m' "$agent_file"
    fi
  done
fi

cat <<'MSG'
Installed Claude Tool Orchestrator.

Start strict orchestration mode:
  claude-tool-orchestrator

Use Opus for top-level reasoning:
  CLAUDE_ORCHESTRATOR_MODEL=opus claude-tool-orchestrator

Skip existing-agent model edits during install:
  SKIP_AGENT_MODEL_UPDATE=1 ./install.sh
MSG
