---
slug: github
name: GitHub
description: Interact with GitHub using the gh CLI for issues, PRs, CI runs, and API queries.
homepage: https://cli.github.com
---

# GitHub Skill

Interact with GitHub using the [GitHub CLI (gh)](https://cli.github.com). Manage issues, pull requests, CI/CD runs, releases, and more.

## Setup

### Get a Personal Access Token

1. Go to [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens)
2. Click **Generate new token (classic)** or use **Fine-grained tokens**
3. Select scopes based on what you need:
   - `repo` - Full control of private repositories
   - `read:org` - Read org membership
   - `workflow` - Update GitHub Actions workflows
   - `gist` - Create gists
4. Copy the token

### Set the Environment Variable

```bash
# Via wrangler secret (for production)
npx wrangler secret put GH_TOKEN

# Or export locally for testing
export GH_TOKEN="ghp_xxxxxxxxxxxx"
```

## Available Scripts

### Issues

| Script | Description |
|--------|-------------|
| `issue-list.sh [repo]` | List issues in a repository |
| `issue-view.sh <number> [repo]` | View issue details |
| `issue-create.sh <title> [body] [repo]` | Create a new issue |
| `issue-close.sh <number> [repo]` | Close an issue |
| `issue-comment.sh <number> <body> [repo]` | Add comment to issue |

### Pull Requests

| Script | Description |
|--------|-------------|
| `pr-list.sh [repo]` | List pull requests |
| `pr-view.sh <number> [repo]` | View PR details |
| `pr-create.sh <title> [body] [repo]` | Create a pull request |
| `pr-merge.sh <number> [repo]` | Merge a pull request |
| `pr-checkout.sh <number> [repo]` | Checkout a PR locally |
| `pr-diff.sh <number> [repo]` | View PR diff |
| `pr-checks.sh <number> [repo]` | View PR check status |
| `pr-review.sh <number> <action> [body] [repo]` | Review a PR (approve/comment/request-changes) |

### Repositories

| Script | Description |
|--------|-------------|
| `repo-view.sh [repo]` | View repository details |
| `repo-clone.sh <repo> [dir]` | Clone a repository |
| `repo-list.sh [owner]` | List repositories |
| `repo-create.sh <name> [--public\|--private]` | Create a new repository |

### Workflow Runs (CI/CD)

| Script | Description |
|--------|-------------|
| `run-list.sh [repo]` | List workflow runs |
| `run-view.sh <run-id> [repo]` | View run details |
| `run-watch.sh <run-id> [repo]` | Watch a run in progress |
| `run-rerun.sh <run-id> [repo]` | Re-run a workflow |
| `workflow-list.sh [repo]` | List workflows |
| `workflow-run.sh <workflow> [repo]` | Trigger a workflow |

### Releases

| Script | Description |
|--------|-------------|
| `release-list.sh [repo]` | List releases |
| `release-view.sh <tag> [repo]` | View release details |
| `release-create.sh <tag> [--title] [--notes] [repo]` | Create a release |

### API

| Script | Description |
|--------|-------------|
| `api.sh <endpoint> [method] [body]` | Make raw API calls |
| `graphql.sh <query>` | Execute GraphQL queries |

### Gists

| Script | Description |
|--------|-------------|
| `gist-list.sh` | List your gists |
| `gist-create.sh <file> [--public]` | Create a gist |
| `gist-view.sh <id>` | View a gist |

### Search

| Script | Description |
|--------|-------------|
| `search-repos.sh <query>` | Search repositories |
| `search-issues.sh <query>` | Search issues |
| `search-prs.sh <query>` | Search pull requests |
| `search-code.sh <query>` | Search code |

## Examples

### List open issues
```bash
./scripts/issue-list.sh owner/repo
./scripts/issue-list.sh owner/repo --state closed --limit 10
```

### Create an issue
```bash
./scripts/issue-create.sh "Bug: Login fails" "Steps to reproduce..." owner/repo
```

### View PR details with diff
```bash
./scripts/pr-view.sh 123 owner/repo
./scripts/pr-diff.sh 123 owner/repo
```

### Check CI status
```bash
./scripts/pr-checks.sh 123 owner/repo
./scripts/run-list.sh owner/repo --limit 5
```

### Make API calls
```bash
# GET request
./scripts/api.sh /repos/owner/repo

# POST request
./scripts/api.sh /repos/owner/repo/issues POST '{"title":"New issue"}'

# GraphQL
./scripts/graphql.sh 'query { viewer { login } }'
```

### Search
```bash
./scripts/search-repos.sh "language:rust stars:>1000"
./scripts/search-issues.sh "is:open label:bug repo:owner/repo"
./scripts/search-code.sh "filename:package.json express"
```

### Trigger workflow
```bash
./scripts/workflow-run.sh deploy.yml owner/repo
./scripts/workflow-run.sh ci.yml owner/repo --ref feature-branch
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `GH_TOKEN` | GitHub personal access token (required) |
| `GH_HOST` | GitHub Enterprise hostname (optional) |
| `GH_REPO` | Default repository in `owner/repo` format (optional) |

## Tips

### Default Repository

Many commands accept an optional `[repo]` argument. If omitted, they use:
1. `GH_REPO` environment variable (if set)
2. Current git repository (if in a git directory)

### JSON Output

Most commands support `--json` for structured output:
```bash
./scripts/issue-list.sh owner/repo --json number,title,state
./scripts/pr-list.sh owner/repo --json number,title,mergeable
```

### Filtering

Use flags to filter results:
```bash
./scripts/issue-list.sh owner/repo --state open --label bug --assignee @me
./scripts/pr-list.sh owner/repo --state merged --base main
```

## Token Scopes

| Scope | Required For |
|-------|-------------|
| `repo` | Private repos, issues, PRs |
| `public_repo` | Public repos only |
| `read:org` | Org membership queries |
| `workflow` | Trigger/manage workflows |
| `gist` | Create/manage gists |
| `delete_repo` | Delete repositories |

## Rate Limits

GitHub API has rate limits:
- **Authenticated**: 5,000 requests/hour
- **Search API**: 30 requests/minute

Check your rate limit:
```bash
./scripts/api.sh /rate_limit
```
