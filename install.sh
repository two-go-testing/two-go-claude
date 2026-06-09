#!/usr/bin/env bash
# Install the two-go Claude Code skill and subagents into the current project.
# Run from the root of your project:
#   curl -sSL https://raw.githubusercontent.com/two-go-testing/two-go-claude/main/install.sh | bash
set -euo pipefail

RAW="https://raw.githubusercontent.com/two-go-testing/two-go-claude/main"

echo "Installing two-go Claude Code resources into .claude/ ..."

mkdir -p .claude/skills/two-go
mkdir -p .claude/agents

curl -fsSL "$RAW/skills/two-go/SKILL.md" -o .claude/skills/two-go/SKILL.md
curl -fsSL "$RAW/agents/two-go-test-author.md" -o .claude/agents/two-go-test-author.md
curl -fsSL "$RAW/agents/two-go-test-reviewer.md" -o .claude/agents/two-go-test-reviewer.md

echo "Done."
echo "Installed:"
echo "  .claude/skills/two-go/SKILL.md"
echo "  .claude/agents/two-go-test-author.md"
echo "  .claude/agents/two-go-test-reviewer.md"
echo "Open Claude Code in this project and ask it to write or review two-go tests."
