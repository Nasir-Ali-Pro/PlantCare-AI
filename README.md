<div align="center">

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/Gemini_AI-4285F4?style=for-the-badge&logo=google&logoColor=white" />
<img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" />
<img src="https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white" />

<br /><br />

# 🌿 PlantCare AI — Your Smart Plant Doctor

### *A Final Year Project (FYP) — BS Computer Science*

**An intelligent, production-grade cross-platform mobile application that leverages Google Gemini Vision AI to diagnose plant diseases, manage virtual gardens, and empower a community of gardeners — all from the palm of your hand.**

<br />

![PlantCare AI Banner](assets/banner_placeholder.png)

</div>

---

## 📋 Table of Contents

- [Problem Statement](#-problem-statement)
- [Solution & Innovation](#-solution--innovation)
- [Features](#-features)
- [System Architecture](#-system-architecture)
- [Tech Stack](#-tech-stack)
- [Database Schema](#-database-schema)
- [AI Pipeline](#-ai-diagnosis-pipeline)
- [Screenshots](#-screenshots)
- [Installation & Setup](#-installation--setup)
- [Environment Configuration](#-environment-configuration)
- [Project Structure](#-project-structure)
- [Security Design](#-security-design)
- [Non-Functional Requirements](#-non-functional-requirements)
- [Admin System](#-admin-system)
- [Future Enhancements](#-future-enhancements)
- [Acknowledgements](#-acknowledgements)

---

## 🚩 Problem Statement

Agriculture faces a **devastating $220 billion annual loss** globally due to plant diseases that go undiagnosed or are misidentified by farmers and gardeners, especially in developing economies like Pakistan. Conventional solutions require:

- **Expert agronomists** (expensive and geographically inaccessible)
- **Lab testing** (takes days, costs money)
- **Manual lookup books** (error-prone, not AI-assisted)

Smallholder farmers, home gardeners, and hobbyists — who constitute the majority of plant growers — have **no accessible, affordable, intelligent tool** to diagnose plant health issues in real time.

---

## 💡 Solution & Innovation

**PlantCare AI** bridges this gap by delivering an **AI-powered plant doctor** directly to the user's smartphone. By combining:

1. **Google Gemini Vision AI** — multimodal large language model for image-based disease detection
2. **Supabase cloud pathology database** — crowdsourced, cached expert reports shared across all users
3. **Offline-first architecture** — SQLite local persistence ensures functionality without internet
4. **Community forum** — knowledge sharing and peer-to-peer expert consultation

The result is a **zero-cost, instant, highly accurate plant diagnosis system** that democratises access to agricultural expertise.

---

## ✨ Features

### 🔬 Core AI Diagnosis System
| Feature | Description |
|---|---|
| **Camera / Gallery Scanning** | Snap or upload any plant photo for instant AI analysis |
| **Two-Stage Gemini Pipeline** | Light detection query first (species + disease), then full pathology generation — optimised for token efficiency |
| **Supabase Cloud Cache** | Diagnosis results stored globally; subsequent scans of same disease served instantly from database |
| **Offline Fallback** | Local JSON treatment database (`treatment_data.json`) provides offline diagnoses |
| **Species Identification** | Separate mode identifies plant species with scientific name, care schedule, toxicity, light requirements |
| **Confidence Scoring** | Every diagnosis includes AI confidence percentage and severity rating (Low / Moderate / High / Critical) |
| **PDF / Share Reports** | Full pathology reports exportable and shareable |

### 🪴 Virtual Garden Manager
| Feature | Description |
|---|---|
| **Plant Profiles** | Create personalised plant entries with nickname, species, scientific name, photo |
| **Smart Care Scheduling** | Customisable watering & fertilising frequency; app tracks overdue care |
| **Health Score System** | Time-based health decay algorithm; score recovers with care actions |
| **Care Streak** | Gamified streak counter rewards consistent plant care |
| **Photo Journal** | Attach timestamped journal entries with photos to track plant growth milestones |
| **Local Notifications** | Push reminders for watering and fertilising schedules |

### 🌦️ Weather Integration
| Feature | Description |
|---|---|
| **Real-Time Weather Dashboard** | OpenWeather API + Open-Meteo fallback for temperature, humidity, UV index |
| **Plant-Contextual Advice** | Weather info displayed with actionable plant care advice ("High UV today — shade outdoor plants") |
| **Frost Warning System** | Alerts when temperatures indicate frost risk |

### 💬 Community Forum
| Feature | Description |
|---|---|
| **Threaded Discussions** | Nested comment system with parent-child reply relationships |
| **Expert Badges** | Verified expert accounts visually distinguished from regular users |
| **Category Filtering** | Browse by Disease, Watering, Fertilising, Pests, General |
| **Upvote System** | Community-driven content quality ranking |
| **Post Reporting** | Moderation system for flagging inappropriate content |
| **Pagination** | Efficient infinite scroll loading from Supabase |
| **Rich Post Creation** | Create posts with plant image attachments and diagnosis tagging |

### 📚 Plant Encyclopedia
| Feature | Description |
|---|---|
| **300+ Plant Database** | Comprehensive local encyclopedia with care guides |
| **AR Plant Viewer** | Augmented Reality 3D plant placement via device camera |
| **Smart Search & Filter** | Filter by care difficulty, light requirements, toxicity |
| **Favourites System** | Bookmark plants for quick access |

### 🤖 AI Chat Assistant
| Feature | Description |
|---|---|
| **Gemini-Powered Chatbot** | Contextual plant care Q&A powered by Gemini Pro |
| **Persistent Chat History** | Conversations saved locally to SQLite across sessions |
| **Context-Aware Responses** | System-prompted as a professional botanist/horticulturist |
| **Typing Indicators** | Animated streaming response experience |

### 🛍️ Affiliate Shop
| Feature | Description |
|---|---|
| **Curated Product Catalog** | Plant care tools, fertilisers, soil, and accessories |
| **Supabase-Driven Inventory** | Products loaded dynamically from cloud; offline fallback to defaults |
| **Affiliate Links** | External product links with click analytics logged to Supabase |
| **Category Navigation** | Filterable product browser by Tools, Soil, Fertiliser, Pots, Seeds |
| **Admin Seeding** | Auto-seeds product catalog to Supabase if database is empty |

### 👤 Authentication & User Management
| Feature | Description |
|---|---|
| **Supabase Auth** | Secure email + password registration/login via Supabase managed auth |
| **Guest Mode** | Full app access without registration via anonymous Supabase session |
| **Email Verification** | Account email confirmation flow |
| **Forgot Password** | Supabase email-based password reset |
| **Profile Sync** | User profile (username, avatar, role) synced to Supabase `user_profiles` table |
| **Admin Role** | Designated admin account with Gemini API key management for global app config |

### 🔒 Security & Compliance
| Feature | Description |
|---|---|
| **AES-256 Encryption** | Local SQLite plant data encrypted at rest |
| **Input Sanitisation** | All user text inputs sanitised via `SecurityService` (XSS, SQL injection prevention) |
| **HMAC Integrity** | Data integrity verification for local storage |
| **Privacy Policy & ToS** | In-app legal screens with full policy text |
| **Offline Banner** | Real-time connectivity banner alerts user to offline state |

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PlantCare AI                                  │
│                    Flutter / Dart (SDK 3.9+)                         │
├─────────────────────────────────────────────────────────────────────┤
│                      PRESENTATION LAYER                              │
│  HomeScreen │ ScanScreen │ ResultScreen │ GardenScreen │ ForumScreen │
│  ChatScreen │ EncyclopediaScreen │ ShopScreen │ ProfileScreen        │
├─────────────────────────────────────────────────────────────────────┤
│                    STATE MANAGEMENT LAYER                            │
│       GardenProvider │ DiagnosisProvider │ ChatProvider              │
│                      ShopProvider                                     │
│               (Provider package — ChangeNotifier)                    │
├─────────────────────────────────────────────────────────────────────┤
│                       SERVICE LAYER                                   │
│  PlantDiagnosisOrchestrator │ WeatherService │ SecurityService       │
│  DatabaseService │ NotificationService │ ImageService               │
│  ReviewService                                                        │
├─────────────────────────────────────────────────────────────────────┤
│                       API LAYER                                       │
│         GeminiService │ SupabaseService                              │
├──────────────────────────┬──────────────────────────────────────────┤
│    LOCAL PERSISTENCE     │        CLOUD SERVICES                     │
│  SQLite (sqflite)        │  Supabase Auth (email + password)         │
│  AES-256 Encrypted       │  Supabase PostgreSQL (cloud DB)           │
│  SharedPreferences       │  Google Gemini Vision AI (gemini-1.5-pro) │
│  Local Notifications     │  OpenWeather API / Open-Meteo API         │
└──────────────────────────┴──────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Category | Technology | Purpose |
|---|---|---|
| **Framework** | Flutter 3.x (Dart SDK 3.9+) | Cross-platform mobile UI |
| **AI Vision** | Google Gemini 1.5 Pro | Plant disease diagnosis, species ID, chatbot |
| **Backend / BaaS** | Supabase (PostgreSQL + Auth) | Cloud database, authentication, storage |
| **Local DB** | SQLite via `sqflite` | Offline plant garden, chat history, reports |
| **State Management** | Provider 6.x | App-wide reactive state |
| **UI Animations** | `flutter_animate` | Premium micro-animations |
| **Image Handling** | `image_picker`, `flutter_image_compress`, `cached_network_image` | Camera access, compression, caching |
| **Networking** | `connectivity_plus`, `http` (via `HttpClient`) | Connectivity detection, weather API |
| **Notifications** | `flutter_local_notifications` + `timezone` | Scheduled plant care reminders |
| **Encryption** | `encrypt` (AES-256) | Local data security |
| **Fonts** | Google Fonts (`Outfit`, `Inter`) | Premium typography |
| **Security** | Custom `SecurityService` | Input sanitisation, HMAC integrity |
| **Reviews** | `in_app_review` | Throttled in-app rating prompts |
| **Sharing** | `share_plus` | Share diagnosis reports |
| **Deep Linking** | `url_launcher` | Open affiliate product URLs |

---

## 🗄️ Database Schema

### Supabase PostgreSQL (Cloud)

```sql
-- Expert Pathology Cache (shared globally across all users)
plant_diseases (
  id UUID PK,
  plant_name VARCHAR(100),     -- e.g. "Tomato"
  disease_name VARCHAR(100),   -- e.g. "Early Blight"
  severity VARCHAR(30),        -- Low | Moderate | High | Critical
  description TEXT,
  symptoms JSONB,              -- ["yellowing leaves", ...]
  treatment JSONB,             -- ["apply fungicide", ...]
  prevention JSONB,            -- ["rotate crops", ...]
  UNIQUE(plant_name, disease_name)  -- cache key
)

-- Community Forum
forum_posts (id, author_name, category, title, content, tags[], upvotes, images[])
forum_comments (id, post_id FK, parent_comment_id FK, author_name, content, upvotes)

-- User Management
user_profiles (id UUID FK→auth.users, username, avatar_url, role, gemini_api_key, joined_at, updated_at)
user_plants (id, user_id FK, nickname, species, health_score, watering schedule...)

-- Shop Analytics
shop_products (id, name, description, price, category, affiliate_url, image_url)
shop_clicks (product_id, user_id, created_at)
```

### SQLite (Local — Encrypted)

```
plants          — GardenPlant entities with care schedules
diagnosis_reports — Full scan history
chat_messages   — AI chatbot conversation history
```

---

## 🧠 AI Diagnosis Pipeline

The diagnosis system uses an intelligent **2-stage Gemini pipeline** designed for cost efficiency and accuracy:

```
User uploads photo
       │
       ▼
┌─────────────────────────────────────────────────────┐
│  Stage 1: Light Detection Query (low tokens)        │
│  Prompt → Gemini Vision                             │
│  Response: { is_plant, species, disease }  (JSON)   │
└─────────────────────────────────────────────────────┘
       │
       ├─ is_plant = false → Reject with user-friendly error
       │
       ▼
┌─────────────────────────────────────────────────────┐
│  Stage 2: Supabase Cache Lookup                     │
│  Query: plant_diseases WHERE plant=X AND disease=Y  │
└─────────────────────────────────────────────────────┘
       │
       ├─ Cache HIT → Return expert report instantly ⚡
       │
       ▼ Cache MISS
┌─────────────────────────────────────────────────────┐
│  Stage 3: Full Pathology Report Generation          │
│  Prompt → Gemini Vision (with structured JSON schema│
│  Response: severity, description, symptoms[],       │
│           treatment[], prevention[], confidence     │
└─────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│  Stage 4: Cache Save to Supabase                    │
│  Future users get instant results for same disease  │
└─────────────────────────────────────────────────────┘
       │
       ▼
  DiagnosisReport displayed to user
```

**Key design decisions:**
- Stage 1 uses a minimal prompt to minimise token cost and latency
- Stage 2 benefits all users — once one user scans a disease, everyone else gets instant results
- Non-plant images are rejected early to prevent hallucination
- JSON responses cleaned of markdown fencing before parsing

---

## 📱 Screenshots

> *(Screenshots to be added after deployment — run `flutter run` to preview)*

| Home Dashboard | AI Diagnosis | Results Report |
|---|---|---|
| Weather + Care Streak | Camera Scan | Severity + Treatment |

| Virtual Garden | Community Forum | AI Chat |
|---|---|---|
| Plant Cards + Journal | Threaded Replies | Botanist Chatbot |

| Encyclopedia | Shop | Profile |
|---|---|---|
| AR Plant Viewer | Affiliate Products | Admin Gemini Config |

---

## 🚀 Installation & Setup

### Prerequisites

| Tool | Version | Install |
|---|---|---|
| Flutter SDK | ≥ 3.9.0 | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Dart SDK | ≥ 3.9.0 | Bundled with Flutter |
| Android Studio / Xcode | Latest | For Android/iOS emulators |
| Git | Any | [git-scm.com](https://git-scm.com) |

### 1. Clone the Repository

```bash
git clone https://github.com/nasir-ahmad/PlantCare-AI.git
cd PlantCare-AI
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Set Up Supabase

1. Create a free project at [supabase.com](https://supabase.com)
2. Open **SQL Editor** and run the full schema:
   ```bash
   # Copy and execute the contents of:
   supabase_schema.sql
   ```
3. Go to **Authentication → Users → Add User**
   - Email: `your-admin@email.com` | Password: `<strong_password>`
4. Run the admin promotion SQL:
   ```sql
   UPDATE public.user_profiles
   SET role = 'admin'
   WHERE id = (SELECT id FROM auth.users WHERE email = 'your-admin@email.com');
   ```
5. Copy your **Project URL** and **anon public key** from Project Settings → API

### 4. Configure Environment

Create a `.env` file (or configure via in-app Settings):

```env
GEMINI_API_KEY=AIzaSy...          # Get from Google AI Studio
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...
```

> **Alternatively:** Launch the app → Settings → enter credentials directly in the UI. The admin can set the global Gemini key from the Profile screen, which all users will automatically use.

### 5. Run the Application

```bash
# Android
flutter run

# iOS (macOS only)
flutter run -d ios

# Release build (Android APK)
flutter build apk --release
```

---

## ⚙️ Environment Configuration

### API Keys Required

| Key | Source | Required |
|---|---|---|
| `GEMINI_API_KEY` | [Google AI Studio](https://aistudio.google.com/app/apikey) | **Yes** (for AI features) |
| `SUPABASE_URL` | Supabase Project Settings → API | **Yes** (for cloud features) |
| `SUPABASE_ANON_KEY` | Supabase Project Settings → API | **Yes** (for cloud features) |
| `OPEN_WEATHER_API_KEY` | [OpenWeatherMap](https://openweathermap.org/api) | Optional (falls back to Open-Meteo) |

> **Note:** The app is fully functional offline without Supabase — local SQLite and fallback offline plant database ensure core diagnosis and garden features work without internet.

### Admin Configuration

The admin user (`nasir@gmail.com` by default) can:
1. Navigate to **Profile → Configuration & Utilities**
2. Tap **Manage** next to Gemini AI API Key
3. Enter the key → **Save & Sync to Supabase**
4. All app users will immediately use this centrally configured key

---

## 📁 Project Structure

```
plantcare_app/
├── lib/
│   ├── main.dart                    # App entry point, provider setup
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart   # Gemini prompts, app-wide constants
│   │   └── theme/
│   │       ├── app_colors.dart      # Design system colour tokens
│   │       └── app_theme.dart       # Material dark theme configuration
│   ├── models/
│   │   ├── garden_plant.dart        # GardenPlant + JournalEntry models
│   │   ├── diagnosis_report.dart    # DiagnosisReport model
│   │   ├── forum_post.dart          # ForumPost + Comment models
│   │   ├── shop_product.dart        # ShopProduct + affiliate defaults
│   │   ├── encyclopedia_item.dart   # Plant encyclopedia entry model
│   │   └── chat_message_model.dart  # Chat message model
│   ├── providers/
│   │   ├── garden_provider.dart     # Auth state, garden, user profile
│   │   ├── diagnosis_provider.dart  # Gemini config, scan history
│   │   ├── chat_provider.dart       # AI chatbot state + history
│   │   └── shop_provider.dart       # Shop products, cart, favourites
│   ├── services/
│   │   ├── api/
│   │   │   ├── gemini_service.dart          # Gemini SDK wrapper
│   │   │   └── supabase_service.dart        # Supabase client + all DB ops
│   │   ├── diagnosis_orchestrator.dart      # 2-stage AI pipeline
│   │   ├── database_service.dart            # SQLite CRUD + AES encryption
│   │   ├── image_service.dart               # Image pick, compress, upload
│   │   ├── notification_service.dart        # Push notification scheduling
│   │   ├── review_service.dart              # In-app review throttling
│   │   ├── security_service.dart            # Input sanitisation, HMAC
│   │   └── weather_service.dart             # OpenWeather + Open-Meteo
│   ├── screens/
│   │   ├── main_navigation_shell.dart       # Bottom nav + offline banner
│   │   ├── auth/                            # Login, Register, ForgotPassword
│   │   ├── home/                            # Dashboard, weather streak
│   │   ├── scanning/                        # Camera scan screen
│   │   ├── result/                          # Diagnosis result + in-app review
│   │   ├── garden/                          # Virtual garden manager
│   │   ├── chat/                            # AI botanist chat
│   │   ├── encyclopedia/                    # Plant encyclopedia + AR
│   │   ├── forum/                           # Community forum
│   │   ├── shop/                            # Affiliate product shop
│   │   ├── profile/                         # User profile + admin panel
│   │   ├── history/                         # Diagnosis history
│   │   ├── onboarding/                      # First-launch onboarding
│   │   └── legal/                           # Privacy policy + ToS
│   └── widgets/                             # Reusable UI components
│       ├── app_card.dart
│       ├── plant_image.dart
│       ├── action_card.dart
│       ├── weather_streak_dashboard.dart
│       └── offline_banner.dart
├── assets/
│   └── data/
│       └── treatment_data.json              # Offline plant disease database
├── supabase_schema.sql                      # Full Supabase DB setup script
├── pubspec.yaml
└── README.md
```

---

## 🔐 Security Design

PlantCare AI implements a **CIA Triad** approach (Confidentiality, Integrity, Availability):

### Confidentiality
- **AES-256 encryption** on all locally persisted plant data via the `encrypt` package
- **Supabase Row-Level Security (RLS)** — users can only access their own `user_profiles` and `user_plants` rows
- **API key obfuscation** — Gemini key displayed as `AIzaSy••••••••••••...xxxx` in UI

### Integrity
- **HMAC checksums** on local database entries via `SecurityService`
- **Input sanitisation** — all text fields sanitised to prevent XSS and SQL injection
- **Supabase unique constraints** — `UNIQUE(plant_name, disease_name)` prevents data duplication

### Availability
- **Offline-first architecture** — SQLite local database ensures app is fully functional without internet
- **Graceful degradation** — every Supabase call has try/catch with offline fallback
- **Connectivity banner** — users immediately informed when offline
- **Multiple API fallbacks** — OpenWeather → Open-Meteo for weather; online → offline JSON for diagnosis

---

## 📊 Non-Functional Requirements

| Requirement | Implementation | Target |
|---|---|---|
| **Performance** | 2-stage AI pipeline, Supabase response caching | < 3s for cached diagnosis |
| **Reliability** | Offline SQLite fallback, multiple API fallbacks | 99% uptime experience |
| **Scalability** | Supabase PostgreSQL + global shared cache | Unlimited concurrent users |
| **Security** | AES-256, RLS, HMAC, input sanitisation | Production-grade |
| **Usability** | Flutter Animate micro-animations, shimmer loading | Premium UX |
| **Maintainability** | Provider pattern, service layer, model separation | Clean architecture |
| **Compliance** | In-app Privacy Policy, Terms of Service | Legal compliance |

---

## 👑 Admin System

A designated **admin account** (`nasir@gmail.com`) has elevated privileges:

```
Admin capabilities:
  ✅ Configure the global Gemini API Key (shared with all users)
  ✅ Key stored encrypted in user_profiles.gemini_api_key in Supabase
  ✅ All regular users automatically receive the admin's key on login
  ✅ "Manage" button visible only to admin in Profile → Configuration
```

**To promote a user to admin:**
```sql
UPDATE public.user_profiles SET role = 'admin'
WHERE id = (SELECT id FROM auth.users WHERE email = 'admin@email.com');
```

---

## 🔮 Future Enhancements

- [ ] **Yield Prediction** — ML model to predict crop yield based on historical scan data
- [ ] **IoT Sensor Integration** — Bluetooth soil moisture and pH sensor data display
- [ ] **Expert Marketplace** — Connect users with certified agronomists for paid consultations
- [ ] **Multi-Language Support** — Urdu, Hindi for broader South Asian reach
- [ ] **Cloud Garden Sync** — Sync `user_plants` to Supabase for multi-device access
- [ ] **AR Enhanced Diagnosis** — Overlay disease markers directly on live camera feed
- [ ] **Firebase Analytics** — User engagement tracking and funnel analysis
- [ ] **Crashlytics** — Production crash reporting integration

---

## 🙏 Acknowledgements

| Resource | Contribution |
|---|---|
| [Google Gemini API](https://ai.google.dev) | Multimodal AI vision and language model |
| [Supabase](https://supabase.com) | Open-source Firebase alternative — BaaS platform |
| [Flutter](https://flutter.dev) | Cross-platform mobile SDK |
| [OpenWeatherMap](https://openweathermap.org) | Real-time weather data API |
| [Open-Meteo](https://open-meteo.com) | Free weather API fallback |
| [PlantVillage Dataset](https://plantvillage.psu.edu) | Reference dataset for disease taxonomy |

---

## 📄 License

This project is submitted as an academic Final Year Project for **BS Computer Science**.  
All rights reserved © 2026. Not licensed for commercial use without permission.

---

<div align="center">

**Built with ❤️ for Pakistan's farming and gardening community**

*🌱 Empowering Every Gardener with the Power of AI 🌱*

</div>
