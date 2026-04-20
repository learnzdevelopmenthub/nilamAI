# NilamAI (நிலம்AI)

Tamil agricultural advisory app for smallholder farmers in Tamil Nadu. STT
runs on-device (Whisper); the LLM runs as Gemma 4 hosted on DeepInfra via its
OpenAI-compatible chat-completions endpoint (the bundled 2.58 GB on-device
Gemma 4 E2B OOM-killed 4 GB RAM devices).
Full spec: [docs/srs_1.0.md](docs/srs_1.0.md).

## Prerequisites

- Flutter 3.24+ / Dart SDK ^3.10.4
- `curl` or `wget` (macOS/Linux) or PowerShell (Windows) for the Whisper model fetch
- A DeepInfra API key — https://deepinfra.com/dash/api_keys

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

Create your `.env` file from the template and fill in your DeepInfra key:

```bash
cp .env.example .env
# then edit .env and set DEEPINFRA_API_KEY=<your-key>
```

`.env` is gitignored — never commit real keys. Run the app:

```bash
flutter run
```

For release builds that shouldn't ship a `.env` (e.g. CI), pass the key at
build time instead:

```bash
flutter build apk --release --dart-define=DEEPINFRA_API_KEY=<your-key>
```

`LlmConstants.deepInfraApiKey` reads `.env` first, then falls back to the
`--dart-define` value.

## Testing

```bash
flutter analyze
flutter test
flutter test --coverage
```
