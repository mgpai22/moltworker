# Bitwarden Skill

A skill for securely managing passwords and credentials using the Bitwarden CLI.

## Prerequisites

- Bitwarden account (free or premium)
- Bitwarden CLI installed (`bw` command available)

## Quick Start

1. **Login**: `bw login`
2. **Unlock**: `bw unlock` (save the session key)
3. **Export session**: `export BW_SESSION="<session_key>"`
4. **Use scripts**: `./scripts/list-items.sh`

## API Key Authentication (Recommended)

For automation and scripting, use API key authentication:

1. Get your API key from Bitwarden web vault → Account Settings → Security → Keys
2. Set environment variables:
   ```bash
   export BW_CLIENTID="your_client_id"
   export BW_CLIENTSECRET="your_client_secret"
   ```
3. Login: `bw login --apikey`

## Self-Hosted Bitwarden

For self-hosted instances:

```bash
bw config server https://your-bitwarden-instance.com
bw login
```

## Security Notes

- Session keys are sensitive - don't log or expose them
- Use `bw lock` when done to destroy the session
- Consider using environment variables or secure secret storage for API keys
- The `export` command can export your entire vault - use with caution

## Documentation

- [Bitwarden CLI Documentation](https://bitwarden.com/help/cli/)
- [Bitwarden CLI Source](https://github.com/bitwarden/clients/tree/main/apps/cli)
