# Adapter Interface

Every adapter must provide commands for these abstract operations. Agents reference these operations by name — the adapter's `commands.md` provides the concrete implementation for each platform.

## How Agents Use Adapters

1. The orchestrator reads `board-config.json` → `adapter` field to know which adapter is active
2. Agents look up the concrete command in `adapters/<adapter-name>/commands.md`
3. Agents substitute placeholders with values from `board-config.json` and `project-config.json`

## Required Operations

### Board Operations

| Operation | Description | Used By |
|---|---|---|
| `list_items` | Query all stories on the board with their fields (status, agent status, priority) | Orchestrator |
| `get_item` | Get a single story by ID or title | All agents |
| `update_field` | Set a field value on a story (status, agent status, priority, etc.) | All agents |
| `create_story` | Create a new story on the board | Refine agent (if needed) |
| `convert_draft` | Convert a draft/idea into a trackable work item (if applicable — not all platforms have drafts) | Refine agent |

### Work Item Operations

| Operation | Description | Used By |
|---|---|---|
| `comment` | Post a comment on a story (for inter-agent communication and audit trails) | All agents |
| `update_description` | Update a story's body/description | Refine agent |
| `get_comments` | Read comments on a story | All agents (when picking up work) |
| `close_work_item` | Close/resolve a work item with a comment (when story moves to Done) | Review agent |
| `reopen_work_item` | Reopen a previously closed work item with an explanation | Orchestrator, Review agent |

### Code Operations

| Operation | Description | Used By |
|---|---|---|
| `create_pr` | Open a pull request / merge request from a feature branch | Review agent |
| `get_pr_status` | Check if a PR/MR exists and its state | Review agent |
| `check_ci` | Check CI/CD pipeline status on a PR/MR (pass/fail/pending) | Review agent |

### Evidence Operations

| Operation | Description | Used By |
|---|---|---|
| `upload_evidence` | Attach screenshots or files to a story so they're visible inline | Test agent |
| `get_file_url` | Get a viewable URL for a file on a branch (for linking evidence in comments) | Test agent, Review agent |

## Adapter Directory Structure

Each adapter lives in `adapters/<adapter-name>/`:

```
adapters/<adapter-name>/
├── README.md       ← Setup instructions (prerequisites, auth, field creation)
└── commands.md     ← Concrete commands mapping each operation above
```

### commands.md Format

Each operation should have a clear heading matching the operation name, with copy-pasteable commands and placeholder notation:

```markdown
## list_items

\```bash
<concrete command with <placeholders>>
\```

**Placeholders:** `<project-num>` from board-config.json → project_number, ...
```

## Adding a New Adapter

1. Create `adapters/<platform-name>/` directory
2. Write `README.md` with:
   - Prerequisites (CLI tools, auth scopes, account setup)
   - Step-by-step board/project creation
   - How to get field IDs and populate `board-config.json`
3. Write `commands.md` implementing every operation in the table above
4. Note any platform-specific concepts in the README (e.g., GitHub has "drafts", Jira has "transitions")
5. If the platform doesn't support an operation (e.g., no draft concept), note it as "N/A — not applicable for this platform"

## Platform Differences to Account For

| Concept | GitHub | GitLab | Bitbucket | Jira | Linear |
|---|---|---|---|---|---|
| Work item term | Issue | Issue | Issue | Ticket | Issue |
| Code review term | Pull Request | Merge Request | Pull Request | — | — |
| Board type | Projects V2 | Boards | Boards | Boards | Projects |
| CLI tool | `gh` | `glab` | `bb` / API | `jira` / API | Linear API |
| Has drafts? | Yes | No | No | No | No |
| Comment on items? | Yes | Yes | Yes | Yes | Yes |
| File attachment? | Via API | Via API | Via API | Via API | Via API |
| Separate issue repo? | Optional | No | No | No | No |

## Board Config Variations

The `board-config.json` structure may vary by adapter. The core fields are:

```json
{
  "adapter": "<adapter-name>",
  "fields": {
    "status": { "options": { "backlog": "", "refinement": "", "ready": "", "in_progress": "", "testing": "", "in_review": "", "done": "" } },
    "agent_status": { "options": { "idle": "", "agent_working": "", "blocked": "" } },
    "priority": { "options": { "p0": "", "p1": "", "p2": "" } }
  }
}
```

Each adapter may add platform-specific fields (e.g., `project_id`, `owner` for GitHub; `workspace`, `board_id` for Jira). See the adapter's README for the full config shape.
