---
slug: bird
name: Bird
description: Fast X/Twitter CLI for reading tweets, search, bookmarks, news, and more via GraphQL API.
homepage: https://github.com/steipete/bird
---

# Bird Skill

Fast X/Twitter CLI for reading tweets, searching, fetching bookmarks, news, trending topics, and user timelines using the [Bird CLI](https://github.com/steipete/bird). Uses X/Twitter's GraphQL API with cookie-based authentication.

## Setup

Bird requires two cookies from an authenticated X/Twitter session: `auth_token` and `ct0`.

### Getting Your Credentials

1. **Open X.com** in your browser and log in
2. **Open Developer Tools** (F12 or right-click → Inspect)
3. **Go to Application tab** → Storage → Cookies → `https://x.com`
4. **Copy these cookie values**:
   - `auth_token` - Your session authentication token
   - `ct0` - CSRF protection token

### Setting Environment Variables

```bash
export AUTH_TOKEN="your_auth_token_value"
export CT0="your_ct0_value"
```

Alternative environment variable names:
- `TWITTER_AUTH_TOKEN` / `TWITTER_CT0`

## Available Scripts

### Reading Tweets
- `read.sh <tweet-url|id>` - Read a single tweet
- `thread.sh <tweet-url|id>` - Get full thread/conversation
- `replies.sh <tweet-url|id> [--max-pages n]` - List replies to a tweet

### Search
- `search.sh "<query>" [-n count]` - Search for tweets
- `mentions.sh [-n count] [--user @handle]` - Find mentions of a user

### User Content
- `user-tweets.sh <@handle> [-n count]` - Get tweets from a user's timeline
- `following.sh [-n count] [--user id]` - List who you/user follows
- `followers.sh [-n count] [--user id]` - List followers
- `about.sh <@handle>` - Get account origin info

### Bookmarks & Likes
- `bookmarks.sh [-n count] [--folder-id id]` - List your bookmarks
- `unbookmark.sh <tweet-url|id>` - Remove a bookmark
- `likes.sh [-n count]` - List your liked tweets

### News & Trending
- `news.sh [-n count] [--ai-only] [--sports] [--entertainment]` - Fetch news/trending
- `trending.sh` - Alias for news

### Lists
- `lists.sh` - List your Twitter lists
- `list-timeline.sh <list-id|url> [-n count]` - Get tweets from a list

### Account
- `whoami.sh` - Show logged-in account info
- `check.sh` - Verify credentials are working

## Examples

### Read a tweet
```bash
./scripts/read.sh https://x.com/elonmusk/status/1234567890
./scripts/read.sh 1234567890 --json
```

### Search tweets
```bash
./scripts/search.sh "from:steipete" -n 10
./scripts/search.sh "AI news" -n 20 --json
```

### Get user's recent tweets
```bash
./scripts/user-tweets.sh @steipete -n 20
./scripts/user-tweets.sh @elonmusk -n 50 --json
```

### Get AI-curated news
```bash
./scripts/news.sh --ai-only -n 15
./scripts/news.sh --sports --entertainment -n 10
```

### Get bookmarks
```bash
./scripts/bookmarks.sh -n 10
./scripts/bookmarks.sh --all --json
```

### Get thread with replies
```bash
./scripts/thread.sh https://x.com/user/status/123 --max-pages 3
./scripts/replies.sh 123456789 --max-pages 2 --json
```

## Output Formats

Most commands support:
- Default: Human-readable text output
- `--json`: Structured JSON output
- `--json-full`: Full API response (includes raw data)
- `--plain`: Stable output without emoji/colors (for scripts)

### JSON Tweet Schema

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Tweet ID |
| `text` | string | Full tweet text |
| `author` | object | `{ username, name }` |
| `createdAt` | string | Timestamp |
| `replyCount` | number | Number of replies |
| `retweetCount` | number | Number of retweets |
| `likeCount` | number | Number of likes |
| `conversationId` | string | Thread conversation ID |
| `quotedTweet` | object? | Embedded quote tweet |

## Environment Variables

| Variable | Description |
|----------|-------------|
| `AUTH_TOKEN` | X/Twitter auth_token cookie value |
| `CT0` | X/Twitter ct0 cookie value |
| `TWITTER_AUTH_TOKEN` | Alternative for AUTH_TOKEN |
| `TWITTER_CT0` | Alternative for CT0 |
| `BIRD_TIMEOUT_MS` | Request timeout (default: 20000) |
| `BIRD_QUOTE_DEPTH` | Max quoted tweet depth (default: 1) |

## Important Notes

- **Read-only recommended**: The author strongly advises against using Bird to post tweets as X actively blocks automated posting. Use Bird primarily for reading.
- **Rate limits**: X may rate limit requests (HTTP 429). Add delays between bulk operations.
- **Cookie expiry**: Cookies may expire. Re-extract from browser if auth fails.
- **Query IDs**: X rotates GraphQL query IDs. Bird auto-recovers, but run `bird query-ids --fresh` if you encounter errors.
