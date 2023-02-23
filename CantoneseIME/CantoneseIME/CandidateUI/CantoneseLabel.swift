import SwiftUI

/// Display Cantonese text and Jyutping romanizations
struct CantoneseLabel: View {

        init(text: String, romanization: String) {
                self.text = text
                self.romanization = romanization
        }

        private let text: String
        private let romanization: String

        var body: some View {
                VStack(alignment: .leading) {
                        if !(romanization.isEmpty) {
                                Text(verbatim: romanization)
                                        .minimumScaleFactor(0.2)
                                        .lineLimit(1)
                                        .font(.footnote)
                        }
                        Text(verbatim: text)
                                .tracking(10)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .font(.title3)
                }
        }
}
