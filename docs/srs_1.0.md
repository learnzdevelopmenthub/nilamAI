# Software Requirements Specification (SRS) — Version 1.0

# NilamAI (நிலம்AI) — AI-Powered Crop Lifecycle Manager for Small Farmers

**App Name:** NilamAI (நிலம்AI)  
**Meaning:** Nilam (நிலம்) = Land | AI = Artificial Intelligence  
**Tagline (Tamil):** நிலம் புத்திசாலி, விவசாயி வெற்றி (Smart land, successful farmer)  
**Tagline (English):** AI that grows with your land  
**App Store Name:** NilamAI — Smart Farming Assistant  
**Brand Colors:** Earth Green (#2E7D32) + Warm Amber (#F59E0B)

**Version:** 1.0  
**Date:** April 2026  
**License:** Apache 2.0

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [Functional Requirements](#3-functional-requirements)
4. [Non-Functional Requirements](#4-non-functional-requirements)
5. [Data Model](#5-data-model)
6. [External Interface Requirements](#6-external-interface-requirements)
7. [Technology Stack](#7-technology-stack)
8. [AI Integration Specification](#8-ai-integration-specification)
9. [State Management Architecture](#9-state-management-architecture)
10. [Error Handling Specification](#10-error-handling-specification)
11. [Caching and Offline Strategy](#11-caching-and-offline-strategy)
12. [Security Specification](#12-security-specification)
13. [Testing Requirements](#13-testing-requirements)
14. [Performance Benchmarks](#14-performance-benchmarks)
15. [Repository Structure](#15-repository-structure)
16. [Future Enhancements](#16-future-enhancements)

---

## 1. Introduction

### 1.1 Purpose

This document defines the complete software requirements for NilamAI, an offline-first, AI-powered crop lifecycle management application for small and marginal farmers in rural India. It specifies all functional behaviour, data structures, API contracts, performance constraints, error handling rules, and integration specifications required to build and verify the system.

This document is intended for:
- Software engineers implementing the Flutter application
- ML engineers configuring the on-device AI pipeline
- QA engineers designing test plans
- Any future contributor joining the project

### 1.2 Scope

NilamAI addresses the fundamental disconnect between advanced AI capabilities and the farmers who need them most. Over 86% of Indian farmers are small or marginal holders cultivating less than 2 hectares. They face crop diseases, water scarcity, pesticide overuse, middleman exploitation, and lack of access to government benefits — often with no internet connectivity and limited literacy.

NilamAI puts a personalized farming assistant directly on the farmer's phone, powered by Gemma 4 E2B running entirely on-device.

**MVP functional scope:**

- Multi-crop lifecycle tracking with stage-based reminders
- Photo-based crop disease diagnosis using Gemma 4 multimodal vision
- Pesticide and fertilizer dosage guidance with organic alternatives
- Tamil language support with voice input/output
- Live mandi (market) price fetching via function calling
- Government scheme matching and deadline alerts
- Post-harvest storage guidance and loss prevention
- Soil health tracking and crop rotation recommendations
- On-device RAG pipeline with sqlite-vec for performance optimization

**Out of scope for v1.0:**
- Cloud sync or backend server
- IoT sensor integration
- Community/social features
- iOS support
- Online payment or e-commerce

### 1.3 Target Users

| User Type | Description | Technical Literacy |
|---|---|---|
| Primary | Small/marginal farmers (< 2 hectares) in Tamil Nadu and South India | Low — familiar with basic smartphone use (WhatsApp, camera) |
| Secondary | Agricultural extension officers using the app to advise farmers | Moderate |
| Tertiary | Farmer family members who assist with technology | Low to moderate |

### 1.4 Definitions and Acronyms

| Term | Definition |
|---|---|
| Mandi | Government-regulated agricultural market in India |
| RAG | Retrieval-Augmented Generation — retrieving relevant context before LLM inference |
| sqlite-vec | Vector search extension for SQLite (pure C, successor to sqlite-vss) |
| PM-KISAN | Pradhan Mantri Kisan Samman Nidhi — government income support scheme |
| PMFBY | Pradhan Mantri Fasal Bima Yojana — crop insurance scheme |
| AgMarknet | Government portal for agricultural market prices |
| E2B | Gemma 4 Effective 2-Billion parameter edge model (selective activation) |
| LiteRT / LiteRT-LM | Google's lightweight runtime for deploying ML / LLM models on mobile |
| EmbeddingGemma | Google's 308M open embedding model for on-device RAG (768-dim) |
| NPU | Neural Processing Unit — dedicated hardware for ML inference |
| INT4 | 4-bit integer quantization — reduces model size and inference time |
| LoRA | Low-Rank Adaptation — parameter-efficient fine-tuning method |
| STT | Speech-to-Text |
| TTS | Text-to-Speech |
| dp / sp | Density-independent pixels / Scale-independent pixels (Android UI units) |
| CRUD | Create, Read, Update, Delete |
| FK | Foreign Key |
| PK | Primary Key |
| APK | Android Package — distributable app bundle format |
| NNAPI | Android Neural Networks API |

### 1.5 References

- Gemma 4 Model Documentation: https://ai.google.dev/gemma
- Gemma 4 E2B LiteRT-LM checkpoint: https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm
- flutter_gemma plugin: https://pub.dev/packages/flutter_gemma
- Ollama Gemma 4 library: https://ollama.com/library/gemma4
- sqlite-vec: https://github.com/asg017/sqlite-vec
- AgMarknet Portal: https://agmarknet.gov.in
- AgMarknet OGD REST API: https://www.data.gov.in/catalog/current-daily-price-various-commodities-various-markets-mandi
- PlantVillage Dataset: https://plantvillage.psu.edu
- PM-KISAN Portal: https://pmkisan.gov.in
- PMFBY Portal: https://pmfby.gov.in

---

## 2. Overall Description

### 2.1 Product Perspective

NilamAI is a standalone mobile application that operates primarily offline. It is not a client-server system. The AI model, knowledge base, and vector database all reside on the user's device. Network connectivity is optional and used only for fetching live market prices, weather forecasts, and syncing scheme deadline updates when available.

There is no backend API, no user accounts, and no cloud data storage. The complete application state lives on the device in a local SQLite database.

### 2.2 System Architecture Overview

The system follows a three-layer architecture:

```
┌─────────────────────────────────────────────────────┐
│              PRESENTATION LAYER (Flutter)             │
│  Dashboard │ Timeline │ Camera │ Market │ Schemes     │
│  Riverpod state │ go_router navigation │ Tamil UI     │
└──────────────────────┬──────────────────────────────┘
                       │ user actions / events
┌──────────────────────▼──────────────────────────────┐
│           INTELLIGENCE LAYER (Gemma 4 On-Device)      │
│  Gemma 4 E2B (LiteRT-LM)  │  EmbeddingGemma (308M)  │
│  RAG Pipeline             │  Function Calling        │
│  Voice I/O (STT + TTS)    │  Multimodal (img+audio)  │
└──────────────────────┬──────────────────────────────┘
                       │ read/write structured data
┌──────────────────────▼──────────────────────────────┐
│                   DATA LAYER                          │
│  SQLite (sqflite)   │  sqlite-vec (vector search)    │
│  Crop profiles      │  Disease embeddings            │
│  Diagnoses          │  Treatment embeddings          │
│  Scheme matches     │  Stage-care embeddings         │
│  Market cache       │  Scheme embeddings             │
└─────────────────────────────────────────────────────┘
```

**Layer 1 — Presentation Layer (Flutter)**
- Cross-platform mobile UI optimized for low-end Android devices
- Touch-friendly interface with large buttons and minimal required text input
- Voice input/output for low-literacy users
- Tamil-first UI with support for other South Indian languages
- Riverpod providers expose application state to widgets
- go_router manages screen transitions and deep links

**Layer 2 — Intelligence Layer (Gemma 4 On-Device)**
- Gemma 4 E2B deployed via LiteRT-LM through the `flutter_gemma` plugin (production) or Ollama HTTP bridge (development)
- EmbeddingGemma (308M) runs alongside for query/document embedding
- Multimodal processing (image + text + audio) for disease diagnosis and voice queries
- Text generation for advisory content in Tamil
- Function calling for external API access (weather, mandi prices)
- Stage-aware context assembly using the RAG pipeline
- Reasoning for scheme eligibility matching and crop rotation

**Layer 3 — Data Layer**
- SQLite for structured crop data (profiles, stages, history, diagnoses, application logs)
- sqlite-vec loaded as a SQLite extension for vector similarity search
- Bundled crop knowledge base (stage templates for all supported crops)
- Cached API responses for offline access (prices, weather, schemes)

### 2.3 RAG Pipeline (On-Device) — Detailed

The Retrieval-Augmented Generation pipeline is the core performance optimization that makes Gemma 4 E2B viable on low-end devices:

```
Farmer Input
    │
    ▼
[1] Query Embedding
    EmbeddingGemma (308M, INT8)
    Input: query text (or transcribed voice)
    Output: 768-dimensional float vector
    Latency: ~200ms
    │
    ▼
[2] Vector Similarity Search (sqlite-vec)
    SELECT id, content_chunk, metadata_json,
           vec_distance_cosine(embedding, ?) AS dist
    FROM disease_embeddings
    WHERE crop_type = ?
    ORDER BY dist ASC LIMIT 5;
    Latency: <50ms (indexed)
    │
    ▼
[3] Context Assembly
    Template:
      crop_stage_metadata (fixed, ~80 tokens)
      + retrieved_chunks (top 3-5, ~300 tokens)
      + farmer_query (~50 tokens)
      + system_instructions (~80 tokens)
    Total: 400-600 tokens
    │
    ▼
[4] Gemma 4 E2B Inference (LiteRT-LM)
    Max input: 600 tokens (capped for latency)
    Max output: 300 tokens
    Temperature: 0.3
    Latency: 1-5s (hardware dependent)
    │
    ▼
[5] Response Delivery
    Text rendered in UI (Tamil)
    Voice readout via flutter_tts (optional auto-play)
```

**Why RAG is critical:**
| Mode | Tokens/Query | Latency (4GB CPU) | Latency (NPU) |
|---|---|---|---|
| Without RAG (full KB in prompt) | 4,000-5,000 | 8-12s | 4-6s |
| With RAG | 400-600 | 1-3s | <2s |

RAG reduces token usage by ~87%, bringing response time within the 5-second UX threshold on target budget devices.

### 2.4 Supported Crops (MVP)

| Crop | Tamil Name | Typical Duration | Growth Stages |
|---|---|---|---|
| Rice (Ponni/Samba) | நெல் | 120-150 days | Nursery → Transplanting → Tillering → Panicle initiation → Flowering → Grain filling → Harvest |
| Tomato | தக்காளி | 90-120 days | Seedling → Vegetative → Flowering → Fruit set → Fruiting → Harvest |
| Groundnut | நிலக்கடலை | 100-130 days | Germination → Vegetative → Pegging → Pod development → Pod filling → Harvest |
| Banana | வாழை | 300-365 days | Planting → Vegetative → Shooting → Flowering → Bunch development → Harvest |
| Onion | வெங்காயம் | 90-120 days | Seedling → Establishment → Bulb initiation → Bulb development → Maturity → Harvest |
| Sugarcane | கரும்பு | 270-365 days | Germination → Tillering → Grand growth → Maturity → Harvest |

Each crop type has a corresponding JSON configuration file bundled in `assets/crops/` that defines:
- Array of stage objects with `name`, `name_tamil`, `duration_days_min`, `duration_days_max`
- Per-stage task list (fertilizer, pest watch, irrigation notes)
- Stage-specific vulnerable diseases
- Harvest readiness indicators

### 2.5 Operating Environment

| Parameter | Minimum | Recommended |
|---|---|---|
| OS | Android 10 (API 29) | Android 12+ (API 31+) |
| RAM | 4 GB | 6 GB |
| Storage (free) | 2.5 GB | 4 GB |
| Processor | ARM64 with NNAPI support | ARM64 with dedicated NPU (Qualcomm, MediaTek, Tensor) |
| Camera | Rear camera, 8 MP | 12+ MP, autofocus |
| Network | None required | Wi-Fi or mobile data for live prices |
| Target devices | Redmi 9A, Realme C11 (4GB) | Redmi Note 11, Samsung Galaxy M13 (6GB) |

### 2.6 Design Constraints

1. All core features must work without internet connectivity
2. UI text must be in Tamil by default with language switching capability
3. Response latency must not exceed 5 seconds for text queries on 4GB RAM CPU-only devices
4. Response latency must not exceed 3 seconds for text queries on NPU-equipped devices
5. Image diagnosis must complete within 8 seconds on 4GB RAM CPU-only devices
6. Image diagnosis must complete within 5 seconds on NPU-equipped devices
7. Total installed size (app + models + knowledge base) must not exceed 2.5 GB
8. No user data may leave the device — complete local data isolation
9. All primary interactions must be achievable without text typing (voice + tap preferred)
10. Minimum touch target: 48×48 dp per Android accessibility standard
11. Application must not crash on low-memory device scenarios; graceful degradation required

### 2.7 Assumptions and Dependencies

| Assumption | Risk if False | Mitigation |
|---|---|---|
| Gemma 4 E2B model weights distributed under Apache 2.0 | Legal blocker | Monitor license; use Gemma 2 2B as fallback |
| LiteRT-LM runtime supports Gemma 4 E2B on Android 10+ | Core feature unavailable | Test early on min-spec device; keep Ollama dev path |
| PlantVillage dataset available for disease embeddings | RAG knowledge quality degraded | Supplement with manually curated Tamil Nadu disease data |
| AgMarknet API provides JSON responses reliably | Market feature degraded | Aggressive caching; show last-known prices |
| Android SpeechRecognizer supports Tamil on target OEM ROMs | Voice input unavailable | Bundle Vosk Tamil model (~50 MB) as guaranteed fallback |

---

## 3. Functional Requirements

Each requirement below uses the format:
- **FR-X.Y.Z:** Unique identifier
- **Priority:** P0 (must-have) / P1 (should-have) / P2 (nice-to-have)
- **Description, Input, Processing, Output, Validation**

---

### 3.1 Multi-Crop Lifecycle Tracking

#### FR-3.1.1 Create Crop Profile — P0

**Description:** Farmer creates a new crop tracking profile for a specific plot/field.

**Input fields:**

| Field | Type | Required | Validation |
|---|---|---|---|
| crop_type | Enum (6 values) | Yes | Must be one of: rice, tomato, groundnut, banana, onion, sugarcane |
| crop_variety | String | No | Max 50 chars; free text or picker from predefined list per crop type |
| sowing_date | Date | Yes | Must be ≤ today + 30 days; must be ≥ today − (crop total duration) |
| land_area | Real | Yes | > 0; ≤ 100 acres; displayed in acres, stored in acres |
| soil_type | Enum | No | One of: black, red, alluvial, sandy, laterite, unknown |
| irrigation_type | Enum | No | One of: rainfed, borewell, canal, drip, unknown |

**Processing:**
1. Load stage template from `assets/crops/{crop_type}.json`
2. Calculate `expected_harvest_date` = `sowing_date` + crop `total_duration_days` (midpoint of min/max range)
3. Instantiate one `growth_stage` record per stage in the template, computing `start_date` and `end_date` for each
4. Set `current_stage` = first stage (index 0)
5. Insert `crop_profile` record; insert all `growth_stage` records in a single transaction
6. Schedule Android local notifications for each stage transition (see §3.1.4)

**Output:**
- New crop card appears on the dashboard
- Full timeline is accessible by tapping the card
- Success toast in Tamil: "நெல் சேர்க்கப்பட்டது" ("Rice added")

**Validation errors (shown inline in Tamil):**
- Invalid sowing date → "விதைப்பு தேதி தவறானது"
- Duplicate crop (same type + overlapping date range on same farmer) → show warning, allow override
- Land area = 0 → "நிலப் பரப்பு சரியில்லை"

---

#### FR-3.1.2 View Crop Dashboard — P0

**Description:** Farmer sees all active crops at a glance on the home screen.

**Display requirements:**

Each crop card must show:
- Crop icon (image asset, one per crop type)
- Crop name in Tamil + variety (if set)
- Current growth stage name in Tamil
- Day counter: "Day 45 of 150"
- Progress bar: filled percentage = `days_elapsed / total_duration_days * 100`
- Days until next stage transition
- Alert badge (red dot) if any pending unread notification OR a low-confidence diagnosis is unresolved

**Ordering:**
1. Crops with active alerts (sorted by alert severity)
2. Crops approaching harvest (within 14 days), sorted by harvest date ascending
3. All other active crops, sorted by sowing date descending

**Empty state:** If no crops exist, display a single large CTA card: "உங்கள் முதல் பயிரை சேர்க்கவும்" ("Add your first crop") with icon and FAB.

---

#### FR-3.1.3 View Crop Timeline — P0

**Description:** Farmer taps a crop card to see the full stage-by-stage timeline.

**Timeline item states and visual treatment:**

| State | Visual |
|---|---|
| completed | Green filled circle + checkmark; stage name in muted text |
| active | Amber filled circle + pulsing ring; stage name in bold; expanded detail card below |
| upcoming | Grey outline circle; stage name in normal weight; date shown |

**Active stage expanded card shows:**
- Stage name (Tamil + English)
- Date range (start – end)
- Task checklist: each task is a tappable row with checkbox
- "Scan for disease" quick-action button
- "Log application" quick-action button (fertilizer/pesticide)
- List of past diagnoses made during this stage (thumbnail + disease name + date)

**Navigation from timeline:**
- Swipe left on a completed stage → opens full stage history
- Tap diagnosis thumbnail → opens full diagnosis detail screen
- Tap task checkbox → marks task complete; persists to `growth_stage.tasks_json`

---

#### FR-3.1.4 Stage-Based Reminders and Notifications — P0

**Description:** System pushes timely reminders based on the current growth stage of each crop.

**Trigger conditions and scheduling:**

| Trigger | When to Schedule | Notification Channel |
|---|---|---|
| Stage transition | At stage start date, time 07:00 local | `channel_stage_reminders` (importance: HIGH) |
| Scheduled activity | Per task `due_day` in stage template, time 07:00 | `channel_task_reminders` (importance: DEFAULT) |
| Harvest approaching | `expected_harvest_date` − 14 days, − 7 days, − 1 day | `channel_harvest_alerts` (importance: HIGH) |
| Weather-based alert | On receiving weather API data that triggers a condition | `channel_weather_alerts` (importance: HIGH) |

**Notification content generation:**
- Text is generated by Gemma 4 using the Stage Reminder Prompt Template (§8.2)
- Maximum 2-3 sentences
- Language matches `farmer_profile.preferred_language`
- Generated text is cached in the `notification_log` table to avoid re-generating on dismiss/reopen

**Android notification structure:**

```
Title:  "{crop_name_tamil} — {stage_name_tamil}"
Body:   "{gemma_generated_reminder_text}"
Actions:
  [கேட்கவும்]  → opens app and triggers TTS readout
  [செய்தேன்]   → marks all tasks for today as completed (inline action)
```

**Notification tap behavior:** Opens the specific crop's timeline screen with the active stage expanded.

**Scheduling implementation:**
- Use `flutter_local_notifications` with `AndroidScheduleMode.exactAllowWhileIdle`
- All notifications for a crop are (re)scheduled atomically when a crop profile is created or sowing date is edited
- Cancelled and rescheduled on crop deletion or archival

---

#### FR-3.1.5 Manage Multiple Crops — P0

**Description:** Farmer can track multiple crops simultaneously with independent timelines.

**Constraints:**
- Maximum 10 **active** crop profiles per farmer
- No limit on archived profiles
- Attempting to add an 11th active crop shows a dialog: "நீங்கள் 10 பயிர்களை கண்காணிக்கிறீர்கள். புதிதாக சேர்க்க ஒன்றை முடிக்கவும்." ("You are tracking 10 crops. Complete one to add a new one.")

**Archive behavior:**
- When `status` is set to `harvested` or `archived`, crop moves to a "History" section at bottom of dashboard
- Archived crops do not appear in active notifications
- Archived crop data is retained permanently for crop rotation analysis

---

#### FR-3.1.6 Edit Crop Profile — P1

**Description:** Farmer can modify crop details after creation.

**Editable fields:** sowing_date, land_area_acres, soil_type, irrigation_type, crop_variety

**Effects of editing `sowing_date`:**
1. All `growth_stage` start_date and end_date fields are recalculated
2. `expected_harvest_date` on `crop_profile` is recalculated
3. All scheduled notifications are cancelled and rescheduled
4. Current stage is recalculated based on the new dates and today's date

**Non-editable fields:** crop_type (changing the crop type would invalidate all stage data; user must delete and recreate)

---

#### FR-3.1.7 Delete Crop Profile — P1

**Description:** Farmer can remove a crop profile.

**Delete flow:**
1. Long-press on crop card → context menu → "நீக்கு" (Delete)
2. Confirmation bottom sheet in Tamil: "{crop_name} நீக்கப்படும். வரலாறு சேமிக்கப்படும்." ("{crop_name} will be deleted. History will be saved.")
3. Two options: "நீக்கு" (Delete / move to archive) | "ரத்து" (Cancel)
4. On confirm: set `status = 'archived'`; cancel all associated notifications

**True deletion (permanent):**
- Only accessible via Settings → Data Management → View Archive
- Permanent delete shows secondary confirmation
- Permanently deleted records are removed from all tables with CASCADE

---

### 3.2 Photo-Based Disease Diagnosis

#### FR-3.2.1 Capture and Diagnose — P0

**Description:** Farmer takes a photo of a diseased leaf/plant and receives a diagnosis with treatment.

**Input flow:**
1. Farmer taps "Scan" FAB from timeline or bottom navigation
2. Camera screen opens in portrait orientation
3. Guide overlay shows a crop-leaf-shaped boundary to help center the subject
4. Farmer taps capture button OR long-presses to select from gallery
5. Preview shown with "Diagnose" CTA and "Retake" option
6. On "Diagnose": processing begins with animated loading indicator

**Processing pipeline:**

```
[A] Image pre-processing (Dart/Flutter)
    - Resize to max 1024×1024 (maintain aspect ratio)
    - JPEG encode at 85% quality
    - Base64 encode for model input
    Latency: ~100ms

[B] RAG context assembly
    - Embed query: "crop disease diagnosis for {crop_type} at {stage_name}"
    - Top-5 disease embeddings retrieved from sqlite-vec
    - Context assembled (crop type, stage, top-5 chunks)
    Latency: ~250ms

[C] Gemma 4 E2B multimodal inference
    - Input: image (base64) + assembled text context
    - Output: structured JSON with disease name, confidence, symptoms, treatment
    Latency: 3-8s (hardware dependent)

[D] Response parsing and storage
    - Parse JSON response from model
    - Insert record into `diagnosis` table
    - Save image to app-private storage: `files/diagnoses/{crop_profile_id}/{timestamp}.jpg`
    Latency: ~50ms
```

**Gemma 4 output format (enforced via structured output / prompt constraint):**

```json
{
  "disease_name": "Rice Blast",
  "disease_name_tamil": "நெல் வெடிப்பு நோய்",
  "confidence": "high",
  "symptoms": "இலையில் வைர வடிவ புள்ளிகள்...",
  "cause": "Magnaporthe oryzae பூஞ்சை",
  "treatment_chemical": {
    "product": "Tricyclazole 75% WP",
    "dosage_per_litre": "0.6 g/L",
    "dosage_per_acre": "200 g/acre",
    "method": "Foliar spray",
    "timing": "Early morning or evening",
    "preharvest_interval_days": 14
  },
  "treatment_organic": {
    "product": "Pseudomonas fluorescens",
    "dosage": "5 g/L water",
    "method": "Foliar spray"
  },
  "safety_precautions": ["Wear gloves", "Avoid spraying near water bodies"],
  "stage_note": "At tillering stage, spray only if >10% leaves show symptoms"
}
```

**Confidence handling:**
- `"high"` — display full diagnosis with confidence indicator (green badge)
- `"medium"` — display diagnosis with amber badge + tip: "வேறு கோணத்தில் மீண்டும் படம் எடுக்கவும்" ("Try another angle for more accuracy")
- `"low"` — show partial diagnosis with red badge + strong recommendation to consult agricultural officer; show officer contact number for their district

**Offline guarantee:** The entire pipeline runs on-device; no network required.

---

#### FR-3.2.2 Diagnosis History — P0

**Description:** All past diagnoses for a crop are accessible from its timeline.

**Display:**
- Chronological list, newest first
- Each row: photo thumbnail (40×40 dp) | disease name (Tamil) | confidence badge | date
- Tap → full diagnosis detail screen (same as immediate post-diagnosis screen)
- If same disease appears ≥ 3 times in one season → show amber banner: "இந்த நோய் மீண்டும் வருகிறது. ஆழமான காரணத்தை கண்டறியவும்." ("This disease is recurring. Investigate underlying cause.")

---

#### FR-3.2.3 Proactive Disease Alerts — P1

**Description:** System proactively warns about common diseases as crop enters vulnerable stages.

**Trigger:** `growth_stage.status` changes to `active`

**Processing:**
- Load `vulnerable_diseases` array from crop stage template JSON
- For each vulnerable disease, check if cached weather data matches risk conditions (high humidity > 80%, temperature 25-30°C for fungal; dry + hot for pest)
- If conditions match OR no weather data available (default: send alert anyway for high-risk diseases)

**Notification content:**
```
Title: "{stage_name_tamil} — நோய் எச்சரிக்கை"
Body:  "உங்கள் {crop_name}க்கு {disease_name} வருவதற்கான சாத்தியம் உள்ளது.
        {visual_symptom_description}"
Actions: [படம் எடுக்கவும்] [பின்னர் பார்க்கவும்]
```

---

### 3.3 Pesticide and Fertilizer Guidance

#### FR-3.3.1 Stage-Based Fertilizer Schedule — P0

**Description:** System provides fertilizer recommendations for each growth stage.

**Data source:** Bundled in `assets/crops/{crop_type}.json` per stage; also retrievable via RAG for custom queries.

**Output per stage:**

| Field | Example |
|---|---|
| Fertilizer type | Urea (46% N) |
| Dosage | 25 kg/acre |
| Application method | Broadcast and incorporate |
| Timing | 21 days after transplanting |
| Organic alternative | Vermicompost 500 kg/acre |
| Notes | "Do not apply during waterlogging" |

**Display:** Fertilizer schedule shown as a card within each stage's detail in the timeline. Tapping expands to full dosage details and organic alternative.

---

#### FR-3.3.2 Safe Pesticide Recommendation — P0

**Description:** Following a disease diagnosis, system recommends precise pesticide usage.

**Source:** Generated by Gemma 4 as part of the diagnosis JSON (§3.2.1 output format).

**Required output fields:**
- Exact product name (generic active ingredient + commercial name if known)
- Dosage per litre of water
- Dosage per acre
- Spray equipment type (knapsack sprayer, power sprayer)
- Pre-harvest interval (days before harvest when spraying must stop)
- Protective equipment required
- Environmental safety note (keep away from water bodies, pollinators)
- Organic alternative (mandatory — always include even if less effective)

---

#### FR-3.3.3 Application Logging — P0

**Description:** Farmer logs each fertilizer/pesticide application.

**Quick-log flow from timeline:**
1. Tap "Log Application" button on active stage card
2. Bottom sheet with two tabs: "உரம்" (Fertilizer) | "பூச்சிக்கொல்லி" (Pesticide)
3. Fields: product_name (text or picker from recent), quantity, unit (kg/L/mL), date (default today)
4. Tap "சேமி" (Save) → inserts into `application_log` table

---

#### FR-3.3.4 Overuse Detection — P1

**Description:** System warns against excessive pesticide/fertilizer applications.

**Detection logic:**
```
For each crop_profile:
  aggregate application_log entries by (product_name, type) within current stage
  compare total quantity to max_safe_quantity from stage template
  if total > max_safe_quantity:
    trigger notification + in-app banner
```

**Warning message (Tamil):**
"அதிக பூச்சிக்கொல்லி பயன்படுத்தப்படுகிறது. இது மண் மற்றும் உடல் நலத்திற்கு தீங்கு விளைவிக்கும்."
("Excessive pesticide used. This harms soil and human health.")

---

### 3.4 Multilingual and Voice Support

#### FR-3.4.1 Tamil Language Interface — P0

**Description:** All UI text is in Tamil by default.

**Coverage:**
- All static strings in `assets/i18n/ta.json`
- All Gemma 4 generated content (prompt instructs Tamil output)
- Error messages, validation messages, toast notifications
- Crop names, stage names, disease names (stored in `_tamil` columns in DB)
- Notification titles and bodies

**String resource format (`assets/i18n/ta.json`):**
```json
{
  "dashboard.title": "என் பயிர்கள்",
  "dashboard.add_crop": "பயிர் சேர்",
  "crop.stage.active": "இப்போது: {stage_name}",
  "diagnosis.confidence.high": "அதிக நம்பிக்கை",
  ...
}
```

---

#### FR-3.4.2 Voice Input — P0

**Description:** Farmer can speak queries in Tamil instead of typing.

**STT Architecture — three-tier fallback:**

```
Tier 1 (Primary): Android SpeechRecognizer
  - Uses on-device Tamil language pack (Google speech services)
  - Zero extra download if Tamil pack installed
  - App checks for Tamil pack on first launch; prompts to install if missing
  - Intent: RecognizerIntent.ACTION_RECOGNIZE_SPEECH
    EXTRA_LANGUAGE = "ta-IN"
    EXTRA_MAX_RESULTS = 1

Tier 2 (Fallback — offline guaranteed):
  - Vosk Flutter plugin with bundled Tamil small model (~50 MB in assets/)
  - Activated automatically if SpeechRecognizer returns RESULT_NO_RESULTS
    or if network unavailable and Tamil pack not installed
  - Input: 16kHz mono PCM audio
  - Output: recognized text string

Tier 3 (Showcase — direct audio input to Gemma 4):
  - Raw audio bytes passed directly to flutter_gemma as multimodal input
  - Gemma 4 E2B processes audio natively without STT intermediary
  - Used for free-form queries ("என் நெல்லுக்கு என்ன பிரச்சனை?")
  - Not used for structured inputs (crop selection, date entry)
```

**UI indicator:** Microphone button shows red pulsing ring while recording; waveform visualization while processing.

---

#### FR-3.4.3 Voice Output — P0

**Description:** All AI-generated advice can be read aloud in Tamil.

**TTS implementation:**
- `flutter_tts` plugin wrapping Android TTS engine
- Language: `ta-IN` (Tamil India)
- On first launch: check if Google Tamil TTS voice is installed; prompt to install if missing
- Fallback: system default TTS voice (quality may be lower)

**Behaviour:**
- Auto-read toggle in Settings (default: OFF)
- When auto-read is ON: diagnosis results, stage reminders, and scheme alerts are read automatically on screen open
- Manual: each advice text block has a speaker icon button (24dp tap target → 48dp touch target)
- Speech speed: configurable in Settings (0.5× to 1.5×, default 0.9×)
- Stopping: pressing speaker icon again stops playback
- Screen-off protection: TTS playback pauses if screen is locked

---

#### FR-3.4.4 Language Switching — P1

**Description:** User can switch the app display language.

**MVP language support:**

| Language | UI Chrome | Gemma Generated Content |
|---|---|---|
| Tamil (ta) | Full | Full (primary, best quality) |
| English (en) | Full | Full |
| Telugu (te) | Tamil chrome only | Gemma 4 multilingual output |
| Kannada (kn) | Tamil chrome only | Gemma 4 multilingual output |

**Setting location:** Settings → "மொழி" (Language) → language picker  
**Effect:** Immediate; app restarts UI with new locale; Gemma prompts updated with new target language

---

### 3.5 Market Price Intelligence

#### FR-3.5.1 Fetch Live Mandi Prices — P0

**Description:** System fetches current market prices for the farmer's crops from nearby mandis.

**Trigger conditions:**
- Manual: farmer taps "Market Prices" on a crop card or from bottom navigation
- Automatic: when a crop's `current_stage` reaches the final stage (harvest imminent) and network is available

**API call via Gemma 4 function calling:**

```
Function: get_mandi_prices
Parameters:
  crop_commodity: string  (English name, e.g., "Rice", "Tomato")
  state: string           (default: "Tamil Nadu")
  district: string        (from farmer_profile.district)
  num_mandis: int         (default: 5)

Underlying endpoint:
  GET https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070
  ?api-key={API_KEY}
  &format=json
  &filters[commodity]={crop_commodity}
  &filters[state]={state}
  &filters[district]={district}
  &limit={num_mandis}
```

**Processing after API response:**
1. Parse JSON array of price records
2. Sort by `modal_price` descending
3. Compute distance from farmer's district to each mandi district (simple string match, not GPS)
4. Cache all records in `market_price_cache` table with `fetched_at = NOW()`
5. Pass price data to Gemma 4 Market Advice Prompt (§8.2) for Tamil recommendation

**Output display:**

| Mandi Name | Distance | Today's Price (₹/quintal) | Trend |
|---|---|---|---|
| Thanjavur | Same district | ₹2,450 | ↑ |
| Tiruchirappalli | 45 km | ₹2,280 | → |

Gemma 4 generated recommendation displayed below table (e.g., "தஞ்சாவூர் மண்டி இன்று சிறந்த விலை தருகிறது — ₹2,450/குவிண்டால்.")

**Offline behavior:**
- Query `market_price_cache` for entries with `fetched_at` within last 7 days
- Display with amber banner: "கடைசியாக புதுப்பிக்கப்பட்டது: {fetched_at_formatted}. புதிய விலைக்கு இணையத்துடன் இணைக்கவும்."

---

#### FR-3.5.2 Price Alerts — P1

**Description:** Notify farmer when mandi price for their crop reaches a set threshold.

**Configuration:**
- From Market Prices screen → "விலை எச்சரிக்கை அமை" (Set price alert)
- Input: minimum acceptable price (₹/quintal), freeform numeric
- Stored in `price_alert` table (crop_type, min_price, active: boolean)

**Check logic:**
- On each successful price fetch, compare max `modal_price` from results to `min_price`
- If `modal_price ≥ min_price` and `price_alert.active = true`:
  - Send notification: "விலை நிர்ணயம் எட்டியது! {mandi_name} இல் ₹{price} கிடைக்கிறது."
  - Set `price_alert.active = false` (one-time alert; farmer must re-enable)

---

### 3.6 Government Scheme Awareness

#### FR-3.6.1 Scheme Matching — P0

**Description:** System matches farmer profile against known government agricultural schemes.

**Eligibility evaluation inputs:**
- `farmer_profile.total_land_acres` → infer small/marginal classification
- `farmer_profile.state`, `farmer_profile.district`
- Active crop types from `crop_profile` table
- Derived: farmer is "small" if total_land_acres ≤ 5; "marginal" if ≤ 2.5

**Schemes bundled in v1.0:**

| Scheme ID | Scheme Name | Key Eligibility | Key Benefit |
|---|---|---|---|
| pm_kisan | PM-KISAN | Small/marginal farmer, own land | ₹6,000/year in 3 installments |
| pmfby | PMFBY (Crop Insurance) | Any farmer growing notified crops | Premium subsidy, crop loss coverage |
| tn_crop_loan | Tamil Nadu Crop Loan | TN-resident farmer | Low-interest crop loans |
| soil_health_card | Soil Health Card Scheme | Any farmer | Free soil testing + recommendations |

**Matching algorithm (RAG-based for nuanced eligibility):**
1. Retrieve top-3 scheme chunks from `scheme_embeddings` matching the farmer's profile summary
2. Gemma 4 evaluates eligibility per scheme based on retrieved details and farmer data
3. Result stored in `scheme_match` table with `eligibility_status` ∈ {eligible, likely_eligible, check_required}

**Output:**
- Schemes screen shows list sorted by: eligible → likely_eligible → check_required
- Each scheme card shows: name (Tamil), benefit summary, eligibility badge, deadline (if applicable)
- Tap to expand: full description, application steps (Gemma-generated, in Tamil), portal URL

---

#### FR-3.6.2 Scheme Deadline Alerts — P0

**Description:** Send timely notifications before scheme application deadlines.

**Schedule:**
- Alert at `deadline − 30 days` (reminder)
- Alert at `deadline − 7 days` (urgent)
- Alert at `deadline − 1 day` (final warning)

**Notification:**
```
Title: "{scheme_name_tamil} — கடைசி தேதி நெருங்குகிறது"
Body:  "{deadline_days} நாட்களில் விண்ணப்பிக்கும் தேதி முடிகிறது.
        சலுகை: {benefit_summary}"
Action: [விண்ணப்பிக்க வழிகள் பார்க்கவும்]
```

---

### 3.7 Post-Harvest Loss Prevention

#### FR-3.7.1 Harvest Readiness Alert — P0

**Description:** Notify farmer when crop is entering optimal harvest window.

**Trigger:** `days_to_harvest ∈ {14, 7, 1}` calculated from `expected_harvest_date`

**Readiness indicators (bundled per crop in template JSON):**

| Crop | Readiness Indicators |
|---|---|
| Rice | Grain moisture 20-22%; 90% spikelets golden yellow |
| Tomato | Full red colour; slight softness to touch |
| Groundnut | Inner pod wall turns dark; kernel fills pod |
| Banana | Fruit fingers round and plump; 75% colour break |

**Notification body:** "உங்கள் {crop_name} அறுவடைக்கு தயாராகிறது. {readiness_indicators}"

---

#### FR-3.7.2 Storage Guidance — P1

**Description:** After harvest is logged, provide post-harvest storage recommendations.

**Trigger:** Farmer taps "Harvest Complete" button on crop card or the final stage in timeline.

**Data source:** Bundled per-crop in template JSON; Gemma 4 generates detailed narrative in Tamil.

**Output fields:**
- Recommended storage container/method
- Maximum storage duration under recommended conditions
- Sell-by timeline with urgency level
- Value-addition options for short-shelf-life crops (sun-drying, processing)
- Common storage mistakes for that crop type

---

### 3.8 Soil Health and Crop Rotation

#### FR-3.8.1 Crop Rotation Recommendations — P1

**Description:** After harvest, suggest what to plant next based on soil history.

**Input:**
- All archived crop profiles for the same farmer (used as proxy for plot history)
- `soil_type` from crop profile
- Current calendar month (season)

**Rotation logic (Gemma 4 reasoning + bundled rules):**
- If last 2 crops were the same → strongly recommend rotation
- If last crop was a cereal → recommend legume (groundnut) to restore nitrogen
- If soil type = black + recent groundnut → recommend onion or tomato
- Output ranked list of 3 recommended crops with reasoning in Tamil

---

#### FR-3.8.2 Soil Health Score — P2

**Description:** Maintain a simple soil health score derived from farming practices.

**Score inputs:**
- Crop rotation adherence (rotated last season: +20 points)
- Organic fertilizer ratio (≥ 50% organic applications: +20 points)
- Pesticide frequency (< 3 applications/season per crop: +20 points)
- Legume cultivation in last 2 seasons (+20 points)
- Soil test done (Soil Health Card applied for: +20 points)

**Score bands:**

| Score | Band | Tamil Label | Colour |
|---|---|---|---|
| 80-100 | Good | நல்ல மண் ஆரோக்கியம் | Green |
| 50-79 | Fair | சராசரி மண் ஆரோக்கியம் | Amber |
| 0-49 | Poor | மண் ஆரோக்கியம் மோசம் | Red |

**Display:** Gauge widget on farmer profile screen with 1-line Tamil improvement tip.

---

## 4. Non-Functional Requirements

### 4.1 Performance

| Metric | CPU-only (4GB RAM) | NPU-equipped (6GB) |
|---|---|---|
| Text query (RAG + Gemma inference) | ≤ 5 seconds | ≤ 3 seconds |
| Image diagnosis (RAG + multimodal inference) | ≤ 8 seconds | ≤ 5 seconds |
| App cold start (to dashboard, model not loaded) | ≤ 4 seconds | ≤ 3 seconds |
| First model inference (includes lazy model load) | ≤ 15 seconds | ≤ 10 seconds |
| Subsequent inferences (model warm) | ≤ 5 seconds | ≤ 3 seconds |
| SQLite query (complex join, <10K rows) | < 100ms | < 100ms |
| Vector similarity search (sqlite-vec, 10K vectors) | < 200ms | < 200ms |
| Image pre-processing (resize + encode) | < 200ms | < 200ms |
| EmbeddingGemma (308M, one query) | ≤ 500ms | ≤ 300ms |

### 4.2 Storage and Size

| Component | Size |
|---|---|
| Gemma 4 E2B (INT4, `.litertlm`) | ~1.3 GB |
| EmbeddingGemma 308M (INT8) | ~200 MB |
| Crop knowledge base + vector index (sqlite-vec) | ~200 MB |
| Vosk Tamil STT fallback model | ~50 MB |
| SQLite database (empty at install) | < 1 MB |
| App APK (Flutter, uncompressed) | ~100 MB |
| **Total installed size** | **~1.85 GB** |
| Maximum database growth per year of active use | ~50 MB |
| Max single diagnosis image (compressed) | ~500 KB |

**Model download strategy:**
- App APK ships without model files (to stay under Play Store 100MB APK limit)
- On first launch: guided download screen in Tamil with progress bar
- Models downloaded over Wi-Fi preferred; warns on mobile data (estimated data cost shown)
- Models stored in app-private external storage: `Android/data/com.learnz.nilamai/files/models/`

### 4.3 Memory Management

**Model loading strategy:**
- Gemma 4 E2B is lazy-loaded: initialized on first inference request, not at app start
- EmbeddingGemma is lazy-loaded: initialized on first RAG query
- `flutter_gemma` plugin manages model lifecycle; do not re-initialize if already loaded
- On `ApplicationLifecycleState.paused`: model stays loaded (re-init is expensive)
- On `ApplicationLifecycleState.detached` (system kill): model unloaded by OS

**Low-memory handling:**
- Register `ComponentCallbacks2.onTrimMemory` listener
- On `TRIM_MEMORY_RUNNING_CRITICAL`: flush image cache, release non-essential bitmaps
- On `TRIM_MEMORY_COMPLETE`: unload EmbeddingGemma; reload on next query
- Never unload Gemma 4 E2B mid-inference (causes crash); complete or cancel current inference

### 4.4 Usability

| Requirement | Specification |
|---|---|
| Navigation depth | Maximum 3 taps from home to any feature |
| Touch target | Minimum 48×48 dp for all interactive elements |
| Body font size | Minimum 16 sp |
| Header font size | Minimum 20 sp |
| Contrast ratio | Minimum 4.5:1 (WCAG AA) for all text |
| Colour scheme | High contrast; optimised for outdoor sunlight visibility |
| Text input usage | Minimised; prefer pickers, dropdowns, voice |
| Onboarding | Voice-guided tutorial on first launch (skippable) |
| Loading indicators | Always show progress/spinner when operation > 300ms |

### 4.5 Reliability

| Requirement | Specification |
|---|---|
| Database atomicity | All multi-table writes use SQLite transactions; no partial state on crash |
| Crash rate target | < 1% of sessions |
| Model inference failure | Show user-friendly Tamil error; retry option; do not crash |
| Notification delivery | Use `exactAllowWhileIdle`; re-schedule on reboot via `BOOT_COMPLETED` receiver |
| Data persistence | All user data survives app restart, Android RAM kill, and OS update |
| Offline capability | 100% of core features (crop tracking, diagnosis, reminders, scheme info) work offline |

### 4.6 Battery Usage

| Operation | Target Maximum Power Draw |
|---|---|
| Gemma 4 inference (active) | ~4W (ARM CPU) / ~2W (NPU) — acceptable for 5s burst |
| Background notification scheduling | Negligible — local notifications only |
| Network sync (when online) | One-time batch per app open; no persistent polling |

No background AI inference. All model calls are user-initiated or notification-triggered foreground operations.

---

## 5. Data Model

### 5.1 Entity Relationship Diagram

```
farmer_profile (1)─────────────────has many───> crop_profile (N)
                └──────────────────has many───> scheme_match (N)
                └──────────────────has many───> price_alert (N)

crop_profile (1)────────────────────has many───> growth_stage (N)
             └──────────────────────has many───> diagnosis (N)
             └──────────────────────has many───> application_log (N)

growth_stage (1)────────────────────has many───> reminder_log (N)
diagnosis (1)───────────────────────has one ───> treatment_recommendation (embedded in diagnosis row)
```

### 5.2 SQLite Table Definitions

All tables use `INTEGER PRIMARY KEY AUTOINCREMENT` for surrogate keys. Timestamps use ISO-8601 TEXT format (`YYYY-MM-DDTHH:MM:SS`). Booleans use `INTEGER` (0/1).

---

#### Table: farmer_profile

```sql
CREATE TABLE farmer_profile (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  name                TEXT,                          -- Optional; farmer may prefer anonymity
  district            TEXT NOT NULL,                 -- Required for scheme matching and mandi search
  state               TEXT NOT NULL DEFAULT 'Tamil Nadu',
  total_land_acres    REAL NOT NULL CHECK (total_land_acres > 0),
  preferred_language  TEXT NOT NULL DEFAULT 'ta'     -- ISO 639-1 code: ta, en, te, kn
    CHECK (preferred_language IN ('ta', 'en', 'te', 'kn')),
  created_at          TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at          TEXT NOT NULL DEFAULT (datetime('now'))
);
-- Note: single-farmer app (v1.0); table will always have exactly one row
```

---

#### Table: crop_profile

```sql
CREATE TABLE crop_profile (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  farmer_id             INTEGER NOT NULL REFERENCES farmer_profile(id) ON DELETE CASCADE,
  crop_type             TEXT NOT NULL
    CHECK (crop_type IN ('rice','tomato','groundnut','banana','onion','sugarcane')),
  crop_variety          TEXT,                         -- e.g., 'Ponni', 'Samba', null if unknown
  sowing_date           TEXT NOT NULL,                -- DATE as TEXT 'YYYY-MM-DD'
  expected_harvest_date TEXT NOT NULL,                -- Calculated: sowing_date + crop_duration_mid
  land_area_acres       REAL NOT NULL CHECK (land_area_acres > 0),
  soil_type             TEXT DEFAULT 'unknown'
    CHECK (soil_type IN ('black','red','alluvial','sandy','laterite','unknown')),
  irrigation_type       TEXT DEFAULT 'unknown'
    CHECK (irrigation_type IN ('rainfed','borewell','canal','drip','unknown')),
  current_stage         TEXT NOT NULL,                -- FK-like reference to growth_stage.stage_name
  status                TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active','harvested','archived')),
  created_at            TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at            TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_crop_profile_farmer_status ON crop_profile(farmer_id, status);
CREATE INDEX idx_crop_profile_harvest_date  ON crop_profile(expected_harvest_date);
```

---

#### Table: growth_stage

```sql
CREATE TABLE growth_stage (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  crop_profile_id   INTEGER NOT NULL REFERENCES crop_profile(id) ON DELETE CASCADE,
  stage_index       INTEGER NOT NULL,               -- 0-based order within this crop's lifecycle
  stage_name        TEXT NOT NULL,                  -- Canonical English identifier
  stage_name_tamil  TEXT NOT NULL,
  start_date        TEXT NOT NULL,                  -- 'YYYY-MM-DD'
  end_date          TEXT NOT NULL,                  -- 'YYYY-MM-DD'
  status            TEXT NOT NULL DEFAULT 'upcoming'
    CHECK (status IN ('upcoming','active','completed')),
  tasks_json        TEXT NOT NULL DEFAULT '[]',     -- JSON array of task objects
  completed_at      TEXT,                           -- Actual completion timestamp (nullable)
  UNIQUE (crop_profile_id, stage_index)
);
-- tasks_json element schema:
-- {"id": "uuid", "label": "string", "label_tamil": "string",
--  "due_day": int, "completed": bool, "completed_at": "timestamp|null"}

CREATE INDEX idx_growth_stage_crop_status ON growth_stage(crop_profile_id, status);
```

---

#### Table: diagnosis

```sql
CREATE TABLE diagnosis (
  id                      INTEGER PRIMARY KEY AUTOINCREMENT,
  crop_profile_id         INTEGER NOT NULL REFERENCES crop_profile(id) ON DELETE CASCADE,
  growth_stage_id         INTEGER REFERENCES growth_stage(id) ON DELETE SET NULL,
  stage_at_diagnosis      TEXT NOT NULL,            -- Stage name snapshot at time of diagnosis
  photo_path              TEXT,                     -- Relative path: diagnoses/{crop_id}/{timestamp}.jpg
  disease_name            TEXT,                     -- English name; null if inconclusive
  disease_name_tamil      TEXT,
  confidence              TEXT NOT NULL DEFAULT 'low'
    CHECK (confidence IN ('high','medium','low','inconclusive')),
  symptoms_tamil          TEXT,
  cause                   TEXT,
  treatment_chemical_json TEXT,                     -- JSON matching treatment_chemical schema
  treatment_organic_json  TEXT,                     -- JSON matching treatment_organic schema
  dosage_details          TEXT,
  safety_precautions_json TEXT,                     -- JSON array of precaution strings
  stage_note_tamil        TEXT,
  raw_model_response      TEXT,                     -- Full Gemma 4 JSON output for debugging
  diagnosed_at            TEXT NOT NULL DEFAULT (datetime('now'))
);
-- treatment_chemical_json schema:
-- {"product": str, "dosage_per_litre": str, "dosage_per_acre": str,
--  "method": str, "timing": str, "preharvest_interval_days": int}

CREATE INDEX idx_diagnosis_crop_date ON diagnosis(crop_profile_id, diagnosed_at DESC);
```

---

#### Table: application_log

```sql
CREATE TABLE application_log (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  crop_profile_id       INTEGER NOT NULL REFERENCES crop_profile(id) ON DELETE CASCADE,
  growth_stage_id       INTEGER REFERENCES growth_stage(id) ON DELETE SET NULL,
  type                  TEXT NOT NULL CHECK (type IN ('fertilizer','pesticide')),
  product_name          TEXT NOT NULL,
  quantity              REAL NOT NULL CHECK (quantity > 0),
  unit                  TEXT NOT NULL CHECK (unit IN ('kg','g','L','mL')),
  stage_at_application  TEXT NOT NULL,
  applied_at            TEXT NOT NULL DEFAULT (date('now')),  -- 'YYYY-MM-DD'
  notes                 TEXT
);

CREATE INDEX idx_application_crop_date ON application_log(crop_profile_id, applied_at DESC);
```

---

#### Table: scheme_match

```sql
CREATE TABLE scheme_match (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  farmer_id             INTEGER NOT NULL REFERENCES farmer_profile(id) ON DELETE CASCADE,
  scheme_id             TEXT NOT NULL,              -- Matches bundled scheme config key
  scheme_name           TEXT NOT NULL,
  scheme_name_tamil     TEXT NOT NULL,
  eligibility_status    TEXT NOT NULL
    CHECK (eligibility_status IN ('eligible','likely_eligible','check_required')),
  benefit_summary_tamil TEXT,
  application_deadline  TEXT,                       -- 'YYYY-MM-DD'; null if rolling
  application_steps_tamil TEXT,
  notified_30d          INTEGER NOT NULL DEFAULT 0, -- Boolean
  notified_7d           INTEGER NOT NULL DEFAULT 0,
  notified_1d           INTEGER NOT NULL DEFAULT 0,
  last_refreshed_at     TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE (farmer_id, scheme_id)
);
```

---

#### Table: market_price_cache

```sql
CREATE TABLE market_price_cache (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  crop_type         TEXT NOT NULL,                  -- Canonical crop type key
  mandi_name        TEXT NOT NULL,
  mandi_district    TEXT NOT NULL,
  mandi_state       TEXT NOT NULL DEFAULT 'Tamil Nadu',
  price_min         REAL,                           -- ₹/quintal
  price_max         REAL,
  price_modal       REAL NOT NULL,                  -- ₹/quintal (use for display)
  price_trend       TEXT CHECK (price_trend IN ('up','down','stable','unknown')),
  fetched_at        TEXT NOT NULL,
  UNIQUE (crop_type, mandi_name, fetched_at)
);

CREATE INDEX idx_price_cache_crop_date ON market_price_cache(crop_type, fetched_at DESC);
```

---

#### Table: price_alert

```sql
CREATE TABLE price_alert (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  farmer_id         INTEGER NOT NULL REFERENCES farmer_profile(id) ON DELETE CASCADE,
  crop_type         TEXT NOT NULL,
  min_price_inr     REAL NOT NULL CHECK (min_price_inr > 0),
  active            INTEGER NOT NULL DEFAULT 1,
  created_at        TEXT NOT NULL DEFAULT (datetime('now')),
  triggered_at      TEXT,                           -- Timestamp when alert fired; null if not yet
  UNIQUE (farmer_id, crop_type)
);
```

---

#### Table: notification_log

```sql
CREATE TABLE notification_log (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  notification_type   TEXT NOT NULL,                -- stage_transition | task_due | harvest | scheme | price
  related_entity_type TEXT,                         -- crop_profile | scheme_match | price_alert
  related_entity_id   INTEGER,
  title               TEXT NOT NULL,
  body                TEXT NOT NULL,
  android_notif_id    INTEGER UNIQUE,               -- Android notification ID for cancellation
  scheduled_for       TEXT,
  sent_at             TEXT,
  dismissed_at        TEXT,
  tapped_at           TEXT
);
```

---

### 5.3 Vector Database Schema (sqlite-vec)

sqlite-vec is loaded as a SQLite runtime extension via `sqflite_common_ffi`. All vector tables use `vec_float32` virtual table type.

**Embedding dimension:** 768 (EmbeddingGemma output). If the embedding model changes, all embedding tables must be regenerated.

---

#### Virtual Table: disease_embeddings

```sql
CREATE VIRTUAL TABLE disease_embeddings USING vec0(
  id              INTEGER PRIMARY KEY,
  crop_type       TEXT PARTITION KEY,               -- Partition for faster filtered search
  embedding       float[768]
);
-- Companion metadata table (non-vector data):
CREATE TABLE disease_metadata (
  id              INTEGER PRIMARY KEY,              -- Matches disease_embeddings.id
  crop_type       TEXT NOT NULL,
  disease_name    TEXT NOT NULL,
  disease_name_tamil TEXT,
  content_chunk   TEXT NOT NULL,                    -- The text that was embedded
  severity        TEXT CHECK (severity IN ('low','medium','high','critical')),
  vulnerable_stages_json TEXT,                      -- JSON array of stage names
  metadata_json   TEXT                              -- Additional structured metadata
);
CREATE INDEX idx_disease_meta_crop ON disease_metadata(crop_type);
```

---

#### Virtual Table: treatment_embeddings

```sql
CREATE VIRTUAL TABLE treatment_embeddings USING vec0(
  id              INTEGER PRIMARY KEY,
  disease_id      INTEGER,
  embedding       float[768]
);
CREATE TABLE treatment_metadata (
  id              INTEGER PRIMARY KEY,
  disease_id      INTEGER NOT NULL REFERENCES disease_metadata(id),
  content_chunk   TEXT NOT NULL,
  treatment_type  TEXT CHECK (treatment_type IN ('chemical','organic','integrated')),
  metadata_json   TEXT
);
```

---

#### Virtual Table: stage_care_embeddings

```sql
CREATE VIRTUAL TABLE stage_care_embeddings USING vec0(
  id              INTEGER PRIMARY KEY,
  crop_type       TEXT PARTITION KEY,
  stage_name      TEXT,
  embedding       float[768]
);
CREATE TABLE stage_care_metadata (
  id              INTEGER PRIMARY KEY,
  crop_type       TEXT NOT NULL,
  stage_name      TEXT NOT NULL,
  content_chunk   TEXT NOT NULL,
  content_type    TEXT CHECK (content_type IN ('fertilizer','pest_watch','irrigation','general')),
  metadata_json   TEXT
);
CREATE INDEX idx_stage_care_crop_stage ON stage_care_metadata(crop_type, stage_name);
```

---

#### Virtual Table: scheme_embeddings

```sql
CREATE VIRTUAL TABLE scheme_embeddings USING vec0(
  id              INTEGER PRIMARY KEY,
  embedding       float[768]
);
CREATE TABLE scheme_metadata (
  id              INTEGER PRIMARY KEY,
  scheme_id       TEXT NOT NULL,
  scheme_name     TEXT NOT NULL,
  content_chunk   TEXT NOT NULL,
  eligibility_criteria_json TEXT,
  benefit_summary TEXT,
  deadline_info   TEXT,
  metadata_json   TEXT
);
```

---

### 5.4 SQLite Initialization and Migration

**Database filename:** `nilamai_v1.db`  
**Location:** App-private internal storage (not accessible without root)

**Migration strategy:**
- Schema version tracked in SQLite `PRAGMA user_version`
- `DatabaseMigrationRunner` class applies sequential migrations on open
- Migrations are append-only (never destructive in production)
- Migration scripts stored in `assets/db/migrations/migration_00X.sql`

**Initialization sequence on first install:**
1. Copy empty schema from assets to app files directory
2. Load sqlite-vec extension: `db.execute("SELECT load_extension('vec0')")`
3. Run all pending migrations
4. Seed initial data: insert one default `farmer_profile` row (district = "Unknown"; user completes profile in onboarding)
5. Load and index crop knowledge base from `assets/knowledge/` into vector tables

---

## 6. External Interface Requirements

### 6.1 User Interface Screens

#### UI-6.1.1 Home Screen / Dashboard

**Layout:**
- `AppBar`: app logo left | notification bell icon right (badge count of unread alerts)
- `Body`: `ListView` of crop cards + archived crops section at bottom (collapsed by default)
- `FloatingActionButton`: "+" icon → create crop flow
- `BottomNavigationBar`: 4 items — Home | Scan | Market | Schemes

**Crop card widget spec:**
```
┌─────────────────────────────────────────┐
│ [crop icon 48dp]  நெல் — பொன்னி         │
│                   Day 45 of 150          │
│ [████████████░░░░░░░] 30%               │
│ Stage: தூர் கட்டுதல் (Tillering)        │
│ Next stage in 12 days                   │
│ [Alert badge if applicable]             │
└─────────────────────────────────────────┘
```
Minimum card height: 96 dp. Horizontal padding: 16 dp.

---

#### UI-6.1.2 Crop Detail / Timeline Screen

**Layout:**
- `AppBar`: crop name + variety | edit icon | delete icon (overflow menu)
- `Body`: scrollable `Column` with:
  - Crop summary card (area, soil type, irrigation type, sowing date)
  - Vertical timeline (`ListView` of stage items)
- `BottomSheet` (persistent, collapsed): quick actions — Scan | Log | Advice

**Stage item heights:**
- Completed stage (collapsed): 56 dp
- Upcoming stage (collapsed): 56 dp
- Active stage (expanded): variable ~200 dp (task list expands)

---

#### UI-6.1.3 Camera / Diagnosis Screen

**Layout:**
- Full-screen `CameraPreview` widget
- Overlay: semi-transparent border with leaf guide shape
- Bottom bar (80 dp): gallery icon left | capture button (64 dp circle) center | flash toggle right
- After capture: preview screen with "Diagnose" (primary CTA) + "Retake" (secondary)
- Loading state: full-screen spinner with Tamil text "நோய் ஆராய்கிறேன்..." (Diagnosing...)
- Results: scrollable card with disease name, confidence badge, symptoms, treatment tabs (Chemical | Organic)

---

#### UI-6.1.4 Market Prices Screen

**Layout:**
- `AppBar`: "சந்தை விலை" (Market Prices)
- Crop selector: horizontal `ChoiceChip` row for each active crop
- Price table: `DataTable` (mandi name, price, trend arrow)
- Recommendation card: Gemma 4 Tamil text below table (amber background)
- Last updated footer: grey caption text
- Pull-to-refresh triggers new API fetch (if online)

---

#### UI-6.1.5 Schemes Screen

**Layout:**
- `AppBar`: "அரசு திட்டங்கள்" (Government Schemes)
- Filter chips: All | Eligible | Upcoming Deadlines
- Scheme cards: `ExpansionTile` — collapsed shows name + eligibility badge; expanded shows benefit, steps, deadline countdown

---

#### UI-6.1.6 Settings Screen

**Layout:**
- `AppBar`: "அமைப்புகள்" (Settings)
- Sections (grouped `ListTile` rows):
  - **Profile**: district, land area, language
  - **Voice**: auto-read toggle, speech speed slider
  - **Notifications**: per-channel toggles
  - **Data**: model download status, re-download option, export CSV, clear cache, delete all data

---

### 6.2 Hardware Interfaces

| Interface | Flutter API | Usage |
|---|---|---|
| Rear camera | `camera` plugin | Capture leaf/plant images for diagnosis |
| Microphone | `speech_to_text` / Vosk | Voice input for Tamil queries |
| Speaker | `flutter_tts` | Voice output for Tamil advice |
| Internal storage | `path_provider` | Model files, SQLite DB, diagnosis images |
| External storage | `path_provider` (getExternalStorageDirectory) | Large model downloads |
| Network (Wi-Fi/mobile) | `connectivity_plus` + `dio` | Market prices, weather, scheme updates |

### 6.3 Software Interface Specifications

#### 6.3.1 AgMarknet OGD REST API

**Base URL:** `https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070`  
**Auth:** API key in query parameter `?api-key={KEY}`  
**Method:** GET  
**Key query parameters:**

| Parameter | Type | Description |
|---|---|---|
| format | string | Always "json" |
| filters[commodity] | string | Crop commodity name in English |
| filters[state] | string | State name (e.g., "Tamil Nadu") |
| filters[district] | string | Farmer's district |
| limit | integer | Max records to return (default: 10) |

**Response schema:**
```json
{
  "status": "ok",
  "total": 42,
  "records": [
    {
      "state": "Tamil Nadu",
      "district": "Thanjavur",
      "market": "Thanjavur",
      "commodity": "Rice",
      "variety": "Common",
      "arrival_date": "16/04/2026",
      "min_price": "2100",
      "max_price": "2500",
      "modal_price": "2350"
    }
  ]
}
```

**Error handling:**
- HTTP 401: invalid API key → show message "சந்தை விலை சேவை தற்காலிகமாக கிடைக்கவில்லை"; display cached data
- HTTP 429: rate limited → exponential backoff (1s, 2s, 4s); max 3 retries
- HTTP 5xx: show cached data with staleness warning
- Timeout (10s): treat as offline; show cached data

---

#### 6.3.2 OpenWeather API (Optional)

**Endpoint:** `https://api.openweathermap.org/data/2.5/forecast`  
**Parameters:** `q={district},IN&appid={KEY}&units=metric&cnt=5`  
**Used for:** Irrigation advice, disease risk assessment  
**Offline fallback:** Skip weather context in prompts; omit from notification body

---

#### 6.3.3 Android Local Notification Service

**Plugin:** `flutter_local_notifications` v16+  
**Channels defined at startup:**

| Channel ID | Name (Tamil) | Importance | Vibration |
|---|---|---|---|
| channel_stage_reminders | கட்ட நினைவூட்டல்கள் | HIGH | Yes |
| channel_task_reminders | வேலை நினைவூட்டல்கள் | DEFAULT | No |
| channel_harvest_alerts | அறுவடை எச்சரிக்கைகள் | HIGH | Yes |
| channel_weather_alerts | வானிலை எச்சரிக்கைகள் | HIGH | Yes |
| channel_scheme_alerts | திட்ட நினைவூட்டல்கள் | DEFAULT | No |
| channel_price_alerts | விலை எச்சரிக்கைகள் | DEFAULT | No |

**Reboot persistence:**
- Register `BOOT_COMPLETED` BroadcastReceiver in `AndroidManifest.xml`
- On boot: query all active crop profiles; re-schedule all pending notifications

---

### 6.4 Communication Interfaces

- All outbound HTTP via `dio` with certificate pinning for `api.data.gov.in`
- HTTP timeout: connect 5s, receive 10s
- Retry policy: 3 attempts with exponential backoff for 5xx and network errors
- Caching: `dio_cache_interceptor` with SQLite cache store; max-age 6 hours for prices, 24 hours for weather
- No WebSockets; no persistent connections; no push notification service (all local)

---

## 7. Technology Stack

### 7.1 Complete Dependency List

| Category | Package | Version | Purpose |
|---|---|---|---|
| Framework | Flutter | ≥ 3.24 (stable) | Cross-platform UI |
| Language | Dart | ≥ 3.5 | Application logic |
| Navigation | `go_router` | ^14.0.0 | Declarative routing + deep links |
| State | `flutter_riverpod` | ^2.5.0 | Scalable, compile-safe state management |
| AI (Production) | `flutter_gemma` | latest | LiteRT-LM wrapper; Gemma 4 + FunctionGemma |
| AI (Development) | `dio` | ^5.4.0 | Ollama HTTP client |
| SQLite | `sqflite` | ^2.3.0 | Structured data persistence |
| SQLite FFI | `sqflite_common_ffi` | ^2.3.0 | Required for sqlite-vec extension loading |
| Vector DB | `sqlite-vec` (native) | ^0.1.6 | C extension, bundled as `.so` in android/jniLibs |
| Camera | `camera` | ^0.11.0 | Crop image capture |
| Image picker | `image_picker` | ^1.1.0 | Gallery selection |
| STT (primary) | `speech_to_text` | ^7.0.0 | Android SpeechRecognizer Tamil |
| STT (fallback) | `vosk_flutter` | ^0.3.0 | Offline Vosk Tamil model |
| TTS | `flutter_tts` | ^4.0.0 | Android TTS Tamil voice |
| Notifications | `flutter_local_notifications` | ^17.0.0 | Scheduled local notifications |
| Connectivity | `connectivity_plus` | ^6.0.0 | Network state detection |
| Caching | `dio_cache_interceptor` | ^3.5.0 | HTTP response caching |
| Path | `path_provider` | ^2.1.0 | App/external storage paths |
| Localization | `flutter_localizations` | SDK | l10n support |
| Permissions | `permission_handler` | ^11.3.0 | Runtime permissions (camera, mic) |
| Logging | `logger` | ^2.4.0 | Structured debug logging |
| Testing | `flutter_test` | SDK | Unit + widget tests |
| Testing | `mockito` | ^5.4.0 | Mock generation |
| Testing | `integration_test` | SDK | End-to-end device tests |

### 7.2 Build Flavors

**`dev` flavor:**
- Uses Ollama HTTP API for Gemma 4 inference (host: `10.0.2.2:11434` in emulator, `192.168.x.x:11434` on physical device)
- App bundle ID: `com.learnz.nilamai.dev`
- Shows developer banner in corner

**`prod` flavor:**
- Uses `flutter_gemma` + LiteRT-LM for fully on-device inference
- App bundle ID: `com.learnz.nilamai`
- No developer tools exposed

**Build commands:**
```bash
flutter run  --flavor dev  -t lib/main_dev.dart
flutter run  --flavor prod -t lib/main_prod.dart
flutter build apk --flavor prod -t lib/main_prod.dart --release
```

### 7.3 Ollama Integration (Development)

Ollama serves as the Gemma 4 runtime during development and local testing.

**Local setup:**
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull gemma4:e2b
ollama serve
# Confirm: curl http://localhost:11434/api/tags
```

**Flutter/Dart client (`lib/services/ollama_client.dart`):**
```dart
class OllamaClient {
  final Dio _dio;
  final String _baseUrl;

  OllamaClient({String baseUrl = 'http://10.0.2.2:11434'})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 60),
        ));

  Future<String> generate({
    required String prompt,
    String? base64Image,
    String model = 'gemma4:e2b',
  }) async {
    final response = await _dio.post('/api/generate', data: {
      'model': model,
      'prompt': prompt,
      if (base64Image != null) 'images': [base64Image],
      'stream': false,
      'options': {'temperature': 0.3, 'num_predict': 300},
    });
    return response.data['response'] as String;
  }
}
```

### 7.4 LiteRT Integration (Production)

**Model file:** `gemma-4-E2B-it-litert-lm.bin` (INT4, `.litertlm` format)  
**Source:** `litert-community/gemma-4-E2B-it-litert-lm` on Hugging Face  
**Storage location:** `{externalStorageDir}/models/gemma4_e2b.bin`

**Initialization (`lib/services/gemma_service.dart`):**
```dart
class GemmaService {
  GemmaModel? _model;
  bool _isLoaded = false;

  Future<void> initialize(String modelPath) async {
    if (_isLoaded) return;
    _model = await GemmaModel.init(
      modelPath: modelPath,
      maxTokens: 600,    // RAG context budget
      temperature: 0.3,
      topK: 40,
    );
    _isLoaded = true;
  }

  Future<String> infer(String prompt, {Uint8List? imageBytes}) async {
    assert(_isLoaded, 'Model not initialized');
    if (imageBytes != null) {
      return await _model!.generateWithImage(
        prompt: prompt,
        image: imageBytes,
        maxNewTokens: 300,
      );
    }
    return await _model!.generate(
      prompt: prompt,
      maxNewTokens: 300,
    );
  }

  void dispose() {
    _model?.dispose();
    _isLoaded = false;
  }
}
```

**NPU delegate selection:** Managed automatically by LiteRT-LM; priority order: NPU → GPU → CPU. No manual delegate selection required in application code.

### 7.5 Unsloth Fine-Tuning (Optional Improvement)

Fine-tuning Gemma 4 E2B on Tamil crop disease data improves diagnosis accuracy for South Indian-specific diseases.

**Pipeline:**
```
Base model: Gemma 4 E2B (from HuggingFace)
    ↓
Dataset preparation:
  - PlantVillage (54,000+ images) → image-caption pairs
  - Custom Tamil agricultural Q&A (manually curated, ~2,000 pairs)
    ↓
LoRA fine-tuning via Unsloth (Google Colab A100 / T4):
  - Rank: 16, Alpha: 32
  - Target modules: q_proj, v_proj
  - Learning rate: 2e-4, epochs: 3
  - Batch size: 4 (gradient accumulation: 4)
    ↓
Adapter merge + quantize to INT4 .litertlm format
    ↓
Publish to HuggingFace under Apache 2.0
```

**Expected accuracy improvement:**
- Disease diagnosis top-3 accuracy: ~75% (base) → ~90%+ (fine-tuned on regional data)

---

## 8. AI Integration Specification

### 8.1 Model Configuration

| Parameter | Value | Rationale |
|---|---|---|
| Model | Gemma 4 E2B instruction-tuned | Best accuracy/size tradeoff for edge; multimodal |
| Quantization | INT4 (LiteRT mobile standard) | ~1.3 GB on-disk; fits in 3 GB runtime |
| Context window (Gemma 4) | 128K tokens supported | Capped at 600 in app for latency |
| Max input tokens (app) | 600 | Achieves ≤5s latency on 4GB devices |
| Max output tokens | 300 | Sufficient for advisory + diagnosis text |
| Temperature | 0.3 | Factual, consistent agricultural advice |
| Top-K | 40 | Balanced diversity; avoids hallucination |
| Repeat penalty | 1.1 | Prevent repetitive output in Tamil |

### 8.2 Prompt Templates

All prompts are rendered server-side (in Dart) by substituting `{variable}` placeholders before sending to the model. Prompts are defined in `assets/prompts/` as `.txt` files.

---

#### Prompt: disease_diagnosis.txt

```
[System]
You are NilamAI (நிலம்AI), an agricultural advisor for Tamil Nadu farmers.
Always respond in {language}. Be specific about product names and dosages.
Format your response as JSON matching the schema exactly. Do not add commentary outside the JSON.

[Schema]
{
  "disease_name": "string (English)",
  "disease_name_tamil": "string (Tamil)",
  "confidence": "high | medium | low | inconclusive",
  "symptoms": "string (Tamil description)",
  "cause": "string",
  "treatment_chemical": {
    "product": "string", "dosage_per_litre": "string",
    "dosage_per_acre": "string", "method": "string",
    "timing": "string", "preharvest_interval_days": number
  },
  "treatment_organic": {
    "product": "string", "dosage": "string", "method": "string"
  },
  "safety_precautions": ["string"],
  "stage_note": "string (Tamil)"
}

[Context]
Crop: {crop_type} ({crop_variety})
Current stage: {stage_name_tamil} (Day {days_since_sowing} of {total_duration})
Season: {current_season}
Retrieved knowledge:
{rag_chunks}

[User]
This photo shows a problem with my {crop_type} plant.
{image_input}
What disease is this and how should I treat it?
```

---

#### Prompt: stage_reminder.txt

```
[System]
You are NilamAI (நிலம்AI). Write a practical, encouraging farming reminder in {language}.
Maximum 3 sentences. Plain language. No jargon. No JSON — plain text only.

[Context]
Crop: {crop_name_tamil} ({crop_type})
Current stage: {stage_name_tamil}
Day {day_in_stage} of {total_stage_days} in this stage
Tasks due today: {tasks_json}
Weather (if available): {weather_summary}

Write a 2-3 sentence reminder about what the farmer should do today and why it matters.
```

---

#### Prompt: market_advice.txt

```
[System]
You are NilamAI (நிலம்AI). Advise the farmer on when and where to sell their crop.
Respond in {language}. Maximum 3 sentences. Be specific about price differences.

[Context]
Crop: {crop_type}
Days until harvest: {days_to_harvest}
Market prices (today):
{mandi_price_table}

Compare the prices and recommend the best mandi. Mention price difference in rupees.
```

---

#### Prompt: scheme_eligibility.txt

```
[System]
You are NilamAI (நிலம்AI). Evaluate government scheme eligibility for this farmer.
Respond in {language}.
For each scheme below, state: eligible | likely_eligible | check_required
Then list application steps in simple numbered points.

[Farmer profile]
Land: {total_land_acres} acres
State: {state}, District: {district}
Crops: {active_crops}
Category: {farmer_category}

[Retrieved scheme information]
{rag_chunks}

For each scheme, provide:
1. Eligibility verdict
2. Key reason
3. Application steps (numbered)
4. Deadline (if known)
```

---

#### Prompt: crop_rotation_advice.txt

```
[System]
You are NilamAI (நிலம்AI). Recommend the next crop to plant.
Respond in {language}. Give top 3 recommendations ranked by soil benefit.

[Context]
Soil type: {soil_type}
Current season: {current_season}
Crop history (most recent first):
{crop_history}

For each recommended crop, give:
1. Crop name (Tamil + English)
2. Why it benefits the soil
3. Expected duration
4. Key income potential
```

---

### 8.3 Function Calling Definitions

Gemma 4 function calling is used for all external API access. Functions are defined using the `FunctionGemma` API in `flutter_gemma`.

#### Function: get_mandi_prices

```json
{
  "name": "get_mandi_prices",
  "description": "Fetch current market prices for an agricultural commodity from government mandi markets",
  "parameters": {
    "type": "object",
    "properties": {
      "crop_commodity": {
        "type": "string",
        "description": "Crop commodity name in English (e.g., 'Rice', 'Tomato', 'Groundnut')"
      },
      "state": {
        "type": "string",
        "description": "State name (default: 'Tamil Nadu')",
        "default": "Tamil Nadu"
      },
      "district": {
        "type": "string",
        "description": "Farmer's district name for nearest mandi search"
      },
      "num_mandis": {
        "type": "integer",
        "description": "Number of mandis to query",
        "default": 5,
        "minimum": 1,
        "maximum": 10
      }
    },
    "required": ["crop_commodity", "district"]
  }
}
```

#### Function: get_weather_forecast

```json
{
  "name": "get_weather_forecast",
  "description": "Fetch 5-day weather forecast for the farmer's location for irrigation planning",
  "parameters": {
    "type": "object",
    "properties": {
      "district": {
        "type": "string",
        "description": "District name in Tamil Nadu"
      },
      "days": {
        "type": "integer",
        "description": "Number of forecast days (1-5)",
        "default": 5,
        "minimum": 1,
        "maximum": 5
      }
    },
    "required": ["district"]
  }
}
```

### 8.4 Response Validation

All Gemma 4 outputs that are expected in JSON format are validated before use:

```dart
class GemmaResponseValidator {
  static DiagnosisResult? parseDiagnosisResponse(String rawResponse) {
    try {
      // Extract JSON from response (model may add surrounding text)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(rawResponse);
      if (jsonMatch == null) return null;
      final json = jsonDecode(jsonMatch.group(0)!);

      // Validate required fields
      final requiredFields = ['disease_name', 'confidence', 'symptoms'];
      for (final field in requiredFields) {
        if (!json.containsKey(field)) return null;
      }

      // Validate confidence is a known enum value
      final validConfidence = {'high', 'medium', 'low', 'inconclusive'};
      if (!validConfidence.contains(json['confidence'])) {
        json['confidence'] = 'low'; // Downgrade to safe default
      }

      return DiagnosisResult.fromJson(json);
    } catch (e) {
      // JSON parse failure → return null → trigger error handling
      return null;
    }
  }
}
```

**Fallback on invalid response:**
- Show user-friendly Tamil message: "AI பதில் புரியவில்லை. மீண்டும் முயற்சிக்கவும்."
- Log `raw_model_response` to `diagnosis` table for debugging
- Confidence set to `inconclusive`; recommend officer consultation

---

## 9. State Management Architecture

### 9.1 Riverpod Provider Tree

```
┌── farmerProfileProvider (StateNotifierProvider)
│     └── farmerProfileNotifier: FarmerProfile?
│
├── activeCropsProvider (StreamProvider)
│     └── Stream<List<CropProfile>> from sqflite
│
├── cropDetailProvider(cropId) (FutureProvider.family)
│     └── CropProfile + List<GrowthStage> + List<Diagnosis>
│
├── currentStageProvider(cropId) (Provider.family)
│     └── GrowthStage? (derived from cropDetailProvider)
│
├── gemmaServiceProvider (Provider)
│     └── GemmaService (singleton, lazy-loaded model)
│
├── ragServiceProvider (Provider)
│     └── RagService (sqlite-vec queries + context assembly)
│
├── diagnosisStateProvider(cropId) (StateNotifierProvider.family)
│     └── DiagnosisState { idle | capturing | processing | success | error }
│
├── marketPricesProvider(cropType) (FutureProvider.family)
│     └── List<MandiPrice> (from cache or live API)
│
├── schemesProvider (FutureProvider)
│     └── List<SchemeMatch>
│
└── notificationServiceProvider (Provider)
      └── NotificationService (schedules Android notifications)
```

### 9.2 Navigation (go_router)

```dart
final router = GoRouter(routes: [
  GoRoute(path: '/',        builder: (_, __) => DashboardScreen()),
  GoRoute(path: '/crop/new', builder: (_, __) => CreateCropScreen()),
  GoRoute(
    path: '/crop/:id',
    builder: (_, state) => CropDetailScreen(cropId: int.parse(state.pathParameters['id']!)),
    routes: [
      GoRoute(path: 'scan',    builder: (_, state) => DiagnosisScreen(cropId: ...)),
      GoRoute(path: 'market',  builder: (_, state) => MarketScreen(cropId: ...)),
    ],
  ),
  GoRoute(path: '/schemes',  builder: (_, __) => SchemesScreen()),
  GoRoute(path: '/settings', builder: (_, __) => SettingsScreen()),
]);
```

---

## 10. Error Handling Specification

### 10.1 Error Categories

| Code | Category | User-Facing Message (Tamil) | Recovery Action |
|---|---|---|---|
| E001 | Model not downloaded | "AI மாடல் பதிவிறக்கப்படவில்லை" | Navigate to download screen |
| E002 | Model load failure | "AI துவக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்." | Retry button; check storage space |
| E003 | Model inference timeout (>15s) | "AI பதில் தாமதமாகிறது. மீண்டும் முயற்சிக்கவும்." | Retry; suggest closing other apps |
| E004 | JSON parse failure | "AI பதில் தெளிவாக இல்லை. மீண்டும் முயற்சிக்கவும்." | Retry; fallback to inconclusive result |
| E005 | Camera permission denied | "படம் எடுக்க அனுமதி வேண்டும்." | Open app settings (permission deep-link) |
| E006 | Microphone permission denied | "குரல் உள்ளீட்டிற்கு அனுமதி வேண்டும்." | Show text input as fallback |
| E007 | SQLite write failure | "தரவு சேமிக்க முடியவில்லை. இடம் உள்ளதா சரிபாருங்கள்." | Retry; check available storage |
| E008 | Network unavailable | "இணையம் இல்லை. சேமிக்கப்பட்ட தரவு காட்டப்படுகிறது." | Show cached data; no retry needed |
| E009 | API rate limit | "சேவை தற்காலிகமாக இல்லை. சில நிமிடம் பின் முயற்சிக்கவும்." | Auto-retry after 60s |
| E010 | API server error (5xx) | "சேவை தற்காலிகமாக இல்லை." | Show cached data; retry after 5 min |
| E011 | Vosk STT failure | "குரல் புரியவில்லை. மீண்டும் பேசவும்." | Retry button; text input fallback |
| E012 | TTS voice not installed | "Tamil குரல் நிறுவப்படவில்லை." | Deep link to TTS settings |
| E013 | Low storage (<200 MB free) | "சாதன இடம் குறைவாக உள்ளது." | Storage management dialog |

### 10.2 Error Presentation

**Inline validation errors:** shown as red helper text below input fields (16sp)  
**Non-blocking errors:** `SnackBar` at bottom (Tamil text, 4s duration, "மீண்டும்" retry action if applicable)  
**Blocking errors:** `AlertDialog` with Tamil title + body + action button  
**Empty states:** Illustrated empty state card (no toast/snackbar for expected empty conditions)

### 10.3 Crash Prevention

- Wrap all `async` Riverpod state changes in `try/catch`; propagate `AsyncError` to provider
- Wrap model inference calls with `Future.timeout(Duration(seconds: 15))`
- SQLite operations always inside transactions; catch `DatabaseException` and surface E007
- Flutter `runZonedGuarded` in `main.dart` catches uncaught exceptions; log locally
- Image loading uses `Image.file` with `errorBuilder` for corrupted diagnosis photos

---

## 11. Caching and Offline Strategy

### 11.1 Cache Tiers

| Data Type | Storage | TTL | Invalidation |
|---|---|---|---|
| Market prices | `market_price_cache` SQLite table | 6 hours | On new successful fetch |
| Weather forecast | `weather_cache` SQLite table | 3 hours | On new successful fetch |
| Scheme metadata | `scheme_match` SQLite table | 7 days | Manual refresh in settings |
| HTTP responses | `dio_cache_interceptor` SQLite store | Per-endpoint (6h/24h) | On cache-clear in settings |
| Diagnosis images | App-private file storage | Permanent | On crop deletion |
| Model files | External storage | Permanent | On manual re-download |

### 11.2 Offline Detection

```dart
// Connectivity check before any network call
final connectivity = await Connectivity().checkConnectivity();
final isOnline = connectivity != ConnectivityResult.none;

if (!isOnline) {
  // Use cached data path
  return _loadFromCache(cropType);
} else {
  try {
    return await _fetchFromApi(cropType);
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return _loadFromCache(cropType);  // Treat timeout as offline
    }
    rethrow;
  }
}
```

### 11.3 Sync Strategy

**Opportunistic sync** — no background service, no push:
1. On app foreground: `connectivity_plus` fires `ConnectivityResult.wifi` or `.mobile`
2. `SyncService.syncIfDue()` checks timestamps in cache tables
3. If any cache is stale (older than TTL): fire API calls in parallel
4. Update cache tables; re-evaluate scheme eligibility; update price alerts
5. No UI blocking — sync runs in background; updated data flows to UI via Riverpod stream providers

---

## 12. Security Specification

### 12.1 Data Isolation

- SQLite database at `getApplicationDocumentsDirectory()/nilamai_v1.db` — accessible only to app process (Android's app-private storage sandbox)
- Diagnosis images at `getApplicationDocumentsDirectory()/diagnoses/` — same sandbox
- Model files at `getExternalStorageDirectory()/models/` — accessible to other apps with READ_EXTERNAL_STORAGE permission (acceptable; model weights are not private data)
- **No cloud transmission of any farmer data** — enforced architecturally (no backend client code exists in production build)

### 12.2 Network Security

- Certificate pinning for `api.data.gov.in` and `api.openweathermap.org` using `dio`'s `BadCertificateCallback` + pinned SHA256 fingerprints stored in `assets/certs/`
- API keys stored in Dart `const String` compiled into release APK; obfuscated via `flutter build apk --obfuscate`
- No API keys stored in plaintext files or committed to version control; injected at build time via `--dart-define=AGMARKNET_API_KEY=xxx`

### 12.3 Android Permissions

**Declared in `AndroidManifest.xml`:**

| Permission | Justification | When Requested |
|---|---|---|
| `CAMERA` | Crop disease photo capture | First time user taps Scan |
| `RECORD_AUDIO` | Voice query input | First time user taps microphone |
| `POST_NOTIFICATIONS` | Crop stage and harvest reminders | On onboarding, before scheduling first reminder |
| `INTERNET` | Optional market price / weather fetch | Declared only; not requested at runtime |
| `RECEIVE_BOOT_COMPLETED` | Re-schedule notifications after reboot | Declared only; no runtime prompt |
| `READ/WRITE_EXTERNAL_STORAGE` (< API 29) | Model file storage | On model download |

**Not requested:** Location (GPS), Contacts, Phone identity, Biometrics

### 12.4 Input Sanitization

- All text inputs trimmed before storage; max lengths enforced at widget level
- SQL injection prevention: all queries use `sqflite` parameterized queries (`?` placeholders) — never string interpolation in SQL
- No user-supplied strings are interpolated into shell commands or file paths (no shell execution in app code)
- Crop variety text field: max 50 chars, alphanumeric + spaces only (validated with RegExp)

---

## 13. Testing Requirements

### 13.1 Unit Tests

All tests located in `test/unit/`. Target: 80% code coverage.

| Area | Test Cases |
|---|---|
| `CropStageCalculator` | Stage date calculation for all 6 crops × multiple varieties × edge dates (leap year, year boundary) |
| `RagService` | Embedding generation, similarity search correctness, context assembly token count |
| `PromptRenderer` | Variable substitution for all 5 prompt templates; edge cases (null weather, empty task list) |
| `GemmaResponseValidator` | Valid JSON parsing, malformed JSON, missing required fields, wrong confidence enum |
| `DatabaseRepository` | CRUD for all 8 tables; transaction rollback on error; constraint violations |
| `DateCalculations` | Harvest date computation, days remaining, stage transition triggers |
| `OveruseDetector` | Total quantity aggregation, threshold comparison, edge cases |
| `SchemeEligibilityEngine` | Eligibility for all 4 schemes across farmer archetypes |

### 13.2 Widget Tests

All tests in `test/widget/`. Test each screen in isolation with mocked providers.

| Screen | Test Scenarios |
|---|---|
| `DashboardScreen` | Empty state, single crop, multiple crops, ordering by urgency |
| `CropDetailScreen` | All 3 stage states (completed/active/upcoming), task checkbox interaction |
| `DiagnosisScreen` | Camera permission denied, loading state, success state, error state |
| `MarketScreen` | Online with data, offline with cache, offline without cache |
| `SchemesScreen` | All eligibility status combinations, deadline countdown rendering |
| `CreateCropScreen` | Form validation (all error cases), successful submission |

### 13.3 Integration Tests

Located in `integration_test/`. Run on physical Android device or emulator.

| Scenario | Steps | Expected Result |
|---|---|---|
| Full crop lifecycle | Create crop → advance stages → reach harvest | Correct stage transitions, notifications scheduled |
| Disease diagnosis E2E | Open scan → capture image → receive Tamil diagnosis | JSON parsed; record saved; TTS button visible |
| Function calling | Tap market prices (online) | API called; prices displayed; recommendation in Tamil |
| Offline diagnosis | Enable airplane mode → scan crop | Full diagnosis completes without network |
| Voice input | Tap mic → speak Tamil query | Query transcribed and processed by Gemma |
| Notification tap | Schedule notification; wait; tap | Correct crop timeline screen opens |
| App restart | Create crop; kill app; reopen | All crop data persists; notifications intact |

### 13.4 Device Testing Matrix

| Device | RAM | Android | Test Focus |
|---|---|---|---|
| Redmi 9A | 2 GB | 10 | Memory pressure; model may fail gracefully |
| Redmi 9C | 4 GB | 11 | Minimum supported spec; all features |
| Realme C11 | 4 GB | 11 | Minimum supported spec baseline |
| Samsung Galaxy M13 | 4 GB | 12 | Mid-range baseline; full feature test |
| Redmi Note 11 | 6 GB | 12 | Target performance benchmarking |
| Pixel 6a | 6 GB | 14 | NPU path validation (Tensor G2) |

### 13.5 Field Testing Protocol

Minimum 5 farmers in rural Tamil Nadu:

| Test | Success Criteria |
|---|---|
| Onboarding (first launch to first crop) | Completed without assistance in ≤ 10 minutes |
| Disease diagnosis with real crop photo | Farmer understands diagnosis and treatment without explanation |
| Voice query in outdoor conditions | Recognition rate ≥ 80% in typical outdoor background noise |
| Tamil output quality | Native Tamil speaker rates advice as "understandable" (4/5+ rating) |
| Sunlight readability | Screen readable in direct midday sunlight without squinting |
| Scheme discovery | Farmer identifies ≥ 1 applicable scheme independently |

### 13.6 Acceptance Criteria

| Criterion | Target |
|---|---|
| Disease diagnosis accuracy (top-3, test dataset) | ≥ 85% |
| Tamil text quality (native speaker rating) | ≥ 4.0 / 5.0 |
| Offline feature availability | 100% of core features |
| Text query response (Redmi Note 11) | ≤ 3 seconds |
| Image diagnosis response (Redmi Note 11) | ≤ 5 seconds |
| App crash rate | < 1% of sessions |
| New user onboarding (crop + first advice) | ≤ 5 minutes |
| Notification delivery accuracy | ≥ 99% within 1 minute of scheduled time |

---

## 14. Performance Benchmarks

### 14.1 Benchmark Protocol

Benchmarks are run using a dedicated `benchmark_test/` suite using `package:benchmark_harness`. Each benchmark runs 20 iterations; mean and p95 values are reported.

| Benchmark | Method | Acceptance Threshold |
|---|---|---|
| `EmbeddingLatency` | Embed 10-word query via EmbeddingGemma | p95 ≤ 500ms |
| `VectorSearchLatency` | Query disease_embeddings (10K vectors, limit 5) | p95 ≤ 200ms |
| `ContextAssembly` | Full RAG pipeline excluding inference | p95 ≤ 800ms |
| `GemmaTextInference` | 500-token input → 200-token output | p95 ≤ 5s (CPU), ≤ 3s (NPU) |
| `GemmaImageInference` | 1024×1024 JPEG + 400 tokens → 200 tokens | p95 ≤ 8s (CPU), ≤ 5s (NPU) |
| `SQLiteWrite` | Insert 1 crop_profile + 7 growth_stages (transaction) | p95 ≤ 50ms |
| `SQLiteRead` | Load all active crops with latest stage (JOIN query) | p95 ≤ 100ms |
| `ImagePreprocess` | Resize 4000×3000 → 1024×1024 + base64 encode | p95 ≤ 300ms |

### 14.2 Memory Footprint

| State | Target RSS (4 GB device) |
|---|---|
| App launch (no model) | ≤ 150 MB |
| App with EmbeddingGemma loaded | ≤ 400 MB |
| App with Gemma 4 E2B loaded (INT4) | ≤ 3.2 GB |
| App during active inference | ≤ 3.4 GB (3.2 GB model + 200 MB compute) |

On a 4 GB device: 3.4 GB used by app + ~500 MB Android OS = ~3.9 GB. Leaves ~100 MB headroom; requires graceful memory handling (§4.3).

---

## 15. Repository Structure

```
nilamai/
├── README.md
├── LICENSE                          # Apache 2.0
├── pubspec.yaml                     # Pinned Flutter dependencies
├── pubspec.lock                     # Exact dependency snapshot
├── analysis_options.yaml            # Strict lint rules
│
├── lib/
│   ├── main.dart                    # Entry point (prod flavor)
│   ├── main_dev.dart                # Entry point (dev flavor, Ollama)
│   ├── app.dart                     # MaterialApp + theme + router setup
│   │
│   ├── routing/
│   │   └── router.dart              # go_router configuration
│   │
│   ├── features/
│   │   ├── dashboard/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── crop_card_widget.dart
│   │   │   └── dashboard_provider.dart
│   │   ├── crop_detail/
│   │   │   ├── crop_detail_screen.dart
│   │   │   ├── timeline_widget.dart
│   │   │   └── crop_detail_provider.dart
│   │   ├── diagnosis/
│   │   │   ├── diagnosis_screen.dart
│   │   │   ├── camera_preview_widget.dart
│   │   │   ├── diagnosis_result_screen.dart
│   │   │   └── diagnosis_provider.dart
│   │   ├── market/
│   │   │   ├── market_screen.dart
│   │   │   └── market_provider.dart
│   │   ├── schemes/
│   │   │   ├── schemes_screen.dart
│   │   │   └── schemes_provider.dart
│   │   ├── create_crop/
│   │   │   ├── create_crop_screen.dart
│   │   │   └── create_crop_provider.dart
│   │   └── settings/
│   │       ├── settings_screen.dart
│   │       └── settings_provider.dart
│   │
│   ├── services/
│   │   ├── gemma_service.dart       # LiteRT-LM inference wrapper
│   │   ├── ollama_client.dart       # Dev-flavor Ollama HTTP client
│   │   ├── rag_service.dart         # Embedding + vector search + context assembly
│   │   ├── notification_service.dart
│   │   ├── sync_service.dart        # Opportunistic API sync
│   │   ├── tts_service.dart
│   │   └── stt_service.dart
│   │
│   ├── data/
│   │   ├── database/
│   │   │   ├── database_helper.dart # sqflite init, migration runner
│   │   │   └── migrations/          # migration_001.dart, etc.
│   │   ├── repositories/
│   │   │   ├── crop_repository.dart
│   │   │   ├── diagnosis_repository.dart
│   │   │   ├── scheme_repository.dart
│   │   │   └── market_repository.dart
│   │   └── api/
│   │       ├── agmarknet_api.dart
│   │       └── weather_api.dart
│   │
│   ├── models/
│   │   ├── farmer_profile.dart
│   │   ├── crop_profile.dart
│   │   ├── growth_stage.dart
│   │   ├── diagnosis.dart
│   │   ├── application_log.dart
│   │   ├── scheme_match.dart
│   │   └── market_price.dart
│   │
│   └── widgets/
│       ├── tamil_text.dart          # Text widget with Tamil font settings
│       ├── voice_button.dart        # Reusable mic button with animation
│       ├── confidence_badge.dart
│       ├── loading_overlay.dart
│       └── error_card.dart
│
├── assets/
│   ├── crops/                       # rice.json, tomato.json, etc.
│   ├── prompts/                     # disease_diagnosis.txt, etc.
│   ├── i18n/                        # ta.json, en.json, te.json, kn.json
│   ├── knowledge/                   # Source text for embedding generation
│   │   ├── diseases/
│   │   ├── treatments/
│   │   ├── stage_care/
│   │   └── schemes/
│   ├── models/vosk-tamil-small/     # Bundled Vosk STT model (~50 MB)
│   ├── icons/crops/                 # Crop icon images
│   └── certs/                       # Pinned TLS cert fingerprints
│
├── android/
│   ├── app/src/main/
│   │   ├── AndroidManifest.xml
│   │   └── kotlin/.../
│   │       └── BootReceiver.kt      # Re-schedules notifications on boot
│   └── app/jniLibs/
│       └── arm64-v8a/
│           └── libvec0.so           # sqlite-vec native extension
│
├── test/
│   ├── unit/
│   └── widget/
│
├── integration_test/
│
├── benchmark_test/
│
├── scripts/
│   ├── generate_embeddings.py       # Build knowledge base vector DB
│   ├── validate_embeddings.py       # Sanity-check embedding quality
│   └── convert_to_litert.py        # Convert fine-tuned model to .litertlm
│
└── model/
    └── fine_tuning/
        ├── train.py                 # Unsloth LoRA training script
        ├── dataset_prep.py
        └── config.yaml
```

---

## 16. Future Enhancements (Post v1.0)

Ordered by estimated user impact:

1. **Water management module** — irrigation scheduling based on crop stage, soil type, and weather forecast; soil moisture sensor integration via Bluetooth
2. **Yield prediction** — ML model predicting harvest yield based on stage health scores and application logs
3. **Photo-based maturity assessment** — camera-based readiness check ("Is my tomato ready to harvest?")
4. **Expense and profit tracking** — input cost logging (seeds, fertilizer, labour) + revenue from sale price; profit/loss per crop
5. **Community disease alerts** — opt-in regional disease outbreak sharing between farmers in same district
6. **e-NAM integration** — connect to National Agriculture Market for online price discovery and digital selling
7. **Additional crop packs** — downloadable knowledge packs for cotton, maize, turmeric, cardamom, etc.
8. **KCC (Kisan Credit Card) module** — loan management, repayment reminders
9. **Multi-farm management** — agricultural officer view managing multiple farmers' dashboards
10. **iOS support** — after LiteRT-LM iOS support matures; Flutter code is platform-agnostic

---

*NilamAI (நிலம்AI) — AI that grows with your land*
