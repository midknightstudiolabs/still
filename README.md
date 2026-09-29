# Still

**Weekly direction. Daily visibility. No daily pressure.**

A Flutter mobile MVP that keeps what matters from disappearing when life gets busy. A vision has a reason, an image, a rhythm, and one current Next Move. Real-life evidence becomes a timeline; a completed vision becomes a memory.

## What is included

- iOS and Android project runners, with a web runner for convenient development.
- Warm ivory and forest-green design, bundled editorial photography, Manrope and Cormorant typography, light/dark/system themes, and quiet transitions.
- Welcome screen with explicit demo entry; an optional personal profile; seven vision-creation steps; photo-library selection and offline suggested images.
- One focused question at a time, numeric progress, cozy rounded answer choices, Back, optional skips, local draft checkpoints, Save and close, and an editable review before committing. Personal profiling is no longer required before creating a vision.
- Today shows the latest real Proof and the chosen obstacle's guidance. Not today now lasts for the local calendar day across reopening, with Undo rest.
- Optional multiple life roles, a user-selected priority, situational obstacles, and realistic time preferences. Settings supports editing and clearing these answers without deleting the board.
- Editable, rule-based Next Move examples, per-vision obstacles, and optional when/if action cues. No AI or personality assessment.
- Tone descriptions with actual Today previews, plus an in-app research explanation. See [research and guidance rules](RESEARCH.md) for sources, implementation choices, and evidence limits.
- See [experience research and acceptance checks](UX-RESEARCH.md) for the one-question approach, accessibility decisions, actual preview coverage, and remaining product-validation work.
- One featured vision at a time, horizontal swiping, a single Next Move, proof count, and a consequence-free “Not today.”
- Vision collection grouped into Right Now, Later, It Happened, and Let Go.
- A maximum of three active visions, with an atomic swap-to-Later flow when adding or reactivating a fourth.
- Next Move creation, replacement history, completion, automatic proof, and an optional invitation to choose another move.
- Photo/note/date proof, a vertical timeline, and subtle acknowledgment.
- Weekly reflection: Still Mine, Slow Down, Later, Let Go. Still Mine offers a move and optional proof. Slowing down reduces the rhythm.
- A welcome-back review after 14 or more days away; interruption preserves the old visit timestamp until acknowledged.
- Completed visions and proof in Memories, including original inspiration and a real photo for Then / Now.
- Tone preferences, theme, an honest notification placeholder, reset confirmation, and return-flow preview.
- Versioned local persistence, test suite, and a read-only widget projection for a future native widget implementation.

## Validation status

**Live app: https://midknightstudiolabs.github.io/still/**

**Version 1.2.1 verified on GitHub Actions (Ubuntu): static analysis, all 30 automated tests, the release web build, and Pages deployment passed.** The live version endpoint reports 1.2.1 build 4. Nine mobile widget previews were generated and visually reviewed, including dark mode and a 320-pixel screen at 160% text scaling. [Successful deployment](https://github.com/midknightstudiolabs/still/actions/runs/36560225272).

Flutter 3.47.5 / Dart 3.13.4 were used. Windows application control originally prevented local runtime testing; the Linux cloud runner subsequently executed the tests and web build successfully. Narrow-layout and test-interaction issues discovered in the first run were corrected before deployment. Native APK/iOS builds and real-device photo picking remain unverified.

## Run

For browser hosting on GitHub, see [GITHUB-PAGES.md](GITHUB-PAGES.md). A GitHub Actions workflow is included to test, build, and publish the web app.

Use **Flutter 3.47.5 stable** (Dart 3.13.4), matching the included native templates and lockfile. Install the relevant platform tools using the [official Flutter setup guide](https://docs.flutter.dev/install). Android needs its SDK and JDK; iOS needs macOS, Xcode, and CocoaPods. No account or backend credentials are required.

```sh
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <device-id>
```

For a browser preview of the same Flutter app:

```sh
flutter run -d chrome
```

For platform builds:

```sh
flutter build apk --debug
# On macOS:
flutter build ios --no-codesign
```

If the Gradle shell script is not executable after extracting the ZIP on macOS/Linux, run `chmod +x android/gradlew`. Flutter generates machine-specific configuration during `flutter pub get` / `flutter run`. For an iPhone, select your development team in `ios/Runner.xcworkspace` and use a unique bundle identifier before signing. The current identifier is `app.still.vision`. Release distribution, store signing, and publication are not configured.

Start with **“What matters to you?”** to create your own vision, or **“Take a look around · Try the demo”** to load the three supplied examples. Demo mode is clearly labeled and stores its sample content locally. Settings → Start fresh clears the demo or personal data after confirmation.

## Architecture

```text
lib/
  domain/models.dart                 Entities, enums, serialization, widget projection
  data/repository.dart               Repository interface and local snapshot adapter
  data/demo.dart                     Explicit sample data
  application/still_controller.dart  Invariants, commands, persistence, return detection
  presentation/design.dart           Theme, bundled-image rendering, photo picker, shared UI
  domain/guidance.dart               Explicit examples and barrier guidance
  presentation/profile.dart          Optional profile and research explanation
  presentation/onboarding.dart       Seven-step vision creation flow
  presentation/question_flow.dart    Shared focused question, progress, answers, review
  presentation/home.dart             Today, Visions, Memories, Settings, lifecycle handling
  presentation/detail.dart           Vision timeline, move history, status changes
  presentation/editors.dart          Next Move, Proof, room-making, Let Go sheets
  presentation/review.dart           Weekly and welcome-back review
  main.dart                         Startup, data-load protection, app composition
test/
  journeys_test.dart                 Domain journeys, persistence, concurrency, failures
  ui_test.dart                       Onboarding, profile, suggested moves, tone descriptions, Not today
  guidance_test.dart                 Legacy data, profiles, action cues, failed saves
  experience_test.dart               Draft recovery, review editing, contrast, large text, UI previews
android/                            Kotlin/Gradle runner
ios/                                Swift/Xcode runner and CocoaPods configuration
web/                                Optional browser development runner
assets/                             Offline photos, fonts, font licenses
```

### Persistence and state

The `VisionRepository` boundary loads and saves `AppData`. The local implementation stores one JSON snapshot using SharedPreferences, keeping related records together under a versioned key. Commands run in a queue, clone the current data, validate the operation, await storage, then publish the saved state. Failed writes leave the visible data unchanged. Unknown schema versions or malformed JSON are reported without replacing existing content.

Selected images are resized to at most 1200 × 1400 pixels by the picker, limited to 2.5 MB per image, and copied as data URIs into the saved snapshot. They do not depend on temporary picker paths or internet access. Bundled images and fonts are offline assets. This approach is appropriate for a small MVP; a larger photo library should move to private image files plus SQLite/Isar metadata, with migration from schema v1. There is no encrypted vault, backup, export, or cloud sync in this version. Clearing app data or uninstalling can remove the local journal.

Next Moves have current/completed/replaced states. Replacing a move preserves the old record. Completing a move is idempotent, archives it, creates an action proof, and clears the active pointer. Pausing or letting go preserves all history. Status changes have no failure state or progress score.

### Rhythm, reflection, and return

All active visions remain a swipe away. Rhythm weights the initial daily focus; it never creates a due date. Weekly reflection is offered when no completed review exists or seven days have passed. A completed review advances `lastReview`. Pausing a review does not mark it completed.

Startup and resume compare `lastAppOpen` with the current time. After 14 days away, the return review takes priority. No moves, proof, or progress are reset. Settings → Preview a gentle return simulates 15 days away for review.

### Future integration

- Implement a cloud-backed `VisionRepository` with conflict resolution, photo uploads, ownership, and schema migrations before adding Supabase/Firebase authentication. The current interface is a snapshot boundary; production sync should evolve toward per-entity operations and tombstones.
- `WidgetVision` and `controller.widgetSnapshot` expose only image, title, and why. A later Android/iOS adapter can materialize data-URI photos into shared files and publish this projection to native widgets. No native widget is claimed in this MVP.
- `notificationsEnabled` is reserved in preferences and remains false. The UI clearly explains that notifications are not sent. Add permission handling and local notification scheduling later.

## Verification checklist

The automated coverage below passed on GitHub Actions. Manual follow-ups remain to be checked on devices.

| Journey | Automated coverage / manual follow-up |
|---|---|
| First vision | Controller round trip + full onboarding widget test |
| Add Next Move | Controller + onboarding widget test |
| Complete Next Move | Completion history, automatic proof, repeat protection |
| Add Proof | Note/photo/date round trip; verify native photo picker on devices |
| Three active visions | Capacity and concurrent-creation tests |
| Fourth active vision | Atomic rejection and swap; manually inspect room-making sheet |
| Weekly check-in | Keep, slow down, seven-day scheduling; inspect full sheet flow |
| Move to Later | Status and preserved history |
| Let Go | Stored reason, status, preserved history |
| It Happened | Milestone, date, original image, real photo |
| Return after 14+ days | Restart persistence, acknowledgment, preserved move |
| Change tone | Manifestation/No Quotes persistence, theme persistence |
| Not today | Widget test checks unchanged move and proof |
| Failed save | No partial visible mutation; queue can recover |
| Corrupt data | Existing storage is retained and error surfaced |
| Reset and demo | Clean state, three demo visions, widget projection |

Also inspect 320-pixel-wide devices, large text, keyboard visibility, light and dark appearance, screen readers, photo-picker cancellation/denial, and native relaunch with user photos. The UI is scrollable, but a rendered visual QA pass is still required.

## Product review

The design gives one vision and one action prominence. No checklist dashboard, streak, deadline warning, performance chart, percentage, or quote library exists. “Not today,” Later, and Let Go are normal choices. Proof comes from real life. The first actionable button is “What matters to you?” or, in the demo, “I did something.” These choices follow the brief; perceived polish and the ten-second comprehension test still need a device review.

See `ASSETS.md` for image provenance and font licenses.
