# GitHub Projects Adapter

Setup instructions for using the Gentic Workflow with GitHub Projects V2.

## Prerequisites

- `gh` CLI installed and authenticated
- GitHub Projects scopes: `gh auth refresh -s read:project -s project -h github.com`
- A private repo for issue tracking (to keep backlog out of public repos)

## Setup

### 1. Create or identify your project board

```bash
gh project list --owner <your-username>
```

### 2. Create required fields

```bash
# Agent Status field
gh project field-create <project-num> --owner <owner> --name "Agent Status" \
  --data-type "SINGLE_SELECT" --single-select-options "Idle,Agent Working,Blocked"

# Priority field
gh project field-create <project-num> --owner <owner> --name "Priority" \
  --data-type "SINGLE_SELECT" --single-select-options "P0,P1,P2"

# Size field
gh project field-create <project-num> --owner <owner> --name "Size" \
  --data-type "SINGLE_SELECT" --single-select-options "XS,S,M,L,XL"

# Epic field
gh project field-create <project-num> --owner <owner> --name "Epic" \
  --data-type "SINGLE_SELECT" --single-select-options "<your epics>"

# Project field (for multi-project boards)
gh project field-create <project-num> --owner <owner> --name "Project" \
  --data-type "SINGLE_SELECT" --single-select-options "<your projects>"
```

### 3. Add Refinement and Testing statuses

GitHub Projects V2 comes with default statuses (Todo, In Progress, Done). You need to add the additional statuses via GraphQL:

```bash
gh api graphql -f query='mutation {
  updateProjectV2Field(input: {
    fieldId: "<STATUS_FIELD_ID>"
    singleSelectOptions: [
      {name: "Backlog", color: GRAY}
      {name: "Refinement", color: YELLOW}
      {name: "Ready", color: GREEN}
      {name: "In progress", color: BLUE}
      {name: "Testing", color: ORANGE}
      {name: "In review", color: PURPLE}
      {name: "Done", color: PINK}
    ]
  }) { projectV2Field { ... on ProjectV2SingleSelectField { options { id name } } } }
}'
```

### 4. Get field IDs and generate config

```bash
gh project field-list <project-num> --owner <owner> --format json
```

Copy the IDs into `config/board-config.json` (use `config/board-config.example.json` as a template).

## Common Commands

See `commands.md` for all board operations used by the agents.
