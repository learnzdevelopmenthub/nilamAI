#!/usr/bin/env bash
# Fetches the Gemma 4 E2B model (.litertlm, ~2.6 GB) for NilamAI.
# Run once after cloning: bash scripts/fetch_gemma_model.sh
# Required for Phase 6 on-device LLM inference.
#
# Pinned to HuggingFace revision 2a101e0 (2026-04-07) of
# litert-community/gemma-4-E2B-it-litert-lm. Bumping the pin is a conscious
# change — update MODEL_URL and EXPECTED_SHA256 together.

set -euo pipefail

MODEL_URL='https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/2a101e00c47f942975ce8b493c2498311ed9900d/gemma-4-E2B-it.litertlm'
EXPECTED_SHA256='ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="$REPO_ROOT/assets/models"
TARGET_FILE="$TARGET_DIR/gemma-4-E2B-it.litertlm"
MIN_BYTES=$((1024 * 1024 * 1024)) # 1 GB sanity threshold

mkdir -p "$TARGET_DIR"

if [ -f "$TARGET_FILE" ]; then
    existing_size="$(stat -c%s "$TARGET_FILE" 2>/dev/null || stat -f%z "$TARGET_FILE")"
    if [ "$existing_size" -gt "$MIN_BYTES" ]; then
        echo "Gemma model already present at $TARGET_FILE ($((existing_size / 1024 / 1024)) MB)"
        exit 0
    fi
fi

echo "Downloading gemma-4-E2B-it.litertlm (~2.6 GB) from Huggingface..."
echo "  URL: $MODEL_URL"
if command -v curl >/dev/null; then
    curl -L -o "$TARGET_FILE" "$MODEL_URL"
elif command -v wget >/dev/null; then
    wget -O "$TARGET_FILE" "$MODEL_URL"
else
    echo "Neither curl nor wget found — install one and retry." >&2
    exit 1
fi

downloaded_size="$(stat -c%s "$TARGET_FILE" 2>/dev/null || stat -f%z "$TARGET_FILE")"
if [ "$downloaded_size" -lt "$MIN_BYTES" ]; then
    echo "ERROR: download too small ($((downloaded_size / 1024 / 1024)) MB) — likely a 404 HTML page." >&2
    rm -f "$TARGET_FILE"
    exit 1
fi

if command -v sha256sum >/dev/null; then
    actual="$(sha256sum "$TARGET_FILE" | awk '{print $1}')"
elif command -v shasum >/dev/null; then
    actual="$(shasum -a 256 "$TARGET_FILE" | awk '{print $1}')"
else
    echo "No sha256sum or shasum available — skipping integrity check." >&2
    actual=""
fi
if [ -n "$actual" ] && [ "$actual" != "$EXPECTED_SHA256" ]; then
    echo "ERROR: SHA256 mismatch for $TARGET_FILE" >&2
    echo "  expected: $EXPECTED_SHA256" >&2
    echo "  actual:   $actual" >&2
    rm -f "$TARGET_FILE"
    exit 1
fi

echo "Downloaded $((downloaded_size / 1024 / 1024)) MB to $TARGET_FILE"
