# 📚 Study Tracker

A simple, offline Flutter app for logging study sessions by **subject** and **duration**, built for university students (especially fellow UUM students) who want to see where their study time goes.

> **Course / Assignment:** _(Put course code and assignment name here)_
> **Author:** _(Put your name and matric number here)_

---

## Table of Contents
1. [Overview](#overview)
2. [Features](#features)
3. [Screenshots](#screenshots)
4. [Tech Stack](#tech-stack)
5. [Project Structure](#project-structure)
6. [Getting Started](#getting-started)
7. [User Guide (Tutorials)](#user-guide-tutorials)
8. [Database Design](#database-design)
9. [Validation Rules](#validation-rules)
10. [Hidden and Debug Features](#hidden-and-debug-features)
11. [Assets](#assets)
12. [Known Limitations](#known-limitations)

---

## Overview

University students handle lectures, assignments, labs and exams across many subjects, but rarely keep a record of how much time each one gets. Study Tracker lets you log each session with a title, subject, duration and optional notes, then shows your total study time at a glance. Everything is stored locally in SQLite, so it works offline and needs no account.

---

## Features

- ➕ **Add** study sessions (title, subject, duration, optional notes)
- ✏️ **Edit** existing sessions with a prefilled form
- 🗑️ **Delete** sessions by swiping or from the long-press menu, with a confirmation dialog
- ⭐ **Favorite** important sessions. Favorites are protected from deletion
- 🔍 **Details view** showing the full title, subject, duration and notes
- ⏱️ **Total Time Studied** banner (for example `2h 30m`)
- 📄 **Pagination** with 10 sessions per page
- ✅ **Form validation** with clear error messages
- 💬 **Feedback messages** (SnackBars) after save, update and delete
- 💾 **Local SQLite storage** that works offline
- 🌱 **Empty state** guidance and a splash screen

---

## Screenshots

> Replace each placeholder with your own screenshot. Suggested folder: `assets/screenshots/`.

| # | Screen | Placeholder |
|---|--------|-------------|
| 1 | Splash screen | _(Put image of the splash screen here.)_ |
| 2 | Empty home state | _(Put image of the empty home screen here.)_ |
| 3 | Populated session list | _(Put image of the home screen with sessions here.)_ |
| 4 | Add form with inputs | _(Put image of the filled-in form here.)_ |
| 5 | Validation errors | _(Put image of the form showing error messages here.)_ |
| 6 | Save confirmation dialog | _(Put image of the "Confirm save" dialog here.)_ |
| 7 | Feedback message | _(Put image of the "saved successfully" SnackBar here.)_ |
| 8 | Details view | _(Put image of the details dialog here.)_ |
| 9 | Prefilled edit form | _(Put image of the edit screen here.)_ |
| 10 | Delete confirmation | _(Put image of the delete dialog here.)_ |
| 11 | Pagination controls | _(Put image of the "Page X of Y" controls here.)_ |

Once you have the images, embed them like this:

```markdown
![Splash Screen](assets/screenshots/01_splash.png)
```

---

## Tech Stack

| Component | Technology |
|---|---|
| Framework | Flutter (Material 3) |
| Language | Dart |
| Database | SQLite via [`sqflite`](https://pub.dev/packages/sqflite) |
| Path handling | [`path`](https://pub.dev/packages/path) |

---

## Project Structure

```
lib/
├── main.dart                     # App entry point, theme, DB initialisation
├── models/
│   └── study_session.dart        # StudySession model (toMap / fromMap / copyWith)
├── screens/
│   ├── splash_screen.dart        # 3-second launch screen
│   ├── main_screen.dart          # Home: list, summary, pagination, actions
│   └── add_session_screen.dart   # Add / edit form with validation
└── utils/
    ├── database_helper.dart      # SQLite singleton and CRUD queries
    └── dummy_data.dart           # Generates random test sessions
```

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install). A recent stable version is recommended, since the form uses `DropdownButtonFormField.initialValue`
- Android Studio or VS Code with the Flutter extension
- An Android/iOS emulator or a physical device

### Installation

```bash
# 1. Clone the repository
git clone <your-repository-url>
cd <project-folder>

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

### Required dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path: ^1.9.0
```

### Build a release APK

```bash
flutter build apk --release
```

---

## User Guide (Tutorials)

### 1. Launch the app
The splash screen appears for 3 seconds, then the home screen opens. On first launch, the list is empty and shows *"Your study log starts here"*.

### 2. Add a study session
1. Tap the **+** floating button.
2. Enter a **Title** (e.g. `Chapter 4 revision`).
3. Choose a **Subject** from the dropdown.
4. Enter the **Duration** in minutes (e.g. `60`).
5. _(Optional)_ Add **Notes**.
6. Tap **Confirm**, then tap **Save** in the confirmation dialog.
7. A message confirms the save, and the new session appears at the top of the list.

### 3. View session details
Tap any session card to open a dialog showing the full title, subject, duration and notes. Tap **Close** to go back, or **Edit** to change it.

### 4. Edit a session
1. Tap a card and choose **Edit**, or long-press the card and tap **Edit**.
2. Change the fields in the prefilled form.
3. Tap **Save Changes**, then confirm.
4. The original creation date is kept.

### 5. Mark a session as favorite
Tap the ⭐ icon on a card. Favorited sessions are highlighted and **cannot be deleted** until you unfavorite them.

### 6. Delete a session
There are two ways:
- **Swipe left** on a card, or
- **Long-press** the card and tap **Delete**.

Confirm in the dialog. Favorited sessions cannot be deleted, so the swipe is disabled and the Delete button is greyed out.

### 7. Navigate pages
When you have more than 10 sessions, use the **‹ ›** arrows at the bottom to move between pages. The label shows your position (e.g. `Page 2 of 5`).

### 8. Refresh the list
Tap the 🔄 icon in the top bar to reload data from the database.

### 9. Check your total time
The blue banner at the top of the list shows the total study time across **all** sessions, not just the current page.

---

## Database Design

**Database:** `study_tracker.db` (version 1) | **Table:** `study_sessions`

| Column | SQLite Type | Constraints | Description |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique ID |
| `title` | TEXT | NOT NULL | Session title |
| `subject` | TEXT | NOT NULL | Selected subject |
| `duration` | INTEGER | NOT NULL | Minutes studied |
| `notes` | TEXT | Nullable | Optional notes |
| `isFavorite` | INTEGER | NOT NULL | `1` = favorite, `0` = not |
| `createdAt` | TEXT | NOT NULL | UTC ISO-8601 timestamp |

```sql
CREATE TABLE study_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  subject TEXT NOT NULL,
  duration INTEGER NOT NULL,
  notes TEXT,
  isFavorite INTEGER NOT NULL,
  createdAt TEXT NOT NULL
);
```

**Implementation notes**
- `createdAt` is saved with `DateTime.toUtc().toIso8601String()` and read back with `DateTime.parse()`.
- Sessions are ordered by `createdAt DESC, id DESC` (newest first).
- Pagination uses `LIMIT 10 OFFSET (page - 1) * 10`.
- Booleans are mapped to integers (`true` → `1`, `false` → `0`).
- Empty notes are stored as `NULL`.

---

## Validation Rules

| Field | Rule | Error message |
|---|---|---|
| Title | Required, not blank | `Please enter a title` |
| Subject | Must pick one option | `Choose a subject` |
| Duration | Digits only, must be **greater than 0** | `Enter a duration greater than 0` |
| Notes | Optional | None |

Available subjects: **Mathematics, Science, English, History, Computer Science, Other**.

---

## Hidden and Debug Features

| Feature | How to use |
|---|---|
| **Add 50 dummy records** | Tap the **"Study Tracker"** title in the top bar **7 times**, then tap the 🐞 icon. Useful for testing pagination |
| **Delete all non-favorite sessions** | A 🧹 icon appears in the top bar in **debug mode only**. Favorited sessions are kept |

---

## Assets

| Asset | Location | Notes |
|---|---|---|
| Screenshots | `assets/screenshots/` | Add your own images here |
| App icon | _(Put path or description here)_ | The app uses Material icons (`auto_stories_rounded`) for its logo |
| Demo video / GIF | _(Put link or path here)_ | Optional |

If you add image assets, register them in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/screenshots/
```

---

## Known Limitations

- Data is stored only on the device, with no cloud sync or backup.
- There is no search, filter or per-subject statistics yet.
- Sessions use a fixed list of subjects.
- The `sqflite` package targets Android and iOS. Desktop and web need extra setup.

### Possible future improvements
- Filter and search by subject or date
- Weekly study charts and statistics
- Custom subjects
- Study reminders and goals
- Data export (CSV) and cloud backup

---

## License

_(Add your license here, or remove this section.)_
