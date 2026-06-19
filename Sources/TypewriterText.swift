import SwiftUI

/// Renders text one character at a time for the CRT typewriter effect, or
/// immediately when `animated` is false (used for catch-up flushes).
struct TypewriterText: View {
    let text: String
    let color: Color
    var animated: Bool = true
    @State private var visibleText: String = ""

    var body: some View {
        Text(visibleText)
            .font(.system(.body, design: .monospaced))
            .foregroundColor(color)
            .task {
                guard animated else {
                    visibleText = text
                    return
                }
                guard visibleText.isEmpty else { return }

                for index in text.indices {
                    visibleText.append(text[index])
                    try? await Task.sleep(for: .seconds(TerminalMetrics.typingSpeed))
                }
            }
    }
}
