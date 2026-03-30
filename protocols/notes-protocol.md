# Agent Notes Protocol

## Purpose

Agent notes are a running log of work performed on a story. They serve as:
- **Continuity** — if an agent crashes, the next agent picks up from the notes
- **Audit trail** — understanding decisions made during development
- **Context for other agents** — downstream agents read upstream notes

## File Location

```
<notes_directory>/agent-notes/active/<story-id>-<role>-<YYYY-MM-DDTHH-MM>.md
```

Example: `<notes_directory>/agent-notes/active/ISSUE-42-implement-2026-03-28T14-30.md`

When a story moves to Done, the orchestrator moves notes to `<notes_directory>/agent-notes/completed/`.

## Format

```markdown
# Agent Notes: <Story Title>
**Role:** <Refine | Implement | Test | Review> Agent
**Started:** <YYYY-MM-DD HH:MM>
**Story ID:** <issue ID>
**Branch:** <branch name, if applicable>

---

### HH:MM — <Brief action title>
<What was done, what was found, decisions made>
<File paths, function names, specific details>

### HH:MM — <Next action>
...
```

## Rules

1. **Log every meaningful action** — file reads, design decisions, test results, blockers encountered
2. **Be specific** — include file paths, function names, error messages, commit hashes
3. **Log blockers immediately** — if stuck, write what you tried and what failed before requesting help
4. **Timestamp every entry** — use HH:MM format within the day
5. **Update at least every 15 minutes** — the orchestrator uses note timestamps for liveness checks
6. **Final entry before exiting** — always write a summary entry before returning to the orchestrator

## What NOT to include

- Full file contents (reference paths instead)
- Sensitive data (API keys, credentials)
- Verbose tool output (summarize, link to artifacts)
