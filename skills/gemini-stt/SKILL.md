---
slug: gemini-stt
name: Gemini Speech-to-Text
description: Transcribe audio files to text using the Gemini API.
homepage: https://ai.google.dev/gemini-api/docs/audio
---

# Gemini Speech-to-Text Skill

Transcribe audio files to text using Gemini audio understanding models via the Gemini API.

## Setup

1. Create a Gemini API key in AI Studio: https://aistudio.google.com/app/apikey
2. Set the secret:

```bash
npx wrangler secret put GEMINI_API_KEY
```

## Available Scripts

### `transcribe.sh <audio-file> [--model <model>] [--prompt "..."] [--json]`

Transcribe a local audio file. Uses `GEMINI_API_KEY` for authentication.

#### Examples

```bash
# Basic transcription
./scripts/transcribe.sh ./samples/interview.mp3

# Use a specific model
./scripts/transcribe.sh ./samples/meeting.wav --model gemini-2.5-flash

# Custom prompt (e.g., include speaker labels)
./scripts/transcribe.sh ./samples/podcast.m4a --prompt "Transcribe with speaker labels."

# Full JSON response
./scripts/transcribe.sh ./samples/lecture.mp4 --json
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GEMINI_API_KEY` | Yes | Gemini API key for `generativelanguage.googleapis.com` |

## Notes

- Gemini API audio understanding is not real-time; for real-time transcription use the Gemini Live API or Google Cloud Speech-to-Text.
- Use an audio-capable Gemini model (for example, `gemini-2.5-flash`).
