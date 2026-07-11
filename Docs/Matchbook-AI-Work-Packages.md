# Matchbook — AI Work Packages (v2)

This document splits the Matchbook technical spec (`matchbook-build-spec.md` v2 / `Matchbook-Technical-Documentation.md` v2) into standalone, sequentially-buildable work packages (WP0–WP13). Each package is self-contained enough to hand to an AI coding agent on its own, states what it depends on, and ends with a ready-to-use English prompt.

**Build order matters.** Packages are numbered in the order they should be implemented — each one assumes everything in the earlier packages already exists in the codebase.

**Changelog (v1 → v2) — what changed in this rewrite:**
- **Localization moved early.** It was a single rollout package at the very end (old WP10); it's now split in two: **WP2 — Localization Infrastructure** runs right after the data layer, before any feature screen is built, so every screen from WP3 onward is written against String Catalog from its first line instead of being retrofitted. A smaller **WP11 — Localization QA & Full Translation Pass** stays near the end to catch drift and finish English coverage once the UI surface is stable (translating screens that are still changing wastes effort — see `matchbook-build-spec.md` §8).
- **Repository pattern added.** WP1 now also defines `PlayerRepository` / `TournamentRepository` / `MatchRepository` / `MediaRepository` protocols (build-spec §3.9). Every later package routes writes/deletes/paywall-gates through these instead of touching `modelContext` directly — this is what keeps a future CloudKit→Firebase swap contained.
- **Corrected CloudKit claim.** WP1's comments and prompt no longer imply that two different Apple IDs see the same child through plain CloudKit sync — that requires `CKShare`, which is Phase 2 (WP13).
- **Edit/delete flows added** to child profile (WP3), tournament (WP4), match (WP5), and media (WP8), each with an explicit confirmation step.
- **Empty/error states added**: iCloud-not-signed-in and new-device-still-syncing states in WP1; empty-tournament state in WP6.
- **Offline-first made explicit** in WP5 (quick match entry): local save must never depend on network.
- **Paywall downgrade behavior added** to WP10: over-limit content becomes read-only, not hidden/deleted, when a subscription lapses.
- **New WP12 — Accessibility Pass** (Dynamic Type, VoiceOver labels, contrast).
- **WP13 (old WP11) Phase 2 backlog** updated: family sharing bullet now correctly names `CKShare`; added the open questions from the tech doc (crash reporting/analytics choice, Android re-evaluation, field validation rules).

## Build order overview

| # | Package | Depends on | One-line goal |
|---|---|---|---|
| WP0 | Design System Foundation | — | Colors, fonts, reusable view styles shared by every screen |
| WP1 | Data Model, Repository Layer & CloudKit App Shell | WP0 | SwiftData models, repository protocols, CloudKit container, splash + empty/sync states |
| WP2 | Localization Infrastructure | WP1 | String Catalog live from day one, plural-key patterns, a checklist every later package must follow |
| WP3 | Child Profile | WP2 | Create/edit/delete a child, multi-child switcher |
| WP4 | Tournament Creation & Album Home | WP3 | Add/edit/delete a tournament, home/album list screen |
| WP5 | Quick Match Entry | WP4 | Fast, offline-first match-logging form with edit/delete |
| WP6 | Tournament Hero & Placement | WP5 | Trophy-style tournament detail screen, empty-match state |
| WP7 | Share Card Generator | WP6 | Shareable PNG cards (square + 9:16) |
| WP8 | Media / Photos | WP6 | Photo attachments with add/delete |
| WP9 | Career Overview | WP4, WP6 | Whole-career timeline + stat aggregates |
| WP10 | Monetization / Paywall | WP4, WP9 | StoreKit 2 subscription + one-time purchase, downgrade behavior |
| WP11 | Localization QA & Full Translation Pass | WP1–WP10 | Audit for drift, complete English coverage, App Store metadata |
| WP12 | Accessibility Pass | WP0–WP11 | Dynamic Type, VoiceOver, contrast |
| WP13 | Phase 2 Backlog | MVP complete | Planning-only package for post-validation work |

---

## WP0 — Design System Foundation

**Depends on:** nothing (do this first).

### Context
The product's visual identity is a warm, "photo album" aesthetic — large rounded cards, soft shadows, gold/silver/bronze podium accents, minimal numeric UI. This package builds the shared design tokens and reusable components every later screen will use, so screens stay visually consistent without re-deriving styles each time.

### Design tokens

**Colors** (add to `Assets.xcassets` as color sets, and expose via a `Color` extension):

| Token name | Hex | Usage |
|---|---|---|
| `brandGreen` | `#1F5E37` | Primary buttons, headers, active tab icon, FAB |
| `brandGreenSecondary` | `#2C6B3E` | Links, gradients paired with brandGreen |
| `screenBackground` | `#F3EEE4` | Default screen background |
| `sheetBackground` | `#F1ECE2` | Modal sheet background |
| `cardSurface` | `#FFFFFF` | Cards, list rows, inputs |
| `textPrimary` | `#1c2a20` | Body/heading text |
| `textMuted` | `#8a978c` | Secondary text |
| `textPlaceholder` | `#bcb5a5` | Field placeholders |
| `hairline` | `#eee7db` | Row dividers |
| `stepperFieldBg` | `#EAE4D6` | Stepper control background |
| `goldStart` / `goldEnd` | `#F6D479` / `#E8B84B` | Podium badge gradient |
| `goldAccentText` | `#C6A02C` | Podium stat number |
| `chipTint` | `#E3EFDF` | Feature icon chips, small tinted backgrounds |
| `drawChipBg` / `drawChipText` | `#EDE7D8` / `#8a7d5e` | Draw result chip |
| `successToggle` | `#34C759` | iOS-standard "on" switch (MOTM) |

**Typography**
- Display font: **Unbounded**, weight 700 — wordmark, screen titles, stat numbers, card titles.
- UI font: **Onest**, weights 400–600 — body text, labels, buttons, tab bar.
- Small uppercase stat labels use letter-spacing (~0.05em) at 7.5–9px — deliberately secondary, per the "minimize numbers" direction.

**Reusable components to build**
- `CardStyle` view modifier: rounded corners (13–26px depending on context), soft shadow (`rgba(20,45,28, 0.14–0.35)`), white surface.
- `StatPill`: equal-width rounded chip showing a bold Unbounded number + small uppercase Onest label; supports a "highlighted" (gold) variant for podium counts.
- `PlacementBadge`: pill with medal emoji (🥇🥈🥉) + gold gradient background + bold label ("Чемпіони", "Фіналісти", "3-тє").
- `PrimaryButton` / `FloatingActionButton`: brand-green rounded button; FAB variant is circular with a paired pill-shaped text label next to it (not icon-only).
- `Stepper Pair` control: a single rounded-rect container with a `−` and `+` button separated by a hairline — used everywhere a count is adjusted (score, goals, assists).
- Photo placeholder fill: diagonal repeating-stripe gradient (`#d7e6d2` / `#e2ecdd`) for any empty photo/cover slot, with a small centered monospace caption.
- Tab bar style: translucent/blurred bar, 3 items, active state = filled icon in `brandGreen`, inactive = outlined icon in a neutral gray.

**Accessibility baseline (new).** Bake this in now rather than retrofitting in WP12: every reusable component that carries information via color/icon alone (StatPill highlight, PlacementBadge, score chips) must accept an accessible label/value pair, not rely on a screen-reader user perceiving color; text-bearing components should be built with system font scaling in mind (avoid fixed-height containers that clip at larger Dynamic Type sizes) even though the full audit happens in WP12.

### Done criteria
A `DesignSystem` (or `Theme`) namespace exists with color tokens, font helpers (`Font.display(_:weight:)`, `Font.ui(_:weight:)`), and the reusable components above, previewed in SwiftUI previews with placeholder content, each interactive/informational component exposing an accessibility label parameter.

### 🤖 AI Prompt
```
Build a SwiftUI design system module for an iOS 17+ app called "Matchbook".

1. Add these colors to Assets.xcassets and expose them via a `Color` extension:
   brandGreen #1F5E37, brandGreenSecondary #2C6B3E, screenBackground #F3EEE4,
   sheetBackground #F1ECE2, cardSurface #FFFFFF, textPrimary #1c2a20,
   textMuted #8a978c, textPlaceholder #bcb5a5, hairline #eee7db,
   stepperFieldBg #EAE4D6, goldStart #F6D479, goldEnd #E8B84B,
   goldAccentText #C6A02C, chipTint #E3EFDF, drawChipBg #EDE7D8,
   drawChipText #8a7d5e, successToggle #34C759.

2. Register two custom fonts: "Unbounded" (display, weight 700 for titles/stat
   numbers) and "Onest" (UI text, weights 400/500/600). Add a `Font` extension
   with helpers like `Font.display(size:)` and `Font.ui(size:weight:)`, built
   using scalable text styles (relative to Dynamic Type) rather than fixed
   point sizes where the component is body/label text.

3. Build these reusable SwiftUI components, each with a preview using dummy data:
   - `CardStyle` ViewModifier: large corner radius (use clipShape(.rect(cornerRadius:))),
     soft shadow, white background.
   - `StatPill`: a rounded chip with a big Unbounded number and a small uppercase
     Onest caption below it; add a `highlighted: Bool` parameter that swaps the
     background/text to the gold tokens, and an `accessibilityLabel: String`
     parameter so a highlighted (podium) stat is announced as such, not just
     shown as a color change.
   - `PlacementBadge`: pill-shaped view taking a medal emoji string and a label,
     gold gradient background, dark gold text; expose the label as the
     accessibility value so VoiceOver reads "Champions" rather than the emoji.
   - `PrimaryButton`: brand-green rounded rectangle button style.
   - `FloatingActionPill`: a circular "+" FAB (brandGreen, white plus) paired
     with an adjacent pill label showing an action name, positioned bottom-trailing.
   - `StepperControl`: a rounded-rect view with a "−" and "+" tap target divided
     by a 1px hairline, taking a Binding<Int> and optional min/max, with
     accessibility labels on each button (e.g. "Decrease goals", "Increase goals").
   - `PhotoPlaceholder`: a view that fills its container with a diagonal
     repeating-stripe pattern (two very light greens) and centers a small
     monospaced uppercase caption text.

4. Build a reusable tab bar style: translucent/blurred background, 3 slots,
   active item shows a filled icon in brandGreen with bold label, inactive
   items show outlined icons in gray with regular-weight labels.

Constraints: use `Button` instead of `onTapGesture` for anything tappable,
`foregroundStyle` instead of `foregroundColor`, `@ViewBuilder` instead of
`AnyView`, and keep every component free of business logic — pure presentation,
driven entirely by parameters/bindings.
```

---

## WP1 — Data Model, Repository Layer & CloudKit App Shell

**Depends on:** WP0.

### Context
This is the foundation everything else is built on: the SwiftData schema (CloudKit-safe), a repository layer that isolates every other package from SwiftData/CloudKit specifics, the app entry point with a CloudKit-backed `modelContainer`, and the screens a user sees before any data exists or while sync is still catching up.

**Why a repository layer (build-spec §3.9):** "CloudKit, no backend" is right for MVP, but it's the kind of decision that's expensive to reverse later (an Android version, a real cross-account sharing need sooner than Phase 2, server-driven config). Routing every write/delete/aggregation through a protocol now — instead of when it's needed — means a future swap to Firebase or any other backend is bounded to new repository implementations, not a rewrite of every screen.

**Correction vs. the original spec text:** CloudKit's private database only syncs between devices signed into the **same Apple ID** (e.g. one parent's phone and iPad). It does **not** make a child's profile visible to a second parent on a different Apple ID — that's a separate feature (`CKShare`-based family sharing) and belongs to Phase 2 (WP13), not this package. Don't build or imply that promise here.

### Data model
CloudKit rules followed: every non-optional property has a default; every relationship is optional; every to-many relationship declares an `inverse`; no `@Attribute(.unique)`.

```swift
import Foundation
import SwiftData

// MARK: - Enums
enum PlayerPosition: String, Codable, CaseIterable {
    case goalkeeper, defender, midfielder, forward, unknown
    var title: LocalizedStringResource {
        switch self {
        case .goalkeeper: "Воротар"
        case .defender:   "Захисник"
        case .midfielder: "Півзахисник"
        case .forward:    "Нападник"
        case .unknown:    "—"
        }
    }
}

enum TournamentFormat: String, Codable, CaseIterable {
    case league, knockout, groupPlusKnockout, friendly, other
    var title: LocalizedStringResource {
        switch self {
        case .league:            "Кругова"
        case .knockout:          "Плей-оф"
        case .groupPlusKnockout: "Групи + плей-оф"
        case .friendly:          "Товариський"
        case .other:             "Інше"
        }
    }
}

enum MatchOutcome: String, Codable { case win, draw, loss }

// MARK: - Player
@Model
final class Player {
    var id: UUID = UUID()
    var name: String = ""
    @Attribute(.externalStorage) var avatarData: Data?
    var shirtNumber: Int?
    var position: PlayerPosition = PlayerPosition.unknown
    var club: String?
    var birthDate: Date?
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Tournament.player)
    var tournaments: [Tournament]? = []

    init(name: String = "") { self.name = name }

    var allMatches: [Match] { (tournaments ?? []).flatMap { $0.matches ?? [] } }
    var totalTournaments: Int { (tournaments ?? []).count }
    var totalMatches: Int { allMatches.count }
    var totalGoals: Int { allMatches.reduce(0) { $0 + $1.goals } }
    var totalAssists: Int { allMatches.reduce(0) { $0 + $1.assists } }
    var podiums: Int { (tournaments ?? []).filter { ($0.finalPlacement ?? 99) <= 3 }.count }
}

// MARK: - Tournament
@Model
final class Tournament {
    var id: UUID = UUID()
    var name: String = ""
    var startDate: Date = Date()
    var endDate: Date?
    var city: String?
    var venue: String?
    var format: TournamentFormat = TournamentFormat.other
    var teamName: String?
    var finalPlacement: Int?
    var placementLabel: String?
    @Attribute(.externalStorage) var coverPhotoData: Data?
    var notes: String?
    var createdAt: Date = Date()

    var player: Player?

    @Relationship(deleteRule: .cascade, inverse: \Match.tournament)
    var matches: [Match]? = []
    @Relationship(deleteRule: .cascade, inverse: \MediaItem.tournament)
    var media: [MediaItem]? = []

    init(name: String = "", startDate: Date = Date()) {
        self.name = name
        self.startDate = startDate
    }

    var sortedMatches: [Match] { (matches ?? []).sorted { $0.date < $1.date } }
    var goals: Int { (matches ?? []).reduce(0) { $0 + $1.goals } }
    var assists: Int { (matches ?? []).reduce(0) { $0 + $1.assists } }
    var wins: Int { (matches ?? []).filter { $0.outcome == .win }.count }
    var isPodium: Bool { (finalPlacement ?? 99) <= 3 }
}

// MARK: - Match
@Model
final class Match {
    var id: UUID = UUID()
    var date: Date = Date()
    var opponent: String = ""
    var teamScore: Int = 0
    var opponentScore: Int = 0
    var stage: String?
    var goals: Int = 0
    var assists: Int = 0
    var minutesPlayed: Int?
    var playerRating: Double?
    var isMotm: Bool = false
    var notes: String?
    var createdAt: Date = Date()

    var tournament: Tournament?

    @Relationship(deleteRule: .cascade, inverse: \MediaItem.match)
    var media: [MediaItem]? = []
    @Relationship(deleteRule: .cascade, inverse: \GoalMoment.match)
    var moments: [GoalMoment]? = []  // Phase 2

    init(opponent: String = "", date: Date = Date()) {
        self.opponent = opponent
        self.date = date
    }

    var outcome: MatchOutcome {
        if teamScore > opponentScore { return .win }
        if teamScore < opponentScore { return .loss }
        return .draw
    }
    var scoreLine: String { "\(teamScore):\(opponentScore)" }
}

// MARK: - MediaItem
@Model
final class MediaItem {
    var id: UUID = UUID()
    @Attribute(.externalStorage) var data: Data?
    var isVideo: Bool = false
    var caption: String?
    var createdAt: Date = Date()
    var tournament: Tournament?
    var match: Match?
    init(data: Data? = nil, isVideo: Bool = false) {
        self.data = data
        self.isVideo = isVideo
    }
}

// MARK: - GoalMoment (Phase 2, model can exist now, UI comes in WP13)
enum GoalKind: String, Codable, CaseIterable { case openPlay, penalty, freeKick, header, other }

@Model
final class GoalMoment {
    var id: UUID = UUID()
    var isAssist: Bool = false
    var kind: GoalKind = GoalKind.openPlay
    var minute: Int?
    var note: String?
    var match: Match?
    init() {}
}
```

### Repository layer (new — build-spec §3.9)

```swift
protocol PlayerRepository {
    func fetchAll() -> [Player]
    func create(_ player: Player) throws
    func update(_ player: Player) throws
    func delete(_ player: Player) throws
}

protocol TournamentRepository {
    func fetchAll(for player: Player) -> [Tournament]
    func create(_ tournament: Tournament, for player: Player) throws
    func update(_ tournament: Tournament) throws
    func delete(_ tournament: Tournament) throws   // cascades to Match/MediaItem
    func canCreateTournament(for player: Player, isSubscribed: Bool) -> Bool // paywall gate lives here, not in the View
}

protocol MatchRepository {
    func create(_ match: Match, for tournament: Tournament) throws
    func update(_ match: Match) throws
    func delete(_ match: Match) throws
}

protocol MediaRepository {
    func addPhoto(_ data: Data, to owner: MediaOwner) throws   // owner = .tournament(Tournament) or .match(Match); compresses before saving
    func delete(_ item: MediaItem) throws
}
```

Default implementations (`SwiftDataPlayerRepository`, `SwiftDataTournamentRepository`, `SwiftDataMatchRepository`, `SwiftDataMediaRepository`) wrap `modelContext`. **List screens can still use `@Query` directly** for reactive rendering — that's normal SwiftData idiom and shouldn't be banned for architectural purity. The rule only covers writes, deletes, paywall checks, and aggregations: those go through the repository so they aren't SwiftData-specific and survive a future backend swap.

### App shell
```swift
@main
struct MatchbookApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(for: [Player.self, Tournament.self, Match.self,
                                   MediaItem.self, GoalMoment.self])
        // Enable iCloud + CloudKit capability on the target for sync.
        // NOTE: this syncs a single Apple ID's own devices only. Cross-account
        // family sharing is a separate CKShare feature — see WP13 Phase 2.
    }
}
```
`RootView` owns `@AppStorage("activePlayerID")` and a `@Query` over all `Player`s (sorted by `createdAt`). Routing:
- No players yet, and no signal that a CloudKit account with existing data is still syncing → **Splash** (brief, on cold launch only) → **Empty state** screen.
- No players yet, but the CloudKit container indicates an iCloud account is configured and data may still be arriving (e.g. this is a second device) → **Syncing…** indicator instead of the empty state, to avoid nudging the user into creating a duplicate child.
- Players exist → active child's home (built in WP4).

### Screens in this package
- **Splash** — full-screen `brandGreen` background, circular monogram "М" in a translucent circle, Unbounded wordmark "Матчбук", tagline "Турніри, які не забудуться", small footer "дитячий футбол · спогади". Auto-dismisses after a short delay.
- **Empty state** — `screenBackground`, ball emoji in a rounded diagonal-stripe tile, Unbounded headline "Вітаємо в Матчбуці", muted subtext, three feature rows (icon chip + label: "Турнір — окремий альбом, не дашборд", "Фото на першому плані", "Картки для чатів команди й сторіз"), primary button "＋ Додати дитину" pinned to the bottom.
- **Syncing state (new)** — lightweight, non-blocking: a spinner/progress indicator with a short caption ("Синхронізуємо дані з iCloud…"), shown instead of the empty state when a second device is likely still pulling down existing data.
- **iCloud-unavailable banner (new)** — a one-time, dismissible, non-blocking banner shown when the device has no iCloud account configured: "Дані зберігаються тільки на цьому пристрої — увімкни iCloud, щоб не втратити їх при заміні телефону." Never blocks any flow; the app must be fully usable without iCloud.

### Done criteria
App launches, shows splash then empty state on first run, `modelContainer` initializes without CloudKit schema errors, the repository protocols and their SwiftData implementations exist and compile, the syncing/iCloud-unavailable states render correctly under their trigger conditions, and tapping "Додати дитину" is wired to open the (stubbed) child-creation flow from WP3.

### 🤖 AI Prompt
```
Create a new SwiftUI app, iOS 17+, using SwiftData and CloudKit (no custom
backend). Do not use ObservableObject or @StateObject anywhere — use the
Observation framework (@Observable) only where a view model is truly needed;
most screens should read directly from @Query.

1. Add the SwiftData models below exactly as given (they are already
   CloudKit-safe: every non-optional property has a default, every
   relationship is optional with an inverse, no @Attribute(.unique)):
   [paste the Player / Tournament / Match / MediaItem / GoalMoment code
   and the PlayerPosition / TournamentFormat / MatchOutcome / GoalKind enums
   from this document].

2. Define repository protocols `PlayerRepository`, `TournamentRepository`,
   `MatchRepository`, `MediaRepository` (signatures as given in this
   document) and default SwiftData-backed implementations
   (`SwiftDataPlayerRepository`, etc.) that wrap `modelContext`. Every later
   feature must go through these for create/update/delete/paywall-gate calls
   instead of touching modelContext directly — list screens may still use
   @Query directly for display. Make the repositories available via the
   environment (e.g. a small `Repositories` container injected with
   `.environment`).

3. Create `MatchbookApp` as the @main entry point with a `.modelContainer`
   registering all five model types. Add a comment noting that (a) the
   iCloud + CloudKit capability must be enabled on the app target for sync to
   work, and (b) this syncs a single Apple ID's own devices only — it does
   NOT make data visible to a different Apple ID; that requires a separate
   CKShare-based feature that is out of scope for this package.

4. Build `RootView`: it queries all `Player` records sorted by `createdAt`,
   and reads/writes the active child's id via `@AppStorage("activePlayerID")`.
   Routing:
   - If there are no players and there's no indication that an existing
     CloudKit account might still be syncing data, show a Splash screen
     briefly (auto-dismiss after ~1 second) followed by an Empty State
     screen.
   - If there are no players but the CloudKit container/account state
     suggests this could be a second device still catching up on sync, show
     a brief "Syncing…" indicator instead of the Empty State, so the user
     isn't nudged into creating a duplicate child. (A simple heuristic is
     fine here — e.g. check whether an iCloud account is available at all
     via CKContainer.accountStatus before deciding which state to show.)
   - If players exist, route to a placeholder "Home" view (replaced in a
     later work package).
   - Independently of the above, show a one-time dismissible banner if no
     iCloud account is configured on the device at all, explaining that data
     is local-only for now. This must never block any flow — the app has to
     work fully without iCloud.

5. Build the Splash screen: full-bleed brandGreen (#1F5E37) background, a
   circular translucent badge containing the letter "М" in a bold display
   font, the wordmark "Матчбук" below it, tagline "Турніри, які не
   забудуться", and a small caption "дитячий футбол · спогади" near the
   bottom.

6. Build the Empty State screen: light background (#F3EEE4), a rounded tile
   with a diagonal-stripe placeholder pattern containing a ball emoji, a bold
   headline "Вітаємо в Матчбуці", a muted one-sentence subtitle, three feature
   rows each with a small tinted icon chip + one line of text, and a
   full-width primary button "＋ Додати дитину" pinned near the bottom of the
   screen. The button should call an `onAddChild` closure passed into the view
   (leave it as a no-op / print statement for now).

Use the design tokens and reusable components from the design-system module
built in the previous work package (CardStyle, PrimaryButton, PhotoPlaceholder,
color/font extensions) rather than hardcoding new styles.
```

---

## WP2 — Localization Infrastructure

**Depends on:** WP1.

### Context
Moved deliberately early (build-spec §8/§10): the model layer's enum titles already use `LocalizedStringResource`, and every screen built from WP3 onward should be written against String Catalog from its first line rather than retrofitted later. This package does **not** attempt to finish translation — the UI surface doesn't exist yet — it sets up the mechanism, the plural-key patterns, and a checklist that every subsequent work package's prompt must satisfy. The final audit and full English coverage pass is WP11, once the screens are stable enough that translating them isn't wasted effort.

### Scope
- Enable **String Catalog** (`.xcstrings`) with **Ukrainian as the base/development language**, and add **English** as a second language immediately (even before most screens exist) so the workflow is "translate as you go," not "translate at the end."
- Establish the **plural-key patterns** that every count-bearing string in the app will need, and get them into the catalog now so later packages just reference them instead of re-deriving the rules:
  - Ukrainian needs one/few/many forms: "1 гол" / "2 голи" / "5 голів"; "1 матч" / "2 матчі" / "5 матчів"; "1 турнір" / "2 турніри" / "5 турнірів"; "1 асист" / "2 асисти" / "5 асистів".
  - English needs one/other: "1 goal" / "5 goals"; "1 match" / "5 matches"; "1 tournament" / "5 tournaments".
  - These must be built as String Catalog plural variations, never as string concatenation (`"\(count) голів"` is wrong regardless of how tempting it looks for a quick MVP screen).
- Establish the **date/number formatting convention**: `Date.FormatStyle` / `.formatted(...)` only, never hand-built date strings — Ukrainian "12–14 червня" and English "Jun 12–14" differ in word order and separators, and a manually concatenated string can't represent both correctly.
- Document what **never gets localized**: user-generated content (child's name, opponent names, tournament names, notes) — these pass through untouched regardless of locale.
- Produce a short **Localization Checklist** (below) that gets pasted into every subsequent work package's AI prompt, so localization discipline doesn't quietly lapse once feature work starts.

### Localization Checklist (reuse verbatim in every later work package's prompt)
```
Localization requirements for this package:
- Every user-visible string goes through Text(), String(localized:), or
  LocalizedStringResource — no string literals directly in view bodies.
- Any string that embeds a count (goals, assists, matches, tournaments,
  podiums) uses the String Catalog plural keys set up in the localization
  work package — never string concatenation or manual pluralization.
- Any date or date range uses Date.FormatStyle / .formatted(...) — never a
  manually built date string.
- Do NOT localize user-entered content: player name, opponent name,
  tournament name, city/venue/team name, notes. These pass through as typed.
```

### Done criteria
String Catalog exists with Ukrainian as base and English registered as a target language; the plural-key entries for goal/match/tournament/assist counts exist in the catalog (even if only used by placeholder/preview content so far); switching the simulator language to English doesn't crash or show missing-translation warnings for anything built in WP0–WP1; the Localization Checklist text is ready to paste into WP3 onward.

### 🤖 AI Prompt
```
Set up localization infrastructure for the Matchbook iOS app (SwiftUI, iOS
17+) before any feature screens beyond the app shell are built.

1. Enable a String Catalog (.xcstrings) with Ukrainian as the base/development
   language, and add English as a second (even mostly-empty-for-now) target
   language.

2. Audit everything built so far (design system previews, Splash, Empty
   State, Syncing indicator, iCloud-unavailable banner from the previous
   work package) for hardcoded strings and convert them to Text() /
   String(localized:) / LocalizedStringResource so the catalog picks them up,
   with English translations provided.

3. Add String Catalog plural-variation entries (even before they're wired to
   a live UI) for these four quantities, so later packages can reference them
   directly instead of re-deriving the rules:
   - goals: uk one="%d гол", few="%d голи", many="%d голів"; en one="%d goal",
     other="%d goals"
   - assists: uk one="%d асист", few="%d асисти", many="%d асистів"; en
     one="%d assist", other="%d assists"
   - matches: uk one="%d матч", few="%d матчі", many="%d матчів"; en
     one="%d match", other="%d matches"
   - tournaments: uk one="%d турнір", few="%d турніри", many="%d турнірів";
     en one="%d tournament", other="%d tournaments"

4. Add a short internal doc-comment (or a markdown note in the repo) stating
   the project's localization rules so future contributors (human or AI)
   follow them without re-deriving them each time:
   - Every user-visible string goes through Text()/String(localized:)/
     LocalizedStringResource.
   - Counts always use the String Catalog plural keys above, never
     concatenation.
   - Dates/numbers always use Date.FormatStyle/.formatted(...).
   - User-generated content (names, notes, typed text) is never localized.

Verify by switching the simulator's language to English: nothing crashes,
nothing shows a raw catalog key, and the plural entries are selectable/usable
by future code without further catalog setup.
```

---

## WP3 — Child Profile

**Depends on:** WP2.

*Apply the Localization Checklist from WP2 to every string and count in this package.*

### Context
The first real user action: create a child profile. This unlocks the rest of the app (a tournament always belongs to an active child).

### Screens
- **New Child modal sheet** — native sheet with "Скасувати" / title "Нова дитина" / "Додати" header row; circular dashed-border avatar picker (`PhotosPicker`) with a "+" glyph and "Додати фото" caption below it; a white rounded card with three rows (Ім'я, Номер, Клуб — label left, value/placeholder right); a "ПОЗИЦІЯ" section label followed by a chevron row to pick `PlayerPosition`; a "ДЕТАЛІ" section label followed by a chevron row for "Дата народження".
- **Children switcher** — only shown when there is more than one `Player`; a simple list/menu at the top of the home screen to change the active child.
- **Delete confirmation (new)** — reachable from the edit form or the Profile tab (WP9). Deleting a child cascades to all their tournaments/matches/photos. The confirmation dialog must state the scope explicitly, e.g. "Видалити Марка та 4 турніри, 87 фото? Це незворотно." If the deleted child was active, the next `Player` in the list becomes active, or the WP1 empty state shows if none remain.

### Data touched
`Player`: `name`, `avatarData`, `shirtNumber`, `position`, `club`, `birthDate`. All create/update/delete calls go through `PlayerRepository` (WP1), not `modelContext` directly.

### Logic
- `@Query` all `Player`, sorted by `createdAt`.
- On save: `PlayerRepository.create`/`.update`; on create, set `@AppStorage("activePlayerID")` to the new player's id.
- Editing reuses the same form pre-filled with the existing player's values.
- Delete: `PlayerRepository.delete`, then re-route the active-child pointer as described above.

### Done criteria
A child can be created with a photo, appears as active immediately, data survives an app relaunch; a second child triggers the switcher and correctly changes which child's data is shown everywhere else; delete works with an explicit confirmation and doesn't crash when deleting the active child.

### 🤖 AI Prompt
```
Using the existing SwiftData `Player` model, `PlayerRepository`, and the
design-system components already in the project, implement the child-profile
feature for the Matchbook app.

1. Build `PlayerEditView` as a form usable for both creating and editing a
   `Player`. Layout (as a native sheet):
   - Header row: "Скасувати" (dismiss) on the left, title "Нова дитина" (or
     "Редагувати дитину" when editing) centered, "Додати" (or "Зберегти") on
     the right, disabled until the name field is non-empty.
   - A circular avatar picker using PhotosPicker (single selection), showing
     a dashed-border placeholder with a "+" when empty, and the selected
     image cropped to a circle once chosen. Caption "Додати фото" below it.
   - A white rounded card containing three rows: "Ім'я" (text field), "Номер"
     (numeric field, optional), "Клуб" (text field, optional).
   - Section label "ПОЗИЦІЯ" followed by a tappable row that opens a picker
     over PlayerPosition.allCases (showing `.title`), displaying "Оберіть"
     when unset.
   - Section label "ДЕТАЛІ" followed by a tappable row for "Дата народження"
     using a DatePicker (optional field).
   - On save, compress the picked photo reasonably and store it in
     `avatarData`, then call `PlayerRepository.create` (new) or `.update`
     (editing) — do not call modelContext directly.
   - When editing an existing player, show a destructive "Видалити дитину"
     action. Tapping it presents a confirmation alert/sheet stating how many
     tournaments and photos will be deleted (e.g. "Видалити Марка та 4
     турніри, 87 фото? Це незворотно."). Confirming calls
     `PlayerRepository.delete`; if the deleted player was the active one,
     set `@AppStorage("activePlayerID")` to the next remaining player, or
     clear it if none remain (routing back to the WP1 empty state).

2. Build `PlayerHomeView`'s top-of-screen child switcher: if there is more
   than one `Player` (via @Query sorted by createdAt), show a compact
   horizontal switcher (e.g. a menu or segmented control of avatars/names);
   selecting one updates `@AppStorage("activePlayerID")`. If there's exactly
   one player, show nothing extra.

3. Wire the Empty State screen's "＋ Додати дитину" button (from the previous
   work packages) to present `PlayerEditView` as a sheet in create mode, and
   set the newly created player as active on save.

Follow project conventions: @State private for local form state, Button
instead of onTapGesture, foregroundStyle, clipShape(.rect(cornerRadius:)) /
clipShape(Circle()) for the avatar, and reuse the CardStyle/PrimaryButton
components from the design system instead of custom styling.

[Paste the Localization Checklist from the localization work package here.]
```

---

## WP4 — Tournament Creation & Album Home

**Depends on:** WP3.

*Apply the Localization Checklist from WP2 to every string and count in this package.*

### Context
This is the app's main hub. Once a child exists, the parent's primary loop starts here: see existing tournaments as an album, and add new ones.

### Screens
- **Home / Album** (tab: "Альбом") — green hero header (avatar, name, "position · club Uxx" subtitle, shirt-number badge) with a 4-item stat pill row (турнірів / матчі / голи / **подіуми**, podium pill gold-highlighted — *values come from `Player` computed properties already available from WP1*); below it, a large featured tournament cover card (most recent or top tournament) with a `PlacementBadge` overlay and title/location/game-count caption; a 2-column grid of the remaining tournaments as smaller cards; a floating "Новий турнір" action button; bottom tab bar (Альбом / Турніри / Профіль — Профіль tab is stubbed until WP9/WP10, "Турніри" tab can simply reuse the same list in list form or be a placeholder).
- **New Tournament modal sheet** — "Скасувати" / "Новий турнір" / "Створити" header; dashed cover-photo picker labeled "Обкладинка турніру"; section "НАЗВА" with a text field; section "ДАТИ" with "Від" / "До" date rows; section "МІСЦЕ І КОМАНДА" with "Місто" / "Команда" rows; section "ФОРМАТ" with a chevron row opening a `TournamentFormat` picker. Reused for editing an existing tournament.
- **Delete confirmation (new)** — reachable from the tournament detail screen (WP6) or an edit-mode long-press here. Cascades to that tournament's matches and photos: "Видалити турнір і всі 6 матчів, 40 фото?"

### Data touched
`Tournament`: `name`, `startDate`, `endDate`, `city`, `venue`, `format`, `teamName`, `coverPhotoData`. Relationship: `player = activePlayer`. All create/update/delete calls go through `TournamentRepository` (WP1).

### Paywall gate (stub now, wired in WP10)
Before creating a tournament, call `TournamentRepository.canCreateTournament(for: activePlayer, isSubscribed:)`. Until WP10 exists, hardcode `isSubscribed = true` (or wire to a placeholder always-true entitlement) so tournament creation isn't blocked prematurely — WP10 replaces that stub with the real StoreKit-backed check.

### Done criteria
A new tournament appears immediately in the active child's album, sorted with the newest first; edit and delete both work, with delete requiring confirmation that states the cascade scope; the featured/grid layout looks correct with 0, 1, and 5+ tournaments; tapping a tournament card navigates toward the (stubbed, until WP6) tournament detail screen.

### 🤖 AI Prompt
```
Using the existing Player/Tournament SwiftData models, `TournamentRepository`,
and design-system components, implement the tournament create/edit/delete and
home-album feature.

1. Build `TournamentEditView` as a form usable for both creating and editing
   (native sheet):
   - Header: "Скасувати" / title "Новий турнір" (or "Редагувати турнір") /
     "Створити" (or "Зберегти"), disabled until name is non-empty.
   - Dashed-border rectangle "cover photo" picker via PhotosPicker, labeled
     "Обкладинка турніру", using the PhotoPlaceholder pattern when empty.
   - Section "НАЗВА": single text field, large/bold input style.
   - Section "ДАТИ": two rows "Від" and "До", each opening a DatePicker
     ("До" optional).
   - Section "МІСЦЕ І КОМАНДА": "Місто" text field row, "Команда" text field
     row.
   - Section "ФОРМАТ": a chevron row opening a picker over
     TournamentFormat.allCases (using `.title`), default label "Оберіть".
   - On create: call `TournamentRepository.canCreateTournament(for:
     isSubscribed:)` first (stub `isSubscribed` to `true` for now — this gets
     wired to real entitlements in a later work package); if it returns
     false, this package doesn't need to build a real paywall yet, just leave
     a TODO/no-op. If true, build a new Tournament, set `player =
     activePlayer` (passed into the view), and call
     `TournamentRepository.create`.
   - On edit: call `TournamentRepository.update`.
   - When editing, show a destructive "Видалити турнір" action with a
     confirmation stating the cascade scope (e.g. "Видалити турнір і всі 6
     матчів, 40 фото?"); confirming calls `TournamentRepository.delete`.

2. Build `PlayerHomeView` (the "Альбом" tab root):
   - Hero header: avatar, name, "{position} · {club} {ageGroup}" subtitle,
     a shirt-number badge — all bound to the active Player.
   - A 4-item StatPill row: totalTournaments / totalMatches / totalGoals /
     podiums, with the podiums pill using the highlighted (gold) StatPill
     variant, and each pill's accessibility label spelling out the full
     meaning (e.g. "3 подіуми" not just "3").
   - Below the header: query the active player's tournaments (@Query or a
     computed/sorted array), newest first. Show the most recent/featured one
     as a large card (cover photo, PlacementBadge overlay if it has a
     placement, title, "{city} · {month year} · {N} ігор" caption — the game
     count using the plural key from the localization work package) and the
     rest in a 2-column grid of smaller cards (cover photo, placement badge
     if any, title, "{city} · {month year}").
   - A FloatingActionPill labeled "Новий турнір" that presents
     `TournamentEditView` as a sheet.
   - A bottom tab bar with 3 items: Альбом (active), Турніри, Профіль. The
     other two tabs can be simple placeholder views for now.
   - Tapping any tournament card should navigate to a `TournamentDetailView`
     placeholder (just show the tournament name for now — it will be built
     out fully in a later work package).

3. Handle the empty-tournaments state within PlayerHomeView gracefully (no
   crash, no empty grid artifacts) — reuse the app's empty-state visual
   language if helpful.

Follow conventions: Button not onTapGesture, foregroundStyle,
clipShape(.rect(cornerRadius:)), @ViewBuilder not AnyView, reuse
CardStyle/StatPill/PlacementBadge/FloatingActionPill from the design system.

[Paste the Localization Checklist from the localization work package here.]
```

---

## WP5 — Quick Match Entry

**Depends on:** WP4.

*Apply the Localization Checklist from WP2 to every string and count in this package.*

### Context
This is described in the spec as the "main flow" — a parent standing on the sideline needs to log a match result in seconds. Speed and minimal friction matter more than completeness here; secondary fields are tucked away. It is also the clearest case where **offline behavior is not optional**: pitch-side connectivity is unreliable, and this flow is the whole reason the app needs to work without it.

### Screen
**Quick Match modal sheet** — title "Новий матч"; section "СУПЕРНИК" with a single text field; section "РАХУНОК" with two side-by-side stepper columns labeled "НАШІ" and "СУПЕРНИК", each showing a large number with a `StepperControl` beneath it, separated by a colon; section "ДИТИНА" with two rows — "⚽ Голи" and "🅰 Асисти" — each showing the current count with a `StepperControl`; a "Деталі" row (caption: "стадія · хвилини · оцінка") opening a `DisclosureGroup`/secondary sheet for `stage`, `minutesPlayed`, `playerRating`, `notes`; a "Гравець матчу" row with a standard iOS toggle bound to `isMotm`; bottom-pinned primary button "Зберегти" and a secondary text action "Зберегти й додати ще" that saves and immediately resets the form (keeping the same tournament context) for the next match. Reused for editing an existing match, with a delete action available.

### Data touched
`Match`: `opponent`, `teamScore`, `opponentScore`, `goals`, `assists`, `stage`, `minutesPlayed`, `playerRating`, `isMotm`, `notes`. Relationship: `tournament` (passed in). All create/update/delete calls go through `MatchRepository` (WP1).

### Logic
- `outcome` is a computed property — never store it.
- "Зберегти й додати ще" inserts the current match, clears the form fields, and keeps the sheet open with the same `tournament` binding.
- **Offline-first (new):** saving a match is a local SwiftData write via `MatchRepository`, which must succeed instantly and synchronously regardless of network state. CloudKit sync happens in the background afterward — never gate the save button or the "saved" confirmation on network reachability.
- **Delete (new):** swipe-to-delete or a button in match detail, with a lightweight confirmation (a match is a smaller unit of loss than a tournament, but accidental deletion should still be confirmed).

### Done criteria
A match can be added in well under 15 seconds using only the score and goals/assists steppers; saving doesn't block or stutter the UI and works with the device in Airplane Mode; "Зберегти й додати ще" correctly starts a fresh match while staying attached to the same tournament; editing and deleting a saved match both work.

### 🤖 AI Prompt
```
Using the existing Match SwiftData model, `MatchRepository`, and
design-system StepperControl component, implement the quick match
create/edit/delete feature for Matchbook.

Build `MatchEditView` as a sheet that takes a `Tournament` binding/reference
(and, when editing, an existing `Match`) and presents:
1. Title "Новий матч" (or "Матч" when editing) centered at the top (no
   back/cancel chrome needed if presented as a small sheet — add a
   drag-to-dismiss grabber).
2. Section "СУПЕРНИК": a single prominent text field bound to `opponent`.
3. Section "РАХУНОК": two columns, "НАШІ" and "СУПЕРНИК", each showing a
   large bold number (teamScore / opponentScore) with a StepperControl
   underneath, separated visually by a colon ":" between the columns.
4. Section "ДИТИНА": two rows, "⚽  Голи" and "🅰  Асисти", each showing the
   current int value with a StepperControl to increment/decrement (bind to
   Match.goals and Match.assists).
5. A "Деталі" row showing static caption text "стадія · хвилини · оцінка"
   with a trailing chevron; tapping it reveals (via DisclosureGroup or a
   secondary sheet) fields for `stage` (text), `minutesPlayed` (numeric),
   `playerRating` (0...10 slider or stepper), and `notes` (multiline text).
6. A "Гравець матчу" row with a standard SwiftUI Toggle bound to `isMotm`.
7. Two bottom actions: a full-width PrimaryButton "Зберегти" that calls
   `MatchRepository.create` (with `tournament` set) or `.update` (editing)
   and dismisses; and, in create mode only, a secondary text button
   "Зберегти й додати ще" that calls `MatchRepository.create` the same way
   but then resets all fields to defaults and keeps the sheet open, still
   bound to the same tournament, so another match can be logged immediately.
8. When editing an existing match, show a destructive "Видалити матч" action
   with a lightweight confirmation (an alert is enough — a match is a
   smaller unit of loss than a tournament); confirming calls
   `MatchRepository.delete`.

Critical: the save action must be a synchronous local write through
`MatchRepository` — it must succeed instantly with no network dependency and
no spinner waiting on connectivity, since the primary use case is logging a
match pitch-side with unreliable signal. CloudKit sync happens in the
background afterward and must not be awaited by the save action.

Compute `outcome` and `scoreLine` from teamScore/opponentScore as read-only
properties on the model — do not persist them separately (they already exist
on the Match model from the earlier work package).

Follow conventions: @State private for form fields, Button not onTapGesture,
StepperControl from the design system for every +/- control, no
ObservableObject.

[Paste the Localization Checklist from the localization work package here.]
```

---

## WP6 — Tournament Hero & Placement

**Depends on:** WP5.

*Apply the Localization Checklist from WP2 to every string and count in this package.*

### Context
This is the emotional payoff screen — the "trophy card" the whole product is built around. It combines the tournament's photo, its placement, and its match history into one album-page-like view.

### Screen
**Tournament Detail** — hero photo block (or diagonal placeholder) at the top with translucent circular back and share buttons overlaid; a gold `PlacementBadge` and the tournament title + "{city} · {date range} · {team}" caption anchored at the bottom of the hero, over a dark gradient scrim; below the hero, a 3-item stat row (W-D-L record in `brandGreen`, goals, assists — using the compact card variant, not the home-screen StatPill); a white card containing the match list — each row shows opponent name (bold), a stage/goal-icon caption line, an "MVP" tag when `isMotm`, and a trailing score chip (filled `brandGreen` for a win, `drawChipBg`/`drawChipText` for a draw/loss); a `FloatingActionPill` labeled "Новий матч" that opens `MatchEditView` from WP5; the same bottom tab bar as the home screen.

Also build the **placement picker**: a preset list — Чемпіон (🥇), Фіналіст (🥈), 3-тє (🥉), Груповий етап, Без місця — that sets `finalPlacement` (1/2/3/nil-with-label/nil) and `placementLabel` together, kept in sync.

**Empty-match state (new):** a tournament with zero matches must not show a bare blank list — show a short prompt ("Додай перший матч") pointing at the FAB instead.

### Data touched
`Tournament.finalPlacement`, `Tournament.placementLabel`, and its computed `sortedMatches` / `goals` / `assists` / `wins` / `isPodium`. Placement updates and tournament delete (reachable from here — see WP4) go through `TournamentRepository`.

### Done criteria
A podium tournament (placement ≤ 3) is visually distinct at a glance; the hero card genuinely reads as an award, not a data record; the match list correctly reflects win/draw/loss styling; the placement picker keeps `finalPlacement` and `placementLabel` consistent; a zero-match tournament shows the empty prompt instead of a blank list.

### 🤖 AI Prompt
```
Using the existing Tournament/Match SwiftData models, `TournamentRepository`,
and design-system components (PlacementBadge, CardStyle, FloatingActionPill),
build out the full `TournamentDetailView` for Matchbook, replacing the
placeholder from the tournament-creation work package.

1. Hero block: full-width photo (coverPhotoData if present, otherwise the
   PhotoPlaceholder pattern) about 220-260pt tall. Overlay: a translucent
   circular back button top-left, a translucent circular share button
   top-right (the share action can be a no-op for now — implemented in the
   next work package). At the bottom of the hero, over a dark linear-gradient
   scrim, show a PlacementBadge (only if finalPlacement/placementLabel is
   set) above the tournament name (large, bold display font) and a caption
   line "{city} · {formatted date range} · {teamName}" using
   Date.FormatStyle for the range.

2. Below the hero, a horizontal row of 3 compact stat cards: "{wins}-{draws}-{losses}"
   labeled "В · Н · П" (win/draw/loss record, computed from sortedMatches),
   total goals, total assists — goals/assists using the plural keys from the
   localization work package. Style the first (record) card filled
   brandGreen with white text; the other two as white cards with muted
   labels.

3. A white rounded card listing every match in `tournament.sortedMatches`.
   Each row: opponent name (bold), a small caption line combining `stage`
   (if set) and a goal/assist icon + count, an "MVP" tag pill when
   `match.isMotm` is true, and a trailing score chip showing `scoreLine` —
   filled brandGreen background/white text for a win, drawChipBg/drawChipText
   for a draw or loss. If `sortedMatches` is empty, show a short prompt
   ("Додай перший матч") instead of an empty list.

4. A FloatingActionPill labeled "Новий матч" that presents the existing
   `MatchEditView` as a sheet, passing this tournament.

5. Build a placement-editing UI (e.g. presented from the back/title area or
   an edit action): a preset list with options Чемпіон (🥇, sets
   finalPlacement=1, placementLabel="Чемпіони"), Фіналіст (🥈, 2,
   "Фіналісти"), 3-тє (🥉, 3, "3-тє місце"), Груповий етап (nil,
   "Груповий етап"), Без місця (nil, nil). Selecting one calls
   `TournamentRepository.update` with both properties set together so they
   never fall out of sync.

6. Add a "Видалити турнір" destructive action reachable from this screen
   (e.g. an edit menu), with a confirmation stating the cascade scope
   ("Видалити турнір і всі N матчів, M фото?"); confirming calls
   `TournamentRepository.delete` and pops back to the album.

Reuse the same bottom tab bar component built in the home-screen work
package. Follow conventions: Button not onTapGesture, foregroundStyle,
clipShape(.rect(cornerRadius:)) for corners.

[Paste the Localization Checklist from the localization work package here.]
```

---

## WP7 — Share Card Generator

**Depends on:** WP6.

*Apply the Localization Checklist from WP2 to every string and count in this package.*

### Context
The spec calls this the #1 viral/organic-growth hook: a good-looking card that gets shared into team parent chats, carrying the app's watermark. Worth building early because it's a fast, high-impact "wow" moment to validate.

### Screen
**Share Card** (rendered, not a live app screen — generated as an image) — supports a square and a 9:16 aspect ratio. Content: full-bleed tournament/child photo (or placeholder), a centered gold `PlacementBadge` near the top, the tournament (or summary) title in the display font, a subtitle line "{childName} · {position} · №{shirtNumber}", a 3-item stat row (games / goals / assists — or whatever summary applies, using plural keys), and a small "Матчбук" wordmark watermark pinned to a top corner.

**Privacy note (new):** the card surfaces the child's name and photo outside the app, into messenger chats. The preview must clearly show exactly what will be shared before `ShareLink` is triggered — no hidden fields. Don't add anything beyond what's visibly in the card preview (e.g. no precise venue geolocation) without a separate, explicit opt-in.

### Logic
Render a SwiftUI view off-screen via `ImageRenderer(content:).uiImage`, then hand the resulting `UIImage` to `ShareLink` as PNG.

### Done criteria
The card is legible and well-composed in both square and 9:16 output; the watermark is always present and doesn't overlap key text; the preview accurately represents exactly what gets shared; sharing works via the native share sheet (`ShareLink`).

### 🤖 AI Prompt
```
Using the existing Tournament/Player SwiftData models and design-system
components (PlacementBadge, PhotoPlaceholder), build the share-card feature
for Matchbook.

1. Build `ShareCardView(tournament: Tournament, aspect: CardAspect)` where
   `CardAspect` is an enum with `.square` and `.vertical` (9:16) cases
   controlling the view's fixed frame size. Layout:
   - Full-bleed background: tournament.coverPhotoData if present, else the
     PhotoPlaceholder pattern, with a dark gradient overlay strongest at the
     bottom for text legibility.
   - A centered PlacementBadge near the top third (only if the tournament has
     a placement).
   - Tournament name in a large bold display font, positioned in the lower
     portion of the card.
   - A subtitle line "{player.name} · {player.position.title} · №{shirtNumber}".
   - A stat row with 2-3 translucent stat chips (e.g. games played, goals,
     assists, using the plural keys from the localization work package)
     styled consistently with StatPill but using a semi-transparent white
     background suited to sitting on a photo.
   - A small "Матчбук" wordmark in the display font, positioned top-left, as
     a permanent watermark — must render in every export regardless of
     aspect ratio.

2. Build `ShareCardPreviewView`: shows the ShareCardView live (default to
   square) exactly as it will be shared — no fields present in the rendered
   export that aren't visible in this preview — a segmented control to
   switch between square/vertical preview, and a ShareLink.

3. Implement the export: use `ImageRenderer(content: ShareCardView(...))`,
   set an appropriate `scale` (e.g. 3) for retina-quality output, get
   `.uiImage`, convert to PNG `Data`, and pass that Data to `ShareLink` with
   a sensible filename/preview.

4. Wire a share button (e.g. the translucent share icon on the tournament
   hero from the previous work package) to present `ShareCardPreviewView`
   as a sheet for that tournament.

Constraints: rendering must not block the main thread noticeably; keep the
watermark non-optional (it's the app's organic marketing channel) — do not
add a setting to hide it in this work package; do not include any data field
(e.g. precise location) that isn't visibly rendered on the card itself.

[Paste the Localization Checklist from the localization work package here.]
```

---

## WP8 — Media / Photos

**Depends on:** WP6.

*Apply the Localization Checklist from WP2 to every string and count in this package.*

### Context
Photos are the emotional core of the product ("photo on the first plane"), but this is deliberately sequenced after the hero/placement and share-card work so the core loop is validated before investing in media handling and storage performance.

### Screen
A photo grid (roughly 3 columns of square thumbnails) embedded on both `TournamentDetailView` and (optionally) inside a match row's detail view; an "add photos" tile using `PhotosPicker` with multi-select; tapping a thumbnail opens a full-screen viewer (swipeable if there are multiple photos); long-press on a thumbnail offers "Видалити" with a confirmation.

### Data touched
`MediaItem`: `data`, `isVideo`, `caption`. Relationships: `tournament` or `match`. Add/delete calls go through `MediaRepository` (WP1).

### Logic
- Compress each picked image to a maximum dimension of ~1600px and JPEG quality ~0.7 before writing to `MediaItem.data` (which is `@Attribute(.externalStorage)`), via `MediaRepository.addPhoto`.
- Show thumbnails (downsampled, not the full-resolution data) in the grid for performance; load full image only in the full-screen viewer.
- Deleting a single photo (`MediaRepository.delete`) must not affect the rest of the tournament/match's media.

### Done criteria
Adding 20+ photos to a single tournament doesn't introduce visible lag or bloat the SwiftData store (verify data is actually going to external storage, not inline). Multi-select add, full-screen viewing, and single-photo delete (with confirmation) all work.

### 🤖 AI Prompt
```
Using the existing MediaItem SwiftData model and `MediaRepository`,
implement the photo feature for Matchbook.

1. Build a reusable `PhotoGridView(items: [MediaItem], onAdd: ([PhotosPickerItem]) -> Void, onDelete: (MediaItem) -> Void)`:
   a LazyVGrid with 3 columns of square rounded thumbnails, plus one tile at
   the start (or end) that is a PhotosPicker configured for multi-selection,
   styled like a dashed "+" add tile consistent with the design system.
   Thumbnails should decode/downsample the stored Data efficiently (don't
   just drop full-resolution UIImages into an Image view at scale) so the
   grid stays smooth with 20+ photos. Long-pressing a thumbnail shows a
   "Видалити" action; confirming calls `onDelete` (routed to
   `MediaRepository.delete` by the caller) with a short confirmation ("Видалити фото?").

2. Implement the add flow: when photos are picked via PhotosPicker, load each
   as Data, resize/compress it (max dimension ~1600px, JPEG quality ~0.7),
   and call `MediaRepository.addPhoto` with the compressed Data and the
   owning tournament or match (whichever context the grid belongs to).

3. Build `PhotoViewerView`: a full-screen, swipeable (TabView with
   .page style or similar) viewer over an array of MediaItem, opened when a
   grid thumbnail is tapped, starting at the tapped index. Include a close
   button and, for isVideo items, basic playback (AVPlayer) instead of a
   static image.

4. Embed `PhotoGridView` into the existing `TournamentDetailView` (bound to
   `tournament.media`), placed below the match list.

Constraints: never hold full-resolution images in memory for the grid; do
the resize/compression off the main thread; keep MediaItem.data using
@Attribute(.externalStorage) as already defined on the model; deleting one
photo must not touch any other MediaItem.

[Paste the Localization Checklist from the localization work package here.]
```

---

## WP9 — Career Overview

**Depends on:** WP4, WP6.

*Apply the Localization Checklist from WP2 to every string and count in this package.*

### Context
The "whole journey" screen — a single scrollable album summarizing everything a child has done. Also the point where the Profile tab (stubbed since WP1/WP4) gets fully wired up.

### Screens
- **Career overview** — header with the same 4-stat aggregate row as the home screen (already computed on `Player`), followed by a vertical timeline of tournament cards (cover + placement badge), ordered chronologically.
- **Profile tab** (completing the screen stubbed earlier) — player summary card (avatar, name, "position · club №number", chevron to edit), the 4-stat pill row, list rows "Редагувати дитину" / "Додати дитину", and a gradient `Матчбук+` upsell banner (icon, bold title, one-line description) — the banner's tap action is stubbed until WP10.

### Data touched
Read-only: `Player.totalTournaments/totalMatches/totalGoals/totalAssists/podiums`, `Player.tournaments` (for the timeline).

### Done criteria
The timeline scrolls smoothly from the first tournament onward, podium entries are visually distinguishable at a glance in the timeline (not just on their own detail page), and the Profile tab's stats match the home screen's stats exactly (same source of truth).

### 🤖 AI Prompt
```
Using the existing Player model's computed career-aggregate properties
(totalTournaments, totalMatches, totalGoals, totalAssists, podiums) and the
design-system StatPill/CardStyle components, build the career-overview
feature and complete the Profile tab for Matchbook.

1. Build a `CareerOverviewView` (or extend PlayerHomeView with a dedicated
   section) with: a header showing the 4-stat row (reuse the exact same
   StatPill row component/config used on the home screen, for visual and
   data consistency), followed by a vertical timeline list of the player's
   tournaments sorted chronologically (oldest-to-newest or newest-first —
   pick one and be consistent), each rendered as a compact card: cover photo
   thumbnail, PlacementBadge if the tournament has a placement, name, and
   date (Date.FormatStyle). Podium tournaments (isPodium == true) should have
   a visually distinct treatment in the timeline (e.g. a colored left-edge
   accent or a subtly elevated card) so they stand out while scrolling.

2. Complete the "Профіль" tab (previously a placeholder):
   - A player summary card at the top: avatar, name, "{position} ·
     {club} №{shirtNumber}" caption, trailing chevron that opens
     PlayerEditView in edit mode.
   - The same 4-stat pill row as above.
   - A white card with two rows: "Редагувати дитину" (opens PlayerEditView)
     and "＋ Додати дитину" (opens PlayerEditView in create mode, same as the
     empty-state flow).
   - A gradient (brandGreen → brandGreenSecondary) banner card with a star
     icon, bold title "Матчбук+", and a one-line description
     ("Необмежені турніри, кілька дітей, преміум-картки"). Make it tappable
     but leave the action as a stub/TODO — the paywall is built in the next
     work package.

Ensure both the home screen and Profile tab pull their stat numbers from the
exact same Player computed properties so they can never disagree.

[Paste the Localization Checklist from the localization work package here.]
```

---

## WP10 — Monetization / Paywall

**Depends on:** WP4, WP9.

*Apply the Localization Checklist from WP2 to every string and count in this package.*

### Context
Deliberately soft-gated — the spec is explicit that copying a competitor's "lock everything after 1 match" paywall kills the habit loop and the organic sharing this product depends on.

### Tiers
- **Free:** 1–2 tournaments in full (unlimited matches within them), basic share card (watermarked), 1 child.
- **Matchbook+ subscription** (~$3–5/mo or discounted annual): unlimited tournaments, multiple children, unlimited photos/video, premium card styles without watermark, widgets + memories (Phase 2 items, but the entitlement should exist now).
- **One-time purchase:** tournament/season photobook (PDF/print), $5–15 — independent of the subscription (Phase 2 feature, but the StoreKit product and entitlement check belong in this package).

### Screen
A paywall screen (presented modally) listing the Matchbook+ benefits and pricing, plus a separate/secondary offer for the one-time photobook purchase; triggered either from the Profile banner (WP9) or automatically when a free user tries to create a 3rd tournament (via `TournamentRepository.canCreateTournament`).

### Downgrade behavior (new)
When Matchbook+ lapses (not renewed), tournaments/children beyond the free limit are **not hidden or deleted** — they become **read-only**: still visible in lists, photos/matches still viewable, but no new match/photo/tournament can be added beyond the limit while the subscription is inactive. This matches the "pay to keep it forever" positioning — the app must never look like it took away data the user already entered or already paid for.

### Done criteria
Creating a 3rd tournament on the free tier surfaces the paywall instead of succeeding (through the repository's gate, not an ad-hoc check in the view); an active Matchbook+ entitlement removes that limit and the share-card watermark; letting a subscription lapse turns over-limit content read-only rather than hiding it; purchases restore correctly across launches via an explicit "Restore Purchases" action.

### 🤖 AI Prompt
```
Implement StoreKit 2 monetization for Matchbook.

1. Define two products: an auto-renewable subscription "Matchbook+"
   (monthly ~$3-5, with an annual discounted option) and a non-consumable
   (or consumable, your call — recommend non-consumable per-tournament)
   one-time purchase "Tournament Photobook". Set up a StoreKit configuration
   file for local testing with these products.

2. Build an `EntitlementStore` (@Observable, not ObservableObject) that:
   - Listens to StoreKit's Transaction.updates.
   - Exposes `isSubscribed: Bool` and a method to check/consume the
     photobook purchase per tournament.
   - Handles restore purchases.

3. Build a `PaywallView`: shows the Matchbook+ benefits (unlimited
   tournaments, multiple children, unlimited photos/video, premium card
   styles without watermark, widgets + memories) with monthly/annual pricing
   from StoreKit, a subscribe button, and a smaller secondary section
   offering the one-time photobook purchase. Include a "Restore Purchases"
   action.

4. Replace the temporary `isSubscribed: true` stub used in
   `TournamentRepository.canCreateTournament` (from the tournament work
   package) with the real check against `EntitlementStore.isSubscribed`. When
   a non-subscribed user attempts to create a 3rd Tournament, the repository
   method returns false; the calling view presents `PaywallView` instead of
   creating the tournament. Tournament count checks should be per-child,
   matching the spec's "1 child free" framing (multiple children require
   Matchbook+ to begin with).

5. Implement downgrade behavior: when `isSubscribed` transitions from true to
   false (subscription lapsed/expired, not just app relaunch), tournaments
   and children beyond the free limit must NOT be hidden or deleted — mark
   them read-only in the UI (disable add-match/add-photo/add-tournament
   actions on over-limit content, but keep browsing, viewing photos, and
   sharing fully functional). Do not implement this as data deletion or
   filtering out of @Query results.

6. Wire the "Матчбук+" banner on the Profile tab (from the previous work
   package) to present `PaywallView`.

7. Gate the share-card watermark toggle and any premium card styles behind
   `entitlementStore.isSubscribed` (for now, a single premium style swap is
   enough — full style variety is a later iteration).

Follow StoreKit 2 best practices: verify transactions via
`VerificationResult`, keep purchase logic off the main actor where
appropriate, and do not block the UI while entitlement checks are pending.

[Paste the Localization Checklist from the localization work package here.]
```

---

## WP11 — Localization QA & Full Translation Pass

**Depends on:** WP1–WP10 (every screen built above).

### Context
WP2 set up the mechanism and discipline early so nothing was built against hardcoded strings in the first place. This package is the closing audit: catch anything that slipped through despite the checklist, finish English translation coverage now that the UI surface is stable (translating a screen that's still being redesigned wastes effort — this is why the *content* pass, unlike the *infrastructure*, waits until here), and pick up the App Store metadata localization lever, which is one of the strongest ASO levers independent of interface translation (build-spec §8).

### Scope
- Full audit of every screen built in WP1–WP10 for any string that bypassed the WP2 checklist (hardcoded literals, string-concatenated counts, manually built date strings).
- Complete English translations for every String Catalog entry — including generated strings like the share-card summary line ("5 ігор · 4 голи" / "5 games · 4 goals").
- Verify Ukrainian plural correctness end-to-end (one/few/many) across every screen that shows a count, not just the entries set up in WP2.
- Verify date/number formatting renders correctly and idiomatically in both locales (word order, separators).
- **Localize App Store metadata** (title, subtitle, keywords, screenshots) for both launch locales — a lever independent of in-app translation, worth doing even though it's not code.
- Confirm user-generated content (child's name, opponent names, tournament names, notes, photos) is never run through localization.

### Done criteria
Switching the device language between Ukrainian and English changes every piece of interface and generated-summary text correctly, with grammatically correct plurals in both languages; no visible hardcoded strings remain anywhere in the app; dates and numbers render correctly for both locales; App Store Connect metadata is prepared for both locales.

### 🤖 AI Prompt
```
Do a final localization QA and completion pass on the Matchbook iOS app
(SwiftUI, iOS 17+), which has had a String Catalog and a localization
checklist in place since early in development (see the localization
infrastructure work package).

1. Audit every screen built so far (splash, empty/syncing states, child
   profile, tournament creation, home/album, quick match entry, tournament
   hero/placement, share card, media grid, career overview, profile,
   paywall) for any string literal that isn't already going through
   Text(), String(localized:), or LocalizedStringResource, and for any count
   display that isn't using the String Catalog plural keys, and for any date
   that isn't using Date.FormatStyle/.formatted(...). Fix every instance
   found — the checklist should have caught most of these already, so this
   is a safety net, not the primary mechanism.

2. Provide complete, natural English translations for every string in the
   catalog, including the generated share-card summary line and any other
   dynamically composed text.

3. Verify Ukrainian plural forms are grammatically correct wherever a count
   appears: "1 гол" / "2 голи" / "5 голів"; "1 матч" / "2 матчі" / "5
   матчів"; "1 турнір" / "2 турніри" / "5 турнірів"; "1 асист" / "2 асисти" /
   "5 асистів" — and the equivalent English one/other forms.

4. Confirm date ranges and other formatted values look idiomatic in both
   locales — e.g. "12–14 червня" in Ukrainian vs. a locale-appropriate
   English rendering (not a literal word-for-word substitution).

5. Do NOT translate or attempt to localize user-entered content: player
   name, opponent name, tournament name, city/venue/team name typed by the
   user, or notes — confirm these pass through untouched regardless of
   locale.

6. Separately (not code): draft localized App Store Connect metadata
   (title, subtitle, keywords, and a screenshot text-overlay plan) for both
   Ukrainian and English storefronts.

Verify by switching the simulator's language to English and confirming every
screen reads naturally, all plurals are grammatically correct in both
languages, and no raw string keys or hardcoded Ukrainian text leak through in
English mode.
```

---

## WP12 — Accessibility Pass

**Depends on:** WP0–WP11 (all UI screens).

### Context
Not a blocker for early milestones, but must land before release rather than being deferred indefinitely (tech doc §5.4). The design system (WP0) already asked for accessibility-friendly component parameters — this package is the audit that confirms they were actually used correctly everywhere, plus the checks that can only happen once real screens exist.

### Scope
- **Dynamic Type:** verify body/label text doesn't break layout at the largest accessibility text sizes, especially the stat pill row and match row (tight horizontally by design).
- **VoiceOver:** every icon-only control (steppers, the floating action button, the share icon, photo delete) has an explicit accessibility label; verify by navigating each screen with VoiceOver enabled.
- **Contrast:** check text contrast on the gold/green accent surfaces specifically; confirm podium/placement information isn't conveyed by color alone (the medal emoji + text label should already cover this from WP0, but verify).

### Done criteria
Every screen is navigable and usable with VoiceOver; text scales without clipping or overlap at the largest Dynamic Type accessibility sizes; no interactive control lacks an accessible label; gold/green surfaces pass a basic contrast check for their text.

### 🤖 AI Prompt
```
Run an accessibility QA pass over the full Matchbook app (all screens built
in the previous work packages).

1. Enable the largest Dynamic Type accessibility text sizes in the simulator
   and go through every screen (empty state, child profile, home/album,
   tournament creation, quick match entry, tournament hero, share card
   preview, media grid, career overview, profile, paywall). Fix any layout
   that clips, truncates unexpectedly, or overlaps — pay particular attention
   to the stat pill row and match list rows, which are tight horizontally.

2. Enable VoiceOver and navigate every screen. Every icon-only control
   (steppers, the floating action button, the share icon, photo delete,
   tab bar items) must have a clear accessibility label describing the
   action, not just the icon name. Fix any control that VoiceOver announces
   ambiguously or skips.

3. Check text contrast on the gold-gradient PlacementBadge and any text
   sitting directly on brandGreen or the gold accent surfaces. Confirm that
   placement/podium status is conveyed through the medal emoji and text
   label, not color alone, so it's still understandable in high-contrast or
   grayscale accessibility modes.

Report any component that needs a design-system-level fix (so it's corrected
once, in WP0's components, rather than patched per-screen).
```

---

## WP13 — Phase 2 Backlog (planning only — do not build yet)

**Depends on:** MVP (WP0–WP12) shipped and validated with real users.

This package is intentionally **not** an implementation prompt — it's a reference list to turn into its own work packages once the MVP has validated the core loop. Pull individual items from this list into new, focused work packages (following the same format as WP0–WP12) when ready.

- **Goal moments (`GoalMoment`)** — per-goal detail (type, minute, optional video clip), replacing the simple `goals`/`assists` counters on `Match`. Model already exists from WP1.
- **Tournament/season photobook (PDF export)** — cover, matches, photos, summary; save/print. This is the primary paid hook tied to the one-time purchase from WP10.
- **Widgets / Lock Screen** — career numbers, next upcoming tournament. Entitlement-gated behind Matchbook+ (WP10).
- **"On this day" memories** — local notifications resurfacing past tournaments for off-season retention. Implemented via `UNUserNotificationCenter` locally; no server needed.
- **Badges / milestones** — first goal, hat-trick, first trophy.
- **Private family sharing (`CKShare`)** — a grandparent or the other parent, on a *different* Apple ID, views (read-only, or read-write — decide at scoping time) the same child profile. This is the feature the original MVP wording incorrectly implied was already covered by plain CloudKit private-database sync — it isn't; it requires a dedicated `CKShare`/`UICloudSharingController` implementation and belongs here.
- **Printable card styles** — additional premium `ShareCardView` templates, entitlement-gated.

### Open questions to resolve before or during Phase 2 (from the tech doc)
- **Crash reporting / analytics** — not decided for MVP. Weigh privacy (the data is about children — minimizing third-party SDKs is a real advantage of the current architecture) against the debugging value of Sentry/TelemetryDeck vs. Apple-only tooling (Xcode Organizer + MetricKit) vs. nothing.
- **Android** — not currently planned, so CloudKit-only stands. Revisit periodically rather than assuming permanently. The WP1 repository layer narrows the migration cost if Android does show up, but doesn't eliminate it — `@Query`-backed screens and the CloudKit layer itself would still need replacing with, e.g., Firestore-backed implementations of the same repository protocols.
- **Field-level validation rules** (min/max shirt number, negative match scores, etc.) — unspecified, left to implementation judgment.

### 🤖 AI Prompt (for scoping only)
```
I'm about to start Phase 2 of the Matchbook app after validating the MVP
(child profiles, tournaments, matches, placement/trophy view, share cards,
photos, career overview, paywall with downgrade behavior, localization,
accessibility — all shipped). Given this Phase 2 backlog:
goal moments (GoalMoment model, replacing simple goal/assist counters),
tournament/season PDF photobook export, home screen widgets, "on this day"
local notification memories, badges/milestones, private family sharing via
CKShare (cross-Apple-ID, read-only view of a child's profile), and additional
premium share-card styles —

help me turn each item into its own self-contained work package following
this format: Context, Screens, Data touched, Logic, Done criteria, and an
AI implementation prompt in English. Also help me resolve the open questions
carried over from MVP: pick a crash-reporting/analytics approach given the
child-data privacy angle, decide whether Android is now in scope (and if so,
scope a repository-swap work package before any Android-specific UI work),
and define field-level validation rules that were left open during MVP.
Prioritize the photobook export first (it's the primary paid feature), then
goal moments, then the rest in whatever order minimizes rework given what's
already built.
```
