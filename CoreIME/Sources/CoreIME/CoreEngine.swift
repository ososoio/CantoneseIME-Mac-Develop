import Foundation
import SQLite3

private struct RowCandidate {
        let candidate: Candidate
        let row: Int
        let isExactlyMatch: Bool
}

private extension Array where Element == RowCandidate {
        func sorted() -> [RowCandidate] {
                return self.sorted(by: { (lhs, rhs) -> Bool in
                        let shouldCompare: Bool = !lhs.isExactlyMatch && !rhs.isExactlyMatch
                        guard shouldCompare else { return lhs.isExactlyMatch && !rhs.isExactlyMatch }
                        let lhsTextCount: Int = lhs.candidate.text.count
                        let rhsTextCount: Int = rhs.candidate.text.count
                        guard lhsTextCount >= rhsTextCount else { return false }
                        return (rhs.row - lhs.row) > 50000
                })
        }
}

extension Engine {

        public static func suggest(for text: String, segmentation: Segmentation) -> [Candidate] {
                guard Engine.isDatabaseReady else { return [] }
                switch text.count {
                case 0:
                        return []
                case 1:
                        return shortcut(for: text)
                default:
                        return fetch(text: text, segmentation: segmentation)
                }
        }

        private static func fetch(text: String, segmentation: Segmentation) -> [CoreCandidate] {
                let textWithoutSeparators: String = text.filter({ !($0.isSeparator) })
                guard let bestScheme: SyllableScheme = segmentation.first, !bestScheme.isEmpty else {
                        return processVerbatim(textWithoutSeparators)
                }
                let convertedText = textWithoutSeparators.replacingOccurrences(of: "(?<!c|s|j|z)yu(?!k|m|ng)", with: "jyu", options: .regularExpression)
                if bestScheme.length == convertedText.count {
                        return process(text: convertedText, origin: text, sequences: segmentation)
                } else {
                        return processPartial(text: textWithoutSeparators, origin: text, segmentation: segmentation)
                }
        }
        private static func processVerbatim(_ text: String) -> [CoreCandidate] {
                let rounds = (0..<text.count).map { number -> [CoreCandidate] in
                        let leading: String = String(text.dropLast(number))
                        return match(for: leading) + shortcut(for: leading)
                }
                return rounds.flatMap({ $0 }).uniqued()
        }
        private static func process(text: String, origin: String, sequences: [[String]]) -> [CoreCandidate] {
                let hasSeparators: Bool = text.count != origin.count
                let candidates = match(schemes: sequences, hasSeparators: hasSeparators, fullTextCount: origin.count)
                guard !hasSeparators else { return candidates }
                let fullProcessed: [CoreCandidate] = match(for: text) + shortcut(for: text)
                let backup: [CoreCandidate] = processVerbatim(text)
                let fallback: [CoreCandidate] = fullProcessed + candidates + backup
                guard let firstCandidate = candidates.first else { return fallback }
                let firstInputCount: Int = firstCandidate.input.count
                guard firstInputCount != text.count else { return fallback }
                let tailText: String = String(text.dropFirst(firstInputCount))
                let tailSegmentation: Segmentation = Segmentor.engineSegment(tailText)
                let hasSchemes: Bool = !(tailSegmentation.first?.isEmpty ?? true)
                guard hasSchemes else { return fallback }
                let tailCandidates: [CoreCandidate] = (match(for: tailText) + shortcut(for: tailText) + match(schemes: tailSegmentation, hasSeparators: false)).uniqued()
                guard !(tailCandidates.isEmpty) else { return fallback }
                let qualified = candidates.enumerated().filter({ $0.offset < 3 && $0.element.input.count == firstInputCount })
                let combines = tailCandidates.map { tail -> [CoreCandidate] in
                        return qualified.map({ $0.element + tail })
                }
                let concatenated: [CoreCandidate] = combines.flatMap({ $0 }).enumerated().filter({ $0.offset < 4 }).map(\.element)
                return fullProcessed + concatenated + candidates + backup
        }
        private static func processPartial(text: String, origin: String, segmentation: Segmentation) -> [CoreCandidate] {
                let hasSeparators: Bool = text.count != origin.count
                let candidates = match(schemes: segmentation, hasSeparators: hasSeparators, fullTextCount: origin.count)
                guard !hasSeparators else { return candidates }
                let fullProcessed: [CoreCandidate] = match(for: text) + shortcut(for: text)
                let backup: [CoreCandidate] = processVerbatim(text)
                let fallback: [CoreCandidate] = fullProcessed + candidates + backup
                guard let firstCandidate = candidates.first else { return fallback }
                let firstInputCount: Int = firstCandidate.input.count
                guard firstInputCount != text.count else { return fallback }
                let anchorsArray: [String] = segmentation.map({ scheme -> String in
                        let last = text.dropFirst(scheme.length).first
                        let schemeAnchors = scheme.map({ $0.first })
                        let anchors = (schemeAnchors + [last]).compactMap({ $0 })
                        return String(anchors)
                })
                let prefixes: [CoreCandidate] = anchorsArray.map({ shortcut(for: $0) }).flatMap({ $0 })
                        .filter({ $0.romanization.removedSpacesTones().hasPrefix(text) })
                        .map({ CoreCandidate(text: $0.text, romanization: $0.romanization, input: text, notation: $0.notation) })
                guard prefixes.isEmpty else { return fullProcessed + prefixes + candidates + backup }
                let tailText: String = String(text.dropFirst(firstInputCount))
                let tailCandidates = processVerbatim(tailText)
                        .filter({ item -> Bool in
                                let hasText: Bool = item.romanization.removedSpacesTones().hasPrefix(tailText)
                                guard !hasText else { return true }
                                let anchors = item.romanization.split(separator: " ").map({ $0.first }).compactMap({ $0 })
                                return anchors == tailText.map({ $0 })
                        })
                        .map({ CoreCandidate(text: $0.text, romanization: $0.romanization, input: tailText) })
                guard !(tailCandidates.isEmpty) else { return fallback }
                let qualified = candidates.enumerated().filter({ $0.offset < 3 && $0.element.input.count == firstInputCount })
                let combines = tailCandidates.map { tail -> [CoreCandidate] in
                        return qualified.map({ $0.element + tail })
                }
                let concatenated: [CoreCandidate] = combines.flatMap({ $0 }).enumerated().filter({ $0.offset < 4 }).map(\.element)
                return fullProcessed + concatenated + candidates + backup
        }
        private static func match(schemes: [[String]], hasSeparators: Bool, fullTextCount: Int = -1) -> [CoreCandidate] {
                let matches = schemes.map { scheme -> [RowCandidate] in
                        let joinedText = scheme.joined()
                        let isExactlyMatch: Bool = joinedText.count == fullTextCount
                        return matchRowCandidate(for: joinedText, isExactlyMatch: isExactlyMatch)
                }
                let candidates: [CoreCandidate] = matches.flatMap({ $0 }).sorted().map(\.candidate)
                guard hasSeparators else { return candidates }
                let firstSyllable: String = schemes.first?.first ?? "X"
                let filtered: [CoreCandidate] = candidates.filter { candidate in
                        let firstRomanization: String = candidate.romanization.components(separatedBy: String.space).first ?? "Y"
                        return firstSyllable == firstRomanization.removedTones()
                }
                return filtered
        }
}

private extension Engine {

        // CREATE TABLE imetable(word TEXT NOT NULL, romanization TEXT NOT NULL, ping INTEGER NOT NULL, shortcut INTEGER NOT NULL, prefix INTEGER NOT NULL);

        static func shortcut(for text: String, count: Int = 100) -> [CoreCandidate] {
                guard !text.isEmpty else { return [] }
                let textHash: Int = text.replacingOccurrences(of: "y", with: "j").hash
                var candidates: [CoreCandidate] = []
                let queryString = "SELECT word, romanization, pronunciationorder, sandhi, literarycolloquial, frequency, altfrequency, partofspeech, register, label, written, colloquial, english, explicit, urdu, nepali, hindi, indonesian FROM lexicontable WHERE shortcut = \(textHash) LIMIT \(count);"
                var queryStatement: OpaquePointer? = nil
                if sqlite3_prepare_v2(Engine.database, queryString, -1, &queryStatement, nil) == SQLITE_OK {
                        while sqlite3_step(queryStatement) == SQLITE_ROW {
                                let word: String = String(cString: sqlite3_column_text(queryStatement, 0))
                                let romanization: String = String(cString: sqlite3_column_text(queryStatement, 1))
                                let pronunciationOrder: Int = Int(sqlite3_column_int64(queryStatement, 2))
                                let sandhi: Int = Int(sqlite3_column_int64(queryStatement, 3))
                                let literaryColloquial: Int = Int(sqlite3_column_int64(queryStatement, 4))
                                let frequency: Int = Int(sqlite3_column_int64(queryStatement, 5))
                                let altFrequency: Int = Int(sqlite3_column_int64(queryStatement, 6))
                                let partOfSpeech: String = String(cString: sqlite3_column_text(queryStatement, 7))
                                let register: String = String(cString: sqlite3_column_text(queryStatement, 8))
                                let label: String = String(cString: sqlite3_column_text(queryStatement, 9))
                                let written: String = String(cString: sqlite3_column_text(queryStatement, 10))
                                let colloquial: String = String(cString: sqlite3_column_text(queryStatement, 11))
                                let english: String = String(cString: sqlite3_column_text(queryStatement, 12))
                                let explicit: String = String(cString: sqlite3_column_text(queryStatement, 13))
                                let urdu: String = String(cString: sqlite3_column_text(queryStatement, 14))
                                let nepali: String = String(cString: sqlite3_column_text(queryStatement, 15))
                                let hindi: String = String(cString: sqlite3_column_text(queryStatement, 16))
                                let indonesian: String = String(cString: sqlite3_column_text(queryStatement, 17))
                                let isSandhi: Bool = sandhi == 1
                                let notation = Notation(word: word, jyutping: romanization, pronunciationOrder: pronunciationOrder, isSandhi: isSandhi, literaryColloquial: literaryColloquial, frequency: frequency, altFrequency: altFrequency, partOfSpeech: partOfSpeech, register: register, label: label, written: written, colloquial: colloquial, english: english, explicit: explicit, urdu: urdu, nepali: nepali, hindi: hindi, indonesian: indonesian)
                                let candidate = CoreCandidate(text: word, romanization: romanization, input: text, notation: notation)
                                candidates.append(candidate)
                        }
                }
                sqlite3_finalize(queryStatement)
                return candidates
        }

        static func match(for text: String) -> [CoreCandidate] {
                let tones: String = text.tones
                let hasTones: Bool = !tones.isEmpty
                let ping: String = hasTones ? text.removedTones() : text
                guard !(ping.isEmpty) else { return [] }
                let candidates: [CoreCandidate] = queryPing(for: text, ping: ping)
                guard hasTones else { return candidates }
                let sameTones = candidates.filter({ $0.romanization.tones == tones })
                guard sameTones.isEmpty else { return sameTones }
                let filtered = candidates.filter({ item -> Bool in
                        let syllables = item.romanization.split(separator: " ")
                        let rawSyllables = item.romanization.removedTones().split(separator: " ")
                        guard rawSyllables.uniqued().count == syllables.count else { return false }
                        let times: Int = syllables.reduce(0, { $0 + (text.contains($1) ? 1 : 0) })
                        return times == tones.count
                })
                return filtered
        }
        private static func queryPing(for text: String, ping: String) -> [CoreCandidate] {
                var candidates: [CoreCandidate] = []
                let queryString = "SELECT word, romanization, pronunciationorder, sandhi, literarycolloquial, frequency, altfrequency, partofspeech, register, label, written, colloquial, english, explicit, urdu, nepali, hindi, indonesian FROM lexicontable WHERE ping = \(ping.hash);"
                var queryStatement: OpaquePointer? = nil
                if sqlite3_prepare_v2(Engine.database, queryString, -1, &queryStatement, nil) == SQLITE_OK {
                        while sqlite3_step(queryStatement) == SQLITE_ROW {
                                let word: String = String(cString: sqlite3_column_text(queryStatement, 0))
                                let romanization: String = String(cString: sqlite3_column_text(queryStatement, 1))
                                let pronunciationOrder: Int = Int(sqlite3_column_int64(queryStatement, 2))
                                let sandhi: Int = Int(sqlite3_column_int64(queryStatement, 3))
                                let literaryColloquial: Int = Int(sqlite3_column_int64(queryStatement, 4))
                                let frequency: Int = Int(sqlite3_column_int64(queryStatement, 5))
                                let altFrequency: Int = Int(sqlite3_column_int64(queryStatement, 6))
                                let partOfSpeech: String = String(cString: sqlite3_column_text(queryStatement, 7))
                                let register: String = String(cString: sqlite3_column_text(queryStatement, 8))
                                let label: String = String(cString: sqlite3_column_text(queryStatement, 9))
                                let written: String = String(cString: sqlite3_column_text(queryStatement, 10))
                                let colloquial: String = String(cString: sqlite3_column_text(queryStatement, 11))
                                let english: String = String(cString: sqlite3_column_text(queryStatement, 12))
                                let explicit: String = String(cString: sqlite3_column_text(queryStatement, 13))
                                let urdu: String = String(cString: sqlite3_column_text(queryStatement, 14))
                                let nepali: String = String(cString: sqlite3_column_text(queryStatement, 15))
                                let hindi: String = String(cString: sqlite3_column_text(queryStatement, 16))
                                let indonesian: String = String(cString: sqlite3_column_text(queryStatement, 17))
                                let isSandhi: Bool = sandhi == 1
                                let notation = Notation(word: word, jyutping: romanization, pronunciationOrder: pronunciationOrder, isSandhi: isSandhi, literaryColloquial: literaryColloquial, frequency: frequency, altFrequency: altFrequency, partOfSpeech: partOfSpeech, register: register, label: label, written: written, colloquial: colloquial, english: english, explicit: explicit, urdu: urdu, nepali: nepali, hindi: hindi, indonesian: indonesian)
                                let candidate = CoreCandidate(text: word, romanization: romanization, input: text, notation: notation)
                                candidates.append(candidate)
                        }
                }
                sqlite3_finalize(queryStatement)
                return candidates
        }

        static func matchRowCandidate(for text: String, isExactlyMatch: Bool) -> [RowCandidate] {
                let tones: String = text.tones
                let hasTones: Bool = !tones.isEmpty
                let ping: String = hasTones ? text.removedTones() : text
                guard !(ping.isEmpty) else { return [] }
                let candidates = queryRowCandidate(for: text, ping: ping, isExactlyMatch: isExactlyMatch)
                guard hasTones else { return candidates }
                let sameTones = candidates.filter({ $0.candidate.romanization.tones == tones })
                guard sameTones.isEmpty else { return sameTones }
                let filtered = candidates.filter({ item -> Bool in
                        let syllables = item.candidate.romanization.split(separator: " ")
                        let rawSyllables = item.candidate.romanization.removedTones().split(separator: " ")
                        guard rawSyllables.uniqued().count == syllables.count else { return false }
                        let times: Int = syllables.reduce(0, { $0 + (text.contains($1) ? 1 : 0) })
                        return times == tones.count
                })
                return filtered
        }
        private static func queryRowCandidate(for text: String, ping: String, isExactlyMatch: Bool) -> [RowCandidate] {
                var rowCandidates: [RowCandidate] = []
                let queryString = "SELECT rowid, word, romanization, pronunciationorder, sandhi, literarycolloquial, frequency, altfrequency, partofspeech, register, label, written, colloquial, english, explicit, urdu, nepali, hindi, indonesian FROM lexicontable WHERE ping = \(ping.hash);"
                var queryStatement: OpaquePointer? = nil
                if sqlite3_prepare_v2(Engine.database, queryString, -1, &queryStatement, nil) == SQLITE_OK {
                        while sqlite3_step(queryStatement) == SQLITE_ROW {
                                let rowid: Int = Int(sqlite3_column_int64(queryStatement, 0))
                                let word: String = String(cString: sqlite3_column_text(queryStatement, 1))
                                let romanization: String = String(cString: sqlite3_column_text(queryStatement, 2))
                                let pronunciationOrder: Int = Int(sqlite3_column_int64(queryStatement, 3))
                                let sandhi: Int = Int(sqlite3_column_int64(queryStatement, 4))
                                let literaryColloquial: Int = Int(sqlite3_column_int64(queryStatement, 5))
                                let frequency: Int = Int(sqlite3_column_int64(queryStatement, 6))
                                let altFrequency: Int = Int(sqlite3_column_int64(queryStatement, 7))
                                let partOfSpeech: String = String(cString: sqlite3_column_text(queryStatement, 8))
                                let register: String = String(cString: sqlite3_column_text(queryStatement, 9))
                                let label: String = String(cString: sqlite3_column_text(queryStatement, 10))
                                let written: String = String(cString: sqlite3_column_text(queryStatement, 11))
                                let colloquial: String = String(cString: sqlite3_column_text(queryStatement, 12))
                                let english: String = String(cString: sqlite3_column_text(queryStatement, 13))
                                let explicit: String = String(cString: sqlite3_column_text(queryStatement, 14))
                                let urdu: String = String(cString: sqlite3_column_text(queryStatement, 15))
                                let nepali: String = String(cString: sqlite3_column_text(queryStatement, 16))
                                let hindi: String = String(cString: sqlite3_column_text(queryStatement, 17))
                                let indonesian: String = String(cString: sqlite3_column_text(queryStatement, 18))
                                let isSandhi: Bool = sandhi == 1
                                let notation = Notation(word: word, jyutping: romanization, pronunciationOrder: pronunciationOrder, isSandhi: isSandhi, literaryColloquial: literaryColloquial, frequency: frequency, altFrequency: altFrequency, partOfSpeech: partOfSpeech, register: register, label: label, written: written, colloquial: colloquial, english: english, explicit: explicit, urdu: urdu, nepali: nepali, hindi: hindi, indonesian: indonesian)
                                let candidate: CoreCandidate = CoreCandidate(text: word, romanization: romanization, input: text, notation: notation)
                                let rowCandidate: RowCandidate = RowCandidate(candidate: candidate, row: rowid, isExactlyMatch: isExactlyMatch)
                                rowCandidates.append(rowCandidate)
                        }
                }
                sqlite3_finalize(queryStatement)
                return rowCandidates
        }
}
