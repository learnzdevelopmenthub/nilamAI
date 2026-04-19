#!/usr/bin/env pwsh
# Fetches the Gemma 4 E2B INT4 model (.litertlm, ~1.3 GB) for NilamAI.
# Run once after cloning: pwsh scripts/fetch_gemma_model.ps1
# Required for Phase 6 on-device LLM inference.
#
# NOTE: The exact HuggingFace revision is not yet pinned in SRS §8. The
# checkpoint below is the reference `litert-community/gemma-4-E2B-it-litert-lm`
# repo; confirm availability and swap in the pinned revision before release.
# See: docs/srs_1.0.md §8 (Model Strategy) and GitHub issue #6.

$ErrorActionPreference = 'Stop'
$modelUrl = 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma_4_e2b_int4.litertlm'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$targetDir = Join-Path $repoRoot 'assets\models'
$targetFile = Join-Path $targetDir 'gemma_4_e2b_int4.litertlm'
$minBytes = 1GB

if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir | Out-Null
}

if ((Test-Path $targetFile) -and (Get-Item $targetFile).Length -gt $minBytes) {
    $existingMb = '{0:N0}' -f ((Get-Item $targetFile).Length / 1MB)
    Write-Host "Gemma model already present at $targetFile ($existingMb MB)"
    exit 0
}

Write-Host "Downloading gemma_4_e2b_int4.litertlm (~1.3 GB) from Huggingface..."
Write-Host "  URL: $modelUrl"
Write-Host "  If this fails, the checkpoint may have moved — see docs/srs_1.0.md §8."
Invoke-WebRequest -Uri $modelUrl -OutFile $targetFile
$sizeMb = '{0:N0}' -f ((Get-Item $targetFile).Length / 1MB)
Write-Host "Downloaded $sizeMb MB to $targetFile"
