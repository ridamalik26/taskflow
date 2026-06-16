# TaskFlow — Flutter Task Management App

A modern, production-ready task management mobile app built with **Flutter**, following **Clean Architecture** with **Riverpod**, **Go Router**, **Hive**, and **Material Design 3**.

![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart)
![Null Safety](https://img.shields.io/badge/Null%20Safety-enabled-success)

---

## ✨ Features

- **Full Task CRUD** — create, read, update, delete and complete tasks.
- **Each task** has a title, description, due date, priority (Low / Medium / High), completion state and creation date.
- **Splash screen** with fade-in + scale animations and a gradient background.
- **Home dashboard** with greeting, current date and live statistics (Total / Completed / Pending).
- **Search**, **filter** (All / Pending / Completed) and **pull-to-refresh**.
- **Swipe gestures** — swipe right to edit, swipe left to delete (with confirmation).
- **Animated completion** checkbox, **Hero** transitions and smooth page transitions.
- **Empty-state illustrations**, **loading** indicators and friendly **error handling** via snackbars & dialogs.
- **Dark mode** support (follows system) and **responsive**, card-based UI.
- **Offline-first** — all data persisted locally with Hive and survives app restarts.

---

## 🏗️ Architecture

The project follows **Clean Architecture**, splitting each feature into three layers:

```
lib/
├── core/                      # Cross-cutting concerns (no feature logic)
│   ├── constants/             # Colors, sizes, strings
│   ├── theme/                 # Material 3 light/dark themes + theme provider
│   ├── utils/                 # Date helpers, validators, exceptions
│   └── widgets/               # Reusable widgets (button, text field, dialogs…)
│
├── features/
│   └── tasks/
│       ├── data/              # Implementation details
│       │   ├── models/        # TaskModel + hand-written Hive adapter
│       │   ├── datasources/   # TaskLocalDataSource (Hive)
│       │   └── repositories/  # TaskRepositoryImpl
│       │
│       ├── domain/            # Pure business layer (no Flutter/Hive)
│       │   ├── entities/      # Task, TaskPriority
│       │   ├── repositories/  # TaskRepository (abstract contract)
│       │   └── usecases/      # GetTasks, AddTask, UpdateTask, DeleteTask…
│       │
│       └── presentation/      # UI layer
│           ├── providers/     # Riverpod providers + TaskListNotifier
│           ├── screens/       # Splash, Home, Create, Edit, Details
│           └── widgets/       # TaskCard, StatsCard, PriorityBadge, TaskForm
│
├── routes/                    # Go Router configuration + route constants
└── main.dart                  # Composition root (Hive init + DI overrides)
```

**Dependency rule:** `presentation → domain ← data`. The domain layer depends on nothing; outer layers depend inward through abstractions (Dependency Inversion).

---

## 🧰 Tech Stack

| Concern            | Package              |
| ------------------ | -------------------- |
| State management   | `flutter_riverpod`   |
| Navigation         | `go_router`          |
| Local storage      | `hive` / `hive_flutter` |
| Date formatting    | `intl`               |
| Unique IDs         | `uuid`               |

> **Note:** A hand-written Hive `TypeAdapter` is used for `TaskModel`, so **no `build_runner` code-generation step is required**.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK **3.22+** (Dart **3.4+**) — verify with `flutter --version`.
- An Android emulator, iOS simulator, or a physical device.

### Setup

```bash
# 1. Fetch dependencies
flutter pub get

# 2. (First time only) generate the platform folders if they are missing
#    Run this from the project root; it will not overwrite lib/.
flutter create .

# 3. Run the app
flutter run
```

### Useful commands

```bash
flutter analyze        # Static analysis / lints
flutter test           # Run tests
flutter build apk      # Build a release Android APK
flutter build ios      # Build for iOS (on macOS)
```

---

## 🎨 Color Palette

| Token       | Hex       |
| ----------- | --------- |
| Primary     | `#4F46E5` |
| Secondary   | `#06B6D4` |
| Success     | `#22C55E` |
| Error       | `#EF4444` |
| Background  | `#F8FAFC` |

---

## 🧭 Navigation Routes

| Route           | Path            | Screen               |
| --------------- | --------------- | -------------------- |
| Splash          | `/`             | `SplashScreen`       |
| Home            | `/home`         | `HomeScreen`         |
| Create Task     | `/create`       | `CreateTaskScreen`   |
| Edit Task       | `/edit/:id`     | `EditTaskScreen`     |
| Task Details    | `/task/:id`     | `TaskDetailsScreen`  |

---

## 🧪 State Management Overview

| Provider                  | Responsibility                              |
| ------------------------- | ------------------------------------------- |
| `taskListProvider`        | Async source of truth for all tasks (CRUD). |
| `filteredTasksProvider`   | Tasks after search + filter + sorting.      |
| `taskStatsProvider`       | Total / completed / pending counts.         |
| `taskFilterProvider`      | Active filter (All / Pending / Completed).  |
| `taskSearchProvider`      | Current search query.                       |
| `taskByIdProvider`        | Single task lookup for details/edit.        |
| `themeModeProvider`       | Light / dark / system theme mode.           |

---

## 📂 Persistence

Tasks are stored in a Hive box (`tasks_box`) keyed by task `id`. The box is opened once at startup in `main.dart` and injected into the Riverpod graph via an override, so the UI never blocks on storage initialization. All Hive errors are wrapped in domain-level `CacheException`s and surfaced to the user through snackbars.

---

## 📝 License

This project is provided as-is for educational and demonstration purposes.
