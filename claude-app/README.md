# Claude app (chat) edition

The chat side of the Claude app has no subagents and cannot switch models mid-conversation, so this edition routes **roles and reasoning depth** instead of models. Same rubric, same checkpoint rules, same eighteen roles.

**Install:** in the Claude app or claude.ai, open Settings → Capabilities → Skills and upload `model-router-chat.zip`. Then start any non-trivial task; the skill triggers on its description. To force it, say "use model-router-chat".

**Projects:** paste the contents of `model-router-chat/SKILL.md` into a Project's custom instructions to make it apply to every chat in that project.

The Claude Code tab inside the desktop app uses `~/.claude` and needs the main installer instead, which gives real per-tier models and effort.
