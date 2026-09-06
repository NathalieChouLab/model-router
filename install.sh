#!/usr/bin/env bash
# Installs the model-router skill and its twenty-two pinned agents into ~/.claude (all projects).
# PROFILE=quality (default, Max/Team/Enterprise) | pro (Claude Pro: Sonnet-centred, Opus for decisions) | cost
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# PROJECT_DIR=/path/to/repo installs into that repo's .claude/ (travels with the repo into Claude Code web/mobile cloud sandboxes).
if [ -n "${PROJECT_DIR:-}" ]; then DEST="$PROJECT_DIR/.claude"; else DEST="${CLAUDE_HOME:-$HOME/.claude}"; fi
mkdir -p "$DEST/skills" "$DEST/agents"
BAK="$DEST/model-router-backup/$(date +%Y%m%d%H%M%S)"; mkdir -p "$BAK"
[ -e "$DEST/skills/model-router" ] && cp -R "$DEST/skills/model-router" "$BAK/skill"
rm -rf "$DEST/skills/model-router"
cp -R "$HERE/skills/model-router" "$DEST/skills/model-router"
for a in scout researcher builder tester writer verifier architect auditor designer debugger analyst librarian coordinator promptsmith editor counsel operator monitor clerk runner digest quickfix; do
  [ -e "$DEST/agents/$a.md" ] && cp "$DEST/agents/$a.md" "$BAK/$a.md"
  cp "$HERE/agents/$a.md" "$DEST/agents/$a.md"
done
PROFILE="${PROFILE:-quality}"; TABLE="$HERE/profiles/$PROFILE.tsv"
[ -f "$TABLE" ] || { echo "unknown PROFILE=$PROFILE (quality|pro|cost)"; exit 1; }
while IFS=$'\t' read -r a m e; do
  [ -n "$a" ] || continue
  sed -i.tmp -e "s/^model: .*/model: $m/" -e "s/^effort: .*/effort: $e/" "$DEST/agents/$a.md"; rm -f "$DEST/agents/$a.md.tmp"
done < "$TABLE"
echo "Profile: $PROFILE"; grep -H '^model:\|^effort:' "$DEST"/agents/{scout,researcher,builder,tester,writer,verifier,architect,auditor,designer,debugger,analyst,librarian,coordinator,promptsmith,editor,counsel,operator,monitor,clerk,runner,digest,quickfix}.md | sed 's|.*/agents/||' | paste - - | column -t
echo "Installed to $DEST. Start a new Claude Code session and type /model-router (or just give it a task)."
if [ -n "${PROJECT_DIR:-}" ]; then
  CM="$PROJECT_DIR/CLAUDE.md"
  if ! { [ -f "$CM" ] && grep -q 'model-router' "$CM"; }; then
    printf '\n# model-router (auto-start)\n- Apply `.claude/skills/model-router/SKILL.md` to every non-trivial task: classify, state one `Routing:` line, delegate parts to the agents in `.claude/agents/`, verify with a different agent, re-route at each checkpoint. Trivial one-step tasks skip it.\n' >> "$CM"
  fi
  echo "Project mode: commit $PROJECT_DIR/.claude and CLAUDE.md so cloud sessions (Claude Code web/mobile) pick it up."
fi
[ "$PROFILE" = quality ] && echo "On Claude Pro, or no Fable access? Re-run with: PROFILE=pro ./install.sh"
