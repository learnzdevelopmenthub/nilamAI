# NilamAI (நிலம்AI)

Tamil agricultural advisory app for smallholder farmers in Tamil Nadu. STT
runs on-device (Whisper); the LLM currently runs via the Google Gemini API
(the bundled 2.58 GB on-device Gemma 4 E2B OOM-killed 4 GB RAM devices — see
[Phase 7 plan](C:/Users/email/.claude/plans/create-complete-implemenaion-plan-glowing-crown.md)).
Full spec: [docs/srs_1.0.md](docs/srs_1.0.md).

## Prerequisites

- Flutter 3.24+ / Dart SDK ^3.10.4
- `curl` or `wget` (macOS/Linux) or PowerShell (Windows) for the Whisper model fetch
- A Google Gemini API key — free tier from https://aistudio.google.com/apikey

## First-time setup

Fetch the on-device Whisper STT model (not committed to git):

```bash
# macOS / Linux
bash scripts/fetch_model.sh

# Windows (PowerShell)
pwsh scripts/fetch_model.ps1
```

Install Flutter deps:

```bash
flutter pub get
```

Create your `.env` file from the template and fill in your Gemini key:

```bash
cp .env.example .env
# then edit .env and set GEMINI_API_KEY=<your-key>
```

`.env` is gitignored — never commit real keys. Run the app:

```bash
flutter run
```

For release builds that shouldn't ship a `.env` (e.g. CI), pass the key at
build time instead:

```bash
flutter build apk --release --dart-define=GEMINI_API_KEY=<your-key>
```

`LlmConstants.geminiApiKey` reads `.env` first, then falls back to the
`--dart-define` value.

## Testing

```bash
flutter analyze
flutter test
flutter test --coverage
```
