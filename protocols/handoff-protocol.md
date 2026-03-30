# Handoff Protocol

## Purpose

Defines how stories transition between statuses and agents, including liveness checks, error handling, and recovery.

## Status Transitions

```
Backlog ──[human]──► Refinement ──[refine agent]──► Ready
Ready ──[implement agent]──► In Progress ──[implement agent]──► Testing
Testing ──[test agent]──► In Review  (or back to In Progress if AC fails)
In Review ──[review agent]──► Done  (or back to In Progress if issues found)
```

### Done = CI Green + Issue Closed

A story can only move to Done when:
1. **All CI/CD pipeline jobs pass** on the PR (including deploy)
2. The **issue is closed** with a comment linking the merged PR

If a story is moved OUT of Done (e.g., regression found):
1. **Reopen the issue** with explanation
2. Move board status back to the appropriate lane

Never mark Done with a failing build. Never leave an issue open when the board says Done.

### Circular Flow (Push-Back)

Any agent can push a story back to a previous state if it finds gaps. The flow is circular, not linear-only:

```
Refinement ◄── Ready        (implement agent finds spec gaps)
Ready ◄── In Progress        (not used — implement agent owns both)
In Progress ◄── Testing      (test agent finds AC failures)
In Progress ◄── In Review    (review agent finds code issues)
```

**When pushing back:**
1. Add a detailed comment explaining:
   - What was found (specific issue, not vague)
   - What needs to change (concrete action items)
   - What was already completed (so work isn't repeated)
2. Set board Status to the previous lane
3. Set Agent Status to **Idle** (so the responsible agent picks it up)
4. The next agent reads the push-back comment and addresses only the flagged issues, not re-doing all work

**When receiving a push-back:**
1. Read the push-back comment carefully
2. Address ONLY the flagged issues
3. Write notes about what was changed
4. Re-transition to the next state when done
5. Add comment: "Addressed feedback from [agent]: [summary of fixes]"

### Work Item State Requirement

All stories MUST be trackable work items (not drafts) to support comments and PR/MR linking. The refine agent converts any remaining drafts during refinement using the adapter's `convert_draft` command. New stories created by humans should be created directly as full work items.

## Agent Status Field

Every actionable story has an "Agent Status" field:
- **Idle** — available for pickup by the orchestrator
- **Agent Working** — an agent is actively working on this
- **Blocked** — needs human intervention

## Orchestrator Poll Cycle

Each poll cycle, the orchestrator executes in order:

### Step 1: Liveness Check (Agent Working items)

```
For each item where Agent Status = "Agent Working":
    1. Check orchestrator-state.json for the agent reference
    2. Attempt to reach the sub-agent (SendMessage)
       ├─ Agent responds → check notes timestamp
       │   ├─ Note in last 30 min → healthy, skip
       │   └─ No note in 30 min → nudge: "Log your progress"
       │       ├─ Wait one poll cycle
       │       ├─ New note + artifacts? → healthy
       │       ├─ New note, no artifacts (2nd consecutive)? → suspect rogue
       │       │   └─ Set Blocked, comment: "No artifacts produced"
       │       └─ Still no note → kill, read notes, respawn
       │
       └─ Agent unreachable → read notes → respawn new agent
           └─ Pass previous notes as context to new agent
```

### Step 2: Dispatch (Idle items)

```
1. Query board: items in (Refinement, Ready, Testing, In Review)
   where Agent Status = "Idle"
2. Sort by: Priority (P0 > P1 > P2), then creation date
3. Pick first item
4. Verify Agent Status is still Idle (prevent race condition)
5. Set Agent Status = "Agent Working"
6. Update orchestrator-state.json with agent reference
7. Add start comment to story
8. Spawn sub-agent with: story context + any previous notes
```

### Step 3: Report (optional)

Log summary of board state for human review:
- N items in each status
- N blocked items (list titles)
- N items completed since last poll

## Sub-Agent Exit Protocol

Before returning to the orchestrator, every sub-agent MUST:

1. Write final notes entry summarizing outcome
2. Add completion comment to story (see comment-protocol.md)
3. Update board Status to next lane
4. Set Agent Status to "Idle"
5. Update orchestrator-state.json (remove from active_agents)

If the sub-agent encounters a failure:

1. Write notes entry describing the failure
2. Add blocker comment to story
3. Check retry count in orchestrator-state.json
   ├─ retry_count < 1 → increment count, set Agent Status = "Idle" (will be retried)
   └─ retry_count >= 1 → set Agent Status = "Blocked" (needs human)
4. Update orchestrator-state.json

## Recovery (Respawned Agent)

When an agent is respawned after a crash:

1. Orchestrator passes the previous agent's notes file path
2. New agent reads notes to understand progress
3. New agent continues from the last logged action, not from scratch
4. New agent writes: "### HH:MM — Respawned after previous agent exit"
5. Normal work continues from there

## Artifact Verification

The orchestrator checks for meaningful artifacts, not just activity:
- **Refine agent:** spec file exists, plan file exists, story body updated
- **Implement agent:** commits on branch, test files created
- **Test agent:** test results logged, AC evidence documented
- **Review agent:** PR/MR created or review comments added

## Board Field IDs

All board field IDs and option IDs are stored in `config/board-config.json` within the gentic-workflow installation. Do NOT hardcode IDs in agent prompts or protocols — always read from the config file. For the concrete commands to execute board operations, see `adapters/<adapter>/commands.md` and `docs/adapter-interface.md`.
