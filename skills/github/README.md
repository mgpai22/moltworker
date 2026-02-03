# GitHub Skill

Interact with GitHub using the gh CLI for issues, PRs, CI runs, and API queries.

## Prerequisites

- GitHub account
- Personal Access Token with appropriate scopes

## Quick Start

1. **Create a token** at https://github.com/settings/tokens
2. **Set the secret**:
   ```bash
   npx wrangler secret put GH_TOKEN
   ```
3. **Deploy** and start using:
   ```bash
   ./scripts/issue-list.sh owner/repo
   ./scripts/pr-list.sh owner/repo
   ```

## Common Commands

```bash
# Issues
./scripts/issue-list.sh owner/repo
./scripts/issue-create.sh "Title" "Body" owner/repo

# Pull Requests
./scripts/pr-list.sh owner/repo
./scripts/pr-view.sh 123 owner/repo
./scripts/pr-checks.sh 123 owner/repo

# CI/CD
./scripts/run-list.sh owner/repo
./scripts/workflow-run.sh deploy.yml owner/repo

# API
./scripts/api.sh /repos/owner/repo
./scripts/search-repos.sh "language:python stars:>100"
```

## Documentation

- [GitHub CLI Manual](https://cli.github.com/manual/)
- [GitHub REST API](https://docs.github.com/en/rest)
- [GitHub GraphQL API](https://docs.github.com/en/graphql)
