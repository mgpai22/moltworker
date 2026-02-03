# Bird Skill

A skill for reading tweets, searching X/Twitter, fetching bookmarks, news, and user timelines using the Bird CLI.

## Prerequisites

- Node.js 22+ or Bun
- Bird CLI installed (`npx @steipete/bird` or `bun x @steipete/bird`)
- X/Twitter account credentials (cookies)

## Quick Start

1. **Get your credentials** from X.com:
   - Log into x.com in your browser
   - Open DevTools (F12) → Application → Cookies → x.com
   - Copy `auth_token` and `ct0` values

2. **Set environment variables**:
   ```bash
   export AUTH_TOKEN="your_auth_token_here"
   export CT0="your_ct0_here"
   ```

3. **Verify setup**:
   ```bash
   ./scripts/whoami.sh
   ```

## Common Commands

```bash
# Read a tweet
./scripts/read.sh https://x.com/user/status/1234567890

# Search tweets
./scripts/search.sh "AI news" -n 10

# Get user's tweets
./scripts/user-tweets.sh @username -n 20

# Get trending/news
./scripts/news.sh --ai-only -n 15

# Get your bookmarks
./scripts/bookmarks.sh -n 10
```

## Security Notes

- Your `auth_token` and `ct0` cookies are sensitive - never commit them
- Cookies provide full access to your X/Twitter account
- Use environment variables, not hardcoded values
- Cookie sessions can expire - re-extract from browser if needed

## Documentation

- [Bird CLI on GitHub](https://github.com/steipete/bird)
- [Bird CLI Documentation](https://bird.steipete.me/)
