# eSumbong — Barangay Justice Mobile App

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/Version-0.1.0-teal" />
  <img src="https://img.shields.io/badge/License-MIT-green" />
</p>

---

## About the Project

### The Problem

In the Philippines, barangay-level dispute resolution — governed by **Republic Act 7160 (Local Government Code)** and the **Katarungang Pambarangay** system — requires citizens to physically visit their barangay hall to file complaints, attend mediation hearings, and track the progress of their cases. This creates significant barriers:

- Citizens have **no visibility** into their case status once filed.
- Barangay staff manage cases through **paper records**, making scheduling and tracking inefficient.
- No-show hearings go unlogged or are recorded manually.
- Certificates to File Action (CFA) are issued on paper with **no digital verification** mechanism.

### The Solution

**eSumbong** is a cross-platform mobile application that digitizes the barangay justice process from end to end. It bridges the gap between citizens and barangay staff by providing:

| Role | What They Can Do |
|---|---|
| **Citizen** | File complaints, track case status in real time, receive hearing updates, and view generated CFAs |
| **Barangay Staff** | Manage all cases, schedule hearings, log no-shows, generate CFAs with QR codes, and verify documents via QR scan |

The app also includes **Ezu**, a built-in Philippine legal assistant chatbot that helps citizens understand their rights, relevant Republic Acts, and the Katarungang Pambarangay process — entirely offline with no API dependency.

### Key Features

- 📋 **Digital Case Filing** — Citizens submit complaints with supporting evidence attachments directly from their phone
- 🔔 **Real-time Status Updates** — Case events (summons, hearings, no-shows, CFA issuance) are reflected instantly in the notifications feed
- 📅 **Hearing Scheduler** — Staff schedule hearings with date/time pickers; summons are triggered automatically
- 🚫 **No-Show Logging** — Staff log respondent absences; the system escalates to CFA eligibility at 3 no-shows
- 📄 **CFA Generation & QR Verification** — Certificates are generated with a tamper-evident QR payload that can be independently verified in-app
- 🤖 **Ezu Legal Chatbot** — Hardcoded Philippine legal assistant covering VAWC (RA 9262), Child Abuse (RA 7610), Juvenile Justice (RA 9344), Data Privacy (RA 10173), the KP process, protection orders, and more
- 🔐 **Role-Based Access Control** — Citizens and barangay staff see completely different UIs, with hard router guards preventing unauthorized access
- 👤 **Account-Linked Cases** — Cases are associated to an account via Firebase UID, phone number, and name — surviving re-logins

---

## Technology Stack

### Language & Framework

| Tool | Purpose |
|---|---|
| [Dart 3](https://dart.dev) | Primary programming language |
| [Flutter 3](https://flutter.dev) | Cross-platform UI framework (Android, iOS, Windows, Web) |

### State Management & Navigation

| Package | Version | Purpose |
|---|---|---|
| [flutter_riverpod](https://riverpod.dev) | `^2.6.1` | Reactive state management and dependency injection |
| [go_router](https://pub.dev/packages/go_router) | `^14.8.1` | Declarative URL-based navigation with role-based redirect guards |

### Firebase (Backend-as-a-Service)

| Package | Version | Purpose |
|---|---|---|
| [firebase_core](https://pub.dev/packages/firebase_core) | `^3.15.2` | Firebase app initialization |
| [firebase_auth](https://pub.dev/packages/firebase_auth) | `^5.6.0` | User authentication (email/password + anonymous mock OTP) |
| [cloud_firestore](https://pub.dev/packages/cloud_firestore) | `^5.6.9` | NoSQL real-time database for cases, users, and events |
| [cloud_functions](https://pub.dev/packages/cloud_functions) | `^5.6.0` | Callable Cloud Functions for PDF/QR generation and summons |
| [firebase_messaging](https://pub.dev/packages/firebase_messaging) | `^15.2.7` | Push notification delivery (mocked on Spark plan) |
| [firebase_storage](https://pub.dev/packages/firebase_storage) | `^12.4.7` | Evidence file uploads (images, PDFs) |

### UI & Utilities

| Package | Version | Purpose |
|---|---|---|
| [google_fonts](https://pub.dev/packages/google_fonts) | `^6.2.1` | **Outfit** typeface for the design system |
| [intl](https://pub.dev/packages/intl) | `^0.20.2` | Date/time formatting |
| [file_picker](https://pub.dev/packages/file_picker) | `^8.1.7` | Evidence file attachment from device storage |
| [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) | `^6.0.1` | Environment variable management (`.env` asset) |

### Design System

- **Color palette** — Teal (`#0F766E`) primary, amber secondary, light neutral background (`#F5F7FB`)
- **Typography** — Google Fonts **Outfit** across all text styles
- **Material 3** — `useMaterial3: true` with custom `ColorScheme.fromSeed`
- **Components** — Custom `AppCard`, `StatusChip`, `CaseTimeline`, `SectionHeader` shared widgets

---

## Architecture

The project follows a **feature-first layered architecture**:

```
lib/src/
├── core/
│   ├── router/         # GoRouter configuration with role-based guards
│   └── theme/          # AppTheme, color palette, typography
└── features/
    ├── auth/           # Firebase Auth, AppUser model, mock OTP
    ├── cases/          # Complaint domain, repositories, providers, screens
    ├── admin/          # Barangay staff case management panel
    ├── chatbot/        # Ezu legal assistant (hardcoded responses)
    ├── dashboard/      # Role-split home screen (citizen vs. staff)
    ├── notifications/  # Case-event notification feed + FCM service
    └── profile/        # User profile, account info, sign-out
```

Each feature is organized into:
- `data/` — Repository implementations, providers, external services
- `domain/` — Pure Dart models (no Flutter dependency)
- `presentation/` — Screens and widgets

---

## Legal Foundation

eSumbong is built around the Philippine barangay justice framework:

| Law | Coverage in App |
|---|---|
| **RA 7160** — Local Government Code | Katarungang Pambarangay system, Lupon Tagapamayapa, CFA process |
| **RA 9262** — VAWC Act | Complaint filing, protection orders (BPO/TPO/PPO) |
| **RA 7610** — Child Abuse Protection | Case context, Ezu chatbot guidance |
| **RA 9344** — Juvenile Justice | Ezu chatbot guidance |
| **RA 10173** — Data Privacy Act | Ezu chatbot guidance |

---

## Credits

### Open Source Packages

All packages used are listed under the [Technology Stack](#technology-stack) section above and are available on [pub.dev](https://pub.dev) under their respective open-source licenses.

### Firebase

Backend infrastructure provided by [Google Firebase](https://firebase.google.com). Authentication, Firestore, Storage, and Cloud Functions services are used under the Firebase [Terms of Service](https://firebase.google.com/terms).

### Fonts

**Outfit** typeface provided by [Google Fonts](https://fonts.google.com/specimen/Outfit) under the [SIL Open Font License 1.1](https://scripts.sil.org/OFL).

### Icons

Material Design Icons provided by Google under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

### Legal References

- Republic Act 7160 — [Chan Robles Virtual Law Library](https://www.chanrobles.com/localgovernmentact.htm)
- Republic Act 9262 — [Official Gazette of the Philippines](https://www.officialgazette.gov.ph/2004/03/08/republic-act-no-9262/)
- Republic Act 7610 — [Official Gazette of the Philippines](https://www.officialgazette.gov.ph/1992/06/17/republic-act-no-7610/)
- Republic Act 9344 — [Official Gazette of the Philippines](https://www.officialgazette.gov.ph/2006/04/28/republic-act-no-9344/)
- Republic Act 10173 — [National Privacy Commission](https://www.privacy.gov.ph/data-privacy-act/)

---

## Disclaimer

> eSumbong is an educational and prototype application. It does not constitute legal advice. Legal information provided by the Ezu chatbot is general in nature. For case-specific guidance, consult a licensed Philippine attorney or your local Lupon Tagapamayapa.

---

<p align="center">Made with ❤️ for Filipino communities.</p>
