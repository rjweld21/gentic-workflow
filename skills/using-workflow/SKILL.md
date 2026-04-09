---
name: using-workflow
description: Use when starting a session that will use the Gentic Workflow for orchestrated development, or when an agent needs context on how to interact with the board and dispatch workers
---

# Using Workflow

## Overview

Session initializer for the Gentic Workflow. Loads the three context layers (org, project, user), adapter commands, and protocols into the agent's context. Run at the start of any session that will interact with the board.

## When to Use

- Starting a new session where you'll be the orchestrator or a worker
- An agent was spawned and needs to understand the workflow system
- You need to check board state or dispatch workers
- Resuming work after a session restart

**Do NOT use when:**
- Workflow hasn't been set up yet — use `initialize-workflow` first
- You're doing work unrelated to the board-driven workflow

## Session Initialization

### Step 1: Load Context Layers (Cascading)

Load context from all three layers. More specific layers override general ones. Read each layer's docs at `docs/context-layers.md` for full details.

**Layer 1 — Organization:**
1. Read `~/.claude/workflow/context/org/org-config.json`
   - If not found: the workflow may not be fully set up. Warn the user but continue — org context is optional for individual use.
   - Extract: adapter type, board IDs, org defaults (methodology, branch pattern, coverage)
2. Read `~/.claude/workflow/context/org/conventions.md` if it exists
   - These are org-wide standards to follow during this session

**Layer 2 — Project:**
1. Determine the current project:
   - Check if the current working directory has `.workflow/project-config.json` (legacy location)
   - Check `~/.claude/workflow/context/project/` for a directory matching the current repo name
   - Check user preferences for `project_paths` mapping
2. If found, read the project's `project-config.json`
   - Values here override org defaults where set (non-empty values win)
3. Read `learnings.md` and `architecture.md` if they exist
   - These are accumulated team knowledge — factor them into your work

**Layer 3 — User:**
1. Read `~/.claude/workflow/context/user/preferences.json` if it exists
   - Respect personal preferences for reporting style, verbosity, auto-commit, etc.
2. Read `~/.claude/workflow/context/user/local.md` if it exists
   - Machine-specific notes (tool versions, environment quirks)
3. Read `~/.claude/workflow/context/user/credentials.json` if it exists
   - NEVER log or echo credential values

### Step 2: Resolve Merged Config

Build a merged configuration by cascading: org defaults → project overrides → user overrides.

For example:
- `methodology`: org says `tdd`, project says nothing → use `tdd`
- `coverage_thresholds.backend`: org default is `80`, project says `90` → use `90`
- `test_verbosity`: user says `verbose` → use `verbose` regardless of other layers

### Step 3: Load Workflow Framework

Read and internalize these core documents:

| Document | Path | Contains |
|---|---|---|
| Adapter commands | `adapters/<adapter>/commands.md` | Concrete CLI commands for board operations |
| Handoff protocol | `protocols/handoff-protocol.md` | Status transitions, liveness, recovery |
| Comment protocol | `protocols/comment-protocol.md` | How to communicate on stories |
| Notes protocol | `protocols/notes-protocol.md` | How to log work for continuity |
| Circular flow | `docs/circular-flow.md` | Push-back mechanics |
| Context layers | `docs/context-layers.md` | How to classify and record new learnings |

### Step 4: Query Board State

Use the adapter's `list_items` command to get current board state. Summarize:

```
Board Status:
  Backlog:      N items
  Refinement:   N items (N idle, N working, N blocked)
  Ready:        N items
  In Progress:  N items (N idle, N working, N blocked)
  Testing:      N items (N idle, N working, N blocked)
  In Review:    N items (N idle, N working, N blocked)
  Done:         N items

Blocked items: [list titles if any]
```

### Step 5: Determine Role

Based on context, determine what role this session will play:

| Context | Role | What to read |
|---|---|---|
| User says "start orchestrator" or "poll the board" | **Orchestrator** | `agents/board-orchestrator.md` |
| Spawned with story context + "refine" | **Refine Worker** | `agents/refine-agent.md` |
| Spawned with story context + "implement" | **Implement Worker** | `agents/implement-agent.md` |
| Spawned with story context + "test" | **Test Worker** | `agents/test-agent.md` |
| Spawned with story context + "review" | **Review Worker** | `agents/review-agent.md` |
| User asks about board or wants to manage stories | **Interactive** | No specific agent doc — respond to user requests |

Read the appropriate agent document and follow its instructions.

### Step 6: Report Ready State

Confirm to the user or orchestrator what's loaded:

```
Gentic Workflow initialized:
  Adapter:       <adapter-name>
  Organization:  <org-name or "not configured">
  Project:       <project-name or "board-level only">
  User:          <display-name or "anonymous">
  Role:          <determined role>
  Board state:   <summary from step 4>
  Ready to:      <what you can do next>
```

## Context Recording During Sessions

Throughout the session, watch for new learnings. When you discover something that would help future sessions, classify and record it:

| If the learning applies to... | Write to... |
|---|---|
| All teams and projects in the org | `context/org/conventions.md` |
| This specific project/team | `context/project/<name>/learnings.md` |
| This user's preferences or machine | `context/user/local.md` |

**Format for appended entries:**
```markdown
### YYYY-MM-DD — <Brief title>
<What was learned and why it matters for future sessions>
```

**Before recording:** read the existing file to avoid duplicating known information.

**Credentials and secrets** always go to `context/user/credentials.json` — never to md files.

## Quick Reference — Common Operations

### As Orchestrator
1. Poll board → find idle stories → dispatch workers
2. Check liveness of active workers
3. Handle blocked stories

### As Worker
1. Read story context and previous notes
2. Do the work for your stage (refine/implement/test/review)
3. Write notes, comment on story, update board status
4. Record any learnings to appropriate context layer
5. Exit when done

### Interactive Commands
- "Show me the board" → query and display board state
- "What's blocked?" → filter for blocked items
- "Dispatch workers" → enter orchestrator mode
- "Start work on [story]" → enter worker mode for that story

## Important Rules

1. **Never edit base framework files** — agents, protocols, adapters, and docs are read-only
2. **Always use adapter commands** from `commands.md` — never hardcode platform-specific CLI commands
3. **Always write notes** — every meaningful action gets logged per the notes protocol
4. **Always comment on stories** — transitions and blockers must be visible on the board
5. **Conventional commits** — `feat:`, `fix:`, `test:`, `refactor:`
6. **Error budget** — 1 retry per story, then block for human
7. **Don't skip to Done** — stories must pass through every stage in order
8. **Record learnings** — when you discover something new, classify it and write it to the right context layer
