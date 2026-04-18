#!/usr/bin/env bash
# Example: fire off a Codex agent for any project.
#
# Customize the vars below, run the script, then watch with:
#   agent-pulse watch

set -euo pipefail

ID="my-task-$(date +%s)"
LABEL="short human-readable description"
PROJECT="my-project"
MODEL="gpt-5.4"
WORKTREE="/tmp/my-project-work"
BRIEF="/tmp/my-brief.md"

# make sure the brief exists and worktree is a directory
test -f "$BRIEF" || { echo "brief missing: $BRIEF" >&2; exit 1; }
test -d "$WORKTREE" || { echo "worktree missing: $WORKTREE" >&2; exit 1; }

agent-pulse dispatch \
  --id "$ID" \
  --label "$LABEL" \
  --project "$PROJECT" \
  --model "$MODEL" \
  --worktree "$WORKTREE" \
  --brief "$BRIEF"

echo
echo "Watch with: agent-pulse watch"
