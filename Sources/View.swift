import SwiftUI

@MainActor
struct MuthurTerminal: View {
    @State private var consoleLog: [String] = []
    @State private var currentInput: String = ""
    @FocusState private var isInputFocused: Bool

    let muThUrGreen = Color(red: 0.0, green: 0.8, blue: 0.0)

    var body: some View {
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
                        ForEach(0 ..< consoleLog.count, id: \.self) { index in
                            TypewriterText(text: consoleLog[index], color: muThUrGreen)
                                .id(index)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: consoleLog) {
                    withAnimation {
                        proxy.scrollTo(consoleLog.count - 1, anchor: .bottom)
                    }
                }
            }
            .background(Color.black)
            .overlay(ScanlineOverlay())

            // Input
            HStack {
                Text("[muthur]>>")
                    .foregroundColor(muThUrGreen)
                    .font(.system(.body, design: .monospaced))

                TextField("", text: $currentInput)
                    .focused($isInputFocused)
                    .textFieldStyle(.plain)
                    .foregroundColor(muThUrGreen)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit(processCommand)
                    .autocorrectionDisabled()
            }
            .padding()
            .background(Color.black)
            .border(muThUrGreen, width: 1)
        }
        .onAppear {
            bootSequence()
            isInputFocused = true
        }
        .onTapGesture {
            isInputFocused = true
        }
    }

    func bootSequence() {
        consoleLog.append("PRIORITY ONE: INSURE RETURN OF ORGANISM.")
        consoleLog.append("ALL OTHER PRIORITIES RESCINDED.")
        consoleLog.append("STANDBY FOR COMMAND...")
    }

    func processCommand() {
        let input = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let commandKey = input.uppercased()
        guard !input.isEmpty else { return }

        consoleLog.append("> \(input)")

        // Intercept built-in and Lore commands
        switch commandKey {
        case "HELP":
            consoleLog.append("""
            MU-TH-UR 6000 INTERFACE v1.0
            --------------------------
            LOCAL COMMANDS:
            CLEAR - PURGE TERMINAL BUFFER
            EXIT  - TERMINATE INTERFACE
            HELP  - DISPLAY THIS DIRECTIVE

            SYSTEM COMMANDS:
            ANY VALID ZSH COMMAND IS AUTHORIZED.
            """)
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
            consoleLog.append(runShell(input))
        }

        currentInput = ""
        isInputFocused = true
    }

    func runShell(_ command: String) -> String {
        let interactiveTools = ["vim", "vi", "nano", "python3", "python", "top", "htop", "bash", "zsh"]
        let cmdBase = command.components(separatedBy: " ").first ?? ""

        if interactiveTools.contains(cmdBase) {
            // AppleScript Bridge: Spawns a real TTY Terminal for interactive apps
            // Added 'activate' to ensure the new Terminal window pops to the front
            let script = "tell application \"Terminal\" to (activate) & (do script \"\(command)\")"
            let osascript = Process()
            osascript.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            osascript.arguments = ["-e", script]
            try? osascript.run()
            return "LOG: INTERACTIVE SESSION ROUTED TO EXTERNAL TTY."
        }

        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")

        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return output.isEmpty ? "SUCCESS." : output
        } catch {
            return "ERROR: COMMAND FAILED."
        }
    }
}

// Typing Subview
struct TypewriterText: View {
    let text: String
    let color: Color
    @State private var visibleChars: Int = 0

    var body: some View {
        Text(text.prefix(visibleChars))
            .font(.system(.body, design: .monospaced))
            .foregroundColor(color)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.015, repeats: true) { timer in
                    // Use local variable to bridge between MainActor and non-isolated timer closure
                    var isFinished = false

                    MainActor.assumeIsolated {
                        if visibleChars < text.count {
                            visibleChars += 1
                        }
                        isFinished = visibleChars >= text.count
                    }

                    // Invalidate timer outside isolation to avoid data race error
                    if isFinished {
                        timer.invalidate()
                    }
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
