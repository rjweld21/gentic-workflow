# Circular Flow

Agents don't just move stories forward. Any agent can push a story back to a previous state when it finds issues that a prior agent needs to address.

## Push-Back Rules

```
Review Agent ──► In Progress    (code issues found)
Test Agent   ──► In Progress    (AC failures)
Implement Agent ──► Refinement  (spec gaps found)
```

## When to Push Back

- **Test Agent:** An acceptance criterion fails. The test agent documents what failed and what was expected. The implement agent picks it up and fixes only the flagged issues.
- **Review Agent:** Code doesn't meet quality standards or deviates from spec. The review agent lists findings with severity. The implement agent fixes blocking findings.
- **Implement Agent:** The spec has gaps or contradictions that block implementation. The refine agent re-examines and clarifies.

## Push-Back Comment Format

```markdown
### Push-Back: [Agent Role] → [Previous State]

**Reason:** [Why this needs to go back]

**Issues Found:**
1. **[Issue Title]** — [Description of problem]
   - Expected: [what should happen]
   - Actual: [what happens now]
   - Suggested fix: [if obvious]

2. **[Issue Title]** — ...

**What's Already Done:** [List completed work that should NOT be redone]

**Action Needed:** [Specific items the receiving agent must address]
```

## Receiving Agent Behavior

When an agent picks up a pushed-back story:
1. Read the push-back comment FIRST
2. Address ONLY the flagged issues
3. Do NOT redo work that was already completed
4. Comment when done: "Addressed feedback from [agent]: [summary]"
5. Re-transition to the next state

## Avoiding Loops

If a story bounces between states more than twice for the same issue:
1. The orchestrator detects this via retry count
2. Story is set to Blocked
3. Human reviews to break the deadlock
