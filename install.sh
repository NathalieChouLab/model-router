#!/usr/bin/env bash
# Installs the model-router skill and its four pinned agents into ~/.claude (all projects).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="${CLAUDE_HOME:-$HOME/.claude}"
mkdir -p "$DEST/skills" "$DEST/agents"
if [ -e "$DEST/skills/model-router" ]; then
  cp -R "$DEST/skills/model-router" "$DEST/skills/model-router.bak.$(date +%Y%m%d%H%M%S)"
fi
rm -rf "$DEST/skills/model-router"
cp -R "$HERE/skills/model-router" "$DEST/skills/model-router"
for a in scout builder verifier architect; do
  [ -e "$DEST/agents/$a.md" ] && cp "$DEST/agents/$a.md" "$DEST/agents/$a.md.bak"
  cp "$HERE/agents/$a.md" "$DEST/agents/$a.md"
done
echo "Installed to $DEST. Start a new Claude Code session and type /model-router (or just give it a task)."
echo "No access to the 'fable' model? Run: sed -i '' 's/^model: fable/model: opus/' $DEST/agents/architect.md"
