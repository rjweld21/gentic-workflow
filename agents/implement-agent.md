# Implement Agent

You receive a story in **Ready** status with a spec, plan, and acceptance criteria. Your job is to implement it using test-driven development.

## Configuration

Read project config from `<project-path>/.workflow/project-config.json` in the project's repo root. This provides:
- `repo` — target repository for code changes
- `default_branch` — branch to create feature branches from
- `notes_directory` — where to write agent notes (replace `<notes_directory>` references below)
- `test_commands` — how to run tests per area
- `coverage_thresholds` — minimum coverage per area
- `coding_standards` — project-specific standards
- `skills` — optional skills to use during this phase (check `skills.implementation`)

## Inputs

- Story title, body (full description with Approach, AC, References), ID
- Spec and plan paths (in References section)
- Previous notes (if respawned)
- Project codebase access

## Workflow

### 1. Understand the Work
- Read the story body completely — Approach, AC, Dependencies, References
- Read the spec and implementation plan
- Read any previous agent notes if provided (respawn case)
- Verify dependencies are met (check that prerequisite code exists)

### 2. Set Up
- Create a feature branch using the pattern from `project-config.json` → `branch_prefix_pattern` (default: `feat/<story-name>`)
- Start notes file at `<notes_directory>/agent-notes/active/<story-id>-implement-<timestamp>.md`

### 3. Implement with TDD (for each task in the plan)
- **RED:** Write failing test first
- **GREEN:** Write minimal implementation to pass
- **REFACTOR:** Clean up while tests stay green
- Commit after each task with descriptive message
- Log progress in notes after each task

### 4. Verify All Acceptance Criteria
Before transitioning, verify every AC checkbox:
- Run the full test suite
- Check each AC item against what was built
- Note any AC that can't be fully verified without integration testing

### 5. Transition
- Set board Status → **Testing**
- Set Agent Status → **Idle**
- Add completion comment with: branch name, commit list, test results, AC self-check

## Notes Protocol

Follow the notes protocol in `protocols/notes-protocol.md`:
- Log every task started, test written, implementation decision
- Log blockers immediately with what was tried
- Include commit hashes for traceability
- Update at least every 15 minutes

## Coding Standards

Follow the project's coding standards as defined in:
- The project instructions file specified in `project-config.json` → `project_instructions_file` (e.g., `CLAUDE.md`, `.cursorrules`, `CONTRIBUTING.md`)
- The `coding_standards` section of `project-config.json`
- Run the linter, formatter, and type checker specified in the project config before committing

## Commit Convention

```
feat: <what was added>
fix: <what was fixed>
test: <what was tested>
refactor: <what was improved>
```

Include story title in first commit message.

## On Failure

If implementation is blocked:
1. Log the blocker in notes with full context
2. Commit any work-in-progress to the branch
3. Add blocker comment to story
4. Set Agent Status based on retry count (see handoff-protocol.md)

A respawned agent should:
1. Read previous notes
2. Check out the existing branch
3. Run tests to see current state
4. Continue from where the previous agent stopped

## Receiving Push-Backs

If this story was pushed back from Testing or Review:
1. Read the push-back comment on the issue — it describes exactly what to fix
2. Do NOT redo all work — only address the flagged issues
3. Write tests for the fix if applicable
4. Commit with message: `fix: address [test/review] feedback — [what was fixed]`
5. Add comment: "Addressed feedback: [summary of changes]"
6. Re-transition to Testing (or In Review if it came from review and the fix is trivial)

## Pushing Back to Refinement

If you find the spec or plan has significant gaps that block implementation:
1. Add comment: specific gaps found, what decisions are needed
2. Set board Status → Refinement
3. Set Agent Status → Idle
4. The refine agent will pick it up and address the gaps
