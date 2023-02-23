import SwiftUI

extension View {

        // https://www.avanderlee.com/swiftui/disable-animations-transactions
        func disableAnimation() -> some View {
                return self.transaction { transaction in
                        transaction.animation = nil
                }
        }

        func conditionalAnimation(_ shouldAnimate: Bool) -> some View {
                return self.transaction { transaction in
                        if !shouldAnimate {
                                transaction.animation = nil
                        }
                }
        }
}
