# Agent Runtime Requirements

The Gentic Workflow is designed to be runtime-agnostic. Any agent system that supports the capabilities below can run this workflow. This document defines the abstract requirements and provides Claude Code as a reference implementation.

## Required Capabilities

### 1. File Operations
Agents must be able to read and write files in the project repository and the notes directory.

| Capability | Used For |
|---|---|
| Read file | Reading specs, plans, notes, project config, code |
| Write file | Creating specs, plans, notes, evidence |
| List/search files | Exploring codebase, finding existing patterns |

### 2. Shell Command Execution
Agents must execute CLI commands for git operations, test running, linting, and board adapter commands.

| Capability | Used For |
|---|---|
| Run command | `git`, `gh`/`glab`/etc., test runners, linters, formatters |
| Read output | Parsing test results, coverage numbers, command output |
| Check exit code | Determining pass/fail for tests and builds |

### 3. Sub-Agent Spawning
The orchestrator must be able to spawn independent worker agents that run in isolation and return results.

| Capability | Used For |
|---|---|
| Spawn agent | Orchestrator dispatching workers for each story stage |
| Pass context | Providing story details, notes paths, config to workers |
| Receive result | Knowing when a worker has completed or failed |

### 4. Agent Messaging (Optional but Recommended)
For liveness monitoring, the orchestrator should be able to send messages to running agents.

| Capability | Used For |
|---|---|
| Send message | Orchestrator nudging agents for status updates |
| Check reachable | Determining if a worker agent is still alive |

Without messaging support, the orchestrator falls back to notes-based liveness checks only (checking file timestamps).

## Reference Implementation: Claude Code

Claude Code supports all required capabilities natively:

| Capability | Claude Code Implementation |
|---|---|
| Read file | `Read` tool |
| Write file | `Write` / `Edit` tools |
| List/search files | `Glob` / `Grep` tools |
| Run command | `Bash` tool |
| Spawn agent | `Agent` tool with prompt containing role instructions |
| Pass context | Agent prompt includes story details, config paths, notes |
| Receive result | Agent tool returns when sub-agent completes |
| Send message | `SendMessage` to agent by ID |

### Orchestrator Spawning Example (Claude Code)

```
Agent tool:
  prompt: |
    You are a REFINE WORKER. You handle ONE stage of ONE story, then exit.

    Story: "Add user authentication"
    Issue: myorg/myrepo#42
    Board Item ID: PVTI_xxx
    Project Path: /home/user/projects/myapp

    Read and follow: ~/.claude/workflow/agents/refine-agent.md
    Read protocols: ~/.claude/workflow/protocols/
    Read adapter commands: ~/.claude/workflow/adapters/github-projects/commands.md

    Board config: ~/.claude/workflow/config/board-config.json
    Project config: /home/user/projects/myapp/.workflow/project-config.json
```

### Liveness Check Example (Claude Code)

```
SendMessage:
  to: <agent-id>
  message: "Status check — please log your progress and any artifacts produced"
```

## Other Runtimes

The workflow can be adapted to other agent systems. Key considerations:

### Cursor / Windsurf / IDE Agents
- File and shell operations: native
- Sub-agent spawning: limited — may need to run workers sequentially rather than in parallel
- Messaging: not available — use notes-based liveness only
- Adaptation: run the orchestrator as a recurring task, workers as sequential steps

### Aider
- File and shell operations: native
- Sub-agent spawning: not native — use shell scripts to invoke aider per stage
- Messaging: not available
- Adaptation: orchestrator could be a shell script that calls aider per story stage

### Custom Agent Frameworks (LangChain, CrewAI, AutoGen)
- All capabilities available via framework primitives
- Map the agent prompts to framework-specific agent definitions
- The markdown agent files become system prompts or instruction sets

## Minimum Viable Runtime

At minimum, you need:
1. **File read/write** — for notes, specs, plans, config
2. **Shell execution** — for git, tests, adapter CLI commands
3. **Sequential execution** — run one agent at a time per story stage

Parallel workers, messaging, and liveness monitoring are enhancements that improve throughput and reliability but aren't strictly required to run the workflow.
