# Skill Integration

The Gentic Workflow is the core orchestration layer — it handles board polling, agent dispatching, handoffs, and recovery. **Skills** are optional, pluggable enhancements that agents can use during their specific phase to improve the quality of their work.

## How Skills Plug In

Each phase of the workflow has a skill slot in `project-config.json`:

```json
{
  "skills": {
    "refinement": ["superpowers:brainstorming"],
    "implementation": ["superpowers:test-driven-development"],
    "testing": ["superpowers:verification-before-completion"],
    "review": ["superpowers:requesting-code-review"]
  }
}
```

When an agent starts its phase, it checks the corresponding skill slot. If skills are listed, the agent invokes them as part of its workflow. If the slot is empty, the agent follows its built-in instructions.

## Supported Skill Frameworks

Skills can come from any framework. The only requirement is that the agent runtime can invoke them. Common frameworks:

### Superpowers (Claude Code)

A collection of development discipline skills. Install via the Claude Code plugin system.

| Phase | Skill | What It Does |
|---|---|---|
| Refinement | `superpowers:brainstorming` | Structured design exploration with user approval gates |
| Implementation | `superpowers:test-driven-development` | Enforces RED-GREEN-REFACTOR discipline |
| Implementation | `superpowers:executing-plans` | Batch execution of plan tasks with verification |
| Testing | `superpowers:verification-before-completion` | Prevents false success claims — evidence before assertions |
| Review | `superpowers:requesting-code-review` | Dispatches a code-reviewer subagent with structured criteria |

To use: set `skills.<phase>` to the skill names above. The agent will invoke them using the `Skill` tool.

### OpenSpec

A structured change management workflow. Install via CLI (`openspec`).

| Phase | Skill | What It Does |
|---|---|---|
| Refinement | `openspec:explore` | Thinking partner for exploring ideas and clarifying requirements |
| Refinement | `openspec:propose` | Generates design, specs, and tasks in one step |
| Implementation | `openspec:apply` | Implements tasks from an OpenSpec change |

To use: set `skills.<phase>` to the skill names above. Requires the `openspec` CLI to be installed.

### Custom Skills

You can create your own skills — they just need to be invocable by the agent runtime. A skill can be:
- A markdown file with instructions the agent reads and follows
- A CLI command the agent executes
- A framework-specific skill (e.g., Cursor rules, Aider conventions)

To reference a custom skill, use the path or name that the agent runtime understands:
```json
{
  "skills": {
    "refinement": ["/path/to/my-refinement-skill.md"],
    "implementation": ["my-tdd-approach"]
  }
}
```

## No Skills? No Problem

The workflow works without any skills configured. Each agent has built-in instructions for its phase:
- **Refine agent:** explores context, writes spec and plan, updates story
- **Implement agent:** TDD with RED-GREEN-REFACTOR, commits per task
- **Test agent:** validates each AC with evidence
- **Review agent:** reviews code against spec, creates PR/MR

Skills enhance these built-in behaviors — they don't replace them. Think of skills as methodology add-ons that enforce additional discipline or provide specialized tooling.

## When to Use Skills vs. Built-In

| Situation | Recommendation |
|---|---|
| Solo developer, small project | Built-in is sufficient |
| Team with established methodology | Configure skills matching your methodology |
| High-stakes production code | Use Superpowers TDD + verification for maximum discipline |
| Rapid prototyping | Skip skills, use built-in for speed |
| Complex design decisions | Use brainstorming/explore skills for refinement phase |
