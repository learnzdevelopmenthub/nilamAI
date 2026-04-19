#!/usr/bin/env pwsh
# Fetches the Gemma 4 E2B model (.litertlm, ~2.6 GB) for NilamAI.
# Run once after cloning: pwsh scripts/fetch_gemma_model.ps1
# Required for Phase 6 on-device LLM inference.
#
# Pinned to HuggingFace revision 2a101e0 (2026-04-07) of
# litert-community/gemma-4-E2B-it-litert-lm. Bumping the pin is a conscious
# change — update $modelUrl and $expectedSha256 together.

$ErrorActionPreference = 'Stop'
$modelUrl = 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/2a101e00c47f942975ce8b493c2498311ed9900d/gemma-4-E2B-it.litertlm'
$expectedSha256 = 'ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$targetDir = Join-Path $repoRoot 'assets\models'
$targetFile = Join-Path $targetDir 'gemma-4-E2B-it.litertlm'
$minBytes = 1GB

if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir | Out-Null
}

if ((Test-Path $targetFile) -and (Get-Item $targetFile).Length -gt $minBytes) {
    $existingMb = '{0:N0}' -f ((Get-Item $targetFile).Length / 1MB)
    Write-Host "Gemma model already present at $targetFile ($existingMb MB)"
    exit 0
}

Write-Host "Downloading gemma-4-E2B-it.litertlm (~2.6 GB) from Huggingface..."
Write-Host "  URL: $modelUrl"
Invoke-WebRequest -Uri $modelUrl -OutFile $targetFile

$downloadedBytes = (Get-Item $targetFile).Length
if ($downloadedBytes -lt $minBytes) {
    Remove-Item $targetFile
    throw "Download too small ($('{0:N0}' -f ($downloadedBytes / 1MB)) MB) — likely a 404 HTML page."
}

$actual = (Get-FileHash -Algorithm SHA256 -Path $targetFile).Hash.ToLower()
if ($actual -ne $expectedSha256.ToLower()) {
    Remove-Item $targetFile
    throw "SHA256 mismatch for $targetFile`n  expected: $expectedSha256`n  actual:   $actual"
}

$sizeMb = '{0:N0}' -f ($downloadedBytes / 1MB)
Write-Host "Downloaded $sizeMb MB to $targetFile"
