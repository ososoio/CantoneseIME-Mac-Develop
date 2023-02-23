import SwiftUI

struct CandidateBoard: View {

        @EnvironmentObject private var displayObject: DisplayObject

        var body: some View {
                VStack(alignment: .leading, spacing: 0) {
                        let placeholder = displayObject.longest
                        ForEach(0..<displayObject.candidates.count, id: \.self) { index in
                                let candidate: Candidate = displayObject.candidates[index]
                                CandidateLabel(index: index, highlightedIndex: $displayObject.highlightedIndex, candidate: candidate, placeholder: placeholder)
                        }
                }
                .padding(8)
                .roundedHUDVisualEffect()
                // .animation(.default, value: displayObject.animationState)
        }
}
