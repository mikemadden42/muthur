import Observation
import SwiftUI

@Observable
@MainActor
class MuthurViewModel {
    var consoleLog: [String] = []
    var currentInput: String = ""
    var isProcessing: Bool = false

    func bootSequence() {
        consoleLog.append("PRIORITY ONE: INSURE RETURN OF ORGANISM.")
        consoleLog.append("ALL OTHER PRIORITIES RESCINDED.")
        consoleLog.append("STANDBY FOR COMMAND...")
    }

    func processCommand() async {
        let input = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let commandKey = input.uppercased()
        guard !input.isEmpty else { return }

        isProcessing = true
        consoleLog.append("> \(input)")
        currentInput = ""

        // Intercept built-in and Lore commands
        switch commandKey {
        case "HELP":
            let helpText = """
            MU-TH-UR 6000 INTERFACE v1.0
            --------------------------
            LOCAL COMMANDS:
            CLEAR - PURGE TERMINAL BUFFER
            EXIT  - TERMINATE INTERFACE
            HELP  - DISPLAY THIS DIRECTIVE

            SYSTEM COMMANDS:
            ANY VALID ZSH COMMAND IS AUTHORIZED.
            """
            appendLines(helpText)
        case "EXIT", "QUIT":
            NSApplication.shared.terminate(nil)
        case "CLEAR":
            consoleLog.removeAll()
        case "SPECIAL ORDER 937", "ORDER 937":
            consoleLog.append("PRIORITY ONE. INSURE RETURN OF ORGANISM. ALL OTHER PRIORITIES RESCINDED. CREW EXPENDABLE.")
        case "CREW STATUS":
            consoleLog.append("NOSTROMO COMPLEMENT: 07. STATUS: 1 ACTIVE / 6 TERMINATED.")
        default:
            // Fall back to standard shell execution
            let result = await runShell(input)
            appendLines(result)
        }

        isProcessing = false
    }

    private func appendLines(_ text: String) {
        let lines = text.components(separatedBy: .newlines)
        for line in lines where !line.isEmpty {
            consoleLog.append(line)
        }
    }

    private func runShell(_ command: String) async -> String {
        let interactiveTools = ["vim", "vi", "nano", "python3", "python", "top", "htop", "bash", "zsh"]
        let cmdBase = command.components(separatedBy: " ").first ?? ""

        if interactiveTools.contains(cmdBase) {
            // AppleScript Bridge: Spawns a real TTY Terminal for interactive apps
            let script = "tell application \"Terminal\" to (activate) & (do script \"\(command)\")"
            let osascript = Process()
            osascript.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            osascript.arguments = ["-e", script]
            try? osascript.run()
            return "LOG: INTERACTIVE SESSION ROUTED TO EXTERNAL TTY."
        }

        return await withCheckedContinuation { continuation in
            let task = Process()
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            task.arguments = ["-c", command]
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")

            task.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                continuation.resume(returning: output.isEmpty ? "SUCCESS." : output)
            }

            do {
                try task.run()
            } catch {
                continuation.resume(returning: "ERROR: COMMAND FAILED.")
            }
        }
    }
}

@MainActor
struct MuthurTerminal: View {
    @State private var viewModel = MuthurViewModel()
    @FocusState private var isInputFocused: Bool

    let muThUrGreen = Color(red: 0.0, green: 0.8, blue: 0.0)

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            // Header
            Text("WEYLAND-YUTANI CORP | MU-TH-UR 6000 | NOSTROMO-2037")
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(muThUrGreen)
                .foregroundColor(.black)

            // Log
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(0 ..< viewModel.consoleLog.count, id: \.self) { index in
                            TypewriterText(text: viewModel.consoleLog[index], color: muThUrGreen)
                                .id(index)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: viewModel.consoleLog) { _, _ in
                    if !viewModel.consoleLog.isEmpty {
                        withAnimation {
                            proxy.scrollTo(viewModel.consoleLog.count - 1, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color.black)
            .overlay(ScanlineOverlay())

            // Input
            HStack {
                Text("[muthur]>>")
                    .foregroundColor(viewModel.isProcessing ? muThUrGreen.opacity(0.5) : muThUrGreen)
                    .font(.system(.body, design: .monospaced))

                TextField("", text: $viewModel.currentInput)
                    .focused($isInputFocused)
                    .textFieldStyle(.plain)
                    .foregroundColor(muThUrGreen)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit {
                        Task {
                            await viewModel.processCommand()
                            isInputFocused = true
                        }
                    }
                    .autocorrectionDisabled()
                    .disabled(viewModel.isProcessing)
            }
            .padding()
            .background(Color.black)
            .border(muThUrGreen, width: 1)
            .opacity(viewModel.isProcessing ? 0.7 : 1.0)
        }
        .onAppear {
            viewModel.bootSequence()
            isInputFocused = true
        }
        .onTapGesture {
            isInputFocused = true
        }
    }
}

// Typing Subview
struct TypewriterText: View {
    let text: String
    let color: Color
    @State private var visibleText: String = ""

    var body: some View {
        Text(visibleText)
            .font(.system(.body, design: .monospaced))
            .foregroundColor(color)
            .task {
                visibleText = ""
                for index in text.indices {
                    visibleText.append(text[index])
                    try? await Task.sleep(for: .seconds(0.015))
                }
            }
    }
}

// CRT Scanline Effect
struct ScanlineOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                // Using 'lineOffset' to satisfy naming conventions
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
