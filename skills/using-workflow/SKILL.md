---
name: using-workflow
description: Use when starting a session that will use the Gentic Workflow for orchestrated development, or when an agent needs context on how to interact with the board and dispatch workers
---

# Using Workflow

## Overview

Session initializer for the Gentic Workflow. Loads board config, project config, and adapter commands into the agent's context so it can orchestrate or participate in the workflow. Run at the start of any session that will interact with the board.

## When to Use

- Starting a new session where you'll be the orchestrator or a worker
- An agent was spawned and needs to understand the workflow system
- You need to check board state or dispatch workers
- Resuming work after a session restart

**Do NOT use when:**
- Workflow hasn't been set up yet — use `initialize-workflow` first
- You're doing work unrelated to the board-driven workflow

## Session Initialization

### Step 1: Locate and Validate Config

1. Read `~/.claude/workflow/config/board-config.json`
   - If not found: tell the user to run `initialize-workflow` first, then stop
   - Extract: `adapter`, field IDs, project/board identifiers
2. Identify the adapter: read `adapter` field from board config
3. Load adapter commands from `~/.claude/workflow/adapters/<adapter>/commands.md`

### Step 2: Detect Current Project

1. Check if the current working directory has `.workflow/project-config.json`
2. If found, read it and extract:
   - `repo`, `default_branch`, `notes_directory`
   - `test_commands`, `coverage_thresholds`, `coding_standards`
   - `skills` configuration for each phase
   - `project_instructions_file` — read it if it exists
   - `spec_directory`, `plan_directory`, `branch_prefix_pattern`, `methodology`
3. If not found, note that this session is board-level only (orchestrator mode, not project-specific)

### Step 3: Load Workflow Context

Read and internalize these documents — they define how you operate:

| Document | Path | Contains |
|---|---|---|
| Adapter commands | `~/.claude/workflow/adapters/<adapter>/commands.md` | Concrete CLI commands for board operations |
| Handoff protocol | `~/.claude/workflow/protocols/handoff-protocol.md` | Status transitions, liveness, recovery |
| Comment protocol | `~/.claude/workflow/protocols/comment-protocol.md` | How to communicate on stories |
| Notes protocol | `~/.claude/workflow/protocols/notes-protocol.md` | How to log work for continuity |
| Circular flow | `~/.claude/workflow/docs/circular-flow.md` | Push-back mechanics |

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
  Adapter:     <adapter-name>
  Project:     <repo> (or "board-level only")
  Role:        <determined role>
  Board state: <summary from step 4>
  Ready to:    <what you can do next>
```

## Quick Reference — Common Operations

### As Orchestrator
1. Poll board → find idle stories → dispatch workers
2. Check liveness of active workers
3. Handle blocked stories

### As Worker
1. Read story context and previous notes
2. Do the work for your stage (refine/implement/test/review)
3. Write notes, comment on story, update board status
4. Exit when done

### Interactive Commands
- "Show me the board" → query and display board state
- "What's blocked?" → filter for blocked items
- "Dispatch workers" → enter orchestrator mode
- "Start work on [story]" → enter worker mode for that story

## Important Rules

1. **Always use adapter commands** from `commands.md` — never hardcode platform-specific CLI commands
2. **Always write notes** — every meaningful action gets logged per the notes protocol
3. **Always comment on stories** — transitions and blockers must be visible on the board
4. **Conventional commits** — `feat:`, `fix:`, `test:`, `refactor:`
5. **Error budget** — 1 retry per story, then block for human
6. **Don't skip to Done** — stories must pass through every stage in order
