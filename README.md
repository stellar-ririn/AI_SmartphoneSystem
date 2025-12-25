# AI Assistant App

A specialized AI Assistant application built with Flutter, Riverpod, and Clean Architecture.

## Features

*   **Dual AI Core:** Switch between Gemini and OpenAI models.
*   **Voice Capability:** Uses Aivis Cloud API for high-quality voice synthesis.
*   **Personal Assistant:** Integrates with Google Calendar, Alarms, and News (RSS).
*   **Privacy First:** API keys are stored locally (BYOK), and iOS notifications are handled securely.

## Getting Started

### Prerequisites

*   Flutter SDK (>=3.22.0)
*   Dart SDK (>=3.4.0)

### Setup

1.  **Dependencies:**
    ```bash
    flutter pub get
    ```

2.  **Generate Code:**
    This project uses code generation for models and providers.
    ```bash
    dart run build_runner build
    ```

3.  **Fix Android NDK Issue:**
    If you encounter an error regarding "Android NDK version 27.0.12077973", run the included fix script:
    ```bash
    dart bin/fix_ndk.dart
    ```
    This will automatically configure your `android/app/build.gradle` with the required NDK version.

3.  **Enable Notifications (Android):**
    To use the notification reading feature, you must add the following service to your `android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:

    ```xml
    <service
        android:name="package.name.of.your.app.NotificationsListenerService"
        android:label="AI Assistant Listener"
        android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE">
        <intent-filter>
            <action android:name="android.service.notification.NotificationListenerService" />
        </intent-filter>
    </service>
    ```
    *Note: Replace `package.name.of.your.app` with the actual package name (e.g., `com.example.ai_assistant_app`).*

4.  **Run the App:**
    ```bash
    flutter run
    ```

## Architecture

This project follows Clean Architecture principles:

*   `domain`: Business logic (Entities, UseCases, Repository Interfaces).
*   `data`: Data implementation (API calls, DTOs, Repository Impls).
*   `presentation`: UI and State Management (Riverpod).
*   `core`: Shared utilities and configuration.

See `DESIGN.md` for full system specifications.
