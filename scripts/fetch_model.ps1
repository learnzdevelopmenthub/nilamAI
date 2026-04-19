#!/usr/bin/env pwsh
# Fetches the Whisper ggml-base-q8_0 model for NilamAI.
# Run once after cloning: pwsh scripts/fetch_model.ps1
# Model: ~82 MB INT8-quantized base Whisper. Required for Phase 4 STT.

$ErrorActionPreference = 'Stop'
$modelUrl = 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base-q8_0.bin'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$targetDir = Join-Path $repoRoot 'assets\models'
$targetFile = Join-Path $targetDir 'ggml-base-q8_0.bin'

if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir | Out-Null
}

if ((Test-Path $targetFile) -and (Get-Item $targetFile).Length -gt 1MB) {
    Write-Host "Model already present at $targetFile ($('{0:N1}' -f ((Get-Item $targetFile).Length/1MB)) MB)"
    exit 0
}

Write-Host "Downloading ggml-base-q8_0.bin from Huggingface..."
Invoke-WebRequest -Uri $modelUrl -OutFile $targetFile
$sizeMb = '{0:N1}' -f ((Get-Item $targetFile).Length/1MB)
Write-Host "Downloaded $sizeMb MB to $targetFile"
