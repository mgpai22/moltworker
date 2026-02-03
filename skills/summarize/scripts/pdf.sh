#!/bin/bash
# Summarize a PDF document
# Usage: pdf.sh <pdf_path_or_url> [options]
# Examples:
#   pdf.sh "/path/to/document.pdf"
#   pdf.sh "https://example.com/report.pdf"
#   pdf.sh "document.pdf" --model google/gemini-3-flash-preview --length long

set -e

if [ -z "$1" ]; then
    echo "Usage: pdf.sh <pdf_path_or_url> [options]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --model <provider/model>  Model to use (google/gemini recommended for PDFs)" >&2
    echo "  --length <preset>         Output length (short/medium/long/xl/xxl)" >&2
    echo "  --extract                 Extract text only, don't summarize" >&2
    echo "  --lang <code>             Output language" >&2
    exit 1
fi

INPUT="$1"
shift

# Validate PDF
if [[ ! "$INPUT" =~ \.pdf$ ]] && [[ ! "$INPUT" =~ \.pdf\? ]]; then
    echo "Warning: Input doesn't appear to be a PDF file" >&2
fi

# Google Gemini handles PDFs best
summarize "$INPUT" "$@"
