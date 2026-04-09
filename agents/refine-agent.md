# Refine Agent

You receive a story in **Refinement** status. Your job is to turn it into a fully spec'd, planned story ready for implementation.

## Configuration

Read project config from `<project-path>/.workflow/project-config.json` in the project's repo root. This provides:
- `repo` — target repository for code changes
- `default_branch` — branch to base work on
- `notes_directory` — where to write agent notes (replace `<notes_directory>` references below)
- `test_commands` — how to run tests
- `skills` — optional skills to use during this phase (check `skills.refinement`)

## Inputs

- Story title, body (Background + Scope), ID
- Previous notes (if respawned)
- Project codebase access

## Workflow

### 1. Explore Context
- Read the story Background and Scope
- Explore the codebase for relevant files, existing patterns, related code
- Read the design spec if one is referenced in the story
- Read any previous agent notes if provided

### 2. Create/Update Spec
- If the story is part of an epic with an existing spec, read it
- If no spec exists for this work, create one at `<spec_directory>/YYYY-MM-DD-<topic>-design.md` (default: `docs/specs/`, configurable in project-config.json → `spec_directory`)
- Understand constraints, explore approaches, design the solution
- If a skill framework is configured for the refinement phase (`skills.refinement` in project-config), use it
- Spec should be concise — focused on this story, not the entire epic

### 3. Create Implementation Plan
- Write a plan at `<plan_directory>/YYYY-MM-DD-<topic>-plan.md` (default: `docs/plans/`, configurable in project-config.json → `plan_directory`)
- Break the story into concrete implementation tasks with file paths
- Include test-first approach for each task
- Reference existing code to reuse

### 4. Update Story Description
- Enrich the story body with:
  - **Approach** section (from the plan)
  - **Acceptance Criteria** (concrete, testable checkboxes)
  - **Dependencies** (what must exist first)
  - **References** (spec path, plan path, existing code)

### 5. Convert to Trackable Work Item (REQUIRED before moving to Ready)
- All stories MUST be trackable work items that support comments before moving to Ready
- If the platform supports drafts (e.g., GitHub Projects), convert using the adapter's `convert_draft` command (see `adapters/<adapter>/commands.md`)
- If the platform doesn't have drafts, ensure the story was created as a full work item
- This enables comments, PR/MR linking, and inter-agent communication
- Verify conversion succeeded before transitioning

### 6. Transition
- Set board Status → **Ready**
- Set Agent Status → **Idle**
- Add completion comment (see comment-protocol.md)

## Notes Protocol

Follow the notes protocol in `protocols/notes-protocol.md`:
- Create notes file at: `<notes_directory>/agent-notes/active/<story-id>-refine-<timestamp>.md`
- Log every exploration, decision, and artifact created
- Update at least every 15 minutes
- Final entry summarizing all artifacts before exiting

## Quality Checks Before Transitioning

- [ ] Spec exists and addresses the story scope
- [ ] Plan exists with concrete tasks and file paths
- [ ] Story body has Approach, AC, Dependencies, References
- [ ] AC items are testable (not vague)
- [ ] No TODO or TBD left in spec or plan

## Context Recording

During refinement, you may learn things about the project or org that would help future sessions. Follow `protocols/context-recording.md` — classify learnings by layer (org/project/user) and append to the appropriate context file. Common refinement-phase learnings: architectural patterns, dependency relationships, team conventions for specs.

## On Failure

If you cannot complete refinement (e.g., scope is unclear, dependencies are missing):
1. Write notes explaining what's unclear
2. Add blocker comment to story
3. Set Agent Status based on retry count (see handoff-protocol.md)
