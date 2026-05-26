# JumPedia

> A 2D vertical platformer mobile game with an educational twist — built around UN Sustainable Development Goal 4 (Quality Education).

Jump from platform to platform, collect knowledge, and unlock fun facts about education along the way.

---

## What is JumPedia?

JumPedia is a Flutter-based mobile game that blends **arcade-style platforming** with **educational micro-content**. The character is a friendly 3D mascot wearing a graduation cap bounces upward across procedurally placed platforms while the player collects books and avoids obstacles. Every **100 points** the player earns, the game pauses to reveal an SDG 4 fun fact, which is then saved to the player's personal collection in the cloud.

The result is a casual game loop where progression is measured **not just in score, but in knowledge collected**.

---

## Key Features

### Gameplay

- **Vertical platformer** with procedurally generated platforms (normal, moving, breakable)
- **Three control modes**: on-screen left/right buttons (mobile), keyboard A/D or arrow keys (desktop), tilt-aware fallback via accelerometer
- **Power-ups**: shield (immune to obstacles) and speed boost from globe collectibles
- **HP system** with 3 hearts, game over when hearts hit zero or the player falls off-screen
- **Animated sky background** with parallax-scrolling clouds for depth perception

### Educational layer

- **Fun fact checkpoints** every 100 points — gameplay pauses to display a curated SDG 4 fact
- **Personal collection page** — every fact you unlock is saved per-user in Firestore and viewable as a grid (collected = blue card, locked = "???" outline)
- **Progress tracker** — "5 / 12 facts" with progress bar
- **Bonus fact reward** on the Game Over screen so every run ends with something learned

### Account & social

- **Firebase Authentication** with Google Sign-In and anonymous guest mode
- **Global leaderboard** — top 10 scores from all players
- **Per-user stats** — best score and games played, surfaced on the home dashboard
- **Settings**: update username, sign out, delete account

### Other

- **Push notifications** via Firebase Cloud Messaging (foreground + background)
- **Bottom navigation bar** with three tabs (Home, Fun Facts, Leaderboard)
- **Light mode** with a clean pastel-blue brand palette
- **Custom mascot** rendered in 3D — appears on login, home, and the fun facts page

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart `>=3.2.0`) |
| Game engine | [Flame](https://flame-engine.org/) `^1.18.0` |
| State management | [Riverpod](https://riverpod.dev/) `^2.5.1` |
| Routing | [go_router](https://pub.dev/packages/go_router) `^13.2.0` with `ShellRoute` for the bottom-nav layout |
| Auth | `firebase_auth` + `google_sign_in` (anonymous mode supported) |
| Database | Cloud Firestore |
| Push notifications | Firebase Cloud Messaging + `flutter_local_notifications` (foreground) |
| Analytics | Firebase Analytics (prod flavor only) |
| Sensors | `sensors_plus` (accelerometer-driven fallback) |

---

## Project Structure

```
lib/
├── core/
│   ├── constants/        ← AppColors, AppConstants, FirestorePaths
│   └── utils/            ← AppLogger
├── models/               ← UserModel, LeaderboardModel, FunFactModel, CollectedFactModel
├── services/             ← AuthService, ScoreService, UserService,
│                            FunFactService, CollectedFactService,
│                            NotificationService
├── providers/            ← Riverpod providers for auth/score/HP/fun facts
├── game/
│   ├── world/            ← GameWorld (FlameGame entry point)
│   ├── components/       ← Player, Platform, Obstacle, Collectible, SkyBackground
│   └── overlays/         ← HudOverlay, FunFactOverlay
└── presentation/
    ├── screens/          ← Splash, Login, Home, Game, GameOver,
    │                       FunFacts, Leaderboard, Settings, MainShell
    └── widgets/          ← SdgButton (reusable styled button)
```

### Cloud schema (Firestore)

```
users/{uid}
  ├── uid, username, total_games_played, created_at, fcm_token
  └── collected_facts/{factId}       ← personal collection (full CRUD)
        ├── fact_id, content, category, collected_at

leaderboard/{auto}                   ← per-session score entries
  └── user_id (ref), score, timestamp

fun_facts/{factId}                   ← master fact list (read-only from app)
  └── fact_id, content, category
```

The `collected_facts` subcollection demonstrates **full CRUD**:
- **C**: when a player unlocks a fact in-game
- **R**: streamed live to the Fun Facts page
- **U**: "Refresh" button re-syncs content from the master list
- **D**: per-fact delete + batch "Reset all" button

---

## Running Locally

### Prerequisites

- Flutter SDK `>=3.2.0`
- Android Studio / Xcode for device emulation
- A Firebase project with:
  - Authentication → Google + Anonymous providers enabled
  - Firestore in production or test mode
  - Cloud Messaging enabled
  - `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) placed in the platform folders

### Setup

```bash
# 1. Install dependencies
flutter pub get

# 2. (One-time) Configure FlutterFire
dart pub global activate flutterfire_cli
flutterfire configure

# 3. Run on a connected device or emulator
flutter run
```

### Build flavors

Two entry points are available:

- `flutter run -t lib/main_dev.dart`  → dev flavor (analytics disabled, debug banner on)
- `flutter run -t lib/main_prod.dart` → prod flavor (analytics enabled, debug banner off)

### Game controls

| Platform | Left / Right | Notes |
|---|---|---|
| Mobile | On-screen buttons (hold to move) | Always visible at the bottom during gameplay |
| Desktop / Web | `A` / `D` or `←` / `→` | Hint label shown in the corner |
| All | Tap left half / right half of screen | Fallback when buttons are obscured |

Jumping is automatic — landing on a platform triggers a bounce.

---

## Functional Feature that establishes a complete end-to-end connection between the cloud server and the mobile application.
- Dustin : LeaderBoard & Funfact collection

---

## Roadmap / TODO

- [ ] External API integration (e.g. UNESCO UIS, World Bank Education indicators) to enrich the fact pool
- [ ] Daily login streak rewards
- [ ] Achievements / badges system
- [ ] Sound effects + background music (assets folder is already wired in `pubspec.yaml`)
- [ ] iOS testing & App Store assets

---

## Credits

- **Theme**: UN SDG 4 — Quality Education
- **Mascot character**: custom 3D illustration (orange-faced student with graduation cap & cape)
- **Game engine**: [Flame](https://flame-engine.org/)
- **Built with**: Flutter, Firebase

---

## License

This project was built as a coursework submission for **PBB (Pemrograman Berbasis Bergerak / Mobile Programming)** at university level. Not licensed for redistribution.
