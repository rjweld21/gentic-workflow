---
name: initialize-workflow
description: Use when setting up the Gentic Workflow for the first time, configuring a new board adapter, or onboarding a new project repo into the workflow
---

# Initialize Workflow

## Overview

Interactive setup wizard that walks you through configuring the Gentic Workflow's three context layers — organization, project, and user. Run once per environment, then use `using-workflow` for each session.

## When to Use

- First time setting up Gentic Workflow on a machine
- Adding a new project to the workflow
- Configuring a new board adapter (GitHub Projects, Linear, etc.)
- Setting up org-level context for a forked instance
- Re-initializing after a broken or stale config

**Do NOT use when:**
- Workflow is already set up and you want to start working — use `using-workflow` instead
- You just need to update a single config value — edit the file directly

## Prerequisites

If you can see this skill, either the bootstrap script already ran or someone manually installed the skills. The bootstrap script (`scripts/bootstrap.sh` or `scripts/bootstrap.ps1`) handles cloning the repo, creating the `~/.claude/workflow/` symlink, and installing skills.

If the bootstrap has NOT been run:
- **Linux/macOS:** `curl -sL https://raw.githubusercontent.com/rjweld21/gentic-workflow/master/scripts/bootstrap.sh | bash`
- **Windows:** `irm https://raw.githubusercontent.com/rjweld21/gentic-workflow/master/scripts/bootstrap.ps1 | iex`

## Context Layers

Before starting, understand the three layers (see `docs/context-layers.md` for full details):

| Layer | Location | Shared? | Purpose |
|---|---|---|---|
| Organization | `context/org/` | All teams in org | Board platform, org conventions |
| Project | `context/project/<name>/` | Team members | Test commands, architecture, learnings |
| User | `context/user/` | Never (private) | Preferences, credentials, local paths |

## Setup Flow

Walk the user through each step below. Check what's already done and skip completed steps.

### Step 1: Verify Installation

Check if the workflow is installed (bootstrap should have done this):

1. Check for `~/.claude/workflow/` (symlink or directory)
2. Verify `~/.claude/workflow/README.md` is readable
3. Check skills are linked:
   - `~/.claude/skills/initialize-workflow/SKILL.md` exists
   - `~/.claude/skills/using-workflow/SKILL.md` exists
4. If anything is missing, guide the user through the bootstrap or manual setup

### Step 2: Organization Context (`context/org/`)

1. Check if `~/.claude/workflow/context/org/org-config.json` exists
2. If not, ask the user:
   - "Are you setting this up for personal use or within an organization?"
   - **Personal use:** Create a minimal org-config with just the board adapter settings
   - **Organization:** Create a full org-config with conventions and defaults
3. Walk through `org-config.json`:
   - `adapter` — which board platform? List available adapters from `adapters/`
   - `board` settings — read the adapter's `README.md` and guide field creation + ID extraction
   - `defaults` — methodology (default: tdd), commit convention, branch pattern, coverage threshold
4. If this is a **fork for an org**, ask:
   - "Do you want to commit org context to this repo so all team members inherit it?"
   - If yes: explain they should remove the `context/org/` line from `.gitignore`
   - If no: keep it gitignored (each user sets up their own)
5. Optionally create `context/org/conventions.md` with initial org standards

### Step 3: Project Context (`context/project/<name>/`)

For each project the user wants to add:

1. Ask for the project name (will become the directory name)
2. Create `~/.claude/workflow/context/project/<name>/`
3. Copy template: `cp context/project/project-config.example.json context/project/<name>/project-config.json`
4. Walk through `project-config.json`:
   - `repo` — the owner/repo-name on the platform
   - `project_path` — local path to the project repo on this machine
   - `default_branch` — usually `main` (or leave empty to inherit org default)
   - `board_project_option_id` — the ID for this project on the board's Project field
   - `project_instructions_file` — auto-detect (check for CLAUDE.md, .cursorrules, CONTRIBUTING.md in the project)
   - `notes_directory` — default `.workflow` (creates agent notes in the project repo)
   - `spec_directory` / `plan_directory` — defaults to `docs/specs` and `docs/plans`
   - `test_commands` — ask what commands run tests (or detect from package.json, pyproject.toml, Makefile)
   - `coverage_thresholds` — ask or inherit org default
   - `coding_standards` — detect from project config files
   - `skills` — ask if they use Superpowers, OpenSpec, or other frameworks per phase
5. Set up the project repo's working directory:
   ```bash
   cd <project-path>
   mkdir -p .workflow/agent-notes/active .workflow/agent-notes/completed .workflow/evidence
   grep -q "^\.workflow/" .gitignore 2>/dev/null || echo ".workflow/" >> .gitignore
   ```
6. Create empty `learnings.md` for the project:
   ```bash
   cp ~/.claude/workflow/context/project/learnings.example.md ~/.claude/workflow/context/project/<name>/learnings.md
   ```
7. If this is a **fork for a team**, ask:
   - "Do you want to commit project context so all team members inherit it?"
   - If yes: explain they should remove the `context/project/` line from `.gitignore`
   - `project_path` will vary per machine — note that team members should override this in their user context

### Step 4: User Context (`context/user/`)

1. Check if `~/.claude/workflow/context/user/preferences.json` exists
2. If not, create from template:
   ```bash
   cp context/user/preferences.example.json context/user/preferences.json
   ```
3. Walk through preferences:
   - `display_name` — how the agent should refer to this user
   - `reporting.style` — concise, detailed, or narrative
   - `reporting.format` — bullet-points, prose, or tables
   - `development.auto_commit` / `auto_push` — should agents commit and push automatically?
   - `project_paths` — local paths to each project repo on this machine
   - `environment` — OS, shell, python command, node version, etc. (auto-detect where possible)
4. Create `context/user/local.md` from template
5. If the user has credentials (API keys, tokens):
   - Create `context/user/credentials.json` with relevant keys
   - Remind: "This file is always gitignored and never leaves your machine"

**User context is ALWAYS gitignored.** Never prompt about committing it.

### Step 5: Install Skills (if not already done)

1. Check if `~/.claude/skills/initialize-workflow` and `~/.claude/skills/using-workflow` exist
2. If not, create symlinks/junctions (bootstrap should have done this)

### Step 6: Verify Setup

Run a health check across all three layers:

1. **Org layer:** org-config.json exists, adapter is set, board IDs populated
2. **Project layer:** at least one project configured, project-config.json has required fields
3. **User layer:** preferences.json exists, project_paths match configured projects
4. **Board connectivity:** use adapter's `list_items` command to verify access
5. Report what's configured and what's still needed

### Step 7: Hand Off to Using-Workflow

After setup is complete, invoke the `using-workflow` skill to initialize the session context with the newly configured layers.

## What Gets Created

| Location | Layer | Purpose |
|---|---|---|
| `context/org/org-config.json` | Org | Board platform, adapter config, org defaults |
| `context/org/conventions.md` | Org | Org-wide standards (optional) |
| `context/project/<name>/project-config.json` | Project | Repo, tests, standards, skills |
| `context/project/<name>/learnings.md` | Project | Team knowledge (grows over time) |
| `context/user/preferences.json` | User | Personal workflow preferences |
| `context/user/credentials.json` | User | API keys and tokens (never committed) |
| `context/user/local.md` | User | Machine-specific notes |
| `<project>/.workflow/` | Runtime | Agent notes, evidence (in project repo, gitignored) |

## Troubleshooting

- **Symlink/junction fails on Windows:** use directory junctions (`mklink /J`) which don't require elevation
- **gh CLI not authenticated:** run `gh auth login` then `gh auth refresh -s read:project -s project`
- **Board field IDs not found:** use the adapter's README step-by-step to create fields first, then query IDs
- **Project config validation fails:** ensure required fields are filled in, not left as empty strings
- **Can't find project by name:** check that the directory name under `context/project/` matches what you expect, and that `project_paths` in user preferences points to the right local path
