import Combine

final class DisplayObject: ObservableObject {

        @Published private(set) var candidates: [Candidate] = []
        @Published private(set) var longest: Candidate = DisplayObject.defaultLongest
        @Published var highlightedIndex: Int = 0
        @Published private(set) var animationState: Int = 0

        private static let defaultLongest: Candidate = Candidate(input: "m", text: "毋", romanization: "m4", comments: [], notation: nil)

        func reset() {
                candidates = []
                longest = DisplayObject.defaultLongest
                highlightedIndex = 0
                animationState = 0
        }

        func update(to newCandidates: [Candidate]) {
                guard !newCandidates.isEmpty else {
                        reset()
                        return
                }
                let pageSize: Int = AppSettings.pageSize
                let shouldAnimate: Bool = candidates.count == pageSize && newCandidates.count == pageSize
                candidates = newCandidates
                longest = newCandidates.longest!
                highlightedIndex = 0
                if shouldAnimate {
                        animationState += 1
                }
        }

        func increaseHighlightedIndex() {
                let lastIndex: Int = candidates.count - 1
                guard highlightedIndex < lastIndex else { return }
                highlightedIndex += 1
        }
        func decreaseHighlightedIndex() {
                let firstIndex: Int = 0
                guard highlightedIndex > firstIndex else { return }
                highlightedIndex -= 1
        }
}
