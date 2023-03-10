extension Candidate {

        /// Convert Cantonese Candidate text to specific variant
        /// - Parameter variant: Character variant
        /// - Returns: Transformed Candidate
        public func transformed(to variant: Logogram) -> Candidate {
                guard self.isCantonese else { return self }
                let convertedText: String = Converter.convert(self.text, to: variant)
                return Candidate(text: convertedText, romanization: self.romanization, input: self.input, lexiconText: self.lexiconText)
        }
}

/// Character Variant Converter
public struct Converter {

        /// Convert original (traditional) text to the specific variant
        /// - Parameters:
        ///   - text: Original (traditional) text
        ///   - variant: Character Variant
        /// - Returns: Converted text
        public static func convert(_ text: String, to variant: Logogram) -> String {
                switch variant {
                case .traditional:
                        return text
                case .hongkong:
                        switch text.count {
                        case 0:
                                return text
                        case 1:
                                return hongkongVariants[text] ?? text
                        default:
                                let converted: [Character] = text.map({ hongkongCharacterVariants[$0] ?? $0 })
                                return String(converted)
                        }
                case .taiwan:
                        switch text.count {
                        case 0:
                                return text
                        case 1:
                                return taiwanVariants[text] ?? text
                        default:
                                let converted: [Character] = text.map({ taiwanCharacterVariants[$0] ?? $0 })
                                return String(converted)
                        }
                case .simplified:
                        return Simplifier.convert(text)
                }
        }

        private static let hongkongVariants: [String: String] = {
                let keys: [String] = hongkongCharacterVariants.keys.map({ String($0) })
                let values: [String] = hongkongCharacterVariants.values.map({ String($0) })
                let newDictionary: [String: String] = Dictionary(uniqueKeysWithValues: zip(keys, values))
                return newDictionary
        }()
        private static let taiwanVariants: [String: String] = {
                let keys: [String] = taiwanCharacterVariants.keys.map({ String($0) })
                let values: [String] = taiwanCharacterVariants.values.map({ String($0) })
                let newDictionary: [String: String] = Dictionary(uniqueKeysWithValues: zip(keys, values))
                return newDictionary
        }()


private static let hongkongCharacterVariants: [Character: Character] = [
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???"
]


private static let taiwanCharacterVariants: [Character: Character] = [
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???",
"???": "???"
]


}

