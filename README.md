# JumPedia

> A 2D vertical platformer mobile game with an educational twist — built around UN Sustainable Development Goal 4 (Quality Education).

Jump from platform to platform, collect knowledge, and unlock AI-generated science fun facts along the way.

---

## What is JumPedia?

JumPedia is a Flutter-based mobile game that blends **arcade-style platforming** with **educational micro-content**. A friendly 3D mascot (Lumi) wearing a graduation cap bounces upward across procedurally placed platforms while the player collects books and dodges a "lazy-thinking AI" robot. Every **300 points**, the game pauses to reveal a science fun fact — **generated in real time by Google Gemini AI** — which is then saved to the player's personal collection in the cloud.

The result is a casual game loop where progression is measured **not just in score, but in knowledge collected**. The "lazy-thinking AI" obstacle reinforces the theme: rely on AI to think for you and you lose — keep learning and thinking for yourself to win.

---

## Key Features

### Gameplay

- **Vertical platformer** with procedurally generated platforms — three types with distinct sprites & behavior: **normal** (grass), **moving** (stone, slides horizontally), and **breakable** (wood, plays a break animation when stepped on)
- **Animated characters & items**: Lumi has 6 pose sprites (idle/jump/land/hurt/collect/shield); collectibles & the obstacle use multi-frame float animations
- **Controls**: on-screen left/right buttons (mobile) and keyboard `A`/`D` or arrow keys (desktop)
- **Shield power-up** from globe collectibles — temporary immunity to obstacles
- **HP system** with **5 hearts**; game over when hearts hit zero or the player falls off-screen
- **Haptic feedback** on jump, collect, hit, and game over (toggleable)
- **Background music + sound effects** with independent volume sliders and a quick mute toggle
- **Animated sky background** with parallax-scrolling clouds
- **In-game pause menu** (Resume / Restart / Home)

### Educational layer

- **AI fun-fact checkpoints** every **300 points** — gameplay pauses and Google Gemini generates a fresh, kid-friendly science fact (with offline fallback facts if AI is unavailable)
- **Anti-duplicate system** (two layers): the AI is told which facts the user already owns, and identical content is rejected on save
- **Personal collection page** — every fact is saved per-user in Firestore, shown as a grid; mark favorites, delete individual facts, or reset the whole collection
- **Fun-fact language** selectable independently (English / Bahasa Indonesia)

### Account & social

- **Firebase Authentication** with Google Sign-In and anonymous guest mode
- **Global leaderboard** — top 10 scores (guest scores are *not* saved to the leaderboard)
- **Per-user stats** — best score & games played on the home dashboard; reset best score from Profile
- **Achievements / badges** — 7 unlockable achievements (first game, score 500/1000, 10/50 games, 10/25 facts) stored in Firestore and shown on the Profile page
- **Custom profile photo** — upload your own picture, stored in **Supabase Storage** (falls back to built-in avatars)

### Polish & UX

- **Bilingual UI** (English / Bahasa Indonesia) across the whole app, switchable in Settings
- **Custom typography** — Poppins (headings) + Nunito (body), bundled offline
- **Consistent design system** — centralized theme, design tokens, reusable card/state widgets, button press animations, page transitions
- **About page** detailing the SDG 4 targets the game supports (4.1 & 4.7)
- **Custom app icon** & brand logo
- **Push notifications** via Firebase Cloud Messaging

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart `>=3.2.0`) |
| Game engine | [Flame](https://flame-engine.org/) `^1.18.0` + `flame_audio` |
| State management | [Riverpod](https://riverpod.dev/) `^2.5.1` |
| Routing | [go_router](https://pub.dev/packages/go_router) `^13.2.0` with `ShellRoute` for the bottom-nav layout |
| Auth | `firebase_auth` + `google_sign_in` (anonymous mode supported) |
| Database | Cloud Firestore |
| Media storage | **Supabase Storage** (custom profile photos) |
| AI content | `google_generative_ai` (Gemini) for fun-fact generation |
| Push notifications | Firebase Cloud Messaging + `flutter_local_notifications` |
| Analytics / Crash | Firebase Analytics & Crashlytics |
| Local prefs | `shared_preferences` (language, volume, haptic) |
| Media | `image_picker` (profile photo) |

---

## Project Structure

```
lib/
├── core/
│   ├── config/           ← ApiKeys (Gemini + Supabase, gitignored)
│   ├── constants/        ← AppColors, AppConstants, AppDimens, FirestorePaths
│   ├── i18n/             ← AppStrings (EN/ID), UiLanguage
│   ├── theme/            ← AppTheme (Poppins/Nunito, component themes)
│   └── utils/            ← AppLogger
├── models/               ← UserModel, LeaderboardModel, FunFactModel,
│                            CollectedFactModel, AchievementModel
├── services/             ← Auth, Score, User, FunFact, CollectedFact,
│                            Achievement, Notification, Audio, Haptic,
│                            GeminiFunFact, ProfilePhoto (Supabase)
├── providers/            ← Riverpod providers (auth, score, HP, fun facts,
│                            achievements, audio, language)
├── game/
│   ├── world/            ← GameWorld (FlameGame entry point)
│   ├── components/       ← Player, Platform, Obstacle, Collectible, SkyBackground
│   └── overlays/         ← HudOverlay, FunFactOverlay, TutorialOverlay
└── presentation/
    ├── screens/          ← Splash, Login, Home, Game, GameOver, FunFacts,
    │                       Leaderboard, Profile, Settings, About, MainShell
    └── widgets/          ← SdgButton, AppCard, state views
```

### Cloud schema

**Firestore**
```
users/{uid}
  ├── uid, username, avatar_path, photo_url,
  │   notifications_enabled, total_games_played, created_at, fcm_token
  ├── collected_facts/{factId}   ← personal fact collection (full CRUD)
  │     └── fact_id, content, category, collected_at, is_favorite
  └── achievements/{id}          ← unlocked badges
        └── id, unlocked_at

leaderboard/{uid}                ← best score per user (Google accounts only)
  └── user_id (ref), score, timestamp
```

**Supabase Storage**
```
bucket: avatars/
  └── {uid}.jpg                  ← custom profile photo (public URL saved to users/{uid}.photo_url)
```

The `collected_facts` subcollection demonstrates **full CRUD**:
- **C**: a fact is saved when unlocked at a checkpoint
- **R**: streamed live to the Fun Facts page
- **U**: toggle favorite on a fact
- **D**: per-fact delete + batch "Reset all"

---

## Running Locally

### Prerequisites

- Flutter SDK `>=3.2.0`
- Android Studio for device emulation
- A **Firebase** project with: Auth (Google + Anonymous), Firestore, Cloud Messaging, and `google-services.json` in `android/app/`
- A **Supabase** project with a public Storage bucket named `avatars` (for profile photos)
- API keys — see below

### Configure keys

Copy the template and fill in your keys (the real file is gitignored):

```bash
cp lib/core/config/api_keys.example.dart lib/core/config/api_keys.dart
```

Then set in `api_keys.dart`:
- `geminiApiKeyFallback` — Google Gemini key ([aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey))
- `supabaseUrl` & `supabaseAnonKey` — from Supabase → Settings → API

### Run

```bash
flutter pub get
flutter run -t lib/main_dev.dart        # dev (debug banner on)
flutter run -t lib/main_prod.dart       # prod (no banner, label "JumPedia")
```

### Build a release APK

```bash
flutter build apk --release -t lib/main_prod.dart
# output: build/app/outputs/flutter-apk/app-release.apk
```

> Note: the release build is currently signed with the debug key (fine for sharing/demo, not for the Play Store).

### App icon

The launcher icon is generated from `assets/images/logo_app.png`:

```bash
dart run flutter_launcher_icons
```

---

## Controls

| Platform | Move | Notes |
|---|---|---|
| Mobile | On-screen Left / Right buttons (hold) | Always visible during gameplay |
| Desktop | `A` / `D` or `←` / `→` | — |

Jumping is automatic — landing on a platform triggers a bounce.

---

## Team & Responsibilities

- **Dustin** — Leaderboard, Fun-fact collection (CRUD), achievements, profile photo (Supabase), UI/UX polish

---

## Credits

- **Theme**: UN SDG 4 — Quality Education
- **Mascot (Lumi)**: custom 3D illustration (graduate with cap & cape)
- **Game engine**: [Flame](https://flame-engine.org/)
- **AI**: Google Gemini
- **Built with**: Flutter, Firebase, Supabase

---

## License

Built as a coursework submission for **PBB (Pemrograman Berbasis Bergerak / Mobile Programming)**. Not licensed for redistribution.
