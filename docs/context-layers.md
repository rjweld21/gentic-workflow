# Context Layers

The Gentic Workflow separates knowledge into three layers. The base framework (agents, protocols, adapters, docs) is read-only — agents never edit it. All learned knowledge goes into context layers that grow over time.

## The Three Layers

```
┌─────────────────────────────────────────────┐
│  Organization Context (context/org/)        │  Shared across all teams
│  Set once, rarely changes                   │  Board platform, org conventions
├─────────────────────────────────────────────┤
│  Project Context (context/project/<name>/)  │  Shared across team members
│  Grows as team learns                       │  Test commands, architecture, gotchas
├─────────────────────────────────────────────┤
│  User Context (context/user/)               │  Private to one person/machine
│  Fully specific, never generic              │  Preferences, credentials, local paths
└─────────────────────────────────────────────┘
```

### Layer 1 — Organization (`context/org/`)

**Who sets it up:** The person who forks or first configures the workflow for their org.
**Who reads it:** Every agent, every session, every project in the org.
**How often it changes:** Rarely — after initial setup, only when org-wide decisions change.

**Contains:**
- `org-config.json` — Board platform choice, board IDs, org-wide repos, shared adapter settings
- `conventions.md` — Org-wide coding conventions, PR standards, documentation expectations
- Any additional `.md` files agents create when they learn something org-wide

**Examples of what goes here:**
- "We use GitHub Projects V2 with board #3"
- "All PRs require at least one human approval before merge"
- "We use conventional commits across all repos"
- "Our CI runs on GitHub Actions, deploys go through ArgoCD"

**What to leave generic (for project level to specify):**
- Specific test commands (vary per project)
- Coverage thresholds (vary per project)
- Branch naming patterns (may vary per team)
- Coding language/framework specifics

### Layer 2 — Project (`context/project/<project-name>/`)

**Who sets it up:** The team lead or first developer who onboards a project.
**Who reads it:** Every agent working on that project.
**How often it changes:** Grows over time as the team learns. Any team member's session can add to it.

**Contains:**
- `project-config.json` — Repo, branch, test commands, coverage, coding standards, skills
- `learnings.md` — Accumulated team knowledge (auto-appended by agents)
- `architecture.md` — Architectural decisions agents discover or are told about
- Any additional `.md` files agents create for project-specific context

**Examples of what goes here:**
- "Run `DB_MIGRATE=1 pytest` before E2E tests — the test DB needs fresh migrations"
- "The frontend uses Chakra UI v2, not v3 — v3 has breaking changes we haven't migrated to"
- "Deploy takes ~5 minutes after CI green — wait before production validation"
- "The `/api/v1/upload` endpoint has a 50MB limit — test with files under that"

**What to leave generic (for user level to specify):**
- Personal report format preferences
- Local paths and environment specifics
- Individual API keys or credentials
- Editor/IDE preferences

### Layer 3 — User (`context/user/`)

**Who sets it up:** Each individual user, on their machine.
**Who reads it:** Only agents running on that user's machine.
**How often it changes:** Updated whenever the agent learns a user preference.

**Contains:**
- `preferences.json` — Personal workflow style, report formatting, verbosity level
- `credentials.json` — API keys, tokens, local paths (NEVER committed)
- `local.md` — Machine-specific notes (local tool versions, environment quirks)
- Any additional `.md` files agents create for user-specific context

**Examples of what goes here:**
- "User prefers bullet-point summaries over prose"
- "User's AWS profile is `dev-east`, region `us-east-1`"
- "User runs tests with `--verbose` flag, prefers seeing full output"
- "On this machine, Python is `python3` not `python`"

**Nothing is left generic at this level.** Everything here is fully specified.

## Context Resolution (Cascading)

When an agent loads context, it reads bottom-up. More specific layers override general ones:

```
1. Read context/org/org-config.json          → Base settings
2. Read context/project/<name>/project-config.json → Override with project specifics
3. Read context/user/preferences.json        → Override with user preferences
```

For `.md` context files (conventions, learnings, etc.), layers are additive — all are read, none override. The agent builds a complete picture from all three.

## How Agents Record New Context

During any session, when an agent learns something new, it should:

1. **Classify** — which layer does this belong to?
   - Applies to all teams/projects → **org**
   - Applies to this project/team → **project**
   - Applies to this user/machine → **user**

2. **Append** — add to the appropriate file with a timestamp:
   ```markdown
   ### 2026-04-08 — <Brief title>
   <What was learned and why it matters>
   ```

3. **Don't duplicate** — read existing context first to avoid repeating what's already known.

4. **Don't move between layers** — if something was recorded at the project level, leave it there even if it might also apply to the org. The org level should only contain things explicitly confirmed as org-wide.

## Gitignore Strategy

### Base open-source repo (this repo)
All three context directories are gitignored. The repo ships with only example/template files.

```gitignore
# Context layers — all gitignored in base repo.
# When forking for an org, remove the ignores for the layers you want to share.
# See docs/context-layers.md for details.
context/org/
context/project/
context/user/
```

### When forked for an organization
Remove the gitignore for `context/org/` — commit org-wide config so all teams inherit it.
Optionally remove the gitignore for `context/project/` — if project configs should be shared via the fork.

```gitignore
# context/org/          ← REMOVED: org context is committed and shared
# context/project/      ← REMOVED: project context is committed and shared
context/user/            ← ALWAYS gitignored: personal/credentials
```

### User context is ALWAYS gitignored
Never commit `context/user/` — it contains credentials and machine-specific details.

## Directory Layout

```
context/
├── org/
│   ├── .gitkeep                          ← Keeps dir in git when empty
│   ├── org-config.example.json           ← Template (committed in base repo)
│   ├── org-config.json                   ← Real config (gitignored in base)
│   └── conventions.md                    ← Org standards (gitignored in base, committed in forks)
├── project/
│   ├── .gitkeep
│   ├── project-config.example.json       ← Template (committed in base repo)
│   └── <project-name>/                   ← One dir per project (gitignored in base)
│       ├── project-config.json
│       ├── learnings.md
│       └── architecture.md
└── user/
    ├── .gitkeep
    ├── preferences.example.json          ← Template (committed in base repo)
    ├── preferences.json                  ← Real preferences (always gitignored)
    ├── credentials.json                  ← Keys and tokens (always gitignored)
    └── local.md                          ← Machine-specific notes (always gitignored)
```

## Relationship to Service Adapters

The base adapter files in `adapters/` are generic and assume a standard developer environment. When used within an enterprise or locked-down ecosystem:

- The **org context** can document adapter overrides (e.g., "our GitHub Enterprise is at `github.acme.com`, use `--hostname` flag")
- Agents read these notes and adapt their adapter command usage accordingly
- If a fork needs permanent adapter changes, they can edit the adapter files directly in their fork — the base repo stays generic

The adapters don't need to anticipate every enterprise variation. The context layer system handles it: the agent encounters something unexpected, records it in the org or project context, and future sessions benefit from that knowledge.
