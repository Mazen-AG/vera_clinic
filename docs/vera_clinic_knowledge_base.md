# Vera Clinic — Project Knowledge Base

> **Purpose:** Read this at the start of a session to orient yourself in the codebase. This document is a **high-level technical map**: tech stack, dependencies, project structure, domain models, data flow, and how the pieces connect. It is not a user-facing README.
>
> **Last updated:** 2026-04-06

---

## Documentation boundaries

| Document | Audience | Purpose |
|----------|----------|---------|
| `README.md` | End users / product readers | User-facing overview: what the app does, setup instructions, key features. |
| `docs/vera_clinic_knowledge_base.md` (this file) | Engineers and AI assistants | System orientation: architecture map, data models, Firestore collections, providers, navigation, and CI. |

---

## Quick reference

| Key | Value |
|-----|-------|
| **Platform** | Flutter **Windows desktop** app (also supports web build) |
| **SDK** | Dart ^3.5.4, Flutter stable |
| **Version** | 1.0.3+4 (Shorebird-managed patches) |
| **Architecture** | MVC — `Core/Model/`, `Core/View/`, `Core/Controller/`, plus page-level folders |
| **State management** | `provider` with `ChangeNotifier` providers, composed at root in `main.dart` |
| **Backend** | Cloud Firestore (single Firebase project: `vera-life-clinic-test`) |
| **OTA updates** | Shorebird Code Push (`shorebird_code_push`) |
| **Window management** | `window_manager` — minimum 800×600, launches maximized |
| **Localization** | Arabic UI text (hardcoded strings in Arabic), `intl` for date formatting |
| **Fonts** | `google_fonts` (Cairo for headings/nav, system defaults elsewhere) |
| **Audio** | `audioplayers` for alert sounds |
| **Logging** | Custom `DebugLoggerService` — `mDebug()` global. Prints in debug, stores in-memory + archives to file in release |
| **CI** | GitHub Actions: `.github/workflows/ci.yml` (analyze, test); local mirror: `scripts/run_ci_locally.ps1` |

## Table of Contents

- [1. How the app boots](#1-how-the-app-boots)
- [2. Repository layout](#2-repository-layout)
- [3. MVC architecture](#3-mvc-architecture)
- [4. Providers (state management)](#4-providers-state-management)
- [5. Entity reference — Dart models and Firestore document shapes](#5-entity-reference--dart-models-and-firestore-document-shapes)
- [6. Theming](#6-theming)
- [7. Navigation](#7-navigation)
- [8. OTA updates (Shorebird)](#8-ota-updates-shorebird)
- [9. Debug logging](#9-debug-logging)
- [10. Dependencies](#10-dependencies)
- [11. CI/CD](#11-cicd)
- [12. Sensitive files and templates](#12-sensitive-files-and-templates)
- [13. Tests](#13-tests)
- [14. Data migration](#14-data-migration)

---

## 1. How the app boots

### Entry: `lib/main.dart`

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Initialize Arabic date formatting (`intl`)
3. Configure window manager (minimum size 800×600, maximize on show) — Windows only
4. Initialize Firebase (`DefaultFirebaseOptions.currentPlatform`)
5. Run Shorebird patch check (`UpdateService().initPatch()`)
6. Preload Material Icons font (workaround for Windows icon rendering)
7. Build `MultiProvider` tree with **all 9 providers** and mount `MyApp`

### Shell: `MyApp` widget

`MyApp` is a `StatefulWidget` wrapping a single `MaterialApp`:

- Theme: `AppTheme.themeData` (blue-based, light theme only — see §6)
- Home: `HomePage`
- Builder wraps child with `GlobalDebugOverlay` (production log viewer)
- No router package — navigation uses imperative `Navigator.push`

---

## 2. Repository layout

```
vera_clinic/
├── lib/
│   ├── main.dart                          # Entry point, provider setup
│   ├── Core/
│   │   ├── Controller/
│   │   │   ├── Providers/                 # 9 ChangeNotifier providers
│   │   │   └── UtilityFunctions.dart      # Shared helpers (formatting, enums, validation)
│   │   ├── Model/
│   │   │   ├── Classes/                   # 9 domain model classes
│   │   │   ├── Firebase/                  # 10 Firestore method classes + FirebaseSingleton
│   │   │   └── CustomExceptions.dart
│   │   ├── Services/
│   │   │   └── DebugLoggerService.dart    # mDebug() logging
│   │   └── View/
│   │       ├── Debug/                     # GlobalDebugOverlay (production log viewer)
│   │       ├── Pages/                     # (currently empty)
│   │       ├── PopUps/                    # Snackbars, alert dialogues
│   │       └── Reusable widgets/          # MyAppBar, MyCard, dropdowns, inputs, etc.
│   ├── HomePage/                          # Home screen + grid menu
│   ├── CheckInPage/                       # Client check-in flow
│   ├── CheckedInClientsPage/              # Live queue of checked-in clients
│   ├── ClientSearchPage/                  # Search clients by name/phone
│   ├── ClientDetailsPage/                 # View client profile + info cards
│   ├── NewClientRegistration/             # New client form
│   ├── NewVisit/                          # Record a new visit
│   ├── DailyClientsPage/                  # Today's client list
│   ├── AnalysisPage/                      # Clinic analytics (income, patients, expenses)
│   ├── ExpensesPage/                      # Expense tracking
│   ├── BiweeklyFollowUp/                  # Biweekly follow-up form
│   ├── SingleFollowUp/                    # Single follow-up form
│   ├── FollowUpNavPage/                   # Follow-up navigation hub
│   ├── MonthlyFollowUpsDetailsPage/       # View monthly follow-up records
│   ├── VisitsDetailsPage/                 # View visit records
│   ├── UpdateClientDetailsPage/           # Edit client info
│   ├── UpdateVisitDetailsPage/            # Edit visit record
│   ├── UpdateMonthlyFollowUpDetailsPage/  # Edit monthly follow-up
│   ├── Shorebird/                         # UpdateService (OTA patch management)
│   ├── theme/                             # AppTheme, AppColors
│   └── firebase_setup/                    # firebase_options.dart, apiKeys.dart(.example)
├── assets/
│   └── alert_sound.mp3                    # Audio alert for checked-in clients
├── test/
│   └── widget_test.dart                   # Default widget test
├── scripts/
│   └── run_ci_locally.ps1                 # Local CI pipeline (5 steps)
├── .github/
│   └── workflows/
│       └── ci.yml                         # GitHub Actions CI
├── docs/
│   └── vera_clinic_knowledge_base.md      # This file
└── references/                            # Reference materials
```

### Page folder convention

Most page folders follow a **Controller / View** split:

```
SomePage/
├── Controller/    # Page-specific logic, form validation, Firestore calls
└── View/          # Widgets and UI for that page
```

Some simpler pages (e.g. `ClientSearchPage`, `AnalysisPage`) have flat files without the Controller/View split.

---

## 3. MVC architecture

The app follows a **centralized MVC** pattern:

### Model (`Core/Model/`)

- **`Classes/`** — 9 domain classes: `Client`, `Clinic`, `Visit`, `Disease`, `ClientConstantInfo`, `ClientMonthlyFollowUp`, `Expense`, `PreferredFoods`, `WeightAreas`. Each has:
  - A constructor with named required fields
  - `fromFirestore(Map<String, dynamic>)` factory constructor
  - `toMap()` for Firestore writes
  - `printX()` debug method using `mDebug()`
- **`Firebase/`** — One `*FirestoreMethods` class per domain model (e.g. `ClientFirestoreMethods`). These handle CRUD operations against Firestore using `FirebaseSingleton.instance.firestore`. All use the `retry` package for resilience.
- **`CustomExceptions.dart`** — `FirebaseOperationException` for human-readable error messages (Arabic).

### View (`Core/View/` + page folders)

- **Reusable Widgets** — `MyAppBar`, `MyInputField`, `MyTextBox`, `MyCheckBox`, `BackGround`, dropdown menus, `datePicker`, `ClientSearchWidget`, etc.
- **PopUps** — `MySnackBar`, `DebugSnackBar`, `RequiredFieldSnackBar`, `InvalidDataTypeSnackBar`, `MyAlertDialogue`
- **Debug** — `GlobalDebugOverlay` for viewing production logs in a floating panel
- **Page-level views** — Each page folder contains its own UI widgets

### Controller (`Core/Controller/`)

- **`Providers/`** — 9 `ChangeNotifier` providers (see §4)
- **`UtilityFunctions.dart`** — Shared helpers: date formatting, BMI calculation, enum conversions (Arabic ↔ enum), numeric validation, 12-hour time formatting

---

## 4. Providers (state management)

All providers are registered at the root `MultiProvider` in `main.dart`. They each extend `ChangeNotifier` and use the corresponding `*FirestoreMethods` class for persistence.

| Provider | Model | Manages |
|----------|-------|---------|
| `ClientProvider` | `Client` | Client CRUD, search (by phone, name, first+second name), in-memory cache, current selected client |
| `ClinicProvider` | `Clinic` | Clinic state (daily/monthly income, expenses, profit, patient counts), check-in/check-out queue, daily/monthly clear, arrival status |
| `VisitProvider` | `Visit` | Visit CRUD per client |
| `ExpenseProvider` | `Expense` | Expense CRUD, monthly clearing |
| `ClientConstantInfoProvider` | `ClientConstantInfo` | Constant info (area, activity level, YOYO, sports) per client |
| `ClientMonthlyFollowUpProvider` | `ClientMonthlyFollowUp` | InBody follow-up CRUD (BMI, PBF, water, BMR, muscle mass, etc.) |
| `DiseaseProvider` | `Disease` | Disease history per client (cardiac, GI, endocrine, etc.) |
| `PreferredFoodsProvider` | `PreferredFoods` | Food preferences per client |
| `WeightAreasProvider` | `WeightAreas` | Weight distribution areas per client |

### Client caching pattern

`ClientProvider` maintains a `_cachedClients` list. All fetch methods check the cache first, then fall back to Firestore. Fetched clients are added to the cache to avoid redundant network reads.

### Clinic daily lifecycle

`ClinicProvider` manages a daily workflow:

1. On app launch: `getClinic()` fetches clinic data, `syncDailyClientsWithCheckedIn()` reconciles daily list
2. Throughout the day: check-in/check-out clients, update income/expenses
3. On exit (via **خروج** button): `dailyClear()` resets daily counters. If last Wednesday of month: `monthlyClear()` also resets monthly counters

---

## 5. Entity reference — Dart models and Firestore document shapes

All model classes live in `lib/Core/Model/Classes/`. Each class has a `fromFirestore(Map<String, dynamic>)` factory and a `toMap()` method. The Firestore field names below are the **exact keys** stored in documents (taken from `toMap()`).

---

### 5.1 `Client` → Firestore collection: `Clients`

The central entity. Other entities link to a client via `clientId`.

| Dart field | Firestore key | Type | Notes |
|------------|--------------|------|-------|
| `mClientId` | `clientId` | `String` | Auto-generated document ID, written back after creation |
| `mName` | `name` | `String?` | Full name (Arabic) |
| `mClientPhoneNum` | `clientPhoneNum` | `String?` | Phone number (used for search) |
| `mGender` | `gender` | `String` | Enum name: `none`, `male`, `female` |
| `mLastVisitId` | `lastVisitId` | `String?` | FK to the most recent Visit document |
| `mBirthdate` | `birthDate` | `Timestamp?` | Stored as Firestore Timestamp |
| `mClientConstantInfoId` | `clientConstantInfoId` | `String?` | FK to ClientConstantInfo |
| `mDiseaseId` | `diseaseId` | `String?` | FK to Disease |
| `mDiet` | `diet` | `String?` | Current diet plan text |
| `Plat` | `plat` | `List<double>` | Last 10 stable weight readings |
| `mClientLastMonthlyFollowUpId` | `lastMonthlyFollowUpId` | `String?` | FK to latest ClientMonthlyFollowUp |
| `mPreferredFoodsId` | `preferredFoodsId` | `String?` | FK to PreferredFoods |
| `mWeightAreasId` | `weightAreasId` | `String?` | FK to WeightAreas |
| `mNotes` | `notes` | `String?` | Free-text notes |
| `mHeight` | `height` | `double?` | Height in cm |
| `mWeight` | `weight` | `double?` | Current weight in kg |
| `mSubscriptionType` | `subscriptionType` | `String?` | Enum name (see below) |

**`SubscriptionType` enum values:** `none`, `newClient`, `singleVisit`, `biWeeklyVisit`, `monthlySubscription`, `afterBreak`, `inBody`, `cavSess`, `cavSess6`, `miso`, `punctureSess`, `punctureSess6`, `injection`, `other`

**`Gender` enum values:** `none`, `male`, `female`

---

### 5.2 `Clinic` → Firestore collection: `Clinic`

**Single document** (ID: `52g2WUMJjoTwbu6ioE96`). Stores all clinic-wide operational state.

| Dart field | Firestore key | Type | Notes |
|------------|--------------|------|-------|
| `mDailyIncome` | `dailyIncome` | `double?` | Reset on daily clear |
| `mMonthlyIncome` | `monthlyIncome` | `double?` | Reset on monthly clear |
| `mDailyPatients` | `dailyPatients` | `int?` | Reset on daily clear |
| `mMonthlyPatients` | `monthlyPatients` | `int?` | Reset on monthly clear |
| `mDailyExpenses` | `dailyExpenses` | `double?` | Reset on daily clear |
| `mMonthlyExpenses` | `monthlyExpenses` | `double?` | Reset on monthly clear |
| `mDailyProfit` | `dailyProfit` | `double?` | Computed: income − expenses |
| `mMonthlyProfit` | `monthlyProfit` | `double?` | Computed: income − expenses |
| `mCheckedInClients` | `checkedInClients` | `Map<String, Map>` | `{ clientId: { checkInTime: String, hasArrived: bool } }` |
| `mDailyClientIds` | `dailyClientIds` | `List<String>` | All client IDs seen today |

---

### 5.3 `Visit` → Firestore collection: `Visits`

One document per client visit.

| Dart field | Firestore key | Type | Notes |
|------------|--------------|------|-------|
| `mVisitId` | `visitId` | `String` | Auto-generated document ID |
| `mClientId` | `clientId` | `String?` | FK to Client |
| `mDate` | `date` | `Timestamp` | Visit date |
| `mDiet` | `diet` | `String` | Diet prescribed at this visit |
| `mWeight` | `weight` | `double` | Weight at this visit (kg) |
| `mBMI` | `bmi` | `double` | BMI at this visit |
| `mVisitNotes` | `visitNotes` | `String` | Visit notes |

---

### 5.4 `Disease` → Firestore collection: `Diseases`

Medical history per client. Boolean flags for common conditions + free-text for others.

| Dart field | Firestore key | Type | Notes |
|------------|--------------|------|-------|
| `mDiseaseId` | `diseaseId` | `String` | Document ID |
| `mClientId` | `clientId` | `String?` | FK to Client |
| `mHypertension` | `hypertension` | `bool` | — |
| `mHypotension` | `hypotension` | `bool` | — |
| `mVascular` | `vascular` | `bool` | — |
| `mAnemia` | `anemia` | `bool` | — |
| `mOtherHeart` | `otherHeart` | `String` | Free-text cardiac notes |
| `mColon` | `colon` | `bool` | — |
| `mConstipation` | `constipation` | `bool` | — |
| `mFamilyHistoryDM` | `familyHistoryDM` | `bool` | Family history of diabetes |
| `mPreviousOBMed` | `previousOBMed` | `bool` | Previous obesity medication |
| `mPreviousOBOperations` | `previousOBOperations` | `bool` | Previous bariatric surgery |
| `mRenal` | `renal` | `String` | — |
| `mLiver` | `liver` | `String` | — |
| `mGit` | `git` | `String` | GI tract notes |
| `mEndocrine` | `endocrine` | `String` | — |
| `mRheumatic` | `rheumatic` | `String` | — |
| `mAllergies` | `allergies` | `String` | — |
| `mNeuro` | `neuro` | `String` | — |
| `mPsychiatric` | `psychiatric` | `String` | — |
| `mOtherDiseases` | `otherDiseases` | `String` | Catch-all |
| `mHormonal` | `hormonal` | `String` | — |

---

### 5.5 `ClientConstantInfo` → Firestore collection: `ClientConstantInfo`

Lifestyle / permanent metadata per client.

| Dart field | Firestore key | Type | Notes |
|------------|--------------|------|-------|
| `mClientConstantInfoId` | `clientConstantInfoId` | `String` | Document ID |
| `mClientId` | `clientId` | `String?` | FK to Client |
| `mArea` | `area` | `String` | Residential area |
| `mActivityLevel` | `activityLevel` | `String?` | Enum name: `none`, `sedentary`, `mid`, `high` |
| `mYOYO` | `YOYO` | `bool` | Yo-yo dieting history |
| `mSports` | `sports` | `bool` | Exercises regularly |

**`Activity` enum values:** `none`, `sedentary`, `mid`, `high`

---

### 5.6 `ClientMonthlyFollowUp` → Firestore collection: `ClientMonthlyFollowUps`

InBody / body composition data taken during monthly follow-ups.

| Dart field | Firestore key | Type | Notes |
|------------|--------------|------|-------|
| `mClientMonthlyFollowUpId` | `clientMonthlyFollowUpId` | `String` | Document ID |
| `mClientId` | `clientId` | `String?` | FK to Client |
| `mBMI` | `BMI` | `double?` | Body Mass Index |
| `mPBF` | `PBF` | `double?` | Percent Body Fat |
| `mWater` | `water` | `String?` | Water intake (stored as string) |
| `mMaxWeight` | `maxWeight` | `double?` | Maximum recorded weight |
| `mOptimalWeight` | `optimalWeight` | `double?` | Target weight |
| `mBMR` | `BMR` | `double?` | Basal Metabolic Rate |
| `mMaxCalories` | `maxCalories` | `double?` | Upper calorie limit |
| `mDailyCalories` | `dailyCalories` | `double?` | Prescribed daily calories |
| `mMuscleMass` | `muscleMass` | `double?` | Muscle mass reading |
| `mDate` | `date` | `Timestamp?` | Follow-up date |
| `mNotes` | `notes` | `String?` | Free-text follow-up notes |

---

### 5.7 `Expense` → Firestore collection: `Expenses`

Clinic expense records.

| Dart field | Firestore key | Type | Notes |
|------------|--------------|------|-------|
| `mExpenseId` | `expenseId` | `String` | Document ID |
| `mName` | `name` | `String?` | Expense description |
| `mAmount` | `amount` | `double?` | Amount in local currency |
| `mDate` | `date` | `Timestamp` | Expense date |

---

### 5.8 `PreferredFoods` → Firestore collection: `PreferredFoods`

Food preference flags per client.

| Dart field | Firestore key | Type | Notes |
|------------|--------------|------|-------|
| `mPreferredFoodsId` | `preferredFoodsId` | `String` | Document ID |
| `mClientId` | `clientId` | `String?` | FK to Client |
| `mCarbohydrates` | `carbohydrates` | `bool` | — |
| `mProtein` | `protein` | `bool` | — |
| `mDairy` | `dairy` | `bool` | — |
| `mVeg` | `veg` | `bool` | — |
| `mFruits` | `fruits` | `bool` | — |
| `mOthers` | `others` | `String` | Free-text |

---

### 5.9 `WeightAreas` → Firestore collection: `WeightAreas`

Body areas where the client carries weight.

| Dart field | Firestore key | Type | Notes |
|------------|--------------|------|-------|
| `mWeightAreasId` | `weightAreasId` | `String` | Document ID |
| `mClientId` | `clientId` | `String?` | FK to Client |
| `mAbdomen` | `abdomen` | `bool` | — |
| `mButtocks` | `buttocks` | `bool` | — |
| `mWaist` | `waist` | `bool` | — |
| `mThighs` | `thighs` | `bool` | — |
| `mArms` | `arms` | `bool` | — |
| `mBreast` | `breast` | `bool` | — |
| `mBack` | `back` | `bool` | — |

---

### 5.10 Entity relationships

```
Client (1) ──► (1) ClientConstantInfo    (via clientConstantInfoId)
Client (1) ──► (1) Disease               (via diseaseId)
Client (1) ──► (1) PreferredFoods        (via preferredFoodsId)
Client (1) ──► (1) WeightAreas           (via weightAreasId)
Client (1) ──► (N) Visit                 (via clientId on Visit)
Client (1) ──► (N) ClientMonthlyFollowUp (via clientId on CMFU)
Client (1) ──► (1) Latest CMFU           (via lastMonthlyFollowUpId)
Client (1) ──► (1) Latest Visit          (via lastVisitId)

Clinic (singleton) ──► tracks checked-in Client IDs in checkedInClients map
Clinic (singleton) ──► tracks daily Client IDs in dailyClientIds list

Expense — standalone, not linked to clients
```

### 5.11 Firestore access layer

Each entity has a corresponding `*FirestoreMethods` class in `lib/Core/Model/Firebase/`:

| Class | Collection | Key operations |
|-------|-----------|----------------|
| `ClientFirestoreMethods` | `Clients` | create, fetchById, fetchByPhone, fetchByFirstName, fetchByFirstAndSecondName, fetchByName, update, delete |
| `ClinicFirestoreMethods` | `Clinic` | fetchClinic (single doc), updateClinic, checkInClient, checkOutClient, updateArrivedStatus |
| `VisitFirestoreMethods` | `Visits` | CRUD per clientId |
| `ExpenseFirestoreMethods` | `Expenses` | CRUD |
| `ClientConstantInfoFirestoreMethods` | `ClientConstantInfo` | CRUD per clientId |
| `ClientMonthlyFollowUpFirestoreMethods` | `ClientMonthlyFollowUps` | CRUD per clientId |
| `DiseaseFirestoreMethods` | `Diseases` | CRUD per clientId |
| `PreferredFoodsFirestoreMethods` | `PreferredFoods` | CRUD per clientId |
| `WeightAreasFirestoreMethods` | `WeightAreas` | CRUD per clientId |

All classes access Firestore through `FirebaseSingleton.instance.firestore` and use the `retry` package (`RetryOptions(maxAttempts: 3)`) for resilience. `ClinicFirestoreMethods` further refines retry to only retry on transient Firebase errors (`unavailable`, `aborted`, `deadline-exceeded`) and exposes an `onRetry` callback so the UI can show retry status.

---

## 6. Theming

Defined in `lib/theme/app_theme.dart`:

- **Light theme only** — no dark mode support
- **`AppColors`**: `primary` = `Colors.blue[800]`, `secondary` = `Colors.blue[50]`, `background` = white
- **`AppTheme.themeData`**: white card theme, blue text selection
- **Fonts**: `google_fonts` Cairo for headings and menu labels throughout page-level widgets

---

## 7. Navigation

The app uses **imperative `Navigator.push`** — no GoRouter, no named routes.

### Home page grid menu

The `HomePage` displays a **3-column grid** of navigation cards:

| Card | Target | Arabic label |
|------|--------|--------------|
| Search | `ClientSearchPage(state: "search")` | بحث |
| Check-in | `ClientSearchPage(state: "checkIn")` | تسجيل دخول |
| New client | `NewClientPage` | عميل جديد |
| Daily clients | `DailyClientsPage` | قائمة عملاء اليوم |
| Analytics | `AnalysisPage` | بيانات |
| Follow-up | `CheckedInClientsPage` | متابعة |
| Exit | Confirm dialog → `dailyClear()` → `exit(0)` | خروج |

Navigation within client flows is typically: search → client details → view/edit visits, follow-ups, etc.

---

## 8. OTA updates (Shorebird)

`lib/Shorebird/update_service.dart` wraps the `shorebird_code_push` package:

1. On launch: `initPatch()` reads the current installed patch number
2. From `HomePage.initState`: `checkForUpdates(context)` checks Shorebird servers
3. If outdated: shows an Arabic dialog → downloads update with progress dialog → prompts restart (on Windows: closes the app via `windowManager.close()`)

App ID: `2cd10a55-dca2-4fc5-9699-8efd55291c89` (in `shorebird.yaml`)

---

## 9. Debug logging

`lib/Core/Services/DebugLoggerService.dart` provides a global `mDebug(String)` function:

- **Debug mode**: prints to terminal via `debugPrint`
- **Release mode**: stores `DebugLogEntry` objects in-memory (max 500), archives to disk every 30 minutes via `path_provider`
- **`GlobalDebugOverlay`** (`lib/Core/View/Debug/`) provides an in-app floating panel to view logs in production

All Firestore methods, providers, and page-level controllers use `mDebug()` for structured logging.

---

## 10. Dependencies

See `pubspec.yaml` for exact versions. Grouped by purpose:

| Purpose | Package |
|---------|---------|
| **State / DI** | `provider` |
| **Backend** | `firebase_core`, `cloud_firestore` |
| **OTA updates** | `shorebird_code_push` |
| **Window management** | `window_manager` |
| **Fonts** | `google_fonts` |
| **Date/locale** | `intl`, `intl_utils` |
| **Resilience** | `retry` |
| **Audio** | `audioplayers` |
| **File paths** | `path_provider` |
| **Icons** | `cupertino_icons` |
| **Linting** | `flutter_lints` (dev) |

---

## 11. CI/CD

### GitHub Actions (`.github/workflows/ci.yml`)

Runs on pushes and PRs to `main` on `windows-latest`:

1. `flutter pub get`
2. Copy `apiKeys.dart` from template
3. `dart fix --apply`
4. `flutter analyze`
5. `flutter test`

### Local CI (`scripts/run_ci_locally.ps1`)

Mirrors the GitHub Actions pipeline for pre-push verification. Run via:

```powershell
powershell -ExecutionPolicy Bypass -File "scripts/run_ci_locally.ps1"
```

---

## 12. Sensitive files and templates

| File | Purpose | Committed? |
|------|---------|------------|
| `lib/firebase_setup/apiKeys.dart` | Real Firebase API keys | **No** (gitignored) |
| `lib/firebase_setup/apiKeys.dart.example` | Template with placeholder keys | Yes |
| `lib/firebase_setup/firebase_options.dart` | Flutter Firebase config | Yes |
| `shorebird.yaml` | Shorebird app ID (not secret) | Yes |

CI scripts copy `.example` → real file before building.

---

## 13. Tests

Currently minimal:

- `test/widget_test.dart` — default Flutter widget test

Test coverage should be expanded as the app grows.

---

## 14. Data migration

`lib/firebase_setup/MigrationService.dart` contains one-off Firestore migration scripts (called from `HomePage._runMigrations()`, currently commented out in production):

- Backfill monthly follow-up dates from last visit
- Backfill `lastMonthlyFollowUpId` on clients
- Backfill notes field for existing follow-ups
- Delete clients with empty IDs
- Sync client weight/diet from latest records
- Migrate checked-in clients from ID-list format to map format

These are run manually by uncommenting the calls in `HomePage`.
