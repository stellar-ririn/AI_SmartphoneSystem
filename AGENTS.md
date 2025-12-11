# AI Assistant App - Architecture Guidelines

This project follows **Clean Architecture** combined with **MVVM** using **Flutter Riverpod**.

## Directory Structure

*   `lib/core/`: Shared kernels, utilities, constants, and exceptions.
*   `lib/data/`: Implementation of repositories and data sources (API calls, Local DB).
    *   `datasources/`: Low-level data access (Remote/Local).
    *   `models/`: DTOs (Data Transfer Objects) that handle JSON serialization. **Must not be used in UI.**
    *   `repositories/`: Implementation of `domain/repositories` interfaces.
*   `lib/domain/`: Pure business logic. **No Flutter dependencies** (except for basic types if needed).
    *   `entities/`: Plain Dart objects used by the app.
    *   `repositories/`: Abstract interfaces defining data operations.
    *   `usecases/`: Single-responsibility classes that encapsulate business logic (optional for simple CRUD).
*   `lib/presentation/`: UI and State Management.
    *   `providers/`: Riverpod providers (ViewModels).
    *   `screens/`: Application screens.
    *   `widgets/`: Reusable UI components.

## Rules

1.  **Dependency Rule**: `domain` depends on nothing. `data` depends on `domain`. `presentation` depends on `domain`.
2.  **State Management**: Use `Riverpod` for all state management. Prefer `@riverpod` annotations (Code generation) for providers.
3.  **Data Flow**:
    *   UI calls a Provider/Controller.
    *   Provider calls a UseCase (or Repository directly if simple).
    *   UseCase calls a Repository Interface.
    *   Repository Implementation calls Data Sources.
4.  **Immutability**: Use `freezed` for all State classes and Data Models.
5.  **Environment**: API Keys and sensitive config should be handled via `flutter_secure_storage` and not hardcoded.

## Testing

*   **Unit Tests**: For UseCases, Repositories (mocked data sources), and Utility functions.
*   **Widget Tests**: For UI components.
