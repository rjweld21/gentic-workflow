#!/usr/bin/env bash
#
# Gentic Workflow — Bootstrap Script (Linux / macOS)
#
# Usage:
#   curl -sL https://raw.githubusercontent.com/rjweld21/gentic-workflow/master/scripts/bootstrap.sh | bash
#
# Or with a custom install directory:
#   curl -sL https://raw.githubusercontent.com/rjweld21/gentic-workflow/master/scripts/bootstrap.sh | bash -s -- --dir ~/my-tools/gentic-workflow
#
# What this does:
#   1. Clones the gentic-workflow repo
#   2. Creates a symlink at ~/.claude/workflow/ → the repo
#   3. Creates ~/.claude/skills/ and symlinks the two included skills
#
# After running, start a new Claude Code session and use:
#   /initialize-workflow  — to configure your board and projects
#   /using-workflow       — to load workflow context into a session
#

set -euo pipefail

REPO_URL="https://github.com/rjweld21/gentic-workflow.git"
DEFAULT_DIR="$HOME/gentic-workflow"
CLAUDE_DIR="$HOME/.claude"

# --- Parse arguments ---
INSTALL_DIR="$DEFAULT_DIR"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      INSTALL_DIR="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: bootstrap.sh [--dir <install-path>]"
      echo ""
      echo "  --dir <path>   Where to clone the repo (default: ~/gentic-workflow)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "=== Gentic Workflow Bootstrap ==="
echo ""

# --- Step 1: Clone the repo ---
if [ -d "$INSTALL_DIR" ]; then
  echo "[1/3] Repo already exists at $INSTALL_DIR — pulling latest..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "[1/3] Cloning gentic-workflow to $INSTALL_DIR..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

# --- Step 2: Symlink workflow root ---
echo "[2/3] Setting up ~/.claude/workflow symlink..."
mkdir -p "$CLAUDE_DIR"

if [ -L "$CLAUDE_DIR/workflow" ]; then
  echo "  Symlink already exists — updating target..."
  rm "$CLAUDE_DIR/workflow"
  ln -s "$INSTALL_DIR" "$CLAUDE_DIR/workflow"
elif [ -d "$CLAUDE_DIR/workflow" ]; then
  echo "  WARNING: ~/.claude/workflow/ is a real directory, not a symlink."
  echo "  If this is a previous installation, back it up and remove it, then re-run."
  echo "  Skipping symlink creation."
else
  ln -s "$INSTALL_DIR" "$CLAUDE_DIR/workflow"
fi

echo "  ~/.claude/workflow → $INSTALL_DIR"

# --- Step 3: Symlink skills ---
echo "[3/3] Installing skills to ~/.claude/skills/..."
mkdir -p "$CLAUDE_DIR/skills"

for skill in initialize-workflow using-workflow; do
  target="$CLAUDE_DIR/workflow/skills/$skill"
  link="$CLAUDE_DIR/skills/$skill"

  if [ -L "$link" ]; then
    rm "$link"
  elif [ -d "$link" ]; then
    echo "  WARNING: ~/.claude/skills/$skill is a real directory — skipping."
    continue
  fi

  ln -s "$target" "$link"
  echo "  ~/.claude/skills/$skill → $target"
done

# --- Done ---
echo ""
echo "=== Bootstrap complete ==="
echo ""
echo "Start a new Claude Code session and run:"
echo "  /initialize-workflow   — to set up your board and projects"
echo "  /using-workflow        — to load workflow context into any session"
echo ""
