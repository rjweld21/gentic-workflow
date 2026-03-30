# GitHub Projects — Adapter Commands

Implementation of the [abstract adapter interface](../../docs/adapter-interface.md) using the `gh` CLI for GitHub Projects V2.

Replace `<placeholders>` with values from your `board-config.json`.

---

## Board Operations

### list_items

```bash
gh project item-list <project-num> --owner <owner> --format json
```

**Placeholders:** `<project-num>` → `board-config.json` → `project_number`, `<owner>` → `owner`

### get_item

```bash
gh project item-list <project-num> --owner <owner> --format json \
  --jq '.items[] | select(.title=="<title>")'
```

### update_field

```bash
# Set any single-select field (status, agent status, priority, etc.)
gh project item-edit --project-id <project-id> --id <item-id> \
  --field-id <field-id> --single-select-option-id <option-id>
```

**Placeholders:** `<project-id>` → `board-config.json` → `project_id`, field/option IDs from `fields` section

### create_story

```bash
# Create issue in the issue repo
gh issue create -R <issue-repo> --title "<title>" --body "<body>"

# Add it to the project board
gh project item-add <project-num> --owner <owner> --url <issue-url>
```

**Placeholders:** `<issue-repo>` → `board-config.json` → `issue_repo`

### convert_draft

GitHub Projects V2 supports "draft" items that aren't yet full issues. Convert them before moving to Ready:

```bash
gh project item-edit --project-id <project-id> --id <item-id> \
  --convert-to-issue <repo-id>
```

**Placeholders:** `<repo-id>` → `board-config.json` → `issue_repo_id`

---

## Work Item Operations

### comment

```bash
gh issue comment <issue-number> -R <issue-repo> --body "<comment>"
```

For draft items that haven't been converted to issues yet, append to the item body instead (drafts don't support comments).

### update_description

```bash
gh issue edit <issue-number> -R <issue-repo> --body "<new-body>"
```

### get_comments

```bash
gh issue view <issue-number> -R <issue-repo> --comments --json comments
```

### close_work_item

```bash
gh issue close <issue-number> -R <issue-repo> -c "Done — merged via PR #<pr-number>"
```

### reopen_work_item

```bash
gh issue reopen <issue-number> -R <issue-repo> -c "Reopened — <reason>"
```

---

## Code Operations

### create_pr

```bash
gh pr create --repo <code-repo> --head <branch> --base <default-branch> \
  --title "<title>" --body "<body>"
```

**Placeholders:** `<code-repo>` → `project-config.json` → `repo`, `<default-branch>` → `default_branch`

### get_pr_status

```bash
gh pr view <branch> --repo <code-repo> --json state,url
```

### check_ci

```bash
# Check CI status on a PR (returns pass/fail/pending per check)
gh pr checks <pr-number> --repo <code-repo>

# Or by branch name
gh pr checks <branch> --repo <code-repo>
```

Poll until all checks complete. A non-zero exit code means checks failed or are still pending.

---

## Evidence Operations

### upload_evidence

Option 1 — Commit to feature branch and link:
```bash
git add <screenshot-path>
git commit -m "test: add evidence screenshot"
git push
```

Option 2 — Upload via GitHub's issue attachment API:
```bash
curl -s -X POST \
  -H "Authorization: token $(gh auth token)" \
  -H "Accept: application/json" \
  -F "file=@<screenshot-path>" \
  "https://uploads.github.com/repos/<issue-repo>/issues/<issue-number>/assets"
```

### get_file_url

For **private repos** (viewable when logged in):
```
https://github.com/<owner>/<repo>/blob/<branch>/<path>
```

For **public repos** (inline rendering in markdown):
```
https://raw.githubusercontent.com/<owner>/<repo>/<branch>/<path>
```

---

## Notes

- **Issue repo vs code repo:** GitHub Projects allows a separate private repo for issue tracking (`issue_repo` in board-config) while code lives in a public repo (`repo` in project-config). This keeps backlogs private. If you don't need this separation, use the same repo for both.
- **Drafts:** GitHub Projects V2 has "draft" items that are lightweight notes on the board but don't support comments or PR linking. The refine agent must convert drafts to issues before moving to Ready. Other platforms may not have this concept.
