# Open Cloud Health - Project Summary

## App Overview
**Open Cloud Health** is a cross-platform, local-first personal health tracking application built with Flutter. The app empowers users to own and manage their medical data privately, without relying on a centralized, proprietary backend server. 

### Core Philosophy
*   **Privacy First:** All health data (profiles, history, medications, allergies) is stored locally on the device using an SQLite database (`sqflite`).
*   **Biometric Security:** The app is gated by native biometric authentication (`local_auth`) upon launch, ensuring data remains secure even if the device is unlocked.
*   **User-Owned Cloud Sync:** Instead of a central server, the app backs up the SQLite database and profile images directly to a hidden "App Data" folder in the user's personal Google Drive. This uses the `driveAppdataScope`, adhering to Google's non-sensitive API policies for seamless, secure device migration.

### Current Features (Implemented)
*   **Profile Management:** Create and manage multiple health profiles (Name, DOB, Gender, Blood Type, Organ Donor status, Profile Picture).
*   **Allergies:** Add, view (with notes), and delete allergies attached to specific profiles.
*   **Medical History Timeline:** Log medical events, doctor visits, or symptoms. Users can attach files/images to these events.
*   **Medication Tracker:** A comprehensive dashboard to manage active medications, set exact daily dosages, log when a dose is taken, and receive local push notifications (`flutter_local_notifications`) as reminders.

---

## Future Roadmap (Features to Implement)

Before considering a 1.0 launch, the following major features are recommended:

1.  **Medical Checkups & Appointments (Placeholder exists)**
    *   Schedule upcoming doctor visits.
    *   Set pre-appointment notes (e.g., "Questions to ask").
    *   Convert completed appointments directly into `HistoryEvent` records for the timeline.
2.  **Vitals & Measurements Tracking (Placeholder exists)**
    *   A dashboard to log quantitative health data over time (Blood Pressure, Heart Rate, Weight, Blood Sugar).
    *   Implement line charts to visualize trends for managing chronic conditions.
3.  **PDF Report Generation**
    *   A secure "Export for Doctor" feature that compiles a user's Profile, active Medications, Allergies, and recent History into a clean PDF document for easy sharing with medical professionals.
4.  **Robust Cloud Sync UI**
    *   Enhance the Google Drive backup mechanism to handle background syncing gracefully.
    *   Provide a clear UI showing "Last Synced Time" and manual backup/restore buttons.

---

## Recommended Architectural Improvements

To ensure the codebase remains maintainable and scalable as new features are added, the following technical refactoring is highly recommended:

1.  ~~**Introduce the Repository Pattern**~~
    *   *Current State:* Riverpod Notifiers (e.g., `HistoryNotifier`, `MedicationsNotifier`) contain raw SQL strings and interact directly with the `sqflite` database helper.
    *   *Recommendation:* Abstract database logic into dedicated classes (e.g., `MedicationRepository`). Notifiers should only call repository methods. This separates business logic from data access, making unit testing easier and allowing for future database migrations (e.g., to Isar or Hive) without rewriting the UI state.
2.  **Componentize Large UI Screens**
    *   *Current State:* Screens like `profile_detail.dart` and `medication_tracker.dart` are monolithic (500+ lines), handling layout, form validation, and complex dialogs.
    *   *Recommendation:* Extract complex form sections, image pickers, and dialogs into their own dedicated, reusable widget files in the `lib/widgets/` directory.
3.  **Transition to Riverpod `AsyncValue`**
    *   *Current State:* StateNotifiers hold raw Lists (e.g., `List<HistoryEvent>`). Database fetches fail silently, and the UI has no concept of a "loading" state.
    *   *Recommendation:* Refactor providers to use Riverpod's `AsyncValue` (or migrate to the newer Riverpod `Notifier`/`AsyncNotifier` classes). This allows the UI to explicitly handle `.data`, `.loading`, and `.error` states, improving the user experience during slow database operations.
4.  **Centralize Routing and Constants**
    *   *Current State:* Route names and asset paths are hardcoded strings scattered throughout the app.
    *   *Recommendation:* Implement a declarative routing package like `go_router` for type-safe navigation. Create a `constants.dart` file to manage hardcoded values, making global updates easier.
