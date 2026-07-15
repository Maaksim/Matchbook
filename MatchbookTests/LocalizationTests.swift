import Foundation
import Testing
@testable import Matchbook

/// Contract tests for the String Catalog (`Resources/Localizable.xcstrings`).
///
/// Both languages are resolved through an explicit `.lproj` bundle + `Locale` rather than the
/// process default, so results don't depend on whatever language the simulator running the
/// tests happens to be set to.
@Suite("Localization")
struct LocalizationTests {

    // MARK: - Plural keys

    private enum Quantity: CaseIterable {
        case goals, assists, matches, tournaments
    }

    /// Resolves one of the four plural keys. The `defaultValue` interpolation exists only to
    /// carry the `Int` argument — the string that ships comes from the catalog.
    private func localized(_ quantity: Quantity, _ count: Int, in bundle: Bundle, locale: Locale) -> String {
        switch quantity {
        case .goals:
            String(localized: "goals_count_key", defaultValue: "\(count)", bundle: bundle, locale: locale)
        case .assists:
            String(localized: "assists_count_key", defaultValue: "\(count)", bundle: bundle, locale: locale)
        case .matches:
            String(localized: "matches_count_key", defaultValue: "\(count)", bundle: bundle, locale: locale)
        case .tournaments:
            String(localized: "tournaments_count_key", defaultValue: "\(count)", bundle: bundle, locale: locale)
        }
    }

    /// Ukrainian one/few/many. The interesting cases are the ones a naive `count == 1` check
    /// gets wrong: 21 is *one*, 22 is *few*, and 0/11 are *many*.
    @Test(
        "Ukrainian plurals pick one/few/many",
        arguments: [
            (1, "1 гол", "1 асист", "1 матч", "1 турнір"),
            (2, "2 голи", "2 асисти", "2 матчі", "2 турніри"),
            (4, "4 голи", "4 асисти", "4 матчі", "4 турніри"),
            (5, "5 голів", "5 асистів", "5 матчів", "5 турнірів"),
            (0, "0 голів", "0 асистів", "0 матчів", "0 турнірів"),
            (11, "11 голів", "11 асистів", "11 матчів", "11 турнірів"),
            (21, "21 гол", "21 асист", "21 матч", "21 турнір"),
            (22, "22 голи", "22 асисти", "22 матчі", "22 турніри"),
            (25, "25 голів", "25 асистів", "25 матчів", "25 турнірів"),
        ]
    )
    func ukrainianPlurals(count: Int, goals: String, assists: String, matches: String, tournaments: String) throws {
        let bundle = try lproj("uk")
        let locale = Locale(identifier: "uk")

        #expect(localized(.goals, count, in: bundle, locale: locale) == goals)
        #expect(localized(.assists, count, in: bundle, locale: locale) == assists)
        #expect(localized(.matches, count, in: bundle, locale: locale) == matches)
        #expect(localized(.tournaments, count, in: bundle, locale: locale) == tournaments)
    }

    @Test(
        "English plurals pick one/other",
        arguments: [
            (1, "1 goal", "1 assist", "1 match", "1 tournament"),
            (0, "0 goals", "0 assists", "0 matches", "0 tournaments"),
            (2, "2 goals", "2 assists", "2 matches", "2 tournaments"),
            (21, "21 goals", "21 assists", "21 matches", "21 tournaments"),
        ]
    )
    func englishPlurals(count: Int, goals: String, assists: String, matches: String, tournaments: String) throws {
        let bundle = try lproj("en")
        let locale = Locale(identifier: "en")

        #expect(localized(.goals, count, in: bundle, locale: locale) == goals)
        #expect(localized(.assists, count, in: bundle, locale: locale) == assists)
        #expect(localized(.matches, count, in: bundle, locale: locale) == matches)
        #expect(localized(.tournaments, count, in: bundle, locale: locale) == tournaments)
    }

    /// Photos get their own test because Ukrainian "фото" is indeclinable — 1 фото / 2 фото /
    /// 5 фото — so all three uk categories carry identical text. That's exactly why it still has
    /// to go through the catalog rather than interpolation: English *does* inflect, and only the
    /// plural entry can express both at once. The delete confirmation depends on this.
    @Test(
        "Photo counts pluralize per language",
        arguments: [
            (1, "1 фото", "1 photo"),
            (2, "2 фото", "2 photos"),
            (5, "5 фото", "5 photos"),
            (0, "0 фото", "0 photos"),
            (21, "21 фото", "21 photos"),
        ]
    )
    func photoPlurals(count: Int, ukrainian: String, english: String) throws {
        let uk = try lproj("uk")
        let en = try lproj("en")

        #expect(
            String(localized: "photos_count_key", defaultValue: "\(count)",
                   bundle: uk, locale: Locale(identifier: "uk")) == ukrainian
        )
        #expect(
            String(localized: "photos_count_key", defaultValue: "\(count)",
                   bundle: en, locale: Locale(identifier: "en")) == english
        )
    }

    /// `Counts` is the only sanctioned way to build a count string, so it must point at the
    /// catalog keys the tests above exercise. If someone renames a key in the catalog without
    /// updating the helper (or vice versa), this fails rather than silently shipping a raw key.
    @Test("Counts helpers reference the catalog's plural keys")
    func countsHelpersUseCatalogKeys() {
        #expect(Counts.goals(3).key == "goals_count_key")
        #expect(Counts.assists(3).key == "assists_count_key")
        #expect(Counts.matches(3).key == "matches_count_key")
        #expect(Counts.tournaments(3).key == "tournaments_count_key")
        #expect(Counts.photos(3).key == "photos_count_key")
    }

    // MARK: - Catalog wiring

    @Test("Both languages ship in the app bundle")
    func bothLocalizationsPresent() {
        #expect(Bundle.main.localizations.contains("uk"))
        #expect(Bundle.main.localizations.contains("en"))
        #expect(Bundle.main.developmentLocalization == "uk")
    }

    /// The failure mode that semantic keys introduce: the key is no longer the copy, so an
    /// entry missing its `uk` value doesn't fall back to Ukrainian — it renders the literal
    /// text `welcome_title_key` on screen. Every key must therefore exist in *both* tables
    /// with a value that isn't just the key echoed back.
    @Test("Every key is translated in both languages")
    func everyKeyTranslatedInBothLanguages() throws {
        let uk = try stringsTable("uk")
        let en = try stringsTable("en")

        #expect(!uk.isEmpty, "uk.lproj/Localizable.strings is empty — semantic keys need explicit Ukrainian values")
        #expect(Set(uk.keys) == Set(en.keys), """
            Key sets differ between uk and en. Only in uk: \(Set(uk.keys).subtracting(en.keys).sorted()); \
            only in en: \(Set(en.keys).subtracting(uk.keys).sorted())
            """)

        for (key, value) in uk {
            #expect(value != key, "uk value for '\(key)' is the raw key — it would render as '\(key)' on screen")
        }
        for (key, value) in en {
            #expect(value != key, "en value for '\(key)' is the raw key — it would render as '\(key)' on screen")
        }
    }

    /// Spot-checks that the keys actually resolve to the intended copy in each language —
    /// a key set can be complete and still be wired to the wrong string.
    @Test(
        "Keys resolve to the right copy in both languages",
        arguments: [
            ("app_name_key", "Матчбук", "Matchbook"),
            ("splash_tagline_key", "Турніри, які не забудуться", "Tournaments worth remembering"),
            ("welcome_title_key", "Вітаємо в Матчбуці", "Welcome to Matchbook"),
            ("add_child_key", "＋ Додати дитину", "＋ Add child"),
            ("tab_album_key", "Альбом", "Album"),
            ("tab_tournaments_key", "Турніри", "Tournaments"),
            ("tab_profile_key", "Профіль", "Profile"),
            ("stat_goals_key", "Голи", "Goals"),
            ("position_goalkeeper_key", "Воротар", "Goalkeeper"),
            ("format_league_key", "Кругова", "Round robin"),
            ("player_new_title_key", "Нова дитина", "New child"),
            ("player_edit_title_key", "Редагувати дитину", "Edit child"),
            ("player_delete_key", "Видалити дитину", "Delete child"),
            ("cancel_key", "Скасувати", "Cancel"),
        ]
    )
    func keysResolveToExpectedCopy(key: String, ukrainian: String, english: String) throws {
        let uk = try lproj("uk")
        let en = try lproj("en")

        #expect(uk.localizedString(forKey: key, value: nil, table: nil) == ukrainian)
        #expect(en.localizedString(forKey: key, value: nil, table: nil) == english)
    }

    // MARK: - Helpers

    private func lproj(_ language: String) throws -> Bundle {
        let path = try #require(
            Bundle.main.path(forResource: language, ofType: "lproj"),
            "No \(language).lproj in the app bundle — the String Catalog didn't compile for \(language)"
        )
        return try #require(Bundle(path: path))
    }

    /// The compiled `Localizable.strings` table for a language, as a plain dictionary.
    private func stringsTable(_ language: String) throws -> [String: String] {
        let bundle = try lproj(language)
        let url = try #require(
            bundle.url(forResource: "Localizable", withExtension: "strings"),
            "No compiled Localizable.strings for \(language)"
        )
        let plist = try PropertyListSerialization.propertyList(
            from: try Data(contentsOf: url), format: nil
        )
        return try #require(plist as? [String: String])
    }
}
