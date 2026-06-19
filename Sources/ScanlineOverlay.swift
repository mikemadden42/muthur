import SwiftUI

/// Vector CRT scanlines drawn in real time so they stay crisp at any scale.
struct ScanlineOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                for lineOffset in stride(from: 0, to: geo.size.height, by: 3) {
                    path.move(to: CGPoint(x: 0, y: CGFloat(lineOffset)))
                    path.addLine(to: CGPoint(x: geo.size.width, y: CGFloat(lineOffset)))
                }
            }
            .stroke(Color.black.opacity(0.25), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}
