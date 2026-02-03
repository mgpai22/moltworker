---
slug: summarize
name: Summarize
description: Summarize URLs, YouTube videos, podcasts, PDFs, and media files using AI
version: 1.0.0
enabled: true
tools:
  - name: summarize
    description: "Summarize a URL, YouTube video, podcast, or file"
    script: scripts/summarize.sh
  - name: summarize-url
    description: "Summarize a web page URL"
    script: scripts/url.sh
  - name: summarize-youtube
    description: "Summarize a YouTube video with transcript"
    script: scripts/youtube.sh
  - name: summarize-podcast
    description: "Summarize a podcast episode (RSS feed, Apple Podcasts, Spotify)"
    script: scripts/podcast.sh
  - name: summarize-pdf
    description: "Summarize a PDF document"
    script: scripts/pdf.sh
  - name: summarize-media
    description: "Summarize audio/video file via transcription"
    script: scripts/media.sh
  - name: summarize-extract
    description: "Extract content from URL without summarizing"
    script: scripts/extract.sh
  - name: summarize-slides
    description: "Extract slides from YouTube video with timestamps"
    script: scripts/slides.sh
  - name: summarize-json
    description: "Get detailed JSON output with diagnostics and metrics"
    script: scripts/json.sh
  - name: summarize-config
    description: "View or update summarize configuration"
    script: scripts/config.sh
  - name: summarize-refresh-free
    description: "Refresh the free OpenRouter model preset"
    script: scripts/refresh-free.sh
---

# Summarize

Fast AI-powered summaries from URLs, files, and media. Supports web pages, PDFs, YouTube videos, podcasts, audio/video files, and images.

## Environment Variables

The skill uses these API keys (in order of preference):

| Variable | Description | Required |
|----------|-------------|----------|
| `ANTHROPIC_API_KEY` | Anthropic Claude models | Yes (default) |
| `OPENAI_API_KEY` | OpenAI GPT models | Optional |
| `GEMINI_API_KEY` | Google Gemini models | Optional |
| `OPENROUTER_API_KEY` | OpenRouter (includes free models) | Optional |
| `FIRECRAWL_API_KEY` | Website extraction fallback | Optional |
| `FAL_KEY` | FAL AI transcription fallback | Optional |

## Basic Usage

```bash
# Summarize any URL
summarize "https://example.com/article"

# Summarize YouTube video
summarize "https://youtu.be/dQw4w9WgXcQ"

# Summarize podcast
summarize "https://podcasts.apple.com/us/podcast/..."

# Summarize local file
summarize "/path/to/document.pdf"
```

## Models

Use `--model <provider>/<model>` to specify which model to use:

```bash
# Use Anthropic Claude (default when ANTHROPIC_API_KEY is set)
summarize "https://example.com" --model anthropic/claude-sonnet-4-5

# Use OpenAI
summarize "https://example.com" --model openai/gpt-5-mini

# Use Google Gemini
summarize "https://example.com" --model google/gemini-3-flash-preview

# Use free OpenRouter models
summarize "https://example.com" --model free

# Auto-select best available model
summarize "https://example.com" --model auto
```

## Output Length

Control summary length with `--length`:

```bash
summarize "https://example.com" --length short    # ~900 chars
summarize "https://example.com" --length medium   # ~1,800 chars (default)
summarize "https://example.com" --length long     # ~4,200 chars
summarize "https://example.com" --length xl       # ~9,000 chars
summarize "https://example.com" --length xxl      # ~17,000 chars
summarize "https://example.com" --length 5000     # Custom char count
```

## YouTube Features

```bash
# Basic YouTube summarization
summarize "https://youtu.be/VIDEO_ID"

# Extract slides/screenshots with timestamps
summarize "https://youtu.be/VIDEO_ID" --slides

# Slides with OCR text extraction
summarize "https://youtu.be/VIDEO_ID" --slides --slides-ocr

# Force specific transcript method
summarize "https://youtu.be/VIDEO_ID" --youtube auto
```

## Podcast Support

Supported podcast sources:
- RSS feeds (with Podcasting 2.0 transcript support)
- Apple Podcasts episode URLs
- Spotify episode URLs
- Amazon Music / Audible podcast pages
- Podbean, Podchaser

```bash
# Summarize podcast RSS feed (latest episode)
summarize "https://feeds.example.com/podcast.xml"

# Summarize specific Apple Podcasts episode
summarize "https://podcasts.apple.com/us/podcast/episode-title/id123?i=456"
```

## Media Transcription

Local audio/video files are automatically transcribed before summarization:

```bash
# Transcribe and summarize audio
summarize "/path/to/audio.mp3"

# Transcribe and summarize video
summarize "/path/to/video.mp4"

# Force transcript mode for direct media URLs
summarize "https://example.com/video.mp4" --video-mode transcript
```

Supported formats: MP3, WAV, M4A, OGG, FLAC, MP4, MOV, WEBM

## Extract Mode

Get raw content without summarization:

```bash
# Extract content as text
summarize "https://example.com" --extract

# Extract as markdown
summarize "https://example.com" --extract --format md

# Extract YouTube transcript
summarize "https://youtu.be/VIDEO_ID" --extract
```

## JSON Output

Get structured output with diagnostics:

```bash
summarize "https://example.com" --json
```

Returns: summary, metrics, timing, cost estimates, and diagnostic info.

## Translation

Translate output to a specific language:

```bash
# Summarize in Spanish
summarize "https://example.com" --lang es

# Summarize in Japanese
summarize "https://example.com" --lang ja

# Auto-detect and match source language
summarize "https://example.com" --lang auto
```

## Configuration

Config file location: `~/.summarize/config.json`

```bash
# View current config
cat ~/.summarize/config.json

# Set default model
summarize config --set model=anthropic/claude-sonnet-4-5

# Set default theme
summarize config --set theme=ember
```

## Free Model Preset

Use OpenRouter's free models (requires `OPENROUTER_API_KEY`):

```bash
# Use free preset
summarize "https://example.com" --model free

# Refresh free model list (tests and ranks available free models)
summarize refresh-free

# Set free as default
summarize refresh-free --set-default
```

## Tips

1. **Short content**: If content is shorter than requested length, it returns as-is. Use `--force-summary` to override.

2. **Large files**: Text inputs over 10MB are rejected. PDFs work best with Google models.

3. **Blocked sites**: Use `--firecrawl always` for sites that block direct fetch (requires `FIRECRAWL_API_KEY`).

4. **Streaming**: Output streams in real-time by default. Use `--stream off` to disable.

5. **Caching**: Results are cached. Use `--no-cache` to force fresh summarization.
