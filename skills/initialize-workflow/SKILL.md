---
name: initialize-workflow
description: Use when setting up the Gentic Workflow for the first time, configuring a new board adapter, or onboarding a new project repo into the workflow
---

# Initialize Workflow

## Overview

Interactive setup wizard that walks you through configuring the Gentic Workflow — board adapter, board config, project config, directory structure, and symlinks. Run once per environment, then use `using-workflow` for each session.

## When to Use

- First time setting up Gentic Workflow on a machine
- Adding a new project repo to the workflow
- Configuring a new board adapter (GitHub Projects, Linear, etc.)
- Re-initializing after a broken or stale config

**Do NOT use when:**
- Workflow is already set up and you want to start working — use `using-workflow` instead
- You just need to update a single config value — edit the file directly

## Prerequisites

If you can see this skill, either the bootstrap script already ran or someone manually installed the skills. The bootstrap script (`scripts/bootstrap.sh` or `scripts/bootstrap.ps1`) handles cloning the repo, creating the `~/.claude/workflow/` symlink, and installing skills. If those steps are already done, this wizard picks up from board/project configuration.

If the bootstrap has NOT been run and someone is reading this skill manually, direct them to run:
- **Linux/macOS:** `curl -sL https://raw.githubusercontent.com/rjweld21/gentic-workflow/master/scripts/bootstrap.sh | bash`
- **Windows:** `irm https://raw.githubusercontent.com/rjweld21/gentic-workflow/master/scripts/bootstrap.ps1 | iex`

## Setup Flow

Walk the user through each step below. Check what's already done and skip completed steps.

### Step 1: Locate the Gentic Workflow Installation

Check if the workflow is already installed (bootstrap should have done this):

1. Check for `~/.claude/workflow/` (symlink or directory)
2. If not found, ask the user where they cloned the gentic-workflow repo
3. If not cloned yet, help them clone it:
   ```bash
   git clone <repo-url> <preferred-path>
   ```
4. Create symlink/junction from `~/.claude/workflow/` to the repo:
   - **Linux/macOS:** `ln -s <repo-path> ~/.claude/workflow`
   - **Windows:** `mklink /J "%USERPROFILE%\.claude\workflow" "<repo-path>"`
5. Verify the symlink works by reading `~/.claude/workflow/README.md`

### Step 2: Choose and Configure Board Adapter

1. Check if `~/.claude/workflow/config/board-config.json` exists
2. If not, ask the user which adapter they want to use:
   - List available adapters from `~/.claude/workflow/adapters/`
3. Read the adapter's `README.md` for prerequisites
4. Walk through adapter setup:
   - For **GitHub Projects**: verify `gh` CLI is installed and authenticated, check project scopes, help create fields if needed
5. Help the user get field IDs and populate `board-config.json`:
   ```bash
   cp ~/.claude/workflow/config/board-config.example.json ~/.claude/workflow/config/board-config.json
   ```
6. Guide them through filling in the IDs from the adapter's README instructions

### Step 3: Configure Project Repo(s)

For each project repo the user wants to add to the workflow:

1. Navigate to the project root
2. Create the workflow directory structure:
   ```bash
   mkdir -p .workflow/agent-notes/active .workflow/agent-notes/completed .workflow/evidence
   ```
3. Copy and fill in project config:
   ```bash
   cp ~/.claude/workflow/config/project-config.example.json .workflow/project-config.json
   ```
4. Walk through each field in `project-config.json`:
   - `repo` — the owner/repo-name on the platform
   - `default_branch` — usually `main`
   - `board_project_option_id` — the ID for this project on the board
   - `project_instructions_file` — detect which one exists (CLAUDE.md, .cursorrules, etc.)
   - `test_commands` — ask what commands run tests for each area
   - `coverage_thresholds` — ask or use defaults (80%)
   - `coding_standards` — detect from existing config files (package.json, pyproject.toml, etc.)
   - `skills` — ask if they use Superpowers, OpenSpec, or other frameworks
5. Ensure `.workflow/` is in `.gitignore`:
   ```bash
   grep -q "^\.workflow/" .gitignore 2>/dev/null || echo ".workflow/" >> .gitignore
   ```

### Step 4: Install Skills

1. Create `~/.claude/skills/` if it doesn't exist
2. Symlink the workflow skills:
   - **Linux/macOS:**
     ```bash
     ln -s ~/.claude/workflow/skills/initialize-workflow ~/.claude/skills/initialize-workflow
     ln -s ~/.claude/workflow/skills/using-workflow ~/.claude/skills/using-workflow
     ```
   - **Windows:**
     ```bash
     mklink /J "%USERPROFILE%\.claude\skills\initialize-workflow" "%USERPROFILE%\.claude\workflow\skills\initialize-workflow"
     mklink /J "%USERPROFILE%\.claude\skills\using-workflow" "%USERPROFILE%\.claude\workflow\skills\using-workflow"
     ```

### Step 5: Verify Setup

Run a quick health check:

1. Read `~/.claude/workflow/config/board-config.json` — verify adapter and field IDs are set
2. For each configured project, read `<project>/.workflow/project-config.json` — verify required fields
3. Test board connectivity using the adapter's `list_items` command
4. Report what's configured and what's still needed

### Step 6: Hand Off to Using-Workflow

After setup is complete, invoke the `using-workflow` skill to initialize the session context.

## What Gets Created

| Location | Purpose |
|---|---|
| `~/.claude/workflow/` | Symlink to gentic-workflow repo |
| `~/.claude/workflow/config/board-config.json` | Board adapter config with field IDs |
| `<project>/.workflow/project-config.json` | Per-project config |
| `<project>/.workflow/agent-notes/` | Agent working notes directory |
| `<project>/.workflow/evidence/` | Test evidence directory |
| `~/.claude/skills/initialize-workflow/` | Symlink to this skill |
| `~/.claude/skills/using-workflow/` | Symlink to using-workflow skill |

## Troubleshooting

- **Symlink/junction fails on Windows**: must run terminal as Administrator, or use directory junctions (`mklink /J`) which don't require elevation
- **gh CLI not authenticated**: run `gh auth login` then `gh auth refresh -s read:project -s project`
- **Board field IDs not found**: use the adapter's README step-by-step to create fields first, then query IDs
- **Project config validation fails**: ensure all required fields are filled in, not left as empty strings
