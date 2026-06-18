import SwiftUI

/// A slim, rounded progress bar with a gradient fill — the clean replacement
/// for the progress ring.
struct ProgressBar: View {
    let progress: Double      // 0...1
    let colors: [Color]

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(
                        LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: max(0, proxy.size.width * min(1, max(0, progress))))
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
    }
}
