# Gentic Workflow

A framework for running autonomous AI development workflows using agents and a Kanban board. One long-lived orchestrator polls for work and spawns specialized short-lived agents that refine, implement, test, and review code — all with structured handoffs and audit trails.

**Board-agnostic.** **Runtime-agnostic.** **Skill-framework-agnostic.**

## How It Works

```
Orchestrator (long-lived, polls on a loop)
    │
    ├── Polls board for Idle stories
    ├── Spawns short-lived WORKER agents (one per stage per story)
    │   ├── Refine Worker   → Spec + plan creation (exits when done)
    │   ├── Implement Worker → TDD implementation (exits when done)
    │   ├── Test Worker      → Acceptance criteria validation (exits when done)
    │   └── Review Worker    → Code review + PR/MR creation (exits when done)
    ├── Monitors worker liveness via timestamped notes
    ├── Handles recovery on worker crash (respawn with context)
    ├── Max 2 concurrent workers (configurable)
    └── Error budget: 1 retry per story, then blocked for human
```

### Why This Architecture?

- **Context freshness** — each worker starts clean. A single agent running a full pipeline accumulates code, test output, and review findings until quality degrades.
- **Concurrency** — the orchestrator runs multiple workers in parallel on different stories.
- **Recovery** — if a worker crashes, the orchestrator respawns with the previous worker's notes. No full restart.
- **Circular flow** — agents can push stories back to previous stages with detailed feedback, not just forward.

## Board Statuses

| Status | Description | Agent |
|---|---|---|
| Backlog | Raw idea | Human moves to Refinement |
| Refinement | Being spec'd and planned | Refine Agent |
| Ready | Fully refined, waiting | — |
| In Progress | Being implemented with TDD | Implement Agent |
| Testing | Validating acceptance criteria | Test Agent |
| In Review | Code review and PR/MR creation | Review Agent |
| Done | Human-approved and merged | Human approval |

## Required Board Fields

| Field | Type | Options |
|---|---|---|
| Status | Single Select | Backlog, Refinement, Ready, In Progress, Testing, In Review, Done |
| Agent Status | Single Select | Idle, Agent Working, Blocked |
| Priority | Single Select | P0, P1, P2 |
| Size | Single Select | XS, S, M, L, XL |
| Epic | Single Select | *(your milestones)* |
| Project | Single Select | *(your project names — for multi-repo boards)* |

## Quick Start

### 1. Install

Clone this repo and symlink it into your agent's config directory:

```bash
git clone <repo-url>
cd gentic-workflow

# For Claude Code users — symlink to ~/.claude/workflow/
# Linux/macOS:
ln -s "$(pwd)" ~/.claude/workflow

# Windows (run as admin, or use junction):
mklink /J "%USERPROFILE%\.claude\workflow" "%cd%"
```

### 2. Choose and set up your board adapter

See [`docs/adapter-interface.md`](docs/adapter-interface.md) for the abstract operations every adapter must support.

Currently included:
- **GitHub Projects V2** — see [`adapters/github-projects/README.md`](adapters/github-projects/README.md)

### 3. Configure your board

```bash
cp config/board-config.example.json config/board-config.json
# Edit with your board's field IDs (see your adapter's README for how to get them)
```

### 4. Configure each project repo

In each repo that agents will work on:

```bash
mkdir -p .workflow/agent-notes/active .workflow/agent-notes/completed .workflow/evidence
cp <gentic-workflow-path>/config/project-config.example.json .workflow/project-config.json
# Edit with your repo's details (test commands, coverage thresholds, etc.)

# Add to .gitignore
echo ".workflow/" >> .gitignore
```

### 5. Install skills

Symlink the included skills into your agent's skill directory:

```bash
# Linux/macOS:
mkdir -p ~/.claude/skills
ln -s ~/.claude/workflow/skills/initialize-workflow ~/.claude/skills/initialize-workflow
ln -s ~/.claude/workflow/skills/using-workflow ~/.claude/skills/using-workflow

# Windows:
mkdir "%USERPROFILE%\.claude\skills" 2>nul
mklink /J "%USERPROFILE%\.claude\skills\initialize-workflow" "%USERPROFILE%\.claude\workflow\skills\initialize-workflow"
mklink /J "%USERPROFILE%\.claude\skills\using-workflow" "%USERPROFILE%\.claude\workflow\skills\using-workflow"
```

### 6. (Optional) Configure skill frameworks

If you use Superpowers, OpenSpec, or another skill framework, configure the `skills` section of your `project-config.json`. See [`docs/skill-integration.md`](docs/skill-integration.md).

### 7. Start using the workflow

In any new Claude Code session, the workflow skills are now available:

- **`/initialize-workflow`** — interactive setup wizard (run once per environment or project)
- **`/using-workflow`** — session initializer that loads board context and determines your role

Or start the orchestrator manually:
```
Read and follow: <gentic-workflow-root>/agents/board-orchestrator.md
Board config: <gentic-workflow-root>/config/board-config.json
Adapter commands: <gentic-workflow-root>/adapters/<adapter>/commands.md
```

## Directory Structure

```
gentic-workflow/
├── README.md                          ← This file
├── LICENSE                            ← MIT License
├── .gitignore
├── agents/
│   ├── board-orchestrator.md          ← Polls and dispatches
│   ├── refine-agent.md                ← Spec + plan
│   ├── implement-agent.md             ← TDD implementation
│   ├── test-agent.md                  ← AC validation
│   └── review-agent.md               ← Code review + PR/MR
├── protocols/
│   ├── notes-protocol.md              ← How agents log work
│   ├── comment-protocol.md            ← How agents communicate on stories
│   └── handoff-protocol.md            ← Status transitions, circular flow, recovery
├── adapters/
│   └── github-projects/
│       ├── README.md                  ← Setup instructions
│       └── commands.md                ← Operation → gh CLI command mappings
├── config/
│   ├── board-config.example.json      ← Template for your board's field IDs
│   ├── project-config.example.json    ← Template for per-repo config
│   └── orchestrator-state.example.json ← Template for orchestrator runtime state
├── skills/
│   ├── initialize-workflow/
│   │   └── SKILL.md                   ← Setup wizard for first-time configuration
│   └── using-workflow/
│       └── SKILL.md                   ← Session initializer — loads context for orchestration
└── docs/
    ├── adapter-interface.md           ← Abstract operations all adapters must implement
    ├── agent-runtime.md               ← Runtime requirements + Claude Code reference
    ├── skill-integration.md           ← How to plug in Superpowers, OpenSpec, etc.
    └── circular-flow.md               ← How push-backs work between agents
```

## Key Concepts

### Circular Flow
Agents don't just move forward. Any agent can push a story back to a previous state with clear comments about what needs fixing. The receiving agent addresses only the flagged issues, not all work. See [`docs/circular-flow.md`](docs/circular-flow.md).

### Agent Notes
Every agent writes timestamped notes to `<notes_directory>/agent-notes/active/`. These provide continuity if an agent crashes and an audit trail for humans. See [`protocols/notes-protocol.md`](protocols/notes-protocol.md).

### Liveness Monitoring
The orchestrator checks that active agents are producing meaningful artifacts (commits, test results, spec files) — not just writing notes.

### Error Budget
Each story gets 1 automatic retry. After that, it's blocked for human intervention. This prevents infinite loops.

### Story Comments
Agents communicate via structured comments on work items — start, completion, blockers, and push-backs all follow a standard format. See [`protocols/comment-protocol.md`](protocols/comment-protocol.md).

### Conventional Commits
All agents follow the [Conventional Commits](https://www.conventionalcommits.org/) standard:
- `feat:` new functionality
- `fix:` bug fixes
- `test:` test additions
- `refactor:` code improvements

This is a core part of the framework, not configurable — consistent commit messages make audit trails readable and enable automated changelogs.

## Adapters

The framework is board-agnostic. Adapters map abstract operations (set status, post comment, create PR/MR) to platform-specific commands. See [`docs/adapter-interface.md`](docs/adapter-interface.md) for the full interface specification.

**Included:**
- **GitHub Projects V2** — via `gh` CLI

**Planned / Community:**
- **GitLab Boards** — via `glab` CLI
- **Linear** — via Linear API
- **Jira** — via Jira API
- **Trello** — via Trello API
- **Azure DevOps** — via `az boards` CLI
- **Bitbucket** — via Bitbucket API

To add a new adapter, create `adapters/<platform>/` implementing every operation in the adapter interface. See existing adapters for reference.

## Agent Runtimes

The workflow is designed for AI coding agents that can read/write files, execute shell commands, and spawn sub-agents. See [`docs/agent-runtime.md`](docs/agent-runtime.md) for the full requirements specification.

**Tested with:**
- **Claude Code** — full support (sub-agents, messaging, liveness)

**Adaptable to:**
- Cursor, Windsurf, and other IDE agents
- Aider
- Custom frameworks (LangChain, CrewAI, AutoGen)

## Skill Frameworks

The workflow works standalone, but you can plug in skill frameworks for enhanced discipline during specific phases. See [`docs/skill-integration.md`](docs/skill-integration.md).

**Supported:**
- **Superpowers** — TDD enforcement, brainstorming, verification
- **OpenSpec** — structured change management
- **Custom skills** — any invocable instruction set

## Contributing

Contributions welcome! Areas that would be especially valuable:
- **New adapters** — GitLab, Linear, Jira, Bitbucket, Azure DevOps
- **Setup automation** — scripts to create board fields and generate config
- **Agent runtime guides** — integration docs for Cursor, Aider, etc.
- **Skill integrations** — documentation for additional skill frameworks

## License

MIT — see [LICENSE](LICENSE).
