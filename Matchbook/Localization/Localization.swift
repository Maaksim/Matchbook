import Foundation

// MARK: - Matchbook localization rules
//
// Base (development) language is **Ukrainian**; English is a shipped target language.
// The single source of truth is `Resources/Localizable.xcstrings`. Four rules, and they
// are not negotiable per-screen — every work package from WP2 onward is written against
// them from its first line rather than retrofitted:
//
// 1. Every user-visible string goes through `Text(…)`, `String(localized:)` or
//    `LocalizedStringResource`, and is addressed by a **semantic key**, never by its
//    Ukrainian text:
//
//        Text("welcome_title_key")        // ✅
//        Text("Вітаємо в Матчбуці")       // ❌ — the copy is not the key
//
//    Keys are `lower_snake_case` and end in `_key`, prefixed by their area:
//    `tab_*`, `stat_*`, `position_*`, `format_*`, `welcome_*`, `splash_*`, `album_*`,
//    `*_accessibility_key` for VoiceOver labels, `*_count_key` for the plurals below.
//    Two identical Ukrainian words in different contexts get two keys — `tab_tournaments_key`
//    and `stat_tournaments_key` are both "Турніри" today but are free to diverge in English
//    or in any later language, which is the whole point of keying semantically.
//
//    **Consequence, and the one thing to actually watch:** the key is no longer the copy,
//    so a key with no `uk` entry does not fall back to Ukrainian — it renders the literal
//    string `welcome_title_key` on screen, in *every* language. Every catalog entry must
//    therefore carry **both** `uk` and `en`. `LocalizationTests` fails the build if one
//    doesn't.
//
//    Display parameters on components are typed `LocalizedStringResource`, never `String` —
//    a component taking `label: String` cannot be localized by its caller (see `StatPill`,
//    `TabPlaceholderView`, `FloatingActionPill`). UIKit call sites that demand a `String`
//    (e.g. `UITabBarItem`) resolve eagerly with `String(localized:)`.
//
// 2. Counts always go through the plural keys below (`Counts.goals(_:)` and friends), never
//    string concatenation. `"\(count) голів"` is wrong even for a throwaway screen:
//    Ukrainian needs one/few/many (1 гол / 2 голи / 5 голів) and no amount of interpolation
//    can express that. English needs one/other.
//
// 3. Dates and numbers always go through `Date.FormatStyle` / `.formatted(…)`, never a
//    hand-built string. "12–14 черв." and "Jun 12 – 14" differ in order *and* separator;
//    a concatenated string can only ever be right in one language.
//
// 4. User-generated content is never localized. Child name, opponent, tournament name, club,
//    city, venue, notes, `Tournament.placementLabel` — all pass through exactly as typed, in
//    any locale. Note `Text(someStringVariable)` is already the non-localizing overload,
//    which is what UGC wants; `Text("literal_key")` is the localizing one. For text that is
//    developer-facing rather than product copy, use `Text(verbatim:)` so it stays out of the
//    catalog entirely.

/// Count-bearing strings, backed by the String Catalog's plural-variation entries.
///
/// Each function resolves a named catalog key (`goals_count_key`, `assists_count_key`,
/// `matches_count_key`, `tournaments_count_key`) whose Ukrainian localization carries
/// one/few/many variations and whose English one carries one/other. The interpolated
/// `defaultValue` supplies the integer argument — it is *not* the string that ships; it is
/// only the fallback if the key ever goes missing from the catalog.
///
/// The catalog stores these as `%lld`, not `%d`: Swift's `Int` interpolation emits `%lld`,
/// and the format specifier has to match the argument actually passed.
///
/// ```swift
/// Text(Counts.goals(player.totalGoals))       // 1 гол / 2 голи / 5 голів
/// StatPill(value: n.formatted(), label: "stat_goals_key", accessibilityLabel: Counts.goals(n))
/// ```
enum Counts {
    static func goals(_ count: Int) -> LocalizedStringResource {
        LocalizedStringResource(
            "goals_count_key",
            defaultValue: "\(count) голів",
            comment: "Number of goals scored. uk: one/few/many; en: one/other."
        )
    }

    static func assists(_ count: Int) -> LocalizedStringResource {
        LocalizedStringResource(
            "assists_count_key",
            defaultValue: "\(count) асистів",
            comment: "Number of assists made. uk: one/few/many; en: one/other."
        )
    }

    static func matches(_ count: Int) -> LocalizedStringResource {
        LocalizedStringResource(
            "matches_count_key",
            defaultValue: "\(count) матчів",
            comment: "Number of matches played. uk: one/few/many; en: one/other."
        )
    }

    static func tournaments(_ count: Int) -> LocalizedStringResource {
        LocalizedStringResource(
            "tournaments_count_key",
            defaultValue: "\(count) турнірів",
            comment: "Number of tournaments played. uk: one/few/many; en: one/other."
        )
    }
}
