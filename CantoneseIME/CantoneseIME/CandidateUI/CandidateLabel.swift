import SwiftUI

private extension Image {
        static let infoCircle: Image = Image(systemName: "info.circle")
}

struct CandidateLabel: View {

        let index: Int
        @Binding var highlightedIndex: Int
        let candidate: Candidate
        let placeholder: Candidate

        @State private var isPopoverPresented: Bool = false

        private var shouldDisplayInfoCircle: Bool {
                return candidate.notation != nil
        }

        var body: some View {
                let shouldHighlight: Bool = index == highlightedIndex
                HStack {
                        HStack(spacing: 14) {
                                SerialNumberLabel(index: index)
                                ContentLabel(placeholder: placeholder, candidate: candidate)
                        }
                        Image.infoCircle
                                .contentShape(Rectangle())
                                .onHover { isHovering in
                                        guard isPopoverPresented != isHovering else { return }
                                        isPopoverPresented = isHovering
                                }
                                .opacity(shouldDisplayInfoCircle ? 1 : 0)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .foregroundColor(shouldHighlight ? .white : .primary)
                .background(shouldHighlight ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                .contentShape(Rectangle())
                .onHover { isHovering in
                        guard highlightedIndex != index else { return }
                        highlightedIndex = index
                }
                .popover(isPresented: $isPopoverPresented, attachmentAnchor: .point(.trailing), arrowEdge: .trailing) {
                        NotationView(notation: candidate.notation!).padding()
                }
        }
}

// TODO: - How about RTL comments?
private struct ContentLabel: View {

        let placeholder: Candidate
        let candidate: Candidate

        private let spacing: CGFloat = 12

        var body: some View {
                ZStack(alignment: .leading) {
                        HStack(spacing: spacing) {
                                CantoneseLabel(text: placeholder.text, romanization: placeholder.romanization)
                                ForEach(0..<placeholder.comments.count, id: \.self) { index in
                                        Text(verbatim: placeholder.comments[index].text)
                                }
                        }
                        .hidden()
                        HStack(spacing: spacing) {
                                CantoneseLabel(text: candidate.text, romanization: candidate.romanization)
                                ForEach(0..<candidate.comments.count, id: \.self) { index in
                                        Text(verbatim: candidate.comments[index].text)
                                }
                        }
                }
        }
}

private struct NotationView: View {

        let notation: Notation

        var body: some View {
                VStack(alignment: .leading, spacing: 8) {
                        if notation.isSandhi {
                                Text(verbatim: "This is a sandi")
                        }
                        if let pos = notation.partOfSpeech {
                                Text(verbatim: "Part of Speech: \(pos)")
                        }
                        if let register = notation.register {
                                Text(verbatim: "Register: \(register)")
                        }
                        if let label = notation.label {
                                Text(verbatim: "Label: \(label)")
                        }
                        if let written = notation.written {
                                Text(verbatim: "Written: \(written)")
                        }
                        if let colloquial = notation.colloquial {
                                Text(verbatim: "Colloquial: \(colloquial)")
                        }
                        if let note = notation.note {
                                Text(verbatim: "Note: \(note)")
                        }
                }
        }
}
