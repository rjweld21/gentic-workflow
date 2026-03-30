# Story Comment Protocol

## Purpose

Story comments are the **inter-agent communication channel**. They provide a concise summary visible on the board that other agents and humans can read without digging into notes files.

## When to Comment

Every agent writes a comment when:
1. **Starting work** on a story
2. **Completing work** and transitioning the story
3. **Hitting a blocker** that requires human intervention
4. **Failing and moving the story back** to a previous lane

## Comment Format

```markdown
### <Agent Role> Agent — <YYYY-MM-DD HH:MM>

**Action:** <One-line summary of what was done>
**Result:** <Outcome — success, partial, or failure>
**Artifacts:**
- Branch: `<branch-name>` (if applicable)
- Spec: `<path>` (if created)
- Plan: `<path>` (if created)
- PR: #<number> (if created)
- Tests: <pass count>/<total count>
**Key Decisions:**
- <Decision 1 and rationale>
- <Decision 2 and rationale>
**Notes:** `<notes_directory>/agent-notes/active/<filename>.md`
**Next:** <What the next agent in the pipeline should know>
```

## Posting Comments

Stories must be trackable work items (not drafts) to support comments. Use the adapter's `comment` command (see `adapters/<adapter>/commands.md`).

For platforms with draft items (e.g., GitHub Projects), drafts don't support comments — append to the story body using the adapter's `update_description` command instead. The refine agent should convert drafts to full work items before transitioning to Ready.

## Blocker Comment Format

```markdown
### <Agent Role> Agent — <YYYY-MM-DD HH:MM> — BLOCKED

**Blocker:** <Clear description of what's blocking>
**Tried:**
- <Attempt 1 and result>
- <Attempt 2 and result>
**Needs:** <What human intervention is required>
**Notes:** `<notes_directory>/agent-notes/active/<filename>.md`
**Retry Count:** <1 of 1> (max retries before permanent block)
```
