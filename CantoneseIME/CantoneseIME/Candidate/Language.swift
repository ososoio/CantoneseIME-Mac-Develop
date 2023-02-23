enum Language: String, Hashable, Identifiable, CaseIterable {

        /// 粵語
        case Cantonese

        /// 英語
        case English

        /// 印地語
        case Hindi

        /// 尼泊爾語
        case Nepali

        /// 印尼語
        case Indonesian

        /// 烏爾都語. RTL
        case Urdu

        /// Urdu
        var isRTL: Bool {
                return self == .Urdu
        }

        /// Identifiable
        var id: String {
                return rawValue
        }
}
