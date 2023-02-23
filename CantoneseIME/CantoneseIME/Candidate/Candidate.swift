import Foundation

struct Comment: Hashable {
        let language: Language
        let text: String
}

struct Candidate: Hashable {
        let input: String
        let text: String
        let romanization: String
        let comments: [Comment]
        let notation: Notation?
}


private extension Comment {
        func isLonger(than another: Comment) -> Bool {
                return self.text.count > another.text.count
        }
}
extension Array where Element == Comment {
        var longest: Element? {
                return self.sorted(by: { $0.isLonger(than: $1) }).first
        }
}


private extension Candidate {
        private var length: Int {
                return text.count + romanization.count + comments.map(\.text).reduce(0, { $0 + $1.count })
        }
        func isLonger(than another: Candidate) -> Bool {
                return self.length > another.length
        }
        var commentLength: Int {
                return comments.map(\.text).reduce(0, { $0 + $1.count })
        }
}
extension Array where Element == Candidate {
        var longest: Element? {
                guard let romanizationOne = self.sorted(by: { $0.romanization.count > $1.romanization.count }).first else { return first }
                guard let commentsOne = self.sorted(by: { $0.commentLength > $1.commentLength }).first else { return first }
                return Candidate(input: romanizationOne.input, text: romanizationOne.text, romanization: romanizationOne.romanization, comments: commentsOne.comments, notation: commentsOne.notation)
        }
}
