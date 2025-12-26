# AI Assistant App System Design Document

## 1. Top-Level Architecture
The application follows a **Clean Architecture** approach combined with **MVVM** (Model-View-ViewModel), managed by **Flutter Riverpod**.

```mermaid
graph TD
    User[User] <--> UI[Presentation Layer (Widgets)]
    UI <--> VM[ViewModels / Controllers (Riverpod Providers)]

    subgraph Domain Layer
        VM --> UseCases[Use Cases / Interactors]
        UseCases --> Entities[Domain Entities]
        UseCases --> Repos[Repository Interfaces]
    end

    subgraph Data Layer
        Repos --> RepoImpl[Repository Implementations]
        RepoImpl --> LocalDS[Local Data Source (Hive/SharedPreferences)]
        RepoImpl --> RemoteDS[Remote Data Source (APIs/Firebase)]
        RepoImpl --> SecureDS[Secure Storage (API Keys)]
    end

    RemoteDS <--> External[External Services]
    External -.-> Google[Google APIs (Calendar, Auth)]
    External -.-> AI[AI APIs (Gemini, OpenAI)]
    External -.-> Voice[Aivis Cloud / TTS]
    External -.-> RSS[News RSS Feeds]
```

## 2. Detailed Feature Design

### 2.1. AI Core (The "Brain")
*   **Multi-LLM Support:** A generic `LLMService` interface with implementations for `GeminiService` and `OpenAIService`.
*   **Persona System:** Users configure a "System Prompt" that defines the AI's name, tone, and role. This is injected into every conversation context.
*   **Context Management:** A rolling window of conversation history (stored locally via Hive) is sent with each request to maintain context.

### 2.2. Voice & TTS
*   **Architecture:** `TextToSpeechService` interface.
*   **Implementations:**
    *   `AivisCloudService`: Calls Aivis API with specific `speaker_id` and parameters.
    *   `StandardTTSService`: Uses `flutter_tts` for on-device synthesis.
    *   `SilentService`: Null object pattern for mute mode.
*   **Audio Queue:** An audio player manager that handles queuing sentences (streaming response handling) to reduce latency.

### 2.3. Assistant Functions
*   **Google Calendar:**
    *   Uses `googleapis` package.
    *   Requires `GoogleSignInAuthentication` headers for requests.
    *   **Logic:** The AI generates a JSON-structured intent (e.g., `{"action": "create_event", "date": "..."}`) which the app parses and executes.
*   **Notifications (Platform Specific):**
    *   **Android:** Uses `NotificationListenerService` (via platform channel) to intercept notifications.
    *   **iOS:** Restricted. Only reads internal app notifications or calendar events triggered by the app.
*   **Alarms:**
    *   **Android:** Uses `android_intent` to trigger `AlarmClock.ACTION_SET_ALARM`.
    *   **iOS:** Falls back to `flutter_local_notifications` to schedule a high-priority notification sound, as programmatic system alarm access is restricted.

### 2.4. News
*   **Source:** RSS Feeds (User configurable).
*   **Processing:**
    *   **Raw Mode:** Reads the title and description from the RSS feed directly.
    *   **Summarize Mode:** Sends the RSS content to the AI with a prompt: "Summarize this news for me in a [Persona] style."

## 3. Data Models

### 3.1. User Settings (Firestore & Local Cache)
```dart
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final DateTime lastLogin;
}
```

### 3.2. AI Configuration
```dart
class AIConfig {
  final String id;
  final AIProvider provider; // enum: gemini, openai
  final String modelName; // e.g. "gpt-4", "gemini-pro"
  final String systemPrompt; // The persona definition
  final double temperature;
}

enum AIProvider { gemini, openai }
```

### 3.3. Voice Configuration
```dart
class VoiceConfig {
  final VoiceType type; // enum: aivis, standard, off
  final String? voiceId; // For Aivis or System voice identifier
  final double speed;
  final double pitch;
}
```

### 3.4. Secrets (Secure Storage - Not Synced)
```dart
class UserSecrets {
  final String? geminiApiKey;
  final String? openAiApiKey;
  final String? aivisApiKey;
}
```

## 4. API Integration Flows

### 4.1. Chat Flow
1.  User input (Voice/Text).
2.  App retrieves `UserSecrets` (API Key) and `AIConfig` (System Prompt).
3.  App retrieves last N messages from `ChatHistoryRepository`.
4.  Request sent to `LLMService`.
5.  Streamed text response received.
6.  Text chunk sent to `TextToSpeechService` buffer.
7.  Audio played to user.

### 4.2. News Summary Flow
1.  App fetches XML from User's RSS URL.
2.  Parses XML to `List<NewsItem>`.
3.  If **Raw Mode**: `TextToSpeechService` reads titles.
4.  If **AI Mode**:
    *   Concatenate top 3 news items.
    *   Send to `LLMService` with prompt: "Summarize these news items: [...]".
    *   Read response via `TextToSpeechService`.

## 5. Directory Structure (Riverpod)

```
lib/
├── main.dart
├── app.dart
├── core/                  # Shared kernels
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── exceptions/
├── config/                # Environment & Router
├── data/
│   ├── datasources/
│   │   ├── local/         # Hive, SecureStorage
│   │   └── remote/        # Retrofit/Dio APIs, Firebase
│   ├── models/            # DTOs (Data Transfer Objects)
│   └── repositories/      # Repository Implementations
├── domain/
│   ├── entities/          # Pure business objects
│   ├── repositories/      # Abstract interfaces
│   └── usecases/          # Business logic units
└── presentation/
    ├── providers/         # Riverpod Providers
    ├── screens/
    │   ├── home/
    │   ├── settings/
    │   ├── chat/
    │   └── onboarding/
    └── widgets/           # Reusable UI components
```

## 6. Recommended Packages

| Category | Package | Purpose |
| :--- | :--- | :--- |
| **State Management** | `flutter_riverpod`, `riverpod_annotation` | State & Dependency Injection |
| **Code Gen** | `freezed`, `json_serializable`, `build_runner` | Immutable models & JSON parsing |
| **Network** | `dio`, `retrofit` | HTTP Client for AI/Aivis APIs |
| **Auth/Backend** | `firebase_auth`, `firebase_core`, `cloud_firestore` | Auth & Settings Sync |
| **Google** | `google_sign_in`, `googleapis` | Login & Calendar Access |
| **Storage** | `hive_flutter`, `flutter_secure_storage` | Local DB & API Key storage |
| **UI/UX** | `flutter_animate`, `cached_network_image` | Animations & Images |
| **Voice/Audio** | `flutter_tts`, `audioplayers`, `record` | TTS & Speech-to-Text (STT) |
| **RSS** | `webfeed` or `xml` | Parsing RSS feeds |
| **Utils** | `intl`, `uuid`, `fpdart` | Formatting, IDs, Functional Utils |
| **Platform** | `android_intent_plus`, `url_launcher` | Alarms (Android) & Links |

## 7. Security Design

1.  **Bring Your Own Key (BYOK):**
    *   **Storage:** API keys (Gemini/OpenAI/Aivis) are stored **only** in `FlutterSecureStorage` (Keychain on iOS, Keystore on Android).
    *   **Transmission:** Keys are sent directly from the client to the AI provider's API. They never touch a dedicated backend server (except Firebase Auth tokens).
2.  **Google OAuth:**
    *   Uses standard OAuth 2.0 flow via `google_sign_in`.
    *   Scopes requested incrementally (only ask for Calendar when enabling the feature).
3.  **Data Privacy:**
    *   Chat logs are stored locally (Hive) for privacy, or optionally in Firestore (encrypted) if cross-device sync is required (default to local).

## 8. Development Roadmap

### Phase 1: Foundation
*   Setup Flutter project & Architecture.
*   Implement Firebase Auth (Google Sign-In).
*   Create Settings UI (BYOK Input, Save to SecureStorage).
*   Implement basic Chat UI (Text only).

### Phase 2: AI & Voice
*   Implement `LLMService` (Gemini & OpenAI).
*   Implement `TextToSpeechService` (Standard TTS first).
*   Connect Chat UI to AI + TTS.
*   Add Aivis API integration.

### Phase 3: Assistant Features
*   Google Calendar integration (Read events).
*   Android Alarm integration.
*   News (RSS) Parser & Summarizer.
*   Background Notification Listener (Android).

### Phase 4: Polish & Release
*   Theming & Dynamic Icons.
*   Persona customization UI.
*   Performance optimization (Audio buffering).
*   Security audit & Store Policy compliance checks.

---
**Note for AI Developer:**
When implementing the **Aivis Cloud API**, please ensure the request format matches the specific parameters required by the endpoint (e.g., `speaker_id` mapping). Since documentation was not directly readable, assume a standard POST request with JSON body until the user provides the specific curl/spec.
