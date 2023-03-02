import Foundation
import CoreIME

extension CantoneseIMEInputController {

        private typealias AppCandidate = Candidate

        private func transformed(_ items: [CoreIME.Candidate]) -> [AppCandidate] {
                let candidates = items.map { item -> AppCandidate in
                        var comments: [Comment] = []
                        if let english = item.notation?.english, english.isValid {
                                let comment = Comment(language: .English, text: english)
                                comments.append(comment)
                        }
                        if let urdu = item.notation?.urdu, urdu.isValid {
                                let comment = Comment(language: .Urdu, text: urdu)
                                comments.append(comment)
                        }
                        if let nepali = item.notation?.nepali, nepali.isValid {
                                let comment = Comment(language: .Nepali, text: nepali)
                                comments.append(comment)
                        }
                        if let hindi = item.notation?.hindi, hindi.isValid {
                                let comment = Comment(language: .Hindi, text: hindi)
                                comments.append(comment)
                        }
                        if let indonesian = item.notation?.indonesian, indonesian.isValid {
                                let comment = Comment(language: .Indonesian, text: indonesian)
                                comments.append(comment)
                        }
                        let enabledComments = comments.filter({ AppSettings.enabledCommentLanguages.contains($0.language) })
                        return AppCandidate(input: item.input, text: item.text, romanization: item.romanization, comments: enabledComments, notation: item.notation)
                }
                return candidates
        }
        func suggest() {
                let fetched: [CoreIME.Candidate] = {
                        let convertedSegmentation: Segmentation = segmentation.converted()
                        let normal = Engine.suggest(for: processingText, segmentation: convertedSegmentation)
                        let droppedLast = processingText.dropLast()
                        let shouldDropSeparator: Bool = normal.isEmpty && processingText.hasSuffix("'") && !droppedLast.contains("'")
                        guard shouldDropSeparator else { return normal }
                        let droppedSeparator: String = String(droppedLast)
                        let newSegmentation: Segmentation = Segmentor.segment(droppedSeparator).filter({ $0.joined() == droppedSeparator || $0.count == 1 })
                        return Engine.suggest(for: droppedSeparator, segmentation: newSegmentation)
                }()
                let candidates = transformed(fetched)
                let sortedCandidates = candidates.uniqued().sorted { (lhs, rhs) -> Bool in
                        guard lhs.input.count == rhs.input.count else { return false }
                        guard let lhsNotation = lhs.notation, let rhsNotation = rhs.notation else { return false }
                        return lhsNotation.frequency > rhsNotation.frequency
                }
                push(sortedCandidates)
        }

        func pinyinReverseLookup() {
                let text: String = String(processingText.dropFirst())
                guard !text.isEmpty else {
                        empty()
                        return
                }
                let lookup = Engine.pinyinLookup(for: text)
                let candidates = transformed(lookup)
                push(candidates.uniqued())
        }
        func cangjieReverseLookup() {
                let text: String = String(processingText.dropFirst())
                let converted = text.map({ Logogram.cangjie(of: $0) }).compactMap({ $0 })
                let isValidSequence: Bool = !converted.isEmpty && converted.count == text.count
                if isValidSequence {
                        markedText = String(converted)
                        let lookup = Engine.cangjieLookup(for: text)
                        let candidates = transformed(lookup)
                        push(candidates.uniqued())
                } else {
                        markedText = processingText
                        empty()
                }
        }
        func strokeReverseLookup() {
                let text: String = String(processingText.dropFirst())
                let transformedText: String = Logogram.strokeTransform(text)
                let converted = transformedText.map({ Logogram.stroke(of: $0) }).compactMap({ $0 })
                let isValidSequence: Bool = !converted.isEmpty && converted.count == text.count
                if isValidSequence {
                        markedText = String(converted)
                        let lookup = Engine.strokeLookup(for: transformedText)
                        let candidates = transformed(lookup)
                        push(candidates.uniqued())
                } else {
                        markedText = processingText
                        empty()
                }
        }
        func leungFanReverseLookup() {
                let text: String = String(processingText.dropFirst())
                guard !text.isEmpty else {
                        empty()
                        return
                }
                let lookup = Engine.leungFanLookup(for: text)
                let candidates = transformed(lookup)
                push(candidates.uniqued())
        }
}


/*

struct EnglishComment: Codable, Hashable {
        let jyutping: String
        let props: Props
        let defs: [Def]
}
struct Def: Codable, Hashable {
        let eng, engShort, pos, register, lbl, written, colloquial, engFull, note: String?
}
struct Props: Codable, Hashable {
        let pronOrder, sandhi, litColReading, freq: Int
}

struct FullComment: Hashable {

        let token: String
        let comment: EnglishComment

        static func prepare() {
                _ = entries.count
        }
        static let entries: Set<FullComment> = {
                guard let url: URL = Bundle.main.url(forResource: "commentsample", withExtension: "txt") else { return [] }
                guard let content: String = try? String(contentsOf: url) else { return [] }
                let sourceLines: [String] = content
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: .controlCharacters)
                        .components(separatedBy: .newlines)
                        .filter({ !$0.isEmpty })
                        .map({ $0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .controlCharacters) })
                        .filter({ !$0.isEmpty })
                        .uniqued()

                let items: [FullComment?] = sourceLines.map { line -> FullComment? in
                        let parts = line.split(separator: "\t")
                        guard parts.count == 2 else { return nil }
                        let token = parts[0]
                        let jsonText = parts[1]
                        let jsonData: Data = Data(jsonText.utf8)
                        guard let comment = try? JSONDecoder().decode(EnglishComment.self, from: jsonData) else { return nil }
                        let full = FullComment(token: String(token), comment: comment)
                        return full
                }
                let flatted = items.compactMap({ $0 })
                return Set<FullComment>(flatted)
        }()
}

*/


/*


extension Notation {

        static func prepare() {
                _ = entries.count
        }

        private static func handleOptional(_ text: String) -> String? {
                let text: String = text.filter({ $0 != "\"" })
                let filtered = text.filter({ $0 != ";" })
                return filtered.isEmpty ? nil : text
        }
        static let entries: Set<Notation> = {
                guard let url: URL = Bundle.main.url(forResource: "notationsample", withExtension: "txt") else { return [] }
                guard let content: String = try? String(contentsOf: url) else { return [] }
                let sourceLines: [String] = content
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: .controlCharacters)
                        .components(separatedBy: .newlines)
                        .filter({ !$0.isEmpty })
                        .uniqued()
                let fill: [String] = Array(repeating: "", count: 20)
                let items: [Notation?] = sourceLines.map { line -> Notation? in
                        let blocks: [String] = line.split(separator: "\t", omittingEmptySubsequences: false).map({ String($0) })
                        let parts: [String] = blocks.count >= 20 ? blocks : (blocks + fill)
                        let word = parts[0]
                        let jyutping = parts[1]
                        let pronunciationOrder: Int = Int(parts[2]) ?? 1
                        let isSandhi: Bool = {
                                let text = parts[3]
                                let number = Int(text)
                                return number == 1
                        }()
                        let literaryColloquial: Int = Int(parts[4]) ?? 0
                        let frequency: Int = Int(parts[5]) ?? 1
                        let altFrequency: Int? = Int(parts[6])
                        let english: String? = handleOptional(parts[7])
                        let explicit: String? = handleOptional(parts[8])
                        let partOfSpeech: String? = handleOptional(parts[9])
                        let register: String? = {
                                let value = handleOptional(parts[10])
                                guard let value else { return nil }
                                return value.replacingOccurrences(of: "wri", with: "Written")
                                        .replacingOccurrences(of: "col", with: "Colloquial")
                                        .replacingOccurrences(of: "for", with: "Formal")
                                        .replacingOccurrences(of: "lit", with: "Literary")
                        }()
                        let label: String? = {
                                let value = handleOptional(parts[11])
                                guard let value else { return nil }
                                return value.replacingOccurrences(of: "sur", with: "Surname")
                        }()
                        let written: String? = handleOptional(parts[12])
                        let colloquial: String? = handleOptional(parts[13])
                        let definition: String? = handleOptional(parts[14])
                        let note: String? = handleOptional(parts[15])

                        let hindi: String? = handleOptional(parts[16])
                        let urdu: String? = handleOptional(parts[17])
                        let nepali: String? = handleOptional(parts[18])
                        let indonesian: String? = handleOptional(parts[19])

                        let entry: Notation = Notation(word: word, jyutping: jyutping, pronunciationOrder: pronunciationOrder, isSandhi: isSandhi, literaryColloquial: literaryColloquial, frequency: frequency, altFrequency: altFrequency, partOfSpeech: partOfSpeech, register: register, label: label, written: written, colloquial: colloquial, english: english, explicit: explicit, definition: definition, note: note, hindi: hindi, urdu: urdu, nepali: nepali, indonesian: indonesian)

                        return entry
                }
                let flatted = items.compactMap({ $0 })
                return Set<Notation>(flatted)
        }()
}

struct Notation: Hashable {

        // Equatable
        static func ==(lhs: Notation, rhs: Notation) -> Bool {
                return lhs.word == rhs.word && lhs.jyutping == rhs.jyutping
        }

        // Hashable
        func hash(into hasher: inout Hasher) {
                hasher.combine(word)
                hasher.combine(jyutping)
        }

        let word: String

        let jyutping: String

        /// smaller is preferred
        let pronunciationOrder: Int

        /// 變調
        let isSandhi: Bool

        /// 無: 0, 文讀: -1, 白讀: 1
        let literaryColloquial: Int

        /// higher is preferred
        let frequency: Int

        let altFrequency: Int?

        /// 詞性
        let partOfSpeech: String?

        /// 語體 / 語域
        let register: String?

        let label: String?

        /// 對應嘅書面語
        let written: String?

        /// 對應嘅口語
        let colloquial: String?

        let english: String?

        /// Disambiguatory Information
        let explicit: String?

        /// Full Definition
        let definition: String?

        let note: String?

        /// 印地語
        let hindi: String?

        /// 烏爾都語. RTL
        let urdu: String?

        /// 尼泊爾語
        let nepali: String?

        /// 印尼語
        let indonesian: String?
}


*/

