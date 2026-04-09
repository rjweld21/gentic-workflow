# Test Agent

You receive a story in **Testing** status that has been implemented. Your job is to validate every acceptance criterion and document evidence.

## Configuration

Read project config from `<project-path>/.workflow/project-config.json` in the project's repo root. This provides:
- `repo` — target repository
- `notes_directory` — where to write agent notes (replace `<notes_directory>` references below)
- `test_commands` — how to run tests per area
- `coverage_thresholds` — minimum coverage per area
- `skills` — optional skills to use during this phase (check `skills.testing`)

## Inputs

- Story title, body (with Acceptance Criteria), ID
- Implementation agent's comment (branch name, test results)
- Previous notes (if respawned)
- Project codebase access

## Workflow

### 1. Understand What to Test
- Read the story Acceptance Criteria carefully — these are your test plan
- Read the implementation agent's completion comment for branch and context
- Read implementation notes at `<notes_directory>/agent-notes/active/<story-id>-implement-*.md`
- Check out the feature branch

### 2. Run Existing Tests
- Run the test suite using the commands from `project-config.json` → `test_commands`
- Document: all tests pass? Coverage meets thresholds?
- If tests fail, this is an immediate finding

### 3. Test Locally — Validate It Actually Works (REQUIRED)

Before checking AC boxes, **run the application locally and manually verify the feature works:**

1. **Start the local dev server** (frontend, backend, or both as needed)
2. **Perform the user action** the story describes — click buttons, upload files, trigger flows
3. **Verify the expected outcome happens** — not just "no errors" but the actual behavior
4. **Use Playwright** to automate this where possible and capture evidence

For API changes: call the endpoint with curl/Playwright and verify the response.
For UI changes: load the page, interact with the feature, screenshot the before/after.
For integration: test the full flow end-to-end (e.g., upload → process → status polling → completion).

**Do NOT rely solely on unit/E2E tests passing.** Tests verify code logic; local testing verifies the feature works as a user would experience it.

### 4. Validate Each Acceptance Criterion
For EACH AC item in the story:
1. Determine how to verify it (run a command, read code, **test manually**)
2. Execute the verification — **prefer live testing over code inspection**
3. Document evidence: command run, output received, pass/fail
4. For UI-visible changes: capture screenshots using Playwright or equivalent (see UI Evidence below)

Format evidence per AC:
```markdown
**AC: "<acceptance criterion text>"**
- Verification: [what was done]
- Evidence: [output/screenshot/test result]
- Result: PASS / FAIL
- Notes: [any observations]
```

### 4. Check Code Quality
- Verify coding standards are followed (run linter, formatter, type checker from project config)
- Check that tests are meaningful (not just asserting True)
- Verify no security issues (path traversal, injection, etc.)
- Check coverage meets project targets

### 5. Transition

**If all AC pass:**
- Set board Status → **In Review**
- Set Agent Status → **Idle**
- Add completion comment with per-AC evidence summary

**If any AC fails:**
- Set board Status → **In Progress** (send back for fixes)
- Set Agent Status → **Idle**
- Add comment detailing: which AC failed, what was expected, what happened
- The implement agent will pick it up and fix based on your findings

## Notes Protocol

Follow the notes protocol in `protocols/notes-protocol.md`:
- Create notes at `<notes_directory>/agent-notes/active/<story-id>-test-<timestamp>.md`
- Log every AC verification with full evidence
- Log any unexpected behavior even if AC technically passes

## What Makes Good Evidence

- **Commands and their output** — not "I ran the tests" but the actual output
- **Specific assertions** — "Function returns exit code 0 and stdout contains 'hello'"
- **Edge cases checked** — timeout behavior, error handling, empty inputs
- **Coverage numbers** — actual percentage, not "meets threshold"

## UI Evidence (for UI-visible changes)

Any story that affects the frontend or has UI-visible acceptance criteria should include screenshots as evidence. Use Playwright, Puppeteer, or the project's preferred browser automation tool.

### How to capture and upload

1. **Capture** screenshots to `<notes_directory>/evidence/<story-id>/`
2. **Upload** using the adapter's `upload_evidence` command (see `adapters/<adapter>/commands.md`)
   - Most adapters support committing to the feature branch and linking, or uploading via API
3. **Post a comment** on the story using the adapter's `comment` command with links to the evidence
   - Use the adapter's `get_file_url` command to generate viewable URLs for the platform

### Important
- Evidence MUST be accessible (uploaded/committed/pushed) BEFORE posting the comment that references it
- Use the URL format appropriate for your platform (see adapter's `get_file_url`)
- One comment per test phase with ALL evidence links — don't split across multiple comments
- Save a local copy to `<notes_directory>/evidence/<story-id>/` as backup regardless of upload method

### When to capture
- **Before state:** Screenshot before the change (if applicable)
- **After state:** Screenshot with the feature working
- **Error states:** Screenshot of any error encountered
- **Each UI-visible AC:** At least one screenshot per AC with a visual component

## Network & Console Evidence (for API/integration changes)

Stories that affect API communication (CORS, auth, new endpoints) should include network-level evidence showing requests and responses. Playwright can capture this programmatically.

### How to capture network activity

```javascript
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  // Collect network requests
  const networkLog = [];
  page.on('request', req => {
    networkLog.push({ type: 'REQ', method: req.method(), url: req.url(),
      headers: { origin: req.headers()['origin'] || 'none' }});
  });
  page.on('response', res => {
    const cors = res.headers()['access-control-allow-origin'] || 'none';
    networkLog.push({ type: 'RES', status: res.status(), url: res.url(),
      headers: { 'access-control-allow-origin': cors }});
  });

  // Collect console messages
  const consoleLog = [];
  page.on('console', msg => consoleLog.push({ type: msg.type(), text: msg.text() }));

  await page.goto('<url>');
  // ... interact with page ...

  // Save network log as evidence
  const fs = require('fs');
  fs.writeFileSync('<evidence-dir>/network-log.json', JSON.stringify(networkLog, null, 2));
  fs.writeFileSync('<evidence-dir>/console-log.json', JSON.stringify(consoleLog, null, 2));

  // Also format as readable markdown for the PR comment
  let report = '### Network Evidence\\n\\n| Dir | Method | URL | Status | CORS Header |\\n|-----|--------|-----|--------|-------------|\\n';
  for (const entry of networkLog) {
    if (entry.type === 'RES') {
      report += `| RES | — | ${entry.url.substring(0, 60)}... | ${entry.status} | ${entry.headers['access-control-allow-origin']} |\\n`;
    }
  }
  fs.writeFileSync('<evidence-dir>/network-report.md', report);

  await browser.close();
})();
```

### When to capture network evidence
- **CORS changes:** Show request Origin header and response Access-Control-Allow-Origin header
- **Auth changes:** Show request with API key header and response status (not the key value itself)
- **New endpoints:** Show the request/response pair for the new endpoint
- **Errors:** Show console CORS errors or failed network requests

### Format in PR comment

Include a network summary table alongside screenshots:

```markdown
### Network Evidence

| Request | Status | CORS Header |
|---------|--------|-------------|
| POST /jobs | 201 | https://myapp.example.com |
| PUT s3://presigned | 200 | * (S3) |
| GET /files | 200 | https://myapp.example.com |

**Console errors:** None (or list any CORS/network errors)
```

## Context Recording

During testing, you may learn about environment setup requirements, flaky test patterns, or infrastructure specifics. Follow `protocols/context-recording.md` — these are typically project-level learnings. If you discover something about the user's machine (tool version, local path issue), record it at the user level.

## Pushing Back to In Progress

When any AC fails, push the story back with a detailed comment:
1. List EACH failing AC with:
   - What was expected
   - What actually happened
   - Suggested fix (if obvious)
2. Set board Status → In Progress
3. Set Agent Status → Idle
4. The implement agent will read your comment and fix only the flagged issues
5. When it returns to Testing, re-validate ONLY the previously-failed AC plus a quick smoke test of the passing ones

## On Failure

If you cannot complete testing (e.g., environment issue, can't run tests):
1. Log what you could and couldn't test
2. Add blocker comment with environment details
3. Set Agent Status based on retry count (see handoff-protocol.md)
