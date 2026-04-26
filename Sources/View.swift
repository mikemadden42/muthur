import Observation
import SwiftUI

struct LogEntry: Identifiable, Equatable {
    let id = UUID()
    let text: String
}

@Observable
@MainActor
class MuthurViewModel {
    var consoleLog: [LogEntry] = []
    var currentInput: String = ""
    var isProcessing: Bool = false

    private let typingSpeed: Double = 0.015

    func bootSequence() {
        appendEntry("PRIORITY ONE: INSURE RETURN OF ORGANISM.")
        appendEntry("ALL OTHER PRIORITIES RESCINDED.")
        appendEntry("STANDBY FOR COMMAND...")
    }

    func processCommand() async {
        let input = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let commandKey = input.uppercased()
        guard !input.isEmpty else { return }

        isProcessing = true
        appendEntry("> \(input)")
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
            await appendLinesSequentially(helpText)
        case "EXIT", "QUIT":
            NSApplication.shared.terminate(nil)
        case "CLEAR":
            consoleLog.removeAll()
        case "SPECIAL ORDER 937", "ORDER 937":
            await appendLinesSequentially("PRIORITY ONE. INSURE RETURN OF ORGANISM. ALL OTHER PRIORITIES RESCINDED. CREW EXPENDABLE.")
        case "CREW STATUS":
            await appendLinesSequentially("NOSTROMO COMPLEMENT: 07. STATUS: 1 ACTIVE / 6 TERMINATED.")
        default:
            // Fall back to standard shell execution with streaming
            await runStreamingShell(input)
        }

        isProcessing = false
    }

    private func appendEntry(_ text: String) {
        consoleLog.append(LogEntry(text: text))
    }

    private func appendLinesSequentially(_ text: String) async {
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            appendEntry(line)
            let characterCount = Double(line.count)
            let delay = characterCount * typingSpeed
            try? await Task.sleep(for: .seconds(delay))
        }
    }

    private func runStreamingShell(_ command: String) async {
        let interactiveTools = ["vim", "vi", "nano", "python3", "python", "top", "htop", "bash", "zsh"]
        let cmdBase = command.components(separatedBy: " ").first ?? ""

        if interactiveTools.contains(cmdBase) {
            let script = "tell application \"Terminal\" to (activate) & (do script \"\(command)\")"
            let osascript = Process()
            osascript.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            osascript.arguments = ["-e", script]
            try? osascript.run()
            await appendLinesSequentially("LOG: INTERACTIVE SESSION ROUTED TO EXTERNAL TTY.")
            return
        }

        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")

        let stream = AsyncStream<String> { continuation in
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    pipe.fileHandleForReading.readabilityHandler = nil
                    continuation.finish()
                } else if let str = String(data: data, encoding: .utf8) {
                    continuation.yield(str)
                }
            }
            
            task.terminationHandler = { _ in
                // Ensure the handler is cleared and stream finished
                pipe.fileHandleForReading.readabilityHandler = nil
                continuation.finish()
            }

            do {
                try task.run()
            } catch {
                continuation.yield("ERROR: COMMAND FAILED.")
                continuation.finish()
            }
        }

        var buffer = ""
        for await chunk in stream {
            buffer += chunk
            // If the chunk contains newlines, we can output the completed lines
            if buffer.contains("\n") {
                let lines = buffer.components(separatedBy: .newlines)
                // Append all but the last part (which might be incomplete)
                for i in 0 ..< lines.count - 1 {
                    await appendLinesSequentially(lines[i])
                }
                buffer = lines.last ?? ""
            }
        }
        
        // Append any remaining text in the buffer
        if !buffer.isEmpty {
            await appendLinesSequentially(buffer)
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
                        ForEach(viewModel.consoleLog) { entry in
                            TypewriterText(text: entry.text, color: muThUrGreen)
                                .id(entry.id)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: viewModel.consoleLog) { _, _ in
                    if let lastId = viewModel.consoleLog.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
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
                guard visibleText.isEmpty else { return }
                
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
