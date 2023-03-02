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
