#!/usr/bin/env bash
# Claude Code cloud-environment setup script.
# Installs model-router into the sandbox's ~/.claude so every cloud session (web, mobile,
# desktop, `claude --cloud`) routes work across the pinned agents, with no per-repo commits.
# Paste into claude.ai/code -> environment settings -> Setup script. Runs once per environment,
# then the filesystem snapshot is cached for about seven days.
# Profile: set MODEL_ROUTER_PROFILE=quality|pro|cost in the environment variables (default quality).
RAW="https://raw.githubusercontent.com/NathalieChouLab/model-router-claude/main"
PROFILE="${MODEL_ROUTER_PROFILE:-quality}"

install_into() {
  local DEST="$1"
  mkdir -p "$DEST/agents" "$DEST/skills/model-router/references" 2>/dev/null || return 0
  curl -fsSL "$RAW/cloud/manifest.txt" -o /tmp/mr-manifest.txt || { echo "model-router: manifest fetch failed"; return 0; }
  while read -r f; do
    [ -n "$f" ] && curl -fsSL "$RAW/$f" -o "$DEST/$f" || true
  done < /tmp/mr-manifest.txt
  curl -fsSL "$RAW/profiles/$PROFILE.tsv" -o /tmp/mr-profile.tsv || true
  if [ -s /tmp/mr-profile.tsv ]; then
    while IFS=$'\t' read -r a m e; do
      [ -n "$a" ] && [ -f "$DEST/agents/$a.md" ] && sed -i.bak -e "s/^model: .*/model: $m/" -e "s/^effort: .*/effort: $e/" "$DEST/agents/$a.md" && rm -f "$DEST/agents/$a.md.bak"
    done < /tmp/mr-profile.tsv
  fi
  local CM="$DEST/CLAUDE.md"
  if ! grep -qs 'model-router' "$CM"; then
    printf '\n# model-router (auto-start)\n- Apply `~/.claude/skills/model-router/SKILL.md` to every non-trivial task: classify, state one `Routing:` line, delegate parts to the agents in `~/.claude/agents/`, verify with a different agent, re-route at each checkpoint. Trivial one-step tasks skip it.\n' >> "$CM"
  fi
  echo "model-router ($PROFILE) installed to $DEST: $(ls "$DEST/agents" | wc -l | tr -d ' ') agents"
}

install_into "${HOME:-/root}/.claude"
[ "${HOME:-/root}" != "/root" ] && [ -w /root ] && install_into /root/.claude
true
