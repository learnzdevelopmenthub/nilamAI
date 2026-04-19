#!/usr/bin/env bash
# Fetches the Whisper ggml-base-q8_0 model for NilamAI.
# Run once after cloning: bash scripts/fetch_model.sh
# Model: ~82 MB INT8-quantized base Whisper. Required for Phase 4 STT.

set -euo pipefail

MODEL_URL='https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base-q8_0.bin'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="$REPO_ROOT/assets/models"
TARGET_FILE="$TARGET_DIR/ggml-base-q8_0.bin"

mkdir -p "$TARGET_DIR"

if [ -f "$TARGET_FILE" ] && [ "$(stat -c%s "$TARGET_FILE" 2>/dev/null || stat -f%z "$TARGET_FILE")" -gt 1000000 ]; then
    echo "Model already present at $TARGET_FILE"
    exit 0
fi

echo "Downloading ggml-base-q8_0.bin from Huggingface..."
if command -v curl >/dev/null; then
    curl -L -o "$TARGET_FILE" "$MODEL_URL"
elif command -v wget >/dev/null; then
    wget -O "$TARGET_FILE" "$MODEL_URL"
else
    echo "Neither curl nor wget found — install one and retry." >&2
    exit 1
fi

echo "Downloaded to $TARGET_FILE"
