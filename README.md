# NilamAI (நிலம்AI)

Offline-first Tamil agricultural advisory app for smallholder farmers in Tamil Nadu.
See [docs/srs_1.0.md](docs/srs_1.0.md) for the canonical spec.

## Prerequisites

- Flutter 3.24+ / Dart SDK ^3.10.4
- `curl` or `wget` (for fetch scripts on macOS/Linux), PowerShell on Windows
- ~3 GB of free disk space for bundled models

## First-time setup

The app ships two on-device models that are **not** committed to git:

- `ggml-base-q8_0.bin` (~75 MB) — Whisper Tamil STT (Phase 4)
- `gemma_4_e2b_int4.litertlm` (~1.3 GB) — Gemma 4 E2B INT4 LLM (Phase 6)

Fetch both once after cloning, before running `flutter run`:

```bash
# macOS / Linux
bash scripts/fetch_model.sh
bash scripts/fetch_gemma_model.sh

# Windows (PowerShell)
pwsh scripts/fetch_model.ps1
pwsh scripts/fetch_gemma_model.ps1
```

Then:

```bash
flutter pub get
flutter run
```

## Testing

```bash
flutter analyze
flutter test
flutter test --coverage
```
