#!/usr/bin/env bash
# Fetches the Gemma 4 E2B INT4 model (.litertlm, ~1.3 GB) for NilamAI.
# Run once after cloning: bash scripts/fetch_gemma_model.sh
# Required for Phase 6 on-device LLM inference.
#
# NOTE: The exact HuggingFace revision is not yet pinned in SRS §8. The
# checkpoint below is the reference `litert-community/gemma-4-E2B-it-litert-lm`
# repo; confirm availability and swap in the pinned revision before release.
# See: docs/srs_1.0.md §8 (Model Strategy) and GitHub issue #6.

set -euo pipefail

MODEL_URL='https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma_4_e2b_int4.litertlm'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="$REPO_ROOT/assets/models"
TARGET_FILE="$TARGET_DIR/gemma_4_e2b_int4.litertlm"
MIN_BYTES=$((1024 * 1024 * 1024)) # 1 GB sanity threshold

mkdir -p "$TARGET_DIR"

if [ -f "$TARGET_FILE" ]; then
    existing_size="$(stat -c%s "$TARGET_FILE" 2>/dev/null || stat -f%z "$TARGET_FILE")"
    if [ "$existing_size" -gt "$MIN_BYTES" ]; then
        echo "Gemma model already present at $TARGET_FILE ($((existing_size / 1024 / 1024)) MB)"
        exit 0
    fi
fi

echo "Downloading gemma_4_e2b_int4.litertlm (~1.3 GB) from Huggingface..."
echo "  URL: $MODEL_URL"
echo "  If this fails, the checkpoint may have moved — see docs/srs_1.0.md §8."
if command -v curl >/dev/null; then
    curl -L -o "$TARGET_FILE" "$MODEL_URL"
elif command -v wget >/dev/null; then
    wget -O "$TARGET_FILE" "$MODEL_URL"
else
    echo "Neither curl nor wget found — install one and retry." >&2
    exit 1
fi

downloaded_size="$(stat -c%s "$TARGET_FILE" 2>/dev/null || stat -f%z "$TARGET_FILE")"
echo "Downloaded $((downloaded_size / 1024 / 1024)) MB to $TARGET_FILE"
