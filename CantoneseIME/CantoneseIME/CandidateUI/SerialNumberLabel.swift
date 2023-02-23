import SwiftUI

struct SerialNumberLabel: View {

        init(index: Int) {
                self.number = (index == 9) ? 0 : (index + 1)
        }

        private let number: Int

        var body: some View {
                Text(verbatim: "\(number).").font(.body.monospacedDigit())
        }
}

struct SerialNumberLabel_Previews: PreviewProvider {
        static var previews: some View {
                SerialNumberLabel(index: 0)
        }
}
