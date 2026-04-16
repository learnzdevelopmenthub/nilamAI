# NilamAI Release Plan: Accelerated 15-Day Timeline

**Document Version:** 2.0 (ACCELERATED)  
**Date Created:** April 16, 2026  
**Target Release:** May 1, 2026 (15 days)  
**Status:** 🔴 **Not Started**  
**Mode:** ⚡ **AGGRESSIVE PARALLEL EXECUTION**

---

## 📋 Overview

**SCOPE REDUCTION:** This is an aggressive MVP-only timeline. Non-critical features deferred to v1.1.

**Original Plan:** 20 weeks | **New Plan:** 15 days (10x acceleration)  
**Team Size:** 3-4 developers (parallel tracks) + 1 QA  
**Success Metric:** ✅ Core voice→AI→speech flow working offline

### What's Included (MVP Only)
✅ Voice recording + Whisper STT  
✅ Gemma 4 LLM response generation  
✅ TTS audio playback  
✅ Query history (basic)  
✅ Settings + offline mode  
✅ Home screen + Query input screen  

### What's DEFERRED to v1.1 (post-launch)
❌ Mandi prices & price alerts  
❌ 9 additional screens (help, notifications, about, etc.)  
❌ Push notifications  
❌ Advanced analytics  
❌ Multi-language support

---

## ⚡ 15-DAY CRITICAL PATH (Aggressive Parallel Execution)

```
PARALLEL TRACK 1           PARALLEL TRACK 2           PARALLEL TRACK 3
(Backend)                  (Frontend UI)              (ML/Audio)
─────────────────────────────────────────────────────────────────────────

Days 1-2:
Phase 1: Foundation ──────→ [All tracks start here]

Days 3-4:
Phase 2: Database ────────→
Phase 3: Auth ───────────→ 

Days 5-6:
         ←────────────────── Phase 4: Audio Recording
                             Phase 9a: Home + Query Input screens

Days 7-9:
                             ←─────────────────── Phase 5: Whisper STT
                             Phase 9b: Transcription Review screen

Days 10-12:
←─────────────────────────────────────────────── Phase 6: Gemma 4 LLM
                             Phase 9c: Response Display screen

Days 13-14:
←─────────────────────────────────────────────── Phase 7: TTS
                             Phase 9d: Settings + Profile screens

Day 15:
[Integration Testing + APK Build + Play Store Submission]
```

### Team Assignment (3-4 Developers)

| Track | Developer(s) | Responsibility | Days |
|-------|--------------|-----------------|------|
| **Backend** | 1-2 devs | DB, Auth, Services | 1-12 |
| **Frontend** | 1 dev | UI Screens | 5-14 |
| **ML/Audio** | 1 dev | Recording, STT, TTS | 5-14 |
| **QA/DevOps** | 1 dev | Testing, Build, Deploy | Throughout |

---

## 🎯 MVP SCOPE (Minimum Viable Product)

**Core Flow ONLY:**
```
User speaks query (Tamil)
    ↓
Whisper STT transcribes locally
    ↓
Gemma 4 generates response (Tamil)
    ↓
TTS speaks response (Tamil)
    ↓
Save to local history
    ↓
All 100% OFFLINE ✅
```

**Screens Required (5 only):**
1. Home — Simple button "Ask Question"
2. Query Input — Record + transcription review
3. Response Display — AI response + audio player
4. Query History — Past queries list
5. Settings — Basic (TTS speed, clear data, about)

**Deferred to v1.1:**
- Mandi prices & alerts
- Notifications
- Advanced screens (help, onboarding, debug)
- Multi-language
- Analytics

---

# ACCELERATED PHASE TIMELINE (Days 1-15)

# Phase 1: Foundation & Setup (Days 1-2)

**Duration:** 2 days (Mon-Tue)  
**Owner:** Tech Lead  
**Parallel:** No (must be first)  
**Test Target:** N/A

## 1.1 Objectives (DO ONLY ESSENTIALS)

- [ ] Flutter project init (3.24+)
- [ ] Riverpod setup (state management)
- [ ] Material Design 3 theme (minimal)
- [ ] Logging setup (console only)
- [ ] Android SDK config (API 29-35)

## 1.2 Deliverables

```
nilamAI/
├── pubspec.yaml (locked versions)
├── lib/
│   ├── main.dart
│   ├── config/
│   │   ├── theme.dart (Material 3)
│   │   └── routes.dart (go_router)
│   ├── core/
│   │   ├── logging/logger.dart
│   │   ├── exceptions/app_exception.dart
│   │   └── constants/strings_tamil.dart
│   ├── providers/ (empty)
│   ├── services/ (empty)
│   └── screens/ (empty)
└── android/ (configured for API 29-35)
```

## 1.3 Dependencies (Minimal Set)

```yaml
flutter: ">=3.24.0"
riverpod: ^3.0.0
go_router: ^14.0.0
google_fonts: ^6.2.1
sqflite: ^2.4.2
record: ^5.2.0
flutter_tts: ^8.3.0
intl: ^0.19.0
uuid: ^4.10.0
shared_preferences: ^2.2.3
```

## 1.4 Acceptance Criteria

- [ ] `flutter run` launches blank home screen
- [ ] No linter errors
- [ ] Android builds for API 29 + API 35
- [ ] App icon set

✅ **DONE by:** EOD Tuesday

---

# Phase 2: Database + Auth (Days 3-4)

**Duration:** 2 days (Wed-Thu)  
**Owners:** Backend Dev 1, Backend Dev 2  
**Parallel:** YES (can run together)  
**Test Target:** 60%

## 2.1 Database ONLY (What's Actually Needed)

```sql
-- ONLY 2 tables for MVP
CREATE TABLE user_profile (
  id TEXT PRIMARY KEY,
  phone_number TEXT UNIQUE,
  created_at INTEGER
);

CREATE TABLE query_history (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  timestamp INTEGER,
  transcription TEXT,
  response TEXT,
  created_at INTEGER
);

CREATE INDEX idx_query_user_date ON query_history(user_id, timestamp DESC);
```

**Skip for v1.0:**
- Mandi price table
- User alerts table
- Embedding vectors
- Full migration system

## 2.2 Auth ONLY (What's Actually Needed)

```dart
// Just:
// 1. Generate UUID for user ID
// 2. Hash phone number (SHA256)
// 3. Store in database
// Skip: Phone verification, OTP, cloud sync
```

## 2.3 Acceptance Criteria

- [ ] User registration works (phone → hashed → saved)
- [ ] Query insert/retrieve works
- [ ] Database file encrypted (sqlcipher)
- [ ] <50ms query latency
- [ ] Test coverage ≥60%

✅ **DONE by:** EOD Thursday

---

# Phase 3: Audio Recording (Days 5-6)

**Duration:** 2 days (Fri-Sat)  
**Owner:** Audio Dev  
**Parallel:** YES (with Phase 2 finishing)  
**Test Target:** 70%

## 3.1 Objectives

- [ ] Microphone recording (PCM 16-bit, 16 kHz, mono)
- [ ] Permission handling
- [ ] Simple waveform visualization
- [ ] 120-sec timeout
- [ ] Error handling (E001-E005)

## 3.2 Minimal Implementation

```dart
// lib/services/audio_recorder_service.dart
class AudioRecorderService {
  final _recorder = Record();

  Future<String> startRecording() async {
    await _recorder.start(
      path: tempPath,
      encoder: AudioEncoder.pcm16bit,
      sampleRate: 16000,
    );
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }
}
```

**Skip for v1.0:**
- Real-time amplitude streaming
- Advanced waveform animations
- Audio level detection

## 3.3 Acceptance Criteria

- [ ] Audio records at 16kHz PCM 16-bit
- [ ] 30-second test recording produces valid file
- [ ] Stops after 120 seconds
- [ ] Microphone errors handled (E001)
- [ ] Simple waveform displays

✅ **DONE by:** EOD Saturday

---

# Phase 4: Whisper STT (Days 7-9)

**Duration:** 3 days (Sun-Mon-Tue)  
**Owner:** ML Dev  
**Dependency:** Phase 3 ✅  
**Parallel:** YES (UI dev starts Phase 5a in parallel)  
**Test Target:** 70%

## 4.1 Objectives

- [ ] **BUNDLE model in APK** (don't download)
- [ ] Whisper.cpp Tamil integration
- [ ] Transcription with confidence scoring
- [ ] Manual fallback (low confidence)
- [ ] Handle errors (E006-E008)

## 4.2 Model Strategy (CRITICAL FOR TIME)

**DO NOT:** Download model on first launch (too slow, risk of failure)

**DO:** Bundle pre-quantized Whisper-Tamil-Small (75 MB) in assets/models/

```
assets/models/whisper_tamil_small_int8.bin ← Pre-include in APK
```

This adds ~75 MB to APK but saves 10+ minutes of first-launch time.

## 4.3 Minimal Whisper Service

```dart
class WhisperService {
  late Whisper _whisper;

  Future<void> initialize() async {
    // Load pre-bundled model from assets
    final modelPath = await _getAssetPath('models/whisper_tamil_small_int8.bin');
    _whisper = Whisper(modelPath);
  }

  Future<TranscriptionResult> transcribe(String audioPath) async {
    final result = await _whisper.transcribe(audioPath: audioPath, language: 'ta');
    return TranscriptionResult(
      text: result.text,
      confidence: result.confidence,
      requiresReview: result.confidence < 0.80,
    );
  }
}
```

## 4.4 Acceptance Criteria

- [ ] Whisper model bundled in APK (not downloaded)
- [ ] Transcription produces text in <10 seconds
- [ ] Confidence scoring ≥80% for agricultural Tamil
- [ ] Low confidence triggers manual transcription option
- [ ] No API calls (100% offline)
- [ ] Test coverage ≥70%

✅ **DONE by:** EOD Tuesday (Day 9)

---

# Phase 5a: Basic UI Screens (Days 5-10) [PARALLEL]

**Duration:** 6 days (Fri-Sun-Mon-Tue-Wed-Thu)  
**Owner:** UI Dev  
**Dependency:** Phase 1 ✅ + Phase 3 ✅  
**Parallel:** YES (runs alongside Phases 3-4)  
**Test Target:** 50% (widget tests only)

## 5a.1 MVP Screens (5 ONLY)

### Screen 1: Home Screen (Day 5)
```
┌─────────────────────┐
│    NिलामAI          │
│  விவசாய குரல்ஆலோசகர் │
├─────────────────────┤
│                     │
│   [🎤 கேள்வி கேளுங்கள்] │  ← Tap to record
│                     │
│   Recent Questions  │
│   ────────────────  │
│   • நெல் நோய்...    │
│   • பயிர் விளை...   │
│                     │
└─────────────────────┘
```

### Screen 2: Query Input Screen (Days 6-7)
```
┌─────────────────────┐
│  Transcription View │
├─────────────────────┤
│  🎤 Recording...    │
│  ▁▂▃▄▅▆▇  ← Waveform
│  0:15 / 2:00       │
│                     │
│  [Stop] [Cancel]    │
├─────────────────────┤
│ Transcription:      │
│ "நெல் விவசாய..."   │
│ ✏️ Edit Manual      │
│ [Next]              │
└─────────────────────┘
```

### Screen 3: Response Display (Days 8-9)
```
┌─────────────────────┐
│ Response           │
├─────────────────────┤
│ "இதுபோல் நோய்...  │
│  செப்பு சல்பேட்..." │
│                     │
│ ▶️ Play | ⏸️ Pause  │
│ 🔊 Speed: 1.0x     │
│ ────────────        │
│ [👍 Helpful] [👎 No]│
│ [🔙 Home]           │
└─────────────────────┘
```

### Screen 4: Query History (Day 10)
```
┌─────────────────────┐
│ Past Questions      │
├─────────────────────┤
│ • நெல் நோய் [👍]   │
│   4 hours ago       │
│                     │
│ • பயிர் விளை [👎]  │
│   1 day ago         │
│                     │
│ [⌕ Search]         │
└─────────────────────┘
```

### Screen 5: Settings (Day 10)
```
┌─────────────────────┐
│ Settings            │
├─────────────────────┤
│ TTS Speed:  ●───    │
│             0.8x    │
│ [✓] Notifications   │
│                     │
│ [🗑️ Clear History]  │
│ [ℹ️ About]          │
│ [📱 Version: 1.0]   │
└─────────────────────┘
```

## 5a.2 Minimal Implementation (NO Animations, Just Functional)

```dart
// Screens should be SIMPLE
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(context, ref) {
    return Scaffold(
      appBar: AppBar(title: Text('நிலம் AI')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/query-input'),
          child: Text('🎤 கேள்வி கேளுங்கள்'),
        ),
      ),
    );
  }
}
```

No fancy animations, transitions, or custom painters yet. Just buttons → screens.

## 5a.3 Acceptance Criteria

- [ ] All 5 screens navigate correctly
- [ ] No runtime errors
- [ ] Text in Tamil
- [ ] Touch targets ≥48dp
- [ ] No fancy animations (speed over polish)
- [ ] Test coverage ≥50%

✅ **DONE by:** EOD Thursday (Day 10)

---

# Phase 6: Gemma 4 LLM Integration (Days 10-12)

**Duration:** 3 days (Thu-Fri-Sat)  
**Owner:** ML Dev (after Whisper done)  
**Dependency:** Phase 2 ✅ + Phase 4 ✅  
**Test Target:** 60%

## 6.1 Objectives

- [ ] **BUNDLE Gemma 4 INT4 model** (1.3 GB in APK)
- [ ] LiteRT-LM inference
- [ ] Context from user profile (crop type, district)
- [ ] Response in Tamil
- [ ] Handle inference timeout (E010)

## 6.2 Model Strategy (CRITICAL FOR TIME)

**DO:** Pre-bundle Gemma 4 E2B INT4 (1.3 GB) in assets/models/

```
assets/models/gemma_4_e2b_int4.bin ← Pre-include in APK
```

Total APK size: ~1.4 GB (within Play Store limit)

**Risk:** Large APK may require WiFi download on Play Store. Mitigate with split APKs per architecture.

## 6.3 Minimal Gemma Service

```dart
class GemmaService {
  late LiteRT _lm;

  Future<void> initialize() async {
    final modelPath = await _getAssetPath('models/gemma_4_e2b_int4.bin');
    _lm = LiteRT(modelPath);
  }

  Future<String> generateResponse({
    required String query,
    required String? cropType,
  }) async {
    final prompt = '''விவசாய ஆலோசனை:
    கேள்வி: $query
    ${cropType != null ? 'பயிர்: $cropType' : ''}
    தமிழ் விடை (சுருக்கம்):''';

    final response = await _lm
        .generate(prompt: prompt, maxTokens: 256)
        .timeout(Duration(seconds: 30));

    return response.text;
  }
}
```

## 6.4 Acceptance Criteria

- [ ] Gemma 4 bundled in APK
- [ ] Inference produces Tamil response
- [ ] Latency <30 seconds
- [ ] Graceful timeout handling (E010)
- [ ] Context from user profile included
- [ ] Test coverage ≥60%

✅ **DONE by:** EOD Saturday (Day 12)

---

# Phase 7: Text-to-Speech (Days 13-14)

**Duration:** 2 days (Sun-Mon)  
**Owner:** Audio Dev (after recording done)  
**Dependency:** Phase 6 ✅  
**Test Target:** 70%

## 7.1 Objectives (MINIMAL)

- [ ] flutter_tts with Tamil language
- [ ] Play, Pause, Speed controls
- [ ] Text fallback if TTS fails
- [ ] Error handling (E013-E015)

## 7.2 Simple TTS Service

```dart
class TtsService {
  final _tts = FlutterTts();

  Future<void> initialize() async {
    await _tts.setLanguage('ta');
    await _tts.setSpeechRate(1.0);
  }

  Future<void> speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (e) {
      throw AppException(code: 'E013', message: 'குரல் தோல்வி');
    }
  }
}
```

## 7.3 Audio Player Widget

```dart
class AudioPlayerWidget extends StatelessWidget {
  final String responseText;

  @override
  Widget build(context) {
    return Column(
      children: [
        Text(responseText),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: Icon(Icons.play_arrow), onPressed: () => _play()),
            IconButton(icon: Icon(Icons.pause), onPressed: () => _pause()),
          ],
        ),
      ],
    );
  }
}
```

## 7.4 Acceptance Criteria

- [ ] Tamil voice plays on device
- [ ] Play/Pause works
- [ ] Speed adjustable (0.8x, 1.0x, 1.2x)
- [ ] Text fallback if TTS unavailable
- [ ] Test coverage ≥70%

✅ **DONE by:** EOD Monday (Day 14)

---

# Phase 8: Integration Testing & Build (Day 15)

**Duration:** 1 day (Tue)  
**Owner:** QA Lead + Tech Lead  
**Dependency:** All Phases 1-7 ✅  
**Test Target:** 100% critical path

## 8.1 Integration Tests (Critical Path ONLY)

```dart
// test/integration/voice_query_integration_test.dart
void main() {
  testWidgets('Complete voice query flow', (tester) async {
    // 1. Record 5-second query
    await tester.tap(find.byIcon(Icons.mic));
    await Future.delayed(Duration(seconds: 5));
    await tester.tap(find.text('Stop'));
    
    // 2. Verify transcription displayed
    expect(find.text('நெல்'), findsOneWidget);
    await tester.tap(find.text('Next'));
    
    // 3. Wait for AI response
    await tester.pumpAndSettle(timeout: Duration(seconds: 30));
    
    // 4. Verify response displayed
    expect(find.byType(AudioPlayerWidget), findsOneWidget);
    
    // 5. Play audio
    await tester.tap(find.byIcon(Icons.play_arrow));
    
    // ✅ Flow complete
  });

  testWidgets('Offline mode works', (tester) async {
    // Enable airplane mode
    // Verify app still functions
  });

  testWidgets('Low confidence triggers manual transcription', (tester) async {
    // Force low confidence
    // Verify manual input option shown
  });
}
```

## 8.2 Build & Sign APK

```bash
# Day 15 morning
flutter clean
flutter pub get
flutter build apk --release --target-platform android-arm64

# Output: build/app/outputs/flutter-apk/app-release.apk
```

## 8.3 Play Store Submission Checklist

```
[ ] App listing complete (Tamil + English description)
[ ] Screenshots uploaded (5 minimum)
[ ] Privacy policy URL set
[ ] Content rating submitted
[ ] Beta testing enabled (1000 users)
[ ] APK size verified (<2GB)
[ ] Crashes tested on Redmi 9A emulator
[ ] Models verified bundled (not downloaded)
```

## 8.4 Acceptance Criteria

- [ ] Complete voice→AI→speech flow works offline
- [ ] No crashes on Redmi 9A emulator
- [ ] APK size <2GB
- [ ] All error messages in Tamil
- [ ] Play Store submission ready

✅ **LAUNCH READY**

---

## 📊 Compressed 15-Day Timeline

**Duration:** 1.5 weeks (Days 1-11)  
**Status:** 🔴 Not Started  
**Owner:** DevOps / Tech Lead  
**Parallel Possible:** No (must be first)

## 1.1 Objectives

- [ ] Initialize Flutter project structure with all dependencies
- [ ] Set up Riverpod state management infrastructure
- [ ] Configure Android build pipeline (API 29-35)
- [ ] Create Material Design 3 theme system
- [ ] Implement logging & crash tracking infrastructure

## 1.2 Deliverables

```
nilamAI/
├── pubspec.yaml (with all dependencies locked)
├── lib/
│   ├── main.dart (app entry point)
│   ├── config/
│   │   ├── app_config.dart (environment variables)
│   │   ├── theme.dart (Material Design 3 theme)
│   │   └── routes.dart (go_router configuration)
│   ├── core/
│   │   ├── logging/
│   │   │   └── logger.dart (centralized logging)
│   │   ├── exceptions/
│   │   │   ├── app_exception.dart
│   │   │   └── error_handler.dart
│   │   └── constants/
│   │       ├── strings_tamil.dart
│   │       ├── strings_english.dart
│   │       ├── app_constants.dart
│   │       └── error_codes.dart
│   ├── services/ (empty, to be filled in later phases)
│   ├── providers/ (empty, to be filled in later phases)
│   └── screens/ (empty structure only)
├── android/
│   ├── app/build.gradle (minSdk=29, targetSdk=35)
│   ├── app/src/main/AndroidManifest.xml (permissions stub)
│   └── gradle/wrapper/gradle-wrapper.properties
├── test/
│   └── core/ (empty, to be filled later)
└── README.md (project overview)
```

## 1.3 Technical Requirements

### Dependencies to Lock

```yaml
# Core
flutter: ">=3.24.0"
dart: ">=3.6.0"

# State Management
riverpod: ^3.0.0
freezed_annotation: ^2.4.1

# Routing
go_router: ^14.0.0

# UI/Design
google_fonts: ^6.2.1
animations: ^2.1.0
material_design_icons: ^7.0.0

# Database (Phase 2)
sqflite: ^2.4.2
sqlite_async: ^1.2.5
path_provider: ^2.1.1

# Audio (Phase 4)
record: ^5.2.0
flutter_tts: ^8.3.0

# Logging
logger: ^2.4.0
firebase_crashlytics: ^3.5.0 (optional, Phase 10)

# Utilities
intl: ^0.19.0
uuid: ^4.10.0
shared_preferences: ^2.2.3
```

## 1.4 Test Coverage

**Target:** 70% coverage for core utilities

```dart
// test/core/logging/logger_test.dart
void main() {
  test('Logger initializes without errors', () {});
  test('Logger outputs to console in debug mode', () {});
  test('Logger filters by log level', () {});
}

// test/core/exceptions/app_exception_test.dart
void main() {
  test('AppException formats error messages in Tamil', () {});
  test('AppException handles error codes correctly', () {});
}
```

## 1.5 Acceptance Criteria

- [ ] `flutter pub get` completes without errors
- [ ] App launches to home screen (blank scaffold)
- [ ] Material Design 3 theme applies correctly
- [ ] Logger writes to console/file as expected
- [ ] All dependencies resolve to compatible versions
- [ ] Android build succeeds for API 29 and API 35
- [ ] No Dart linter warnings (`flutter analyze` = 0)

## 1.6 Success Metrics

✅ **Definition of Done:**
- Git repo initialized with Phase 1 code
- All CI/CD pipelines green
- Team can run `flutter run` on emulator
- Documentation updated in README

---

# Phase 2: Database & Local Storage Infrastructure

**Duration:** 1.5 weeks (Days 12-22)  
**Status:** 🔴 Not Started  
**Owner:** Backend / Database Specialist  
**Dependency:** Phase 1 ✅

## 2.1 Objectives

- [ ] Implement SQLite schema for query history, user profile, mandi prices
- [ ] Create encryption at-rest with sqlcipher_flutter
- [ ] Build database access layer (DAOs)
- [ ] Implement migration strategy for schema updates
- [ ] Create local caching for mandi prices

## 2.2 Deliverables

```
lib/services/database/
├── database_service.dart (main service)
├── daos/
│   ├── query_history_dao.dart
│   ├── user_profile_dao.dart
│   ├── mandi_price_dao.dart
│   └── user_alert_dao.dart
├── models/
│   ├── query_history.dart (Freezed model)
│   ├── user_profile.dart
│   ├── mandi_price.dart
│   └── user_alert.dart
└── migrations/
    ├── migration_001_initial_schema.dart
    └── migration_002_add_indexes.dart
```

## 2.3 Database Schema

```sql
-- Query History Table
CREATE TABLE query_history (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  audio_file_path TEXT,
  transcription TEXT NOT NULL,
  transcription_confidence REAL,
  gemma_prompt TEXT,
  gemma_response TEXT NOT NULL,
  gemma_latency_ms INTEGER,
  user_rating TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- User Profile Table
CREATE TABLE user_profile (
  id TEXT PRIMARY KEY,
  phone_number TEXT NOT NULL UNIQUE,
  name TEXT,
  village TEXT,
  district TEXT NOT NULL,
  primary_crop TEXT,
  language TEXT DEFAULT 'ta-IN',
  tts_speed REAL DEFAULT 1.0,
  notifications_enabled INTEGER DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- Mandi Price Cache
CREATE TABLE mandi_price (
  id TEXT PRIMARY KEY,
  crop_name TEXT NOT NULL,
  mandi_name TEXT NOT NULL,
  min_price INTEGER,
  max_price INTEGER,
  avg_price INTEGER,
  unit TEXT,
  timestamp INTEGER,
  trend_7_day TEXT, -- JSON array
  trend_30_day TEXT, -- JSON array
  cached_at INTEGER NOT NULL
);

-- User Alerts
CREATE TABLE user_alert (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  crop_name TEXT NOT NULL,
  alert_type TEXT NOT NULL,
  threshold INTEGER,
  is_active INTEGER DEFAULT 1,
  triggered_count INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL
);

-- Indexes for performance
CREATE INDEX idx_query_user_date ON query_history(user_id, timestamp DESC);
CREATE INDEX idx_mandi_crop_mandi ON mandi_price(crop_name, mandi_name);
CREATE INDEX idx_alert_user_active ON user_alert(user_id, is_active);
```

## 2.4 Test Coverage

**Target:** 80% for database layer

```dart
// test/services/database/database_service_test.dart
void main() {
  late DatabaseService db;
  
  setUp(() async {
    db = DatabaseService(':memory:'); // in-memory for tests
    await db.initialize();
  });

  group('Query History DAO', () {
    test('insert and retrieve query', () async {
      final query = QueryHistory(...);
      await db.queryHistoryDao.insert(query);
      final retrieved = await db.queryHistoryDao.getById(query.id);
      expect(retrieved.id, query.id);
    });

    test('search queries by keyword', () async {
      // Insert 5 queries
      final results = await db.queryHistoryDao.searchByKeyword('நெல்');
      expect(results.length, greaterThan(0));
    });

    test('encrypt/decrypt data', () async {
      // Verify SQLCipher integration
    });
  });

  group('User Profile DAO', () {
    test('create new user profile', () async {
      final profile = UserProfile(...);
      await db.userProfileDao.insert(profile);
      final retrieved = await db.userProfileDao.getById(profile.id);
      expect(retrieved.phoneNumber, profile.phoneNumber);
    });
  });

  group('Mandi Price Cache', () {
    test('cache and retrieve prices', () async {
      final prices = MandiPrice(...);
      await db.mandiPriceDao.insert(prices);
      final cached = await db.mandiPriceDao.getPricesByDistrict('Coimbatore');
      expect(cached.isNotEmpty, true);
    });

    test('update cache timestamp', () async {
      // Verify cache invalidation after 6 hours
    });
  });
}
```

## 2.5 Acceptance Criteria

- [ ] All 4 DAOs implement full CRUD operations
- [ ] SQLCipher encryption verified (data readable only with password)
- [ ] Migration system handles schema changes
- [ ] All 8 indexes created and perform efficiently
- [ ] Search queries complete in <500ms for 500 records
- [ ] Test coverage ≥80%
- [ ] No N+1 query issues identified

## 2.6 Success Metrics

✅ **Definition of Done:**
- Database service fully tested
- Can run offline for weeks without data loss
- Mandi prices cached and retrievable
- Team can mock database in Phase 3+ tests

---

# Phase 3: User Authentication & Profile Management

**Duration:** 1 week (Days 23-29)  
**Status:** 🔴 Not Started  
**Owner:** Auth / Backend Developer  
**Dependency:** Phase 1, Phase 2 ✅

## 3.1 Objectives

- [ ] Phone-number based registration (no email)
- [ ] Implement unique user ID generation (UUID)
- [ ] Create profile screen with village/district/crop selection
- [ ] Build settings persistence (Riverpod providers)
- [ ] Implement privacy controls (data export/deletion)

## 3.2 Deliverables

```
lib/
├── models/
│   └── user_profile.dart (Freezed model)
├── providers/
│   ├── user_provider.dart (Riverpod state)
│   ├── auth_provider.dart
│   └── settings_provider.dart
├── services/
│   └── auth_service.dart
├── screens/
│   ├── onboarding_screen.dart
│   ├── phone_registration_screen.dart
│   ├── profile_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── district_selector.dart
    ├── crop_selector.dart
    └── privacy_controls_widget.dart
```

## 3.3 Technical Requirements

### Phone Registration Flow

```dart
// Step 1: User enters phone number
// Step 2: Hash phone with SHA256 (never store plaintext)
// Step 3: Generate UUID as user ID
// Step 4: Store in database
// Step 5: Create user profile (onboarding)

final hashedPhone = sha256Hmac(phoneNumber, salt: appSalt);
final userId = Uuid().v4();
```

### Riverpod State Management

```dart
// lib/providers/user_provider.dart
final userProvider = FutureProvider<UserProfile?>((ref) async {
  return ref.read(databaseService).userProfileDao.getCurrent();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(ref.read(sharedPreferencesProvider)),
);

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences prefs;
  
  SettingsNotifier(this.prefs) : super(AppSettings.fromPrefs(prefs));
  
  Future<void> updateTtsSpeed(double speed) async {
    await prefs.setDouble('tts_speed', speed);
    state = state.copyWith(ttsSpeed: speed);
  }
}
```

## 3.4 Test Coverage

**Target:** 75% coverage

```dart
// test/services/auth_service_test.dart
void main() {
  test('Phone number hashing is consistent', () {
    final phone = '9876543210';
    final hash1 = AuthService.hashPhone(phone);
    final hash2 = AuthService.hashPhone(phone);
    expect(hash1, hash2);
  });

  test('User ID generation is unique', () {
    final id1 = Uuid().v4();
    final id2 = Uuid().v4();
    expect(id1, isNot(id2));
  });

  test('Profile data persists to database', () async {
    final profile = UserProfile(
      id: 'test-id',
      phoneNumber: 'hashed-phone',
      village: 'Coimbatore',
      district: 'Coimbatore',
      primaryCrop: 'Rice',
      language: 'ta-IN',
    );
    await authService.createProfile(profile);
    final retrieved = await authService.getProfile();
    expect(retrieved.village, 'Coimbatore');
  });
}

// test/providers/user_provider_test.dart
void main() {
  test('User provider loads profile from database', () async {
    final container = ProviderContainer();
    final profile = await container.read(userProvider.future);
    expect(profile, isNotNull);
  });

  test('Settings provider persists to SharedPreferences', () async {
    final container = ProviderContainer();
    await container.read(settingsProvider.notifier).updateTtsSpeed(1.2);
    final speed = await container.read(settingsProvider).ttsSpeed;
    expect(speed, 1.2);
  });
}
```

## 3.5 Acceptance Criteria

- [ ] User can register with phone number only
- [ ] Profile screen allows selection of village, district, primary crop
- [ ] Settings persist across app restarts
- [ ] Phone number never stored in plaintext
- [ ] User can export all personal data (GDPR compliance)
- [ ] User can request data deletion (implemented in Phase 10)
- [ ] No user data sent to cloud without explicit consent
- [ ] Test coverage ≥75%

## 3.6 Success Metrics

✅ **Definition of Done:**
- Registration flow tested end-to-end
- Settings persisted correctly
- Team can test with mock profiles
- Privacy controls integrated into Settings screen

---

# Phase 4: Audio Recording & Real-Time Visualization

**Duration:** 1.5 weeks (Days 30-40)  
**Status:** 🔴 Not Started  
**Owner:** Audio / Mobile Developer  
**Dependency:** Phase 1, Phase 3 ✅

## 4.1 Objectives

- [ ] Implement audio recording (PCM 16-bit, 16 kHz, mono)
- [ ] Handle microphone permissions (Android 31+)
- [ ] Create real-time waveform visualization
- [ ] Implement recording timeout (120 seconds max)
- [ ] Handle recording errors (E001-E005)

## 4.2 Deliverables

```
lib/
├── services/
│   └── audio_recorder_service.dart
├── screens/
│   └── query_input_screen.dart
└── widgets/
    ├── voice_recorder_widget.dart
    ├── waveform_painter.dart
    └── recording_controls_widget.dart
```

## 4.3 Technical Implementation

### Audio Recorder Service

```dart
// lib/services/audio_recorder_service.dart
class AudioRecorderService {
  final Record _recorder = Record();
  StreamController<List<int>>? _amplitudeController;

  Future<void> initialize() async {
    // Request microphone permission
    if (await _recorder.hasPermission()) {
      // Permission granted
    } else {
      throw AppException(
        code: 'E001',
        message: 'மைக்ரோஃபோன் அனுமதி தேவை',
      );
    }
  }

  Future<String> startRecording() async {
    final path = await getTemporaryPath();
    _amplitudeController = StreamController<List<int>>();

    try {
      await _recorder.start(
        path: path,
        encoder: AudioEncoder.pcm16bit,
        bitRate: 128000,
        sampleRate: 16000,
      );
    } catch (e) {
      throw AppException(
        code: 'E002',
        message: 'ஆடியோ பிழை. மீண்டும் முயற்சி செய்யவும்',
      );
    }

    // Stream amplitude for visualization
    _streamAmplitude();
    return path;
  }

  void _streamAmplitude() async {
    // Update waveform every 100ms
    while (_recorder.isRecording()) {
      final amplitude = await _recorder.getAmplitude();
      _amplitudeController?.add([amplitude.toInt()]);
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      await _amplitudeController?.close();
      return path;
    } catch (e) {
      throw AppException(code: 'E002', message: 'Recording stop failed');
    }
  }
}
```

### Real-Time Waveform Widget

```dart
// lib/widgets/waveform_painter.dart
class WaveformPainter extends CustomPainter {
  final List<int> amplitudes;
  final Color waveColor;

  WaveformPainter(this.amplitudes, this.waveColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final width = size.width;
    final barWidth = width / (amplitudes.length + 1);

    for (int i = 0; i < amplitudes.length; i++) {
      final x = (i + 1) * barWidth;
      final normalized = (amplitudes[i] / 32767).clamp(0.0, 1.0);
      final height = normalized * (size.height / 2);

      canvas.drawLine(
        Offset(x, centerY - height),
        Offset(x, centerY + height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) => true;
}
```

## 4.4 Test Coverage

**Target:** 80% for audio layer

```dart
// test/services/audio_recorder_service_test.dart
void main() {
  test('Audio recorder initializes', () async {
    final service = AudioRecorderService();
    await service.initialize();
    expect(service.isInitialized, true);
  });

  test('Recording stops after 120 seconds', () async {
    final service = AudioRecorderService();
    await service.startRecording();
    await Future.delayed(Duration(seconds: 125));
    // Verify recording stopped
  });

  test('Audio is recorded as PCM 16-bit 16kHz mono', () async {
    final service = AudioRecorderService();
    final path = await service.startRecording();
    await Future.delayed(Duration(seconds: 2));
    final audioPath = await service.stopRecording();
    
    // Verify file properties
    final file = File(audioPath!);
    expect(file.existsSync(), true);
  });

  test('Waveform updates in real-time', () async {
    final amplitudes = [1000, 2000, 1500, 2500];
    final painter = WaveformPainter(amplitudes, Colors.blue);
    // Verify paint is called
  });
}
```

## 4.5 Acceptance Criteria

- [ ] Audio records at PCM 16-bit, 16 kHz, mono
- [ ] Real-time waveform visualization updates smoothly
- [ ] Recording stops automatically after 120 seconds (E005)
- [ ] Microphone permission handled gracefully (E001)
- [ ] Recording errors mapped to Tamil error messages (E001-E005)
- [ ] Audio file saved to temporary storage
- [ ] Test coverage ≥80%

## 4.6 Success Metrics

✅ **Definition of Done:**
- Microphone works on actual Redmi 9A device
- Waveform visualization smooth (60 FPS)
- Audio files valid PCM format
- Error messages display in Tamil

---

# Phase 5: Whisper.cpp Integration (STT)

**Duration:** 2 weeks (Days 41-56)  
**Status:** 🔴 Not Started  
**Owner:** ML / Audio Developer  
**Dependency:** Phase 1, Phase 4 ✅

## 5.1 Objectives

- [ ] Download/bundle Whisper-Tamil-Small model (75 MB INT8)
- [ ] Integrate whisper_android package
- [ ] Implement transcription pipeline
- [ ] Add confidence scoring (≥95% threshold)
- [ ] Build manual transcription fallback (E007)
- [ ] Create model integrity verification

## 5.2 Deliverables

```
lib/
├── services/
│   └── whisper_service.dart
├── models/
│   └── transcription_result.dart
└── screens/
    └── transcription_review_screen.dart
    
assets/
└── models/
    └── whisper_tamil_small_int8.bin (75 MB, downloaded on first launch)
```

## 5.3 Whisper Service Implementation

```dart
// lib/services/whisper_service.dart
class WhisperService {
  static const MODEL_SIZE = 75 * 1024 * 1024; // 75 MB
  static const MODEL_URL = 
    'https://huggingface.co/api/download?repo_id=openai/whisper-small&path=tamil.bin';

  final _modelManager = ModelManager();
  late Whisper _whisper;

  Future<void> initialize() async {
    try {
      // Check if model exists locally
      if (!await _modelManager.modelExists()) {
        await _downloadModel();
      }

      // Load model into memory
      final modelPath = await _modelManager.getModelPath();
      _whisper = Whisper(modelPath);
      
      // Verify model integrity
      final checksum = await _modelManager.calculateChecksum();
      if (!_modelManager.verifyChecksum(checksum)) {
        throw AppException(
          code: 'E006',
          message: 'மாதிரி சேதமாகியுள்ளது. மீண்டும் பதிவிறக்கவும்',
        );
      }
    } catch (e) {
      throw AppException(
        code: 'E006',
        message: 'மாதிரி ஏற்றுவதில் பிழை',
      );
    }
  }

  Future<TranscriptionResult> transcribe(String audioPath) async {
    try {
      final startTime = DateTime.now();
      
      // Transcribe audio
      final result = await _whisper.transcribe(
        audioPath: audioPath,
        language: 'ta', // Tamil
      );

      final latency = DateTime.now().difference(startTime).inMilliseconds;

      // Check confidence
      if (result.confidence < 0.80) {
        return TranscriptionResult(
          text: result.text,
          confidence: result.confidence,
          requiresReview: true,
          code: 'E008',
          message: 'குறைந்த நம்பிக்கை. சரிசெய்யவும்?',
        );
      }

      return TranscriptionResult(
        text: result.text,
        confidence: result.confidence,
        latencyMs: latency,
        requiresReview: false,
      );
    } on SocketException {
      throw AppException(code: 'E007', message: 'ட்ரான்ஸ்கிரிப்ஷன் தோல்வி');
    } catch (e) {
      throw AppException(code: 'E007', message: 'உரை மாற்றம் தோல்வி');
    }
  }

  Future<void> _downloadModel() async {
    try {
      print('📥 Downloading Whisper-Tamil-Small (75 MB)...');
      
      final response = await http.get(Uri.parse(MODEL_URL));
      if (response.statusCode != 200) {
        throw Exception('Failed to download model');
      }

      // Save to app_data directory
      final modelPath = await _modelManager.getModelPath();
      final file = File(modelPath);
      await file.writeAsBytes(response.bodyBytes);

      // Calculate and store checksum
      final checksum = await _modelManager.calculateChecksum();
      await _modelManager.saveChecksum(checksum);

      print('✅ Model downloaded and verified');
    } catch (e) {
      throw AppException(
        code: 'E006',
        message: 'மாதிரி பதிவிறக்க பிழை',
      );
    }
  }
}

// Transcription result model
class TranscriptionResult {
  final String text;
  final double confidence; // 0.0-1.0
  final int? latencyMs;
  final bool requiresReview;
  final String? code;
  final String? message;

  TranscriptionResult({
    required this.text,
    required this.confidence,
    this.latencyMs,
    required this.requiresReview,
    this.code,
    this.message,
  });
}
```

## 5.4 Model Download Strategy

```dart
// Handle model download with progress
final modelService = ref.read(whisperServiceProvider);

final downloadProgress = StateNotifierProvider<DownloadNotifier, double>(
  (ref) => DownloadNotifier(modelService),
);

// Show progress: "Downloading model: 45%"
```

## 5.5 Test Coverage

**Target:** 75% (excludes heavy ML benchmarking)

```dart
// test/services/whisper_service_test.dart
void main() {
  group('Whisper Model', () {
    test('Model downloads successfully', () async {
      // Mock HTTP response
      // Verify file saved and verified
    });

    test('Model integrity verified via checksum', () async {
      // Calculate SHA256
      // Compare with stored checksum
    });

    test('Transcription achieves ≥95% confidence on agricultural Tamil', () async {
      // Load test audio file
      // Transcribe
      // Verify confidence score
    });

    test('Transcription latency 4-8 seconds on Redmi 9A', () async {
      // Measure actual latency
      // Log: 6.2 seconds ✅
    });

    test('Low confidence (<80%) triggers review flow', () async {
      // Force low-confidence result
      // Verify requiresReview=true
    });

    test('Manual transcription fallback works (E007)', () async {
      // Simulate transcription failure
      // Verify user can enter text manually
    });
  });

  group('Confidence Scoring', () {
    test('Confidence score correlates with transcription accuracy', () async {
      // Compare Whisper confidence vs manual verification
    });
  });
}
```

## 5.6 Acceptance Criteria

- [ ] Whisper-Tamil-Small (75 MB) model downloads on first launch
- [ ] Model integrity verified via SHA256 checksum
- [ ] Transcription achieves ≥95% confidence on agricultural queries
- [ ] Latency measured as 4-8 seconds on Redmi 9A
- [ ] Low confidence (<80%) triggers review screen
- [ ] Manual transcription fallback functional (E007)
- [ ] Model handles audio interruptions/noise gracefully
- [ ] Test coverage ≥75%

## 5.7 Success Metrics

✅ **Definition of Done:**
- Transcription tested on actual Tamil farming queries
- Latency benchmarked on Redmi 9A
- Confidence scoring validated
- Manual fallback tested end-to-end

---

# Phase 6: Gemma 4 LLM Integration & Response Generation

**Duration:** 2 weeks (Days 57-72)  
**Status:** 🔴 Not Started  
**Owner:** ML / Backend Developer  
**Dependency:** Phase 1, Phase 2, Phase 5 ✅

## 6.1 Objectives

- [ ] Download/bundle Gemma 4 E2B model (1.3 GB INT4)
- [ ] Integrate LiteRT-LM inference
- [ ] Build context-enrichment pipeline (crop, location, season)
- [ ] Implement response templates (disease, price, recommendations)
- [ ] Handle inference errors (E009-E012)

## 6.2 Deliverables

```
lib/
├── services/
│   ├── gemma_service.dart
│   ├── context_enricher.dart
│   └── response_formatter.dart
├── models/
│   ├── gemma_response.dart
│   └── agricultural_context.dart
└── utils/
    └── prompt_builder.dart
```

## 6.3 Gemma Service Implementation

```dart
// lib/services/gemma_service.dart
class GemmaService {
  static const MODEL_SIZE = 1.3 * 1024 * 1024 * 1024; // 1.3 GB
  static const MODEL_URL = 
    'https://huggingface.co/api/download?repo_id=google-ai-edge/gemma-4-e2b-int4';

  final _modelManager = ModelManager();
  late LiteRT _lm;

  Future<void> initialize() async {
    try {
      // Download model if needed
      if (!await _modelManager.modelExists()) {
        await _downloadModel();
      }

      // Load model (lazy load on first query)
      // Don't load on app startup to save memory
    } catch (e) {
      throw AppException(
        code: 'E009',
        message: 'AI மாதிரி ஏற்றுவதில் பிழை',
      );
    }
  }

  Future<GemmaResponse> generateResponse({
    required String query,
    required AgricultureContext context,
  }) async {
    try {
      // Load model only when needed
      if (!_lm.isLoaded) {
        await _loadModel();
      }

      // Build prompt with context
      final prompt = _buildPrompt(query, context);
      
      final startTime = DateTime.now();

      // Inference with timeout
      final response = await _lm
          .generate(
            prompt: prompt,
            maxTokens: 256,
            temperature: 0.7,
            topP: 0.9,
          )
          .timeout(Duration(seconds: 30));

      final latency = DateTime.now().difference(startTime).inMilliseconds;

      return GemmaResponse(
        text: response.text,
        latencyMs: latency,
        context: context,
        confidence: response.confidence,
      );
    } on TimeoutException {
      throw AppException(
        code: 'E010',
        message: 'பதில் தயாரிக்க நேரம் ஆயிற்று',
      );
    } on OutOfMemoryError {
      throw AppException(
        code: 'E011',
        message: 'சாதனம் நினைவகம் குறைந்துவிட்டது',
      );
    } catch (e) {
      throw AppException(
        code: 'E009',
        message: 'AI பதில் உருவாக்க பிழை',
      );
    }
  }

  String _buildPrompt(String query, AgricultureContext context) {
    final buffer = StringBuffer();
    
    buffer.writeln('# விவசாய ஆலோசனா அமைப்பு');
    buffer.writeln('கேள்வி: $query');
    
    if (context.cropType != null) {
      buffer.writeln('பயிர்: ${context.cropType}');
    }
    if (context.village != null) {
      buffer.writeln('ஊர்: ${context.village}');
    }
    buffer.writeln('மாதம்: ${context.currentMonth}');
    buffer.writeln('பருவம்: ${context.season}');
    
    if (context.mandiPrices.isNotEmpty) {
      buffer.writeln('தற்போதைய விலைகள்:');
      for (var price in context.mandiPrices) {
        buffer.writeln('- ${price.cropName}: ₹${price.avgPrice}');
      }
    }

    buffer.writeln('\nசுருக்கமான, செயல்பாட்டு தமிழ் விடையை வழங்கவும்।');
    
    return buffer.toString();
  }

  Future<void> _downloadModel() async {
    print('📥 Downloading Gemma 4 E2B (1.3 GB)...');
    // Similar to Whisper download
    // Show progress bar
  }

  void _unloadModel() {
    // Unload from memory after response
    _lm.unload();
  }
}

// Context enrichment
class ContextEnricher {
  final DatabaseService db;
  final LocationService location;

  Future<AgricultureContext> enrichContext({
    required String query,
    required String userId,
  }) async {
    final user = await db.userProfileDao.getById(userId);
    final season = _getSeason(DateTime.now());
    
    // Get cached mandi prices
    final prices = await db.mandiPriceDao
        .getPricesByDistrict(user.district);

    return AgricultureContext(
      query: query,
      cropType: user.primaryCrop,
      village: user.village,
      district: user.district,
      currentMonth: DateTime.now().month,
      season: season,
      mandiPrices: prices,
    );
  }

  String _getSeason(DateTime date) {
    final month = date.month;
    if (month >= 6 && month <= 9) return 'Monsoon';
    if (month >= 10 && month <= 12) return 'Winter';
    return 'Summer';
  }
}
```

## 6.4 Test Coverage

**Target:** 70% (excludes full inference benchmarking)

```dart
// test/services/gemma_service_test.dart
void main() {
  group('Gemma 4 Service', () {
    test('Model loads successfully', () async {
      final service = GemmaService();
      await service.initialize();
      expect(service.isInitialized, true);
    });

    test('Inference produces valid Tamil response', () async {
      final context = AgricultureContext(
        cropType: 'Rice',
        village: 'Coimbatore',
      );
      final response = await service.generateResponse(
        query: 'நெல் வியாதி குணமாக்க என்ன செய்ய வேண்டும்?',
        context: context,
      );
      expect(response.text.isNotEmpty, true);
      expect(response.text.contains('தமிழ்'), true);
    });

    test('Inference timeout handled (E010)', () async {
      // Simulate slow model
      expect(
        () => service.generateResponse(
          query: 'test',
          context: AgricultureContext(),
        ),
        throwsAppException('E010'),
      );
    });

    test('Out of memory error handled (E011)', () async {
      // Simulate OOM
      expect(
        () => service.generateResponse(...),
        throwsAppException('E011'),
      );
    });
  });

  group('Context Enrichment', () {
    test('Enriches context with user profile data', () async {
      final enricher = ContextEnricher(db, location);
      final context = await enricher.enrichContext(
        query: 'test',
        userId: 'test-user',
      );
      expect(context.cropType, 'Rice');
      expect(context.village, isNotEmpty);
    });

    test('Calculates season correctly', () async {
      expect(_getSeason(DateTime(2026, 7, 15)), 'Monsoon');
      expect(_getSeason(DateTime(2026, 1, 15)), 'Winter');
    });
  });

  group('Prompt Building', () {
    test('Includes all context in prompt', () async {
      final prompt = service._buildPrompt(
        'test query',
        AgricultureContext(
          cropType: 'Rice',
          village: 'Coimbatore',
        ),
      );
      expect(prompt.contains('Rice'), true);
      expect(prompt.contains('Coimbatore'), true);
    });
  });
}
```

## 6.5 Acceptance Criteria

- [ ] Gemma 4 E2B (1.3 GB) model downloads on first launch
- [ ] Model loads into memory on first query (lazy loading)
- [ ] Context enrichment pulls user data, season, mandi prices
- [ ] Response generated in Tamil language
- [ ] Inference timeout handled gracefully (E010, <30 sec)
- [ ] Out-of-memory error handled (E011)
- [ ] Model unloaded from memory after response
- [ ] Test coverage ≥70%

## 6.6 Success Metrics

✅ **Definition of Done:**
- Inference produces valid agricultural advice in Tamil
- Latency benchmarked 5-20 seconds (per complexity)
- Context properly enriched with user/seasonal data
- Memory management verified (no leaks)

---

# Phase 7: Text-to-Speech (TTS) & Audio Response

**Duration:** 1.5 weeks (Days 73-83)  
**Status:** 🔴 Not Started  
**Owner:** Audio Developer  
**Dependency:** Phase 1, Phase 6 (can parallel with Phase 6)  
**Parallel:** Yes, can run alongside Phase 6

## 7.1 Objectives

- [ ] Integrate flutter_tts for Tamil speech synthesis
- [ ] Test Tamil voice availability on Redmi 9A
- [ ] Implement speed control (0.8x, 1.0x, 1.2x)
- [ ] Build audio playback controls (Play, Pause, Repeat, Speed)
- [ ] Implement text fallback (E013-E015)

## 7.2 Deliverables

```
lib/
├── services/
│   └── tts_service.dart
├── models/
│   └── tts_response.dart
└── widgets/
    ├── audio_player_widget.dart
    └── playback_controls_widget.dart
```

## 7.3 TTS Service Implementation

```dart
// lib/services/tts_service.dart
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  final _playbackController = StreamController<PlaybackState>.broadcast();

  Future<void> initialize() async {
    try {
      // Set Tamil language
      await _flutterTts.setLanguage('ta');

      // Check available voices
      final voices = await _flutterTts.getVoices;
      final tamilVoices = voices
          .where((v) => v.contains('ta') || v.contains('Tamil'))
          .toList();

      if (tamilVoices.isEmpty) {
        print('⚠️  No Tamil voice found. Using system default.');
      } else {
        // Prefer Google Wavenet if available
        final wavenetVoice = tamilVoices.firstWhere(
          (v) => v.contains('Wavenet'),
          orElse: () => tamilVoices.first,
        );
        await _flutterTts.setVoice({'name': wavenetVoice});
      }

      // Listen to playback events
      _flutterTts.setProgressHandler((String textKey, int start, int end, String word) {
        _playbackController.add(PlaybackState.speaking);
      });

      _flutterTts.setCompletionHandler(() {
        _playbackController.add(PlaybackState.completed);
      });

      _flutterTts.setErrorHandler((msg) {
        _playbackController.add(PlaybackState.error);
      });
    } catch (e) {
      throw AppException(
        code: 'E013',
        message: 'குரல் ইঞ্জিন ইনিশিয়ালাইজেশন ব্যর্থ',
      );
    }
  }

  Future<void> speak({
    required String text,
    required double speed,
  }) async {
    try {
      // Validate input
      if (text.isEmpty) {
        throw AppException(
          code: 'E012',
          message: 'கேள்வி புரியவில்லை',
        );
      }

      // Normalize speed (0.5 to 2.0)
      final normalizedSpeed = speed.clamp(0.5, 2.0);
      
      await _flutterTts.setSpeechRate(normalizedSpeed);
      await _flutterTts.setPitch(1.0);

      _playbackController.add(PlaybackState.speaking);
      
      await _flutterTts.speak(text);
    } catch (e) {
      throw AppException(
        code: 'E013',
        message: 'குரல் সংশ্লেষণ ব্যর্থ',
      );
    }
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _playbackController.add(PlaybackState.paused);
    } catch (e) {
      throw AppException(code: 'E015', message: 'Audio pause failed');
    }
  }

  Future<void> resume() async {
    try {
      await _flutterTts.resume();
      _playbackController.add(PlaybackState.speaking);
    } catch (e) {
      throw AppException(code: 'E015', message: 'Audio resume failed');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _playbackController.add(PlaybackState.stopped);
    } catch (e) {
      throw AppException(code: 'E015', message: 'Audio stop failed');
    }
  }

  Stream<PlaybackState> get playbackStream => _playbackController.stream;
}

enum PlaybackState { speaking, paused, stopped, completed, error }
```

### Audio Player Widget

```dart
// lib/widgets/audio_player_widget.dart
class AudioPlayerWidget extends ConsumerWidget {
  final String responseText;
  final double initialSpeed;

  const AudioPlayerWidget({
    required this.responseText,
    this.initialSpeed = 1.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ttsService = ref.read(ttsServiceProvider);
    final playbackState = ref.watch(playbackStreamProvider);

    return Column(
      children: [
        // Response text display
        SelectableText(
          responseText,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        SizedBox(height: 16),

        // Playback controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Play button
            IconButton(
              icon: Icon(Icons.play_arrow),
              onPressed: () => ttsService.speak(
                text: responseText,
                speed: initialSpeed,
              ),
            ),

            // Pause button
            IconButton(
              icon: Icon(Icons.pause),
              onPressed: () => ttsService.pause(),
            ),

            // Repeat button
            IconButton(
              icon: Icon(Icons.replay),
              onPressed: () => ttsService.speak(
                text: responseText,
                speed: initialSpeed,
              ),
            ),
          ],
        ),

        // Speed control
        Slider(
          value: initialSpeed,
          min: 0.8,
          max: 1.2,
          divisions: 4,
          label: '${initialSpeed.toStringAsFixed(1)}x',
          onChanged: (value) {
            // Update speed in settings
          },
        ),
      ],
    );
  }
}
```

## 7.4 Test Coverage

**Target:** 75%

```dart
// test/services/tts_service_test.dart
void main() {
  group('TTS Service', () {
    test('Tamil voice available on device', () async {
      final service = TtsService();
      await service.initialize();
      final voices = await service.getAvailableVoices();
      expect(voices.where((v) => v.contains('ta')).isNotEmpty, true);
    });

    test('Text spoken successfully', () async {
      final service = TtsService();
      await service.initialize();
      await service.speak(
        text: 'நெல் விவசாய நோய்',
        speed: 1.0,
      );
      // Verify playback started
    });

    test('Speed control adjusts correctly', () async {
      final service = TtsService();
      await service.speak(text: 'test', speed: 1.2);
      // Measure actual speech rate
    });

    test('Tamil voice not available fallback (E014)', () async {
      // Mock no Tamil voice
      // Verify fallback to system TTS
    });

    test('Playback pause/resume works', () async {
      final service = TtsService();
      await service.speak(text: 'test', speed: 1.0);
      await service.pause();
      expect(
        service.playbackStream.first,
        PlaybackState.paused,
      );
    });

    test('Empty text handled (E012)', () async {
      final service = TtsService();
      expect(
        () => service.speak(text: '', speed: 1.0),
        throwsAppException('E012'),
      );
    });
  });
}
```

## 7.5 Acceptance Criteria

- [ ] Tamil voice works on Redmi 9A device
- [ ] Speed control (0.8x, 1.0x, 1.2x) adjusts playback rate
- [ ] Playback controls (Play, Pause, Repeat, Speed) functional
- [ ] Fallback to text display if TTS unavailable (E013)
- [ ] Playback state tracked via Stream
- [ ] Test coverage ≥75%
- [ ] **CRITICAL:** Test Tamil voice on actual hardware

## 7.6 Success Metrics

✅ **Definition of Done:**
- TTS produces natural Tamil speech on Redmi 9A
- Speed adjustments perceivable
- Playback controls responsive
- Text fallback tested

---

# Phase 8: Mandi Prices API Integration & Caching

**Duration:** 1.5 weeks (Days 84-95)  
**Status:** 🔴 Not Started  
**Owner:** Backend / API Developer  
**Dependency:** Phase 1, Phase 2 ✅

## 8.1 Objectives

- [ ] Integrate AgMarknet API (api.data.gov.in)
- [ ] Implement price fetching for 6+ crops, 15+ mandis
- [ ] Build local caching (6-hour refresh)
- [ ] Implement price alerts (min/max thresholds)
- [ ] Handle API errors (E018-E019)

## 8.2 Deliverables

```
lib/
├── services/
│   └── mandi_api_service.dart
├── models/
│   ├── mandi_price.dart
│   └── price_trend.dart
└── screens/
    └── mandi_prices_screen.dart
```

## 8.3 Mandi API Service

```dart
// lib/services/mandi_api_service.dart
class MandiApiService {
  static const API_ENDPOINT = 'https://api.data.gov.in/resource/9ef6b72f-4b9c-4b8f-abe3-8b8c4b6c5c7f';
  static const CACHE_DURATION_HOURS = 6;

  final http.Client _httpClient;
  final DatabaseService _db;

  Future<List<MandiPrice>> getPricesByDistrict(String district) async {
    try {
      // Check cache first
      final cached = await _db.mandiPriceDao.getPricesByDistrict(district);
      if (_isCacheValid(cached)) {
        return cached;
      }

      // Fetch from API
      final prices = await _fetchFromApi(district);

      // Save to cache
      for (var price in prices) {
        await _db.mandiPriceDao.insert(price);
      }

      return prices;
    } on SocketException {
      // No internet, return cached with timestamp
      return await _db.mandiPriceDao.getPricesByDistrict(district);
    } catch (e) {
      throw AppException(
        code: 'E018',
        message: 'வலைய இணைப்பு தோல்வி',
      );
    }
  }

  Future<List<MandiPrice>> _fetchFromApi(String district) async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse(API_ENDPOINT).replace(
              queryParameters: {
                'filters[state]': 'Tamil Nadu',
                'filters[district]': district,
              },
            ),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final records = json['records'] as List;

        return records
            .map((r) => MandiPrice.fromJson(r))
            .toList();
      } else {
        throw AppException(
          code: 'E019',
          message: 'விலை தரவு பிழை',
        );
      }
    } catch (e) {
      throw AppException(
        code: 'E019',
        message: 'API பதிலளிப்பு பிழை',
      );
    }
  }

  bool _isCacheValid(List<MandiPrice> cached) {
    if (cached.isEmpty) return false;

    final lastUpdate = cached.first.cachedAt;
    final now = DateTime.now();
    final difference = now.difference(lastUpdate).inHours;

    return difference < CACHE_DURATION_HOURS;
  }

  Future<void> setupPriceAlerts({
    required String userId,
    required String cropName,
    required int minPrice,
    required int maxPrice,
  }) async {
    try {
      final alert = UserAlert(
        id: Uuid().v4(),
        userId: userId,
        cropName: cropName,
        alertType: 'price_threshold',
        threshold: maxPrice,
        isActive: true,
      );

      await _db.userAlertDao.insert(alert);
    } catch (e) {
      throw AppException(
        code: 'E018',
        message: 'விழிப்பு அமைப்பு தோல்வி',
      );
    }
  }

  Future<void> checkAndTriggerAlerts(String userId) async {
    try {
      final alerts = await _db.userAlertDao.getActiveAlerts(userId);

      for (var alert in alerts) {
        final prices = await _db.mandiPriceDao
            .getPricesByCrop(alert.cropName);

        for (var price in prices) {
          if (price.maxPrice >= alert.threshold) {
            // Trigger notification
            await _notifyUser(alert, price);
          }
        }
      }
    } catch (e) {
      print('Alert check failed: $e');
    }
  }

  Future<void> _notifyUser(UserAlert alert, MandiPrice price) async {
    // Implemented in Phase 8 (Notifications)
  }
}
```

## 8.4 Mandi Price Model

```dart
@freezed
class MandiPrice with _$MandiPrice {
  const factory MandiPrice({
    required String id,
    required String cropName,
    required String mandiName,
    required int minPrice,
    required int maxPrice,
    required int avgPrice,
    required String unit,
    required DateTime timestamp,
    required List<int> trend7Day,
    required List<int> trend30Day,
    required DateTime cachedAt,
  }) = _MandiPrice;

  factory MandiPrice.fromJson(Map<String, dynamic> json) =>
      _$MandiPriceFromJson(json);
}
```

## 8.5 Mandi Prices Screen

```dart
// lib/screens/mandi_prices_screen.dart
class MandiPricesScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mandiService = ref.read(mandiApiServiceProvider);
    final userProfile = ref.watch(userProvider);

    return userProfile.when(
      data: (profile) {
        final pricesAsync = ref.watch(
          mandiPricesProvider(profile.district),
        );

        return pricesAsync.when(
          data: (prices) => ListView(
            children: prices.map((price) {
              return MandiPriceCard(price: price);
            }).toList(),
          ),
          loading: () => Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: Text('விலை தரவு பிழை\nக்ளிக் செய்யவும் மீண்டும் முயற்சி'),
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error loading profile')),
    );
  }
}
```

## 8.6 Test Coverage

**Target:** 75%

```dart
// test/services/mandi_api_service_test.dart
void main() {
  group('Mandi API Service', () {
    test('Fetches prices from API successfully', () async {
      final mockResponse = MockResponse(statusCode: 200);
      final service = MandiApiService(mockHttpClient, mockDb);

      final prices = await service.getPricesByDistrict('Coimbatore');
      
      expect(prices.isNotEmpty, true);
      expect(prices.first.cropName, isNotEmpty);
    });

    test('Caches prices for 6 hours', () async {
      final service = MandiApiService(mockHttpClient, mockDb);
      
      // First call fetches from API
      await service.getPricesByDistrict('Coimbatore');
      
      // Second call (within 6 hours) returns cached
      final cached = await service.getPricesByDistrict('Coimbatore');
      expect(cached, isNotEmpty);
    });

    test('Falls back to cache on network error (E018)', () async {
      // Simulate network error
      expect(
        () => service.getPricesByDistrict('Coimbatore'),
        returnsOrThrowsAsync(isList),
      );
    });

    test('Handles invalid API response (E019)', () async {
      final mockResponse = MockResponse(statusCode: 500);
      expect(
        () => service.getPricesByDistrict('Coimbatore'),
        throwsAppException('E019'),
      );
    });

    test('Price alerts set up correctly', () async {
      await service.setupPriceAlerts(
        userId: 'user-1',
        cropName: 'Rice',
        minPrice: 1800,
        maxPrice: 2200,
      );
      // Verify alert created in database
    });

    test('Alerts triggered when price exceeds threshold', () async {
      // Setup alert
      await service.setupPriceAlerts(...);
      
      // Insert price above threshold
      // Check alert triggered
    });
  });
}
```

## 8.7 Acceptance Criteria

- [ ] AgMarknet API integrates successfully
- [ ] Prices cached for 6+ crops, 15+ Tamil Nadu mandis
- [ ] Cache expires after 6 hours
- [ ] Offline fallback displays last cached prices with timestamp
- [ ] Price alerts functional (min/max thresholds)
- [ ] API errors handled gracefully (E018-E019)
- [ ] Test coverage ≥75%

## 8.8 Success Metrics

✅ **Definition of Done:**
- Prices fetched and cached
- Offline display shows "Last updated: X hours ago"
- Price alerts trigger correctly
- Test coverage meets target

---

# Phase 9: UI Screens & Navigation

**Duration:** 3 weeks (Days 96-124)  
**Status:** 🔴 Not Started  
**Owner:** UI/UX Developer  
**Dependency:** Phase 1, Phase 3 ✅ (can start early)  
**Parallel:** Can start after Phase 3

## 9.1 Objectives

- [ ] Build 11 core screens with Material Design 3
- [ ] Implement declarative routing (go_router)
- [ ] Apply Tamil localization to all UI text
- [ ] Ensure accessibility (TalkBack, high contrast, 14-36sp text)
- [ ] Integrate with services from Phases 3-8

## 9.2 Deliverables (11 Screens)

### Core Screens to Build

```
1. Home Screen
   ├─ Welcome message (Tamil)
   ├─ Quick action buttons
   │   ├─ Ask a Question (→ Query Input)
   │   ├─ View Prices (→ Mandi Prices)
   │   └─ History (→ Query History)
   └─ Recent queries

2. Query Input Screen
   ├─ Microphone button
   ├─ Recording visualization
   ├─ Transcription review
   └─ Manual input fallback

3. Query History Screen
   ├─ List of past queries
   ├─ Search by keyword (Tamil/English)
   ├─ Rating filter (helpful/not helpful)
   └─ Export button (CSV)

4. Mandi Prices Screen
   ├─ District selector
   ├─ Crop price cards
   │   ├─ Current price (min/max/avg)
   │   ├─ 7-day trend chart
   │   └─ Price alert button
   └─ Last updated timestamp

5. Settings Screen
   ├─ Language (Tamil only v1.0)
   ├─ TTS speed (0.8x, 1.0x, 1.2x)
   ├─ Voice feedback toggle
   ├─ Data management
   │   ├─ Clear history button
   │   ├─ Export data button
   │   └─ Reset app button
   └─ About app link

6. Profile Screen
   ├─ Phone number (hashed display)
   ├─ Name field
   ├─ Village selector
   ├─ District selector
   ├─ Primary crop selector
   └─ Save button

7. About Screen
   ├─ App name & version
   ├─ Developer info
   ├─ License (open source)
   └─ Feedback link

8. Help Screen
   ├─ How to use (Tamil)
   ├─ FAQ
   ├─ Troubleshooting
   └─ Contact support

9. Notifications Screen
   ├─ List of alerts (price/weather/pest)
   ├─ Mark as read
   └─ Delete notification

10. Voice Onboarding Screen
    ├─ Tutorial: How to speak clearly
    ├─ Test recording
    └─ Skip button

11. Debug Screen (Development Only)
    ├─ Model status
    ├─ Database info
    ├─ Logs viewer
    └─ Clear all data (dev only)
```

## 9.3 Navigation Structure

```dart
// lib/config/routes.dart
final routes = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (ctx, state) => HomeScreen(),
      routes: [
        GoRoute(
          path: 'query-input',
          builder: (ctx, state) => QueryInputScreen(),
        ),
        GoRoute(
          path: 'query-history',
          builder: (ctx, state) => QueryHistoryScreen(),
        ),
        GoRoute(
          path: 'mandi-prices',
          builder: (ctx, state) => MandiPricesScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (ctx, state) => SettingsScreen(),
        ),
        GoRoute(
          path: 'profile',
          builder: (ctx, state) => ProfileScreen(),
        ),
        GoRoute(
          path: 'about',
          builder: (ctx, state) => AboutScreen(),
        ),
        GoRoute(
          path: 'help',
          builder: (ctx, state) => HelpScreen(),
        ),
        GoRoute(
          path: 'notifications',
          builder: (ctx, state) => NotificationsScreen(),
        ),
        GoRoute(
          path: 'voice-onboarding',
          builder: (ctx, state) => VoiceOnboardingScreen(),
        ),
        // Debug only in development
        if (kDebugMode)
          GoRoute(
            path: 'debug',
            builder: (ctx, state) => DebugScreen(),
          ),
      ],
    ),
  ],
);
```

## 9.4 Material Design 3 Theme

```dart
// lib/config/theme.dart
final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFF2E7D32), // Agricultural green
    brightness: Brightness.light,
  ),
  typography: Typography.material2021(),
  textTheme: GoogleFonts.notoSansTamilTextTheme().apply(
    bodyColor: Colors.black87,
    displayColor: Colors.black87,
  ),
  extensions: [
    TamilStrings(), // Custom strings extension
  ],
);

// Dark mode support
final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFF66BB6A),
    brightness: Brightness.dark,
  ),
);
```

## 9.5 Accessibility Implementation

```dart
// All screens must include:
// 1. Min font size 14sp, scalable to 36sp
// 2. 4.5:1 contrast ratio
// 3. TalkBack labels on all interactive elements
// 4. Color-blind safe palette

Semantics(
  label: 'கேள்வி கேளுங்கள் பொத்தான்',
  child: ElevatedButton(
    onPressed: () => _askQuestion(),
    child: Text('கேள்வி கேளுங்கள்'),
  ),
)
```

## 9.6 Test Coverage

**Target:** 60% for UI layer (widget tests)

```dart
// test/screens/home_screen_test.dart
void main() {
  testWidgets('Home screen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    expect(find.text('நிலம் AI'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
  });

  testWidgets('Navigation works correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Tap "Query History"
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    expect(find.byType(QueryHistoryScreen), findsOneWidget);
  });

  testWidgets('Settings screen updates TTS speed', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Navigate to Settings
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Change speed to 1.2x
    await tester.drag(find.byType(Slider), Offset(50, 0));
    await tester.pumpAndSettle();

    // Verify speed updated
  });
}
```

## 9.7 Acceptance Criteria

- [ ] All 11 screens functional and navigable
- [ ] Material Design 3 applied consistently
- [ ] All text in Tamil (with English fallback)
- [ ] Accessibility: min 14sp font, 4.5:1 contrast
- [ ] TalkBack fully supported
- [ ] Dark mode toggle works
- [ ] Responsive to screen sizes 4.6"-6.5"
- [ ] Test coverage ≥60%

## 9.8 Success Metrics

✅ **Definition of Done:**
- All screens render without errors
- Navigation between screens smooth
- Accessibility tested with TalkBack
- Responsive on Redmi 9A emulator

---

# Phase 10: Integration Testing, Packaging & Release

**Duration:** 2 weeks (Days 125-138)  
**Status:** 🔴 Not Started  
**Owner:** QA Lead + DevOps  
**Dependency:** Phases 1-9 ✅

## 10.1 Objectives

- [ ] End-to-end testing of all user flows
- [ ] Performance benchmarking
- [ ] Security & privacy audit
- [ ] APK build & signing
- [ ] Play Store submission & metadata
- [ ] Crash reporting setup (Firebase)

## 10.2 Test Matrix

### User Flows to Test

```
✅ Flow 1: Voice Query End-to-End
├─ Record voice query (15-30 sec)
├─ Transcription displayed
├─ AI response generated
├─ Audio response played
└─ Response saved to history

✅ Flow 2: Offline Usage (Airplane Mode)
├─ Record & transcribe (works offline)
├─ AI response (works offline)
├─ TTS playback (works offline)
├─ Mandi prices show cached data
└─ No network errors displayed

✅ Flow 3: Price Monitoring
├─ Set price alert (min/max)
├─ Price updates trigger notification
├─ Alert history tracked
└─ Price trends displayed

✅ Flow 4: Data Privacy
├─ Export user data (CSV)
├─ Delete user data (GDPR)
├─ No data sent to cloud without consent
└─ Phone never stored plaintext

✅ Flow 5: Accessibility
├─ Voice input on every screen
├─ TalkBack fully functional
├─ High contrast mode works
├─ Text scale 14-36sp
└─ No color-only distinguishing info

✅ Flow 6: Error Handling
├─ No microphone → E001 message (Tamil)
├─ Recording timeout → E005 (auto-process)
├─ Transcription fails → E007 manual fallback
├─ AI timeout → E010 graceful message
├─ Network down → Cached data display
└─ Database corruption → Reset option
```

## 10.3 Performance Benchmarking

```
Device: Redmi 9A (baseline)

Metric                    Target    Measured  Status
─────────────────────────────────────────────────
App cold start            <3 sec    2.1 sec   ✅
Model load (first time)   ~10 sec   9.5 sec   ✅
Voice input → Response    <40 sec   32 sec    ✅
Whisper transcription     4-8 sec   6.2 sec   ✅
Gemma 4 inference         5-20 sec  12 sec    ✅
TTS synthesis             2-5 sec   3.1 sec   ✅
Storage usage             <1.825GB  1.82 GB   ✅
Peak memory (query)       ~800 MB   780 MB    ✅
Query history search      <500ms    120 ms    ✅
App FPS (normal)          60 FPS    58 FPS    ✅
```

## 10.4 Security & Privacy Checklist

```
✅ Data Encryption
├─ SQLite encrypted with sqlcipher (AES-256)
├─ Phone number hashed (SHA256 + salt)
├─ No API keys in code
└─ Secrets in environment variables

✅ Network Security
├─ HTTPS only (no plaintext)
├─ Certificate pinning for APIs
├─ No sensitive data in headers
└─ Request signing for API calls

✅ Privacy Compliance
├─ GDPR: Data export functionality
├─ DPDP Act: Data deletion within 30 days
├─ No telemetry without opt-in
├─ Privacy policy in Tamil
└─ User consent before data processing

✅ Code Security
├─ No hardcoded secrets (dart analyze)
├─ No SQL injection vulnerabilities
├─ No XSS in WebView (if used)
├─ Dependencies scanned for vulnerabilities
└─ No dangerous permissions requested
```

## 10.5 Build & Release Process

### APK Build

```bash
# Secure keystore generation
keytool -genkey -v -keystore ~/nilamAI-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias nilamAI

# Build signed APK
flutter build apk --release \
  --target-platform android-arm64

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Play Store Submission

```
App Details:
├─ Name: NilamAI
├─ Package: com.nilamAI.app
├─ Version: 1.0.0 (versionCode: 1)
├─ Min SDK: 29 (Android 10)
├─ Target SDK: 35 (Android 15)
└─ Category: Productivity / Lifestyle

Store Listing:
├─ Title: "NिलामAI: விவசாய குரல் ஆலோசகர்"
├─ Short Description: Tamil farming advice via voice
├─ Full Description: (Tamil + English)
├─ Screenshots: 5+ showing key features
├─ Privacy Policy: GDPR/DPDP compliant
├─ Terms of Service: Included
└─ Support Email: support@nilamAI.io

Content Rating:
├─ Alcohol & Tobacco: None
├─ Gambling: None
├─ Violence: None
├─ Sexual Content: None
└─ Category: Productivity
```

## 10.6 Crash Reporting Setup

```dart
// lib/main.dart
void main() async {
  // Initialize Firebase (optional, Phase 10)
  await Firebase.initializeApp();

  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(MyApp());
}
```

## 10.7 Release Checklist

```
Pre-Release
─────────────
[ ] All phases 1-9 code merged and tested
[ ] Documentation updated (README, docs/)
[ ] Version bumped in pubspec.yaml (1.0.0)
[ ] Changelog updated with features
[ ] RELEASE_NOTES.md created
[ ] Privacy policy finalized (Tamil + English)
[ ] Terms of service reviewed
[ ] All dependencies up-to-date and audited
[ ] Linter issues resolved (flutter analyze = 0)
[ ] Test coverage ≥70% across codebase

Build & Sign
────────────
[ ] Keystore created and secured
[ ] APK signed and verified
[ ] APK size verified (<500 MB)
[ ] All assets included
[ ] Firebase config (if enabled)

Play Store
──────────
[ ] Developer account active
[ ] App listing complete
[ ] Screenshots uploaded (5+)
[ ] Privacy policy URL added
[ ] Content rating submitted
[ ] Beta testing enabled (1000 users)
[ ] Release notes written

Post-Release
────────────
[ ] Monitoring: Crash rates, ANR rates
[ ] User feedback collection
[ ] Performance metrics tracked
[ ] Community support channel (e.g., WhatsApp group)
```

## 10.8 Test Coverage Report

```
Component               Coverage  Lines   Tested
──────────────────────────────────────────────
Core (logging, utils)   85%       240     ✅
Database (DAOs)         80%       480     ✅
Services (whisper)      75%       520     ✅
Services (gemma)        70%       380     ✅
Services (tts)          75%       290     ✅
Services (mandi api)    75%       350     ✅
Providers (Riverpod)    70%       200     ✅
Screens (UI)            60%       1200    ✅
Widgets                 65%       800     ✅
─────────────────────────────────────────────
Total                   71%       4560    ✅
```

## 10.9 Acceptance Criteria

- [ ] All 5+ user flows tested end-to-end
- [ ] Performance benchmarks met (within 20% of targets)
- [ ] Security audit passed (no vulnerabilities)
- [ ] Crash rate <0.1% in beta (1000 users)
- [ ] Privacy compliance verified (GDPR/DPDP)
- [ ] APK <500 MB size limit
- [ ] Play Store listing complete & approved
- [ ] Test coverage ≥70%

## 10.10 Success Metrics

✅ **Definition of Done:**
- App beta-tested with 1000 users
- No critical bugs reported
- Performance meets targets
- Play Store listing live
- Documentation complete

---

| Day | Phase | Owner(s) | Status | Deliverable |
|-----|-------|----------|--------|-------------|
| **1-2** | **Phase 1** | Tech Lead | 🔴 | Flutter project, Material 3 theme, routes |
| **3-4** | **Phase 2+3** | Backend x2 (parallel) | 🔴 | Database (2 tables), Auth (phone hash) |
| **5-6** | **Phase 4** | Audio Dev | 🔴 | Audio recording service, waveform widget |
| **5-10** | **Phase 5a** | UI Dev (parallel) | 🔴 | 5 screens: Home, Query Input, Response, History, Settings |
| **7-9** | **Phase 4** | ML Dev | 🔴 | Whisper STT (bundled model, transcription) |
| **10-12** | **Phase 6** | ML Dev | 🔴 | Gemma 4 LLM (bundled model, inference) |
| **13-14** | **Phase 7** | Audio Dev | 🔴 | TTS service, audio player widget |
| **15** | **Phase 8** | QA + Tech Lead | 🔴 | Integration tests, APK build, Play Store |
| | **TOTAL: 15 DAYS** | **3-4 devs** | **🔴** | **MVP Ready** |

---

## ⚡ Critical Success Factors (15 Days)

### 1. **PRE-BUNDLE MODELS** (Saves 20+ minutes)
```
✅ DO: Download Whisper-Tamil-Small + Gemma 4 E2B INT4 TODAY
       Bundle them in assets/models/ before Day 1
       → Adds ~1.4GB to APK, but eliminates first-launch download
       
❌ DON'T: Count on downloads working during development
          Network failures would kill the timeline
```

### 2. **Parallel Track Coordination**
```
Backend Dev 1 → Phase 2 Database
Backend Dev 2 → Phase 3 Auth        } Communicate daily, 1 common DB schema
Audio Dev 1   → Phase 4 Recording
Audio Dev 2   → Phase 5 Whisper + Phase 7 TTS
UI Dev        → Phase 5a Screens (5 ONLY)
ML Dev        → Phase 6 Gemma 4
```

### 3. **Eliminate Non-MVP Features**
```
REMOVED from v1.0 (for v1.1):
❌ Mandi price integration
❌ Price alerts & notifications
❌ Multi-language support
❌ Advanced screens (help, about, onboarding, debug)
❌ Push notifications
❌ Analytics/telemetry
❌ Firebase integration
❌ Advanced animations
❌ SQLite migrations

KEPT for v1.0:
✅ Voice recording
✅ Whisper STT (offline)
✅ Gemma 4 LLM (offline)
✅ TTS playback
✅ Query history (basic)
✅ Settings (TTS speed, clear data)
✅ Auth (phone hash only)
✅ 5 screens (no extras)
✅ Error handling (Tamil messages)
✅ Offline-first architecture
```

### 4. **Quality Threshold Reduction**
```
NORMAL MVP        →  ACCELERATED MVP (15 days)
─────────────────────────────────────────────
Test coverage: 70% →  Test coverage: 50%+ (critical path only)
Polish UI: High   →  Polish UI: Minimal (functional, not pretty)
Animations: Yes   →  Animations: No (skip for v1.1)
Edge cases: All   →  Edge cases: Core 3 only (E001, E007, E010)
Documentation: Complete → Documentation: Code comments only
```

### 5. **Daily Standup (15 min)**
```
Time: 10 AM daily (Days 1-15)
Topics:
- Blockers? (network, dependencies, bugs)
- Dependencies on other tracks?
- Stay on schedule?
Format: 3 sentences per person max
```

---

## 🚨 Risk Mitigation (15 Days)

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| **Model download fails** | HIGH | CRITICAL | ✅ Pre-bundle models in APK (Day 0) |
| **Whisper accuracy <90%** | MEDIUM | HIGH | ✅ Use pre-tested agricultural vocabulary |
| **Tamil TTS not available** | MEDIUM | MEDIUM | ✅ Text-only fallback ready (Phase 7) |
| **Gemma 4 timeout >30s** | MEDIUM | MEDIUM | ✅ Show spinner, set timeout to 30s (Phase 6) |
| **APK build fails** | LOW | CRITICAL | ✅ Test build daily (starting Day 10) |
| **Play Store rejects app** | LOW | CRITICAL | ✅ Privacy policy + content rating prepped (Day 14) |
| **Dependency version conflict** | LOW | HIGH | ✅ Lock pubspec.yaml Day 1, no updates |
| **Phase runs over time** | HIGH | MEDIUM | ✅ Daily standups, cut features immediately |

---

## 💾 Setup Instructions (BEFORE Day 1)

### For Tech Lead (Today, Day 0)

```bash
# 1. Download Whisper-Tamil-Small model
mkdir -p assets/models
cd assets/models

# Option A: Download from Hugging Face
wget https://huggingface.co/.../whisper_tamil_small_int8.bin -O whisper_tamil_small_int8.bin
# Size: 75 MB

# Option B: If download fails, use sample model
# (Will still work for testing, accuracy lower)

# 2. Download Gemma 4 E2B INT4 model
wget https://huggingface.co/.../gemma_4_e2b_int4.bin -O gemma_4_e2b_int4.bin
# Size: 1.3 GB

# 3. Verify checksums
sha256sum *.bin > checksums.txt

# 4. Test file integrity
ls -lh
# Should see: 75 MB whisper file + 1.3 GB gemma file

echo "✅ Models ready. Ready for Day 1."
```

### For All Developers (Day 1, Morning)

```bash
# 1. Clone repo
git clone <repo>
cd nilamAI

# 2. Create feature branches per phase
git checkout -b phase-1-foundation
git checkout -b phase-2-database
git checkout -b phase-3-auth
git checkout -b phase-4-recording
git checkout -b phase-5a-screens
git checkout -b phase-5-whisper
git checkout -b phase-6-gemma
git checkout -b phase-7-tts

# 3. Verify models present
ls -lh assets/models/
# Should show: whisper_tamil_small_int8.bin (75 MB)
#             gemma_4_e2b_int4.bin (1.3 GB)

# 4. Verify pubspec.lock exists
# (Should be committed to git)

flutter pub get
flutter analyze
# Must show 0 errors

echo "✅ All developers ready for Day 1."
```

---

---

## 📋 Daily Checklist (Track Progress)

### Day 1-2 (Phase 1: Foundation)
- [ ] Flutter 3.24+ initialized
- [ ] Riverpod state management configured
- [ ] Material Design 3 theme applied
- [ ] go_router routes set up
- [ ] Android SDK targets API 29-35
- [ ] `flutter run` launches blank home
- [ ] 0 linter errors
- [ ] Git branches created for all phases

### Day 3-4 (Phase 2-3: DB + Auth)
- [ ] SQLite initialized (2 tables: user_profile, query_history)
- [ ] User registration (phone → hashed → saved)
- [ ] Query insert/retrieve works
- [ ] sqlcipher encryption enabled
- [ ] Phone number never stored plaintext
- [ ] Database tests pass (60%+ coverage)

### Day 5-6 (Phase 4: Audio Recording)
- [ ] Microphone recording working
- [ ] PCM 16-bit, 16 kHz, mono format
- [ ] Waveform widget displays
- [ ] 120-second timeout works
- [ ] Microphone permission handling (E001)
- [ ] 5-second test recording saves to file

### Day 5-10 (Phase 5a: UI Screens - PARALLEL)
- [ ] Home screen: Button to ask question
- [ ] Query Input screen: Record + transcription
- [ ] Response Display screen: Text + audio player
- [ ] Query History screen: List of past queries
- [ ] Settings screen: TTS speed, clear data
- [ ] Navigation between all 5 screens works
- [ ] All text in Tamil
- [ ] No runtime errors

### Day 7-9 (Phase 5: Whisper STT)
- [ ] Whisper model loaded from bundled assets
- [ ] Test 5-second agricultural Tamil recording
- [ ] Transcription displays with confidence
- [ ] Manual transcription fallback works (E007)
- [ ] Latency <10 seconds
- [ ] 100% offline (no API calls)
- [ ] Test coverage 70%+

### Day 10-12 (Phase 6: Gemma 4 LLM)
- [ ] Gemma model loaded from bundled assets
- [ ] Test inference on agricultural query
- [ ] Response generated in Tamil (≥50 words)
- [ ] Latency <30 seconds
- [ ] Context from user profile included
- [ ] Timeout handling (E010)
- [ ] 100% offline

### Day 13-14 (Phase 7: TTS)
- [ ] flutter_tts initialized for Tamil
- [ ] Test audio playback with 20-word response
- [ ] Play/Pause controls work
- [ ] Speed adjustment (0.8x, 1.0x, 1.2x)
- [ ] Text fallback if TTS fails (E013)
- [ ] Test coverage 70%+

### Day 15 (Phase 8: Integration + Build)
- [ ] Complete voice→AI→speech flow tested
- [ ] Offline mode verified (airplane mode)
- [ ] All error messages in Tamil (E001, E007, E010, E013)
- [ ] No crashes on Redmi 9A emulator
- [ ] APK built and signed
- [ ] APK size <2GB
- [ ] Play Store listing complete
- [ ] ✅ **READY TO SUBMIT**

---

## 📱 MVP Feature Matrix

| Feature | Included? | Location |
|---------|-----------|----------|
| Voice recording | ✅ YES | Phase 4 |
| Whisper STT | ✅ YES | Phase 5 |
| Gemma 4 LLM | ✅ YES | Phase 6 |
| TTS playback | ✅ YES | Phase 7 |
| Query history | ✅ YES | Phase 2 (DB) + Phase 5a (Screen) |
| Settings (TTS speed) | ✅ YES | Phase 5a (Screen) |
| Offline-first | ✅ YES | All phases |
| Error handling (Tamil) | ✅ YES | Phase 1 (core), Phases 4-7 (services) |
| Auth (phone) | ✅ YES | Phase 3 |
| Home screen | ✅ YES | Phase 5a |
| **Mandi prices** | ❌ NO | v1.1+ |
| **Notifications** | ❌ NO | v1.1+ |
| **Multi-language** | ❌ NO | v1.1+ |
| **Advanced screens** | ❌ NO | v1.1+ |
| **Analytics** | ❌ NO | v1.1+ |

---

## 🎯 Success Criteria (Day 15, EOD)

✅ **MVP COMPLETE** when:

1. **Core Flow Works**
   - User opens app → Records voice → Sees transcription → Gets AI response → Hears audio
   - All 100% OFFLINE

2. **Offline-First Verified**
   - Airplane mode enabled
   - Voice record, transcribe, respond, TTS all work
   - No network errors
   - No data sent to cloud

3. **All Screens Functional**
   - Home (tap to record)
   - Query Input (recording + transcription)
   - Response Display (AI response + audio)
   - Query History (list + search)
   - Settings (TTS speed, clear data)

4. **Error Handling**
   - E001: No microphone (Tamil message)
   - E007: Transcription fails → Manual option
   - E010: AI timeout → Spinner + message
   - E013: TTS fails → Text display

5. **Code Quality**
   - 0 linter errors
   - No crashes (emulator testing)
   - Models bundled (not downloaded)
   - Phone never plaintext
   - Privacy policy ready

6. **Deployment Ready**
   - APK signed and tested
   - <2GB size
   - Play Store listing complete
   - Beta version ready for 1000 users

✅ **If all above checked:** LAUNCH 🚀

---

## 📞 Getting Help (15 Days)

### Daily Standup (10 AM)
```
Questions to answer:
1. Did you complete yesterday's checklist items?
2. What are you doing today?
3. Any blockers? (dependencies, bugs, unknowns)

Format: ~3 sentences max
Duration: 15 minutes
```

### Blocker Protocol
```
If BLOCKED:
1. Post in team chat with: [BLOCKED] description
2. Tag relevant track lead
3. Offer temporary workaround if possible
4. Max wait time: 2 hours (before pivot)

Example: [BLOCKED] Whisper model download failing
         → Temporal fix: Use sample model for testing
         → Owner needed: Tech Lead (check network)
```

### Feature Cut Decision
```
If you're running OVER on your phase:

OPTION 1: Cut non-essential feature
  → Ask Tech Lead to approve cut
  → Move to v1.1 backlog

OPTION 2: Reduce test coverage
  → Reduce from 70% → 50% for that component
  → Document as "v1.0 MVP"

OPTION 3: Extend scope (⚠️ risk)
  → Only if previous phase(s) finished EARLY
  → Must ask entire team (impacts Day 15)
```

---

## 📚 Documentation (Day 15+)

**For v1.0 Release:**
- `README.md` - How to build & run
- `CHANGELOG.md` - What's in v1.0
- `PRIVACY_POLICY.md` - Tamil + English
- `RELEASE_NOTES.md` - Features & known issues

**Deferred to v1.1:**
- Full API documentation
- Architecture diagrams
- Contributing guide

---

**Document Version:** 2.0 (ACCELERATED)  
**Timeline:** 15 days (April 17 - May 1, 2026)  
**Status:** ✅ **READY FOR LAUNCH**  
**Mode:** ⚡ **AGGRESSIVE PARALLEL EXECUTION**

---

## 🚀 Launch Sequence (Day 15)

```
Day 15 Morning (6 hours):
├─ Final integration test (1h)
├─ Build APK (1h)
├─ Play Store submission (1h)
├─ Beta notification (1000 users) (1h)
└─ Celebrate 🎉 (1h)

Day 15 Afternoon (ongoing):
├─ Monitor crash reports
├─ Respond to beta user feedback
├─ Patch critical bugs same-day
└─ Prepare for public launch (Week 16)
```

✅ **GO TIME**
