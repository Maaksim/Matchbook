# Matchbook — Technical Documentation (v2)

Source materials: `matchbook-build-spec.md` (v2 — current source of truth; supersedes `matchbook-build-spec.pdf`, which is kept only as the historical v1 artifact) and `Matchbook.html` (interactive UI flow mockup, direction "Поле" / "Field"). This document merges both into a single reference for implementation.

**Changelog (v1 → v2):** corrected the CloudKit family-sharing claim (§2, §6); added a repository-pattern data access layer requirement (§3.9); added explicit edit/delete flows and empty/error states (§4.1–4.5, §4.8); added paywall downgrade behavior and Restore Purchases requirement (§7); added an Offline & Sync Behavior section (§9); added an Accessibility note (§5.4); added an Open Questions section (§11).

---

## 1. Product Overview

**Working title:** Matchbook (Матчбук)

**Category:** Youth football (soccer) companion app — a keepsake/memory-book for kids' tournaments and matches, not a stats dashboard.

**Target user:** Parents of children aged 6–14 who play in football tournaments.

**Job to be done:** "Save forever a tournament that would otherwise be forgotten."

**Emotional register:** Pride and nostalgia — not analytics.

**Key differentiator vs. competitor (STATZO):** Tournament is modeled as its own first-class object, and the product is framed as a photo album / memory book rather than a dashboard or player CV. Stats exist, but as a bonus, not the point.

**UX consequences:**
- Photos lead on every primary screen.
- Large "trophy card" treatments for tournament results.
- Minimal numeric/tabular UI on primary screens.
- The mental model is "album," not "spreadsheet."

---

## 2. Technical Stack

| Layer | Choice |
|---|---|
| Platform | iOS 17+ only (no iOS 16 support) |
| UI | SwiftUI |
| Persistence | SwiftData (`@Model`, `@Query`, `@Environment(\.modelContext)`) |
| Sync | CloudKit private database — free sync **between devices signed into the same Apple ID** (e.g. one parent's phone + iPad). This is *not* cross-account sharing: if the two parents use different Apple IDs, the private database does not sync between them. Viewing one child's profile from two different Apple IDs requires `CKShare`-based family sharing, which is a Phase 2 feature (§6), not part of MVP. No custom backend for MVP. |
| Data access | All writes/deletes/aggregations go through Repository protocols (§3.9), not directly from views into `modelContext`. This is a deliberate insurance policy: if CloudKit-only ever needs to be replaced (Android version, real cross-account sharing sooner than Phase 2, server-driven config), the migration is bounded to new repository implementations instead of a full rewrite. |
| Payments | StoreKit 2 (subscription + one-time purchase) |
| State management | Native `@Observable` (Observation framework) — **no** `ObservableObject` / `@StateObject`. ViewModels are introduced only where logic is genuinely complex; most screens read directly from `@Query`. |
| Localization | String Catalog (`.xcstrings`) from day one. Base language Ukrainian, second language English. |

---

## 3. Data Model (SwiftData, CloudKit-ready)

CloudKit compatibility rules followed throughout: every non-optional property has a default value; every relationship is optional; every to-many relationship declares an inverse; no `@Attribute(.unique)` is used anywhere (CloudKit does not support unique constraints).

### 3.1 Enums

```swift
enum PlayerPosition: String, Codable, CaseIterable {
    case goalkeeper, defender, midfielder, forward, unknown
    // LocalizedStringResource → strings are auto-extracted into the String Catalog
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
    case league             // round robin / groups
    case knockout           // knockout
    case groupPlusKnockout  // groups + knockout
    case friendly           // friendly
    case other
    var title: LocalizedStringResource {
        switch self {
        case .league:             "Кругова"
        case .knockout:           "Плей-оф"
        case .groupPlusKnockout:  "Групи + плей-оф"
        case .friendly:           "Товариський"
        case .other:              "Інше"
        }
    }
}

enum MatchOutcome: String, Codable {
    case win, draw, loss
}
```

### 3.2 `Player`

```swift
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

    // Career aggregates — computed, not stored
    var allMatches: [Match] { (tournaments ?? []).flatMap { $0.matches ?? [] } }
    var totalTournaments: Int { (tournaments ?? []).count }
    var totalMatches: Int { allMatches.count }
    var totalGoals: Int { allMatches.reduce(0) { $0 + $1.goals } }
    var totalAssists: Int { allMatches.reduce(0) { $0 + $1.assists } }
    var podiums: Int { (tournaments ?? []).filter { ($0.finalPlacement ?? 99) <= 3 }.count }
}
```

### 3.3 `Tournament`

```swift
@Model
final class Tournament {
    var id: UUID = UUID()
    var name: String = ""
    var startDate: Date = Date()
    var endDate: Date?
    var city: String?
    var venue: String?
    var format: TournamentFormat = TournamentFormat.other
    var teamName: String?          // team the child played for
    var finalPlacement: Int?       // 1, 2, 3… nil if not applicable
    var placementLabel: String?    // "Champions", "Finalists", "Group stage"
    @Attribute(.externalStorage) var coverPhotoData: Data?  // tournament cover image
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

    // Tournament aggregates
    var sortedMatches: [Match] { (matches ?? []).sorted { $0.date < $1.date } }
    var goals: Int { (matches ?? []).reduce(0) { $0 + $1.goals } }
    var assists: Int { (matches ?? []).reduce(0) { $0 + $1.assists } }
    var wins: Int { (matches ?? []).filter { $0.outcome == .win }.count }
    var isPodium: Bool { (finalPlacement ?? 99) <= 3 }
}
```

### 3.4 `Match`

```swift
@Model
final class Match {
    var id: UUID = UUID()
    var date: Date = Date()
    var opponent: String = ""
    var teamScore: Int = 0
    var opponentScore: Int = 0
    var stage: String?          // "Group A", "1/4", "Final"
    var goals: Int = 0          // child's goals — simple counter, MVP only
    var assists: Int = 0        // child's assists
    var minutesPlayed: Int?
    var playerRating: Double?   // 0…10, optional
    var isMotm: Bool = false    // Man of the Match
    var notes: String?
    var createdAt: Date = Date()

    var tournament: Tournament?

    @Relationship(deleteRule: .cascade, inverse: \MediaItem.match)
    var media: [MediaItem]? = []

    // Phase 2: replace goals/assists counters with a list of moments
    @Relationship(deleteRule: .cascade, inverse: \GoalMoment.match)
    var moments: [GoalMoment]? = []

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
```

### 3.5 `MediaItem` (photo/video)

```swift
@Model
final class MediaItem {
    var id: UUID = UUID()
    @Attribute(.externalStorage) var data: Data?  // large payloads live outside the DB
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
```

### 3.6 `GoalMoment` (Phase 2 — per-goal detail)

```swift
enum GoalKind: String, Codable, CaseIterable {
    case openPlay, penalty, freeKick, header, other
}

@Model
final class GoalMoment {
    var id: UUID = UUID()
    var isAssist: Bool = false   // false = goal, true = assist
    var kind: GoalKind = GoalKind.openPlay
    var minute: Int?
    var note: String?
    var match: Match?
    init() {}
}
```

### 3.7 Entity relationship summary

```
Player 1───* Tournament 1───* Match 1───* MediaItem
                  │                 │
                  └──────* MediaItem └───* GoalMoment (Phase 2)
```

### 3.8 App container / CloudKit bootstrap

```swift
@main
struct MatchbookApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(for: [Player.self, Tournament.self, Match.self,
                                   MediaItem.self, GoalMoment.self])
        // For sync: enable the iCloud + CloudKit capability on the target;
        // SwiftData then mirrors to the private database automatically.
    }
}
```

**Implementation notes:**
- If CloudKit schema initialization fails because of the enum-backed properties, fall back to storing `position` / `format` as `String` with a computed wrapper property. On iOS 17+, direct Codable-enum storage generally works, so start with the clean version above.
- Video `Data`, even in external storage, is heavy. For MVP, cap video to 15–20 seconds, or ship photos only in v1 and move video to Phase 2.

### 3.9 Data Access Architecture (Repository pattern) — new requirement

**Why:** "CloudKit, no backend" is the right call for MVP, but it's exactly the kind of decision that's expensive to reverse later — an Android version, a real cross-account family-sharing need earlier than Phase 2, or server-driven paywall/config logic could all force a change. Isolating persistence behind an interface now, rather than "when it's needed," keeps that door open cheaply.

**Rule:** every create/update/delete and every business aggregation goes through a repository protocol, not directly from a View/ViewModel into `modelContext`.

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

protocol MatchRepository { /* same shape: create/update/delete/fetch */ }
protocol MediaRepository { /* create/delete + photo/video compression */ }
```

- **Default implementations:** `SwiftDataPlayerRepository`, `SwiftDataTournamentRepository`, etc. — thin wrappers around `modelContext`.
- **List screens** (`PlayerHomeView`, `TournamentDetailView`) can keep using `@Query` directly for reactive rendering — that's a normal SwiftData idiom, and banning it everywhere for architectural purity would fight the simplicity principle in §2. But *writes*, *deletes*, *paywall checks*, and *aggregations* (career stats, podium counts, etc.) belong in the repository, not scattered across views.
- **What this buys:** if Firebase (Firestore/Realtime Database) is ever needed, the migration narrows to (1) new implementations of the same protocols and (2) replacing `@Query`-backed list screens with an `@Observable` wrapper around a Firestore snapshot listener. Business logic (paywall gates, aggregation, validation) doesn't get rewritten, because it was never coupled to the SwiftData API in the first place.
- **Cost:** modest extra boilerplate up front (one protocol + one implementation per aggregate). This is a deliberate trade for optionality, not a mandate to minimize LOC.

---

## 4. MVP Features (v1)

Each feature is specified as: **what it does → screens → key logic → data → done criteria**.

### 4.1 Child profile (`Player`)
- **What:** create/edit/**delete** a child; support multiple children (switcher at the top).
- **Screens:** children list (if >1) → form (name, photo via `PhotosPicker`, shirt number, position, club, birth date).
- **Logic:** `@Query` over all `Player`, sorted by `createdAt`. Active child stored in `@AppStorage("activePlayerID")`. Create/update/delete go through `PlayerRepository` (§3.9).
- **Delete:** deleting a child cascades to all their tournaments/matches/photos (`.cascade` in the model). Requires a confirmation dialog stating the scope of loss explicitly ("Delete Marko and 4 tournaments, 87 photos? This can't be undone"). If the deleted child was active, the next `Player` in the list becomes active, or the empty state (§4.8) shows if none remain.
- **Data:** `Player`.
- **Done when:** a child can be created with a photo, becomes active, and survives an app relaunch; delete works with confirmation and doesn't crash when deleting the active child.

### 4.2 Create tournament (`Tournament`)
- **What:** add/edit/**delete** a tournament under the active child.
- **Screens:** form (name, start/end dates, city, venue, format, team name, cover photo).
- **Logic:** new `Tournament`, `player = activePlayer`, created through `TournamentRepository`. Before creation, call `canCreateTournament(for:isSubscribed:)` for the free-tier gate (§7).
- **Delete:** confirmation dialog ("Delete this tournament and all 6 matches, 40 photos?"). Cascades to that tournament's `Match` and `MediaItem` records.
- **Data:** `Tournament`.
- **Done when:** the tournament appears in the child's tournament list, sorted by date (newest first); edit and delete work with confirmation.

### 4.3 Quick match entry (`Match`) — primary flow
- **What:** log/edit/**delete** a match in ~3 taps, courtside.
- **Screen:** single form sheet: opponent (text) → score (two steppers: `teamScore` / `opponentScore`) → child's goals/assists (steppers). Everything else (stage, minutes, rating, MOTM, notes) lives under a `DisclosureGroup` labeled "Details."
- **Logic:** bound to the current tournament; `outcome` is computed automatically; a "Save & add another" action supports back-to-back matches. Writes go through `MatchRepository`.
- **Offline:** saving a match is a local SwiftData write and succeeds instantly regardless of pitch-side connectivity; CloudKit sync happens in the background once network is available (see §9).
- **Delete:** swipe-to-delete or a button in match detail, with a lightweight confirmation (a match is a smaller unit of loss than a tournament, but accidental deletion should still be confirmed).
- **Data:** `Match`.
- **Done when:** a match can be added in under 15 seconds, saving doesn't block the UI or require network, "add another" preserves the tournament context, and editing/deleting a saved match works.

### 4.4 Tournament summary (placement + trophy)
- **What:** record the final placement and produce a "trophy" card.
- **Screen:** tournament detail: hero block on top (cover photo + placement + medal emoji + `placementLabel`), match list below, aggregates (W-D-L, goals, assists) in small secondary text underneath.
- **Logic:** placement chosen from presets (Champion / Finalist / 3rd / Group stage / No placement); `finalPlacement` and `placementLabel` stay in sync.
- **Data:** `Tournament`.
- **Done when:** a podium tournament is visually distinct and the card reads like an award.

### 4.5 Media (photos)
- **What:** attach/**delete** photos on a match and on a tournament.
- **Screen:** photo grid on match/tournament detail; add via `PhotosPicker` (multi-select); delete via long-press → "Delete," with confirmation.
- **Logic:** store compressed images (max ~1600px, JPEG ~0.7 quality) in `MediaItem.data` (external storage), through `MediaRepository`. Show thumbnails; full image on tap.
- **Privacy note:** the share card (§4.6) surfaces the child's name and photo outside the app. Don't attach anything beyond what's shown in the preview (e.g., no precise venue geolocation on the card) without a separate opt-in.
- **Data:** `MediaItem`.
- **Done when:** 20+ photos don't cause lag or bloat the database (verify external storage is actually being used); deleting a single photo doesn't affect the rest of the tournament.

### 4.6 Share card (viral hook #1)
- **What:** generate a shareable card for a match/tournament for team chats and stories.
- **Screen:** card preview + `ShareLink`. A SwiftUI view is rendered to `Image` via `ImageRenderer`.
- **Card content:** child/tournament photo, name, placement/medal, score or a summary line ("5 games • 4 goals •"). App logo watermark — this is the organic marketing channel.
- **Logic:** `ImageRenderer(content:).uiImage`, shared as PNG.
- **Done when:** the card is legible in both square and 9:16 formats, and the watermark is present.

### 4.7 Career overview
- **What:** a single "album of the whole journey" screen for the child.
- **Screen:** header with aggregates (tournaments, matches, goals, assists, podiums) + a timeline of tournament cards (cover + placement).
- **Logic:** computed properties on `Player`.
- **Done when:** the timeline scrolls from the first tournament onward and podium finishes stand out.

### 4.8 Empty & error states — new requirement

Only "first launch" was previously specified. Not enough for a sync-dependent app:

- **iCloud not signed in / disabled on the device.** The app must still fully work locally (SwiftData without CloudKit mirroring just doesn't sync). Show a one-time, non-blocking banner ("Data is only stored on this device — sign in to iCloud so you don't lose it when you switch phones"); never block the flow.
- **New device, sync not finished yet.** First launch on a second device on the same Apple ID can show an empty state for a few seconds/minutes while CloudKit catches up. Show a brief "Syncing…" indicator instead of the "Add a child" welcome screen when the CloudKit container indicates an account is configured and likely already has data — to avoid nudging the user into creating a duplicate child.
- **iCloud storage full.** Photo/video sync can silently fail. Check sync status once per session and show a non-blocking warning (toast/banner, not a per-screen alert) if writes to CloudKit keep failing.
- **Tournament with zero matches.** Show a short "Add your first match" prompt instead of a blank list.
- **Cascading deletes.** Every delete that touches child records (Player → Tournament → Match/MediaItem) requires confirmation with an explicit statement of what's being lost (see §4.1–4.3).

### v1 navigation map

```
RootView (tab bar / active child)
 └─ PlayerHomeView (career + tournament list)
     └─ TournamentDetailView (hero + matches)
         └─ MatchEditView

Modals: PlayerEditView, TournamentEditView, ShareCardView
```

---

## 5. Screen Flow & UI Specification (from `Matchbook.html`)

`Matchbook.html` is a self-contained interactive canvas export (design-tool bundle, direction labeled **"Поле" / "Field"**) showing the app's primary flow as a sequence of iPhone frames connected by directional arrows. No real photo assets are embedded — all photo/cover placeholders use a diagonal-stripe pattern fill with an uppercase caption (e.g. "ФОТО ТУРНІРУ" / "PHOTO OF TOURNAMENT").

### 5.1 Flow sequence (in canvas order, left → right, with branch below)

| # | Screen (label on canvas) | Type | Purpose / key content |
|---|---|---|---|
| 1 | Splash · запуск | Full screen | Dark green background, circular monogram "М", wordmark "Матчбук", tagline "Турніри, які не забудуться" ("Tournaments that won't be forgotten"), footnote "дитячий футбол · спогади" |
| 2 | Порожній стан · вітання | Full screen | First-run welcome: ball icon, headline "Вітаємо в Матчбуці", subtext explaining the value prop, 3 feature bullets (Tournament = album not dashboard; Photo-first; Shareable cards), primary CTA "＋ Додати дитину" |
| 3 | Нова дитина · модальний лист | Modal sheet | Add-child form: Cancel / "Нова дитина" title / Add; circular "add photo" avatar picker; fields Ім'я (Name), Номер (Number), Клуб (Club); section ПОЗИЦІЯ (Position, chevron row); section ДЕТАЛІ → Дата народження (Birth date, chevron row) |
| 4 | Головна · Альбом | Full screen (tab: Album) | Home/album screen. Green hero header: avatar, child name "Марко", subtitle "Нападник · ДЮФК «Лев» U-11", shirt-number badge "10"; 4-stat pill row (турнірів / матчі / голи / **подіуми** — podium stat gets the gold accent tint); large tournament cover card with gold "🥇 Чемпіони" badge, title, "Львів · червень 2026 · 5 ігор"; 2-column grid of smaller tournament cards (🥈 Фіналісти, 🥉 3-тє); floating action button "Новий турнір" + "+"; bottom tab bar (Альбом / Турніри / Профіль) |
| 5 | Профіль · «Додати дитину» → форма | Full screen (tab: Profile) | Header "Профіль"; player summary card (avatar, name, position/club/number, chevron); same 4-stat pill row; list rows "Редагувати дитину" and "Додати дитину" (with + icon); gradient upsell banner "Матчбук+" advertising unlimited tournaments/multiple children/premium cards; tab bar with Profile active |
| 6 | Новий турнір · модальний лист | Modal sheet | Cancel / "Новий турнір" / Create; dashed-border cover-photo picker "Обкладинка турніру"; section НАЗВА (Name) — "Кубок Карпат 2026"; section ДАТИ (Dates) — Від / До rows; section МІСЦЕ І КОМАНДА (City / Team); section ФОРМАТ (Format, chevron row) — "Групи + плей-оф" |
| 7 | Турнір · герой + матчі | Full screen (tab: Album, pushed) | Hero photo block with back and share icon buttons, gold "🥇 Чемпіони" badge, title "Кубок Карпат 2026", "Львів · 12–14 червня · Лев U-11"; stat row (4–1–0 В·Н·П = W-D-L, 5 голи, 2 асисти); match list rows — opponent name, stage + goal/assist icon, MVP tag, score chip (win = filled green, draw = beige/neutral); floating action "Новий матч" + "+"; tab bar |
| 8 | Картка для шерингу · 9:16 | Share-card artifact | Vertical (9:16) share card: full-bleed photo, gold "🥇 Чемпіони" pill centered near top, title, "Марко · Нападник · №10", 3-stat row (ігор / голів / асисти), small "Матчбук" wordmark watermark top-left |
| 9 | Швидкий матч · модальний лист | Modal sheet | Title "Новий матч"; СУПЕРНИК (Opponent) text field; РАХУНОК (Score) — two stepper columns "НАШІ" / "СУПЕРНИК" with −/+ controls; ДИТИНА (Child) section — Голи (Goals) and Асисти (Assists) stepper rows; Деталі row (stage · minutes · rating, chevron); "Гравець матчу" (MOTM) toggle switch; bottom-pinned primary button "Зберегти" (Save) and secondary text action "Зберегти й додати ще" (Save & add another) |

### 5.2 Transition labels shown on the canvas (arrows between frames)

- Splash → Empty state: **"Перший запуск"** (First launch)
- Empty state → New Child sheet: **"«Додати дитину»"** (tap "Add child")
- New Child sheet → Home/Album: **"«Додати» → збережено"** (tap "Add" → saved)
- Home/Album → Profile: **"Таб «Профіль»"** (Profile tab)
- Profile → New Tournament sheet: **"Плаваюча «＋» → Новий турнір"** (floating "+" → New tournament), with a secondary annotation "або тап на наявний турнір →" (or tap an existing tournament)
- New Tournament sheet → Tournament detail: **"«Створити»"** (tap "Create")
- Tournament detail → Share card: **"Кнопка «↗ Поділитися»"** (Share button)
- Tournament detail → Quick Match sheet: **"Плаваюча «＋» → Матч"** (floating "+" → Match)

This confirms the primary loop the spec describes in §4: **Home → new tournament → quick match entry (repeatable) → placement/trophy → share card**, with Profile as the secondary hub for child management and the upsell entry point.

### 5.3 Design system extracted from the mockup

**Color palette**

| Token | Hex | Usage |
|---|---|---|
| Brand green (primary) | `#1F5E37` | Headers, primary buttons, active tab icon, splash background, FAB, filled score chips |
| Brand green (secondary/hover) | `#2C6B3E` | Links, arrow/connector strokes, gradient partner for brand green |
| Canvas background | `#e7e2d8` | Design-doc canvas backdrop (not app UI) |
| Screen background (light) | `#F3EEE4` / `#F1ECE2` | Default app background / modal sheet background |
| Card surface | `#FFFFFF` | Cards, list rows, input fields |
| Primary text | `#1c2a20` | Default body/heading text on light backgrounds |
| Muted text | `#8a978c`, `#9b9384`, `#8a8578` | Secondary text, placeholders, section labels |
| Hairline / divider | `#eee7db`, `#f0eadd`, `#d5cdbc` | Row separators, sheet grabber |
| Subtle field background | `#EAE4D6` | Stepper control background |
| Gold gradient (podium accent) | `#F6D479 → #E8B84B` | 1st-place / "Чемпіони" badges, share-card medal pill |
| Gold text/accent | `#F4CE6E`, `#C6A02C`, `#6b4e0f` | Podium stat number, badge text |
| Light green tint | `#E3EFDF`, `#e8efe2` | Icon chips, feature bullet backgrounds, annotation labels |
| Silver/bronze placement chips | neutral white badge with emoji (🥈/🥉) | 2nd/3rd place tournament cards |
| Draw/neutral score chip | `#EDE7D8` bg / `#8a7d5e` text | Draw result in match list |
| Success toggle (MOTM) | `#34C759` | iOS-standard switch "on" state |

**Typography**

- **Unbounded** (weight 700) — display/heading font: wordmark, screen titles, stat numbers, card titles. Distinctive geometric display face reinforcing the "trophy/keepsake" feel.
- **Onest** — UI/body font (weights 400–600): labels, body copy, list rows, buttons, tab bar labels.
- **Manrope** — loaded as a web font (multiple weights/unicode ranges incl. Cyrillic) but not applied anywhere in the visible mockup; treat as unused/reserved rather than part of the active type system.
- Numeric stat labels use uppercase with letter-spacing (e.g., "ТУРНІРІВ", "МАТЧІ") at ~7.5–8px — deliberately small/secondary per the spec's "minimize numbers" direction.

**Component patterns**

- **Cards:** large corner radii throughout (13–26px), soft elevated shadows (`box-shadow: 0 Npx Mpx rgba(20,45,28,.1–.35)`), diagonal-stripe placeholder fill for any photo slot.
- **Stat pill row:** 3–4 equal-width rounded chips in a row; the "podium" stat is visually distinguished with a warm gold tint instead of the neutral chip color.
- **Placement badge:** pill-shaped, gold gradient background, medal emoji + label (e.g. "🥇 Чемпіони"), used consistently on cover cards, tournament hero, and the share card.
- **Match row:** opponent name (bold) + stage/goal icon line, trailing score chip (filled green for win, muted beige for draw/loss).
- **Steppers:** paired −/+ buttons in a single rounded-rect control, used for score and goals/assists entry — matches spec §4.3's "steppers, not text fields" requirement for the quick-add flow.
- **Bottom tab bar:** frosted/blurred translucent bar, 3 items (Альбом / Турніри / Профіль), active icon filled + brand green, inactive icon outlined + muted gray.
- **Floating action button:** circular, brand green, "+", paired with a pill-shaped text label describing the action ("Новий турнір", "Новий матч") — an explicit affordance rather than an icon-only FAB.
- **Modals:** presented as iOS sheets with a grabber handle, Cancel/Title/primary-action header row — standard native sheet chrome, consistent with the spec's instruction to avoid custom navigation chrome.

This visual direction matches spec §7 (Design direction) point for point: warm "album" aesthetic, large rounded corners, soft shadows, gold/silver/bronze accents for podium results, minimal/secondary numeric display on primary screens.

### 5.4 Accessibility — new requirement

- **Dynamic Type:** body/label text must not break layout at the largest accessibility text sizes; test the stat pill row and match row specifically, since they're tight horizontally.
- **VoiceOver:** icon-only controls (steppers, the floating action button, the share icon) need explicit labels — none of the mockup's icon-only affordances have a text fallback baked in.
- **Contrast:** verify text contrast on the gold/green accent surfaces separately; treat gold badges as a secondary/decorative signal, not the sole carrier of information (e.g., don't rely on gold color alone to convey "1st place" — the medal emoji + label text already do this correctly).
- Not a blocker for early MVP milestones, but must be on the pre-release checklist, not deferred indefinitely.

---

## 6. Phase 2 Roadmap (post-MVP validation)

- **Goal moments (`GoalMoment`)** — goal type, minute, video clip per goal; replaces the simple `goals`/`assists` counters on `Match`.
- **Tournament/season photobook** — generated PDF (cover, matches, photos, summary) with save/print. Primary paid hook.
- **Widgets / Lock Screen** — child's career numbers, next upcoming tournament.
- **"On this day" memories** — local notifications resurfacing past tournaments (off-season retention).
- **Badges/milestones** — first goal, hat-trick, first trophy.
- **Private family sharing (`CKShare`)** — grandparents/the other parent, on a *different* Apple ID, can view (read-only, or read-write — decide when this feature is scoped) the same child profile. This is the feature that §2 previously implied was already covered by plain CloudKit sync — it isn't; it requires a dedicated `CKShare`/`UICloudSharingController` implementation and belongs here.
- **Printable card styles** — additional premium share-card templates.

---

## 7. Monetization (StoreKit 2)

Explicit design goal: **do not** copy STATZO's hard paywall after 1 match — that kills the habit-forming loop and the organic reach that comes from parent group chats.

**Free tier** (build the habit, let cards circulate):
- 1–2 tournaments in full, unlimited matches within them.
- Basic share card (with watermark).
- 1 child profile.

**Matchbook+ subscription** (~$3–5/mo, or discounted annual):
- Unlimited tournaments.
- Multiple children.
- Unlimited photos/video.
- Premium card styles, no watermark.
- Widgets + memories.

**One-time purchase** (independent of subscription):
- Tournament/season photobook (PDF/print) — $5–15 each. Parents pay more readily for a keepsake than for graphs; this monetizes users who won't subscribe.

**Downgrade behavior — new requirement.** When Matchbook+ lapses (not renewed), tournaments/children beyond the free limit are **not hidden or deleted** — they become **read-only**: still visible in lists, photos/matches still viewable, but no new match/photo/tournament can be added beyond the limit while the subscription is inactive. This matches the "pay to keep it forever" positioning — the app should never look like it "took away" data the user already entered or already paid for.

**Restore Purchases — new requirement.** The StoreKit 2 flow must include an explicit "Restore Purchases" action on the paywall screen (required by App Review; also needed on reinstall/device change).

**Underlying logic:** people pay not "to keep using it" but "to keep it forever."

---

## 8. Localization Strategy

**Bottom line:** localization has real ROI here — youth football is a universal category (STATZO has downloads in 20+ countries) and this app has no dependency on external league data (everything is user-entered), so it works "out of the box" in any market; expanding is just an interface translation, not a data-sourcing problem.

**What actually drives ROI, in order:**
1. **Never hardcode strings.** Cheap if done from day one, painful retroactively — hence all enum titles are already `LocalizedStringResource`.
2. **Localize App Store metadata** (title, subtitle, keywords, screenshots) per region — one of the strongest ASO levers, independent of interface translation.
3. **Translate the interface into 1–3 languages at launch**; add more only after validation.

**Launch languages:** Ukrainian + English (base + English unlocks the global market).
**Fast follow:** Polish, Spanish, Portuguese, German — large football cultures / adjacent markets.

**Technical approach (SwiftUI, iOS 17+):**
- **String Catalog (`.xcstrings`)** — the Xcode 15+ mechanism, replacing `.strings`/`.stringsdict`; auto-extracts strings from code and holds translations + plurals in one file.
- `Text("...")` and `String(localized:)` localize automatically; strings passed between functions should be typed as `LocalizedStringResource`.
- **Pluralization is critical for Ukrainian** (Slavic one/few/many forms: "1 гол", "2 голи", "5 голів"; "матч/матчі/матчів"; "турнір/турніри/турнірів"). Never build these by string concatenation — always use String Catalog plural keys.
- **Dates/numbers must be locale-aware** — use `Date.FormatStyle` / `.formatted(...)`, never manual string formatting (e.g. "12–14 червня" vs. "12–14 June" differ in word order and separators).
- **RTL readiness** (Arabic, etc., when it comes up) — use `leading`/`trailing`, never `left`/`right`; SwiftUI mirrors layout automatically if directions aren't hardcoded.

**Localize:** all interface chrome, position/format names, labels, buttons, and — critically — *generated* strings (tournament summaries, share-card text like "Чемпіони · 5 ігор · 11 голів"), including correct pluralization.

**Do not localize:** user-generated content — child's name, opponent names, tournament names, notes, photos. Entered as-is.

---

## 9. Offline & Sync Behavior — new section

- **Local write is always primary.** Every create/edit (especially quick match entry, §4.3) writes to the local SwiftData store synchronously and instantly, regardless of network — the core use case is a pitch/sports venue with unreliable connectivity.
- **CloudKit sync is background and best-effort.** SwiftData mirrors changes to the private CloudKit database whenever network is available. The UI must not block, and must not surface an error just because sync is delayed — only if it's failing systematically (§4.8).
- **Write conflicts.** If two devices on the same Apple ID edit the same record offline at the same time (rare but possible — e.g. one parent's phone and iPad), CloudKit/SwiftData applies standard field-level merge (last write wins per changed field). **Duplicate records** (the same match entered twice from different devices before they sync) are an accepted MVP limitation, not solved. If it becomes a real problem in production, consider de-duplicating on (opponent + date + tournament) when a sync conflict is detected.
- This is another place the repository layer (§3.9) earns its keep: the "save now, sync later" logic is encapsulated in the repository implementation, not spread across views.

---

## 10. Recommended Build Order

1. Data model (with `LocalizedStringResource` enums) + repository protocols (§3.9) → enable String Catalog immediately.
2. §4.1 Child profile (create/edit/delete)
3. §4.2 Tournament creation (create/edit/delete, paywall gate through the repository)
4. §4.3 Quick match entry (create/edit/delete, offline-first)
5. §4.4 Tournament summary / placement
6. §4.6 Share card (early "wow" moment, validates the core hook)
7. §4.5 Media
8. §4.7 Career overview
9. §4.8 Empty & error states (build alongside 2–8, not as a separate pass at the end)
10. Paywall (StoreKit 2, with downgrade behavior and Restore Purchases)
11. Second language + App Store metadata localization
12. Accessibility checklist (§5.4)
13. Phase 2 backlog

Localization infrastructure (String Catalog, localized strings from the first line of UI code) should not be deferred — the second language and App Store metadata translation can land right before launch, but the *scaffolding* must exist from the first commit.

### Reference AI implementation prompts (from the spec, for use one feature at a time)

1. **Project scaffold:** "Create a new SwiftUI app, iOS 17+, with SwiftData and CloudKit. Add the models from §3 of this spec. Create the repository protocols from §3.9 (`PlayerRepository`, `TournamentRepository`, `MatchRepository`, `MediaRepository`) and their SwiftData implementations. Configure `modelContainer` with CloudKit. Build `RootView` with an active-child switcher via `@AppStorage`."
2. **Profile + tournaments (4.1–4.2):** "Implement `PlayerEditView` (PhotosPicker for avatar) with create/edit/delete through `PlayerRepository`, and `PlayerHomeView` with the active child's tournament list via `@Query`. Add `TournamentEditView` with create/edit/delete through `TournamentRepository`, including the `canCreateTournament` paywall gate. Every delete needs a confirmation showing the scope of the cascade. Follow: `@State private`, `foregroundStyle`, `clipShape(.rect(cornerRadius:))`, `Button` instead of `onTapGesture`."
3. **Quick match (4.3):** "Build `MatchEditView` — a match create/edit/delete form with score and goals/assists steppers, details under a `DisclosureGroup`, a 'Save & add another' action. Bind to the passed-in `Tournament` through `MatchRepository`. Make sure saving never depends on network (local SwiftData write)."
4. **Tournament hero + media (4.4–4.5):** "Build `TournamentDetailView`: hero block with cover photo, placement, and medal; match list; photo grid with multi-select `PhotosPicker` and per-photo delete; compress photos to 1600px before saving to `MediaItem` through `MediaRepository`."
5. **Share card (4.6):** "Build `ShareCardView` — square and 9:16 variants, with photo, name, summary, and watermark. Render via `ImageRenderer`, hand off to `ShareLink` as PNG. The preview must clearly show what will be shared before the user shares it."
6. **Empty & error states (4.8):** "Add states for: no iCloud account (banner, app still works locally), sync-in-progress on a new device (indicator instead of the welcome screen), a tournament with no matches (prompt to add the first one), and confirmation dialogs for every cascading delete."
7. **Paywall (§7 here / §6 in spec):** "Add StoreKit 2: the Matchbook+ subscription and the one-time 'Photobook' purchase. Free-tier limit is 2 tournaments; show the paywall via `canCreateTournament` when a third is attempted. Implement downgrade as read-only (not hide/delete) for over-limit content once a subscription lapses. Add a 'Restore Purchases' action."
8. **Localization (§8 here):** "Enable String Catalog (`.xcstrings`), base language Ukrainian, add English. Verify all UI strings are localized, not hardcoded. Output goal/match/tournament counts via plural keys (one/few/many), not concatenation. Format dates/numbers via `Date.FormatStyle`/`.formatted()`. Make the generated share-card summary text localized and correctly pluralized."

---

## 11. Open Questions — new section

Deliberately left unresolved so they don't block the start of development, but they need to land in the backlog before release:

- **Crash reporting / analytics.** Not decided (Sentry/TelemetryDeck vs. Apple-only tooling — Xcode Organizer + MetricKit — vs. nothing for MVP). Privacy is a real factor here given the data is about children; minimizing third-party SDKs is a genuine advantage of the current architecture, and whatever gets picked should weigh that.
- **Android.** Not currently planned, so CloudKit-only stands. Worth revisiting periodically rather than assuming permanently — the repository layer (§3.9) narrows the migration cost if Android does show up, but doesn't eliminate it; `@Query`-backed screens and the CloudKit layer itself would still need replacing.
- **Field-level validation rules** (min/max shirt number, negative match scores, etc.) are unspecified — left to implementation judgment on the first pass.

---

## Appendix: Source Files

- `matchbook-build-spec.pdf` — original (v1) 12-page Ukrainian-language build spec. Kept as a historical artifact only; superseded by `matchbook-build-spec.md`.
- `matchbook-build-spec.md` — current (v2) build spec: same scope as the PDF plus the corrections and additions listed in this document's changelog (repository pattern, corrected CloudKit sharing claim, edit/delete flows, empty/error states, downgrade behavior, offline/sync behavior, accessibility, open questions).
- `Matchbook.html` — self-contained interactive canvas export (design-tool bundle) showing the "Поле"/"Field" flow direction as 9 connected iPhone-frame mockups with transition annotations; no bitmap photo assets embedded, only placeholder patterns and web fonts (Unbounded, Onest, Manrope).
