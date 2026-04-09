# Context Recording Protocol

## Purpose

As agents work, they learn things — about the org, the project, or the user's preferences. This protocol defines how to classify and record new knowledge so future sessions benefit.

## When to Record

Record a new learning when you discover something that:
- Would save time if a future agent already knew it
- Isn't already documented in the existing context files
- Isn't ephemeral (e.g., "build is currently failing" is notes-level, not context-level)

**Do NOT record:**
- Things already in the context files (check first)
- Temporary states (test is flaky right now, deploy is in progress)
- Anything that belongs in agent notes instead (current task progress)

## How to Classify

| If the learning applies to... | Layer | Write to... |
|---|---|---|
| All teams and projects in the org | **Organization** | `context/org/conventions.md` |
| How the org's board/adapter is configured | **Organization** | `context/org/org-config.json` (if config change) |
| This specific project's code, tools, or patterns | **Project** | `context/project/<name>/learnings.md` |
| This project's architecture decisions | **Project** | `context/project/<name>/architecture.md` |
| The user's preferences or style | **User** | `context/user/local.md` |
| Machine-specific setup details | **User** | `context/user/local.md` |
| Credentials, tokens, API keys | **User** | `context/user/credentials.json` |

**When in doubt:** use the most specific layer. It's better to record at the project level than the org level unless you're certain it's org-wide.

## How to Record

### For markdown files (conventions.md, learnings.md, local.md)

Append a new entry with a date header:

```markdown
### YYYY-MM-DD — <Brief descriptive title>
<What was learned, why it matters, and how to apply it in future sessions>
```

**Rules:**
- Read the file first to check for duplicates
- Append at the end, don't modify existing entries
- Keep entries concise — 1-3 sentences
- Include the "why" and "how to apply", not just the "what"
- If an existing entry is outdated, add a new entry noting the change rather than editing the old one

### For JSON config files

Only update if you discover a config value is wrong or missing. For example:
- A test command that needs a special flag
- A coverage threshold that was agreed upon
- A project path that the user mentioned

**Rules:**
- Read the file first
- Only update fields that are empty or clearly wrong
- Never overwrite values the user explicitly set
- For credentials.json, never log the values you're writing

## Examples

### Org-level learning
```markdown
### 2026-04-08 — CI requires signed commits
All repos in the org enforce commit signing via branch protection rules.
Agents must not use --no-gpg-sign when committing. If signing fails, ask the user to configure their GPG key.
```

### Project-level learning
```markdown
### 2026-04-08 — Backend tests require Redis
The backend test suite connects to Redis on localhost:6379. If Redis isn't running, tests hang for 30 seconds then fail with ConnectionRefusedError. Start Redis before running pytest.
```

### User-level learning
```markdown
### 2026-04-08 — User prefers detailed PR descriptions
When creating PRs, include full AC checklist with evidence links inline. User reviews PRs on mobile and wants all context visible without clicking through.
```

## What NOT to Record as Context

| This... | Goes in... | Not in context because... |
|---|---|---|
| Current task progress | Agent notes | Ephemeral — only relevant to this session |
| Bug you're currently fixing | Agent notes / story comment | Will be resolved soon |
| Test output | Agent notes / story comment | Too verbose for context |
| Code snippets | Agent notes / story comment | Code changes, context should be principles |
| Story-specific decisions | Story comments | Scoped to one story |

## Never Edit Base Framework Files

Context goes in `context/` layers only. Never edit:
- `agents/*.md`
- `protocols/*.md`
- `adapters/**/*.md`
- `docs/*.md` (except `context-layers.md` which is also base)

These are the upstream open-source framework. If you're in a fork that has diverged, the fork owner may have different rules — but by default, treat all non-context files as read-only.
