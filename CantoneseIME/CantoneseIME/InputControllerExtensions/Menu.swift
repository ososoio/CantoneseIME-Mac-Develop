import SwiftUI
import InputMethodKit

extension CantoneseIMEInputController {

        override func menu() -> NSMenu! {
                let menuTittle: String = NSLocalizedString("menu.tittle", comment: "")
                let menu = NSMenu(title: menuTittle)

                for language in AppSettings.commentLanguages {
                        let name: String = language.rawValue
                        let localizedName: String = NSLocalizedString(name, comment: "")
                        let isEnabled: Bool = language.isEnabledCommentLanguage
                        let tittle: String = isEnabled ? ("✓ " + localizedName) : localizedName
                        let selector: Selector? = {
                                switch language {
                                case .Cantonese:
                                        return nil
                                case .English:
                                        return #selector(toggleEnglish)
                                case .Hindi:
                                        return #selector(toggleHindi)
                                case .Indonesian:
                                        return #selector(toggleIndonesian)
                                case .Nepali:
                                        return #selector(toggleNepali)
                                case .Urdu:
                                        return #selector(toggleUrdu)
                                }
                        }()
                        let item: NSMenuItem = NSMenuItem(title: tittle, action: selector, keyEquivalent: "")
                        menu.addItem(item)
                }

                menu.addItem(.separator())

                let helpTitle: String = NSLocalizedString("Help", comment: "")
                let help = NSMenuItem(title: helpTitle, action: #selector(openHelp), keyEquivalent: "")
                menu.addItem(help)

                let terminateTittle: String = NSLocalizedString("Quit", comment: "")
                let terminate = NSMenuItem(title: terminateTittle, action: #selector(terminateApp), keyEquivalent: "")
                menu.addItem(terminate)

                return menu
        }

        @objc private func toggleEnglish() {
                let language: Language = .English
                let isEnabled: Bool = language.isEnabledCommentLanguage
                let shouldEnable: Bool = !isEnabled
                AppSettings.updateCommentLanguage(language, shouldEnable: shouldEnable)
        }
        @objc private func toggleHindi() {
                let language: Language = .Hindi
                let isEnabled: Bool = language.isEnabledCommentLanguage
                let shouldEnable: Bool = !isEnabled
                AppSettings.updateCommentLanguage(language, shouldEnable: shouldEnable)
        }
        @objc private func toggleIndonesian() {
                let language: Language = .Indonesian
                let isEnabled: Bool = language.isEnabledCommentLanguage
                let shouldEnable: Bool = !isEnabled
                AppSettings.updateCommentLanguage(language, shouldEnable: shouldEnable)
        }
        @objc private func toggleNepali() {
                let language: Language = .Nepali
                let isEnabled: Bool = language.isEnabledCommentLanguage
                let shouldEnable: Bool = !isEnabled
                AppSettings.updateCommentLanguage(language, shouldEnable: shouldEnable)
        }
        @objc private func toggleUrdu() {
                let language: Language = .Urdu
                let isEnabled: Bool = language.isEnabledCommentLanguage
                let shouldEnable: Bool = !isEnabled
                AppSettings.updateCommentLanguage(language, shouldEnable: shouldEnable)
        }

        @objc private func openHelp() {}

        @objc private func terminateApp() {
                NSRunningApplication.current.terminate()
                NSApp.terminate(self)
                exit(0)
        }
}


struct SettingsKey {
        static let EnabledCommentLanguages: String = "EnabledCommentLanguages"
}


struct AppSettings {

        static let commentLanguages: [Language] = [.English, .Hindi, .Indonesian, .Nepali, .Urdu ]

        private static let defaultEnabledCommentLanguages: [Language] = [.English]

        private(set) static var enabledCommentLanguages: [Language] = {
                guard let savedValue = UserDefaults.standard.string(forKey: SettingsKey.EnabledCommentLanguages) else { return defaultEnabledCommentLanguages }
                let languageValues: [String] = savedValue.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .controlCharacters) }).filter({ !$0.isEmpty })
                guard !(languageValues.isEmpty) else { return [] }
                let languages: [Language] = languageValues.map({ Language(rawValue: $0) }).compactMap({ $0 }).uniqued()
                return languages
        }()
        static func updateCommentLanguage(_ language: Language, shouldEnable: Bool) {
                let newLanguages: [Language] = enabledCommentLanguages + [language]
                let handledNewLanguages: [Language?] = newLanguages.map({ item -> Language? in
                        guard item == language else { return item }
                        guard shouldEnable else { return nil }
                        return item
                })
                enabledCommentLanguages = handledNewLanguages.compactMap({ $0 }).uniqued()
                let newText: String = enabledCommentLanguages.map(\.rawValue).joined(separator: ",")
                UserDefaults.standard.set(newText, forKey: SettingsKey.EnabledCommentLanguages)
        }

        static let pageSize: Int = 9
}

extension Language {
        var isEnabledCommentLanguage: Bool {
                return AppSettings.enabledCommentLanguages.contains(self)
        }
}
