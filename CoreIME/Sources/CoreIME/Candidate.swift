enum Tone: Int {

        case tone1_陰平 = 1
        case tone2_陰上 = 2
        case tone3_陰去 = 3
        case tone4_陽平 = 4
        case tone5_陽上 = 5
        case tone6_陽去 = 6

        static func tone(of text: String) -> Tone? {
                guard text.count == 1 else { return nil }
                return tone(of: text.first!)
        }
        static func tone(of character: Character) -> Tone? {
                switch character {
                case "1":
                        return .tone1_陰平
                case "2":
                        return .tone2_陰上
                case "3":
                        return .tone3_陰去
                case "4":
                        return .tone4_陽平
                case "5":
                        return .tone5_陽上
                case "6":
                        return .tone6_陽去
                default:
                        return nil
                }
        }
}

extension Character {

        /// a-z
        var isValidPhoneLetter: Bool {
                return ("a"..."z") ~= self
        }
}

struct Syllable: Hashable {

        init?(text: String) {
                guard text.count >= 2 else { return nil }
                guard let tone: Tone = Tone.tone(of: text.last!) else { return nil }
                let phone = text.dropLast()
                guard phone.reduce(true, { $0 && $1.isValidPhoneLetter }) else { return nil }
                self.text = text
                self.phone = String(phone)
                self.anchor = text.first!
                self.tone = tone
        }

        /// initial? & final & tone
        let text: String

        /// initial? & final
        let phone: String

        /// First character of the syllable text
        let anchor: Character

        let tone: Tone

        // Equatable
        public static func ==(lhs: Syllable, rhs: Syllable) -> Bool {
                return lhs.text == rhs.text
        }

        // Hashable
        public func hash(into hasher: inout Hasher) {
                hasher.combine(text)
        }
}

struct CantoneseCandidate: Hashable {

        let text: String
        let romanization: [Syllable]
        let input: String

        // Equatable
        public static func ==(lhs: CantoneseCandidate, rhs: CantoneseCandidate) -> Bool {
                return lhs.text == rhs.text && lhs.romanization == rhs.romanization
        }

        // Hashable
        public func hash(into hasher: inout Hasher) {
                hasher.combine(text)
                hasher.combine(romanization)
        }

}

struct CoreLexicon: Hashable {

        /// Input text for the lexicon
        let input: String

        /// Lexicon text for the input
        let text: String
}


public enum CandidateType {

        case cantonese

        /// Examples: iPad, macOS
        case specialMark

        case emoji

        /// Note that `text.count == 1` not always true
        case symbol

        /// macOS Keyboard composed text
        case compose
}


public struct Candidate: Hashable {

        /// Displaying Candidate text
        public let text: String

        /// Jyutping
        public let romanization: String

        /// User input
        public let input: String

        /// Candidate text for UserLexicon Entry.
        ///
        /// Always be traditional characters. User invisible.
        public let lexiconText: String

        /// Candidate Type
        public let type: CandidateType

        /// Primary initializer of Candidate
        /// - Parameters:
        ///   - text: Candidate word.
        ///   - romanization: Jyutping.
        ///   - input: User input for this Candidate.
        ///   - lexiconText: Lexicon Entry Cantonese word. User invisible.
        public init(text: String, romanization: String, input: String, lexiconText: String) {
                self.text = text
                self.romanization = romanization
                self.input = input
                self.lexiconText = lexiconText
                self.type = .cantonese
        }

        /// Create a Candidate with special mark text
        /// - Parameter mark: Special mark. Examples: iPhone, GitHub
        init(mark: String) {
                self.text = mark
                self.romanization = mark
                self.input = mark
                self.lexiconText = mark
                self.type = .specialMark
        }

        /// Create a Candidate with Emoji
        /// - Parameters:
        ///   - emoji: Emoji
        ///   - cantonese: Cantonese word for this Emoji
        ///   - romanization: Romanization (Jyutping) of Cantonese word
        ///   - input: User input
        init(emoji: String, cantonese: String, romanization: String, input: String) {
                self.text = emoji
                self.romanization = romanization
                self.input = input
                self.lexiconText = cantonese
                self.type = .emoji
        }

        /// Create a Candidate with symbol
        /// - Parameters:
        ///   - emoji: Symbol text
        ///   - cantonese: Cantonese word for this symbol
        ///   - romanization: Romanization (Jyutping) of Cantonese word
        ///   - input: User input
        init(symbol: String, cantonese: String, romanization: String, input: String) {
                self.text = symbol
                self.romanization = romanization
                self.input = input
                self.lexiconText = cantonese
                self.type = .symbol
        }

        /// Create a Candidate for keyboard compose
        /// - Parameters:
        ///   - text: Symbol text for this key compose
        ///   - comment: Name comment of this key symbol
        ///   - secondaryComment: Unicode code point
        ///   - input: User input
        public init(text: String, comment: String?, secondaryComment: String?, input: String) {
                let commentText: String = comment ?? ""
                let secondaryCommentText: String = secondaryComment ?? ""
                self.text = text
                self.romanization = secondaryCommentText
                self.input = input
                self.lexiconText = commentText
                self.type = .compose
        }

        /// type == .cantonese
        public var isCantonese: Bool {
                return self.type == .cantonese
        }

        // Equatable
        public static func ==(lhs: Candidate, rhs: Candidate) -> Bool {
                if (lhs.isCantonese && rhs.isCantonese) {
                        return lhs.text == rhs.text && lhs.romanization == rhs.romanization
                } else {
                        return lhs.text == rhs.text
                }
        }

        // Hashable
        public func hash(into hasher: inout Hasher) {
                switch type {
                case .cantonese:
                        hasher.combine(text)
                        hasher.combine(romanization)
                case .specialMark:
                        hasher.combine(text)
                case .emoji:
                        hasher.combine(text)
                case .symbol:
                        hasher.combine(text)
                case .compose:
                        hasher.combine(text)
                }
        }

        public static func +(lhs: Candidate, rhs: Candidate) -> Candidate {
                let newText: String = lhs.text + rhs.text
                let newRomanization: String = lhs.romanization + " " + rhs.romanization
                let newInput: String = lhs.input + rhs.input
                let newLexiconText: String = lhs.lexiconText + rhs.lexiconText
                let newCandidate: Candidate = Candidate(text: newText, romanization: newRomanization, input: newInput, lexiconText: newLexiconText)
                return newCandidate
        }
}


extension Array where Element == Candidate {

        /// Returns a new Candidate by concatenating the candidates of the sequence.
        /// - Returns: Single, concatenated Candidate.
        public func joined() -> Candidate {
                let text: String = map({ $0.text }).joined()
                let romanization: String = map({ $0.romanization }).joined(separator: String.space)
                let input: String = map({ $0.input }).joined()
                let lexiconText: String = map({ $0.lexiconText }).joined()
                let candidate: Candidate = Candidate(text: text, romanization: romanization, input: input, lexiconText: lexiconText)
                return candidate
        }
}


typealias CoreCandidate = Candidate

extension CoreCandidate {

        /// Create a CoreCandidate
        /// - Parameters:
        ///   - text: Candidate word
        ///   - romanization: Jyutping
        ///   - input: Input text for this Candidate
        init(text: String, romanization: String, input: String) {
                self.text = text
                self.romanization = romanization
                self.input = input
                self.lexiconText = text
                self.type = .cantonese
        }
}

