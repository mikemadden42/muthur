import Observation
import SwiftUI

/// Shared terminal tuning constants, so the model and the view animate in step.
enum TerminalMetrics {
    /// Seconds per character for the typewriter reveal animation.
    static let typingSpeed: Double = 0.015
}

struct LogEntry: Identifiable, Equatable {
    let id = UUID()
    let text: String
    var animated: Bool = true
}

@Observable
@MainActor
class MuthurViewModel {
    var consoleLog: [LogEntry] = []
    var currentInput: String = ""
    var isProcessing: Bool = false

    /// Pending shell lines above this count are flushed instantly instead of
    /// typed, so high-volume output (e.g. `find /`) can never lock the UI.
    private let catchUpThreshold = 40
    /// Scrollback limit. Older lines are dropped so the log can't grow without
    /// bound and stall rendering during torrential output (e.g. `find ~/src`).
    private let maxLogEntries = 2000

    /// The shell process currently bound to the interface, retained so it can
    /// be interrupted (Esc) or reaped on shutdown. `isProcessing` tracks its
    /// lifecycle strictly.
    private var activeProcess: Process?
    private var wasInterrupted = false

    func bootSequence() {
        appendEntry("PRIORITY ONE: INSURE RETURN OF ORGANISM.")
        appendEntry("ALL OTHER PRIORITIES RESCINDED.")
        appendEntry("STANDBY FOR COMMAND...")
    }

    func processCommand() async {
        let input = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        // Collapse internal whitespace so `CREW  STATUS` still matches.
        let commandKey = input
            .uppercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")

        isProcessing = true
        defer { isProcessing = false }

        appendEntry("> \(input)")
        currentInput = ""

        if await handleLoreCommands(commandKey) { return }

        // Fall back to standard shell execution with streaming.
        await runStreamingShell(input)
    }

    /// Operator interrupt (Esc): terminate the active process. Its termination
    /// handler finishes the stream, unwinding `runStreamingShell` naturally.
    func interrupt() {
        guard isProcessing, let process = activeProcess, process.isRunning else { return }
        wasInterrupted = true
        process.terminate()
    }

    /// Reap any running process on view dismissal / app shutdown to prevent
    /// orphaned background shells.
    func cleanup() {
        activeProcess?.terminate()
        activeProcess = nil
    }

    /// Ctrl-D: terminal-style EOF. Logs out only on an empty input line with no
    /// command running, matching shell behavior, so it can't fire mid-command.
    func requestEOF() {
        guard !isProcessing, currentInput.isEmpty else { return }
        NSApplication.shared.terminate(nil)
    }

    private func handleLoreCommands(_ commandKey: String) async -> Bool {
        switch commandKey {
        case "HELP":
            await appendLinesSequentially(MuthurViewModel.helpText)
            return true
        case "EXIT", "QUIT":
            NSApplication.shared.terminate(nil)
            return true
        case "CLEAR":
            consoleLog.removeAll()
            return true
        case "SPECIAL ORDER 937", "ORDER 937":
            await appendLinesSequentially("PRIORITY ONE. INSURE RETURN OF ORGANISM. ALL OTHER PRIORITIES RESCINDED.")
            return true
        case "CREW STATUS":
            await appendLinesSequentially("NOSTROMO COMPLEMENT: 07. STATUS: 1 ACTIVE / 6 TERMINATED.")
            return true
        default:
            return false
        }
    }

    private static let helpText = """
    MU-TH-UR 6000 INTERFACE v1.0
    --------------------------
    LOCAL COMMANDS:
    CLEAR - PURGE TERMINAL BUFFER
    EXIT  - TERMINATE INTERFACE (OR CTRL-D)
    HELP  - DISPLAY THIS DIRECTIVE

    SYSTEM COMMANDS:
    ANY VALID ZSH COMMAND IS AUTHORIZED.
    """

    private func appendEntry(_ text: String, animated: Bool = true) {
        consoleLog.append(LogEntry(text: text, animated: animated))
        if consoleLog.count > maxLogEntries {
            consoleLog.removeFirst(consoleLog.count - maxLogEntries)
        }
    }

    private func appendLinesSequentially(_ text: String) async {
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            appendEntry(line)
            let characterCount = Double(line.count)
            let delay = characterCount * TerminalMetrics.typingSpeed
            try? await Task.sleep(for: .seconds(delay))
        }
    }

    static let interactiveTools: Set<String> = [
        "vim", "vi", "nano", "python3", "python", "top", "htop", "bash", "zsh",
    ]

    /// Wrapper commands that precede the real program (e.g. `sudo vim`).
    static let commandWrappers: Set<String> = [
        "sudo", "env", "command", "nohup", "nice", "stdbuf",
    ]

    /// Best-effort extraction of the program being invoked, looking past
    /// `env VAR=val` assignments, option flags, and wrapper commands like
    /// `sudo`/`env`. Limitation: a wrapper option that takes a *separate*
    /// argument (e.g. `sudo -u user vim`) is not parsed and may defeat
    /// detection of the inner program.
    static func baseCommand(of command: String) -> String {
        let tokens = command.split(whereSeparator: \.isWhitespace).map(String.init)
        var index = 0
        while index < tokens.count {
            let token = tokens[index]
            if token.contains("=") || token.hasPrefix("-") || commandWrappers.contains(token) {
                index += 1
            } else {
                return token
            }
        }
        return ""
    }

    static func isInteractive(_ command: String) -> Bool {
        interactiveTools.contains(baseCommand(of: command))
    }

    private func runStreamingShell(_ command: String) async {
        if Self.isInteractive(command) {
            routeToExternalTTY(command)
            return
        }

        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        // Login shell so Homebrew / dev-tool paths from .zprofile are loaded.
        task.arguments = ["-l", "-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")

        wasInterrupted = false
        activeProcess = task
        defer { activeProcess = nil }

        // Launch first: this lets us report launch failures cleanly and avoids
        // a final-drain read against a pipe whose writer was never opened.
        do {
            try task.run()
        } catch {
            appendEntry("ERROR: COMMAND FAILED — \(error.localizedDescription)")
            return
        }

        var buffer = ""
        var pending: [String] = []
        for await chunk in makeOutputStream(for: task, pipe: pipe) {
            buffer += chunk
            absorb(&buffer, into: &pending)
            await drainPending(&pending)
        }

        // Final drain: the termination handler can finish the stream before the
        // readability handler delivers the last buffered chunk, so recover any
        // bytes still sitting in the pipe. The process has exited (and its writer
        // closed) by now, so this read returns immediately at EOF.
        let remaining = pipe.fileHandleForReading.readDataToEndOfFile()
        if let tail = String(data: remaining, encoding: .utf8), !tail.isEmpty {
            buffer += tail
            absorb(&buffer, into: &pending)
        }

        // Flush the trailing partial line plus any remaining backlog.
        if !buffer.isEmpty { pending.append(buffer) }
        await drainPending(&pending)

        reportTermination(of: task)
    }

    /// Bridge the process pipe to an `AsyncStream` of decoded chunks. Either the
    /// EOF callback (empty data) or the termination safety net finishes the
    /// stream; both nil the readability handler first so the caller's post-loop
    /// drain never races a live reader.
    private func makeOutputStream(for task: Process, pipe: Pipe) -> AsyncStream<String> {
        AsyncStream<String> { continuation in
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
                pipe.fileHandleForReading.readabilityHandler = nil
                continuation.finish()
            }
        }
    }

    /// Move complete lines out of `buffer` into `pending`, leaving any trailing
    /// partial line in `buffer` for the next chunk.
    private func absorb(_ buffer: inout String, into pending: inout [String]) {
        let parts = buffer.components(separatedBy: "\n")
        buffer = parts.last ?? ""
        pending.append(contentsOf: parts.dropLast())
    }

    /// Reveal pending shell lines with the typewriter cadence, but fall back to
    /// instant rendering whenever we fall too far behind (or are interrupted),
    /// so the interface stays responsive under high-volume output.
    private func drainPending(_ pending: inout [String]) async {
        while !pending.isEmpty {
            if wasInterrupted || pending.count > catchUpThreshold {
                // Only the most recent lines can outlast the scrollback cap, so
                // skip the doomed older ones rather than append-then-trim them.
                for line in pending.suffix(maxLogEntries) {
                    appendEntry(line, animated: false)
                }
                pending.removeAll()
                return
            }

            let line = pending.removeFirst()
            appendEntry(line, animated: true)
            try? await Task.sleep(for: .seconds(Double(line.count) * TerminalMetrics.typingSpeed))
        }
    }

    private func routeToExternalTTY(_ command: String) {
        // Escape backslashes first, then quotes, so commands like
        // `python3 -c "print(1)"` survive interpolation into AppleScript.
        let escaped = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = "tell application \"Terminal\" to (activate) & (do script \"\(escaped)\")"

        let osascript = Process()
        osascript.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        osascript.arguments = ["-e", script]
        do {
            try osascript.run()
            appendEntry("LOG: INTERACTIVE SESSION ROUTED TO EXTERNAL TTY.")
        } catch {
            appendEntry("ERROR: UNABLE TO ROUTE INTERACTIVE SESSION — \(error.localizedDescription)")
        }
    }

    private func reportTermination(of task: Process) {
        if wasInterrupted {
            appendEntry("SIGNAL: PROCESS TERMINATED BY OPERATOR.")
            return
        }
        let status = task.terminationStatus
        if status != 0 {
            appendEntry("LOG: PROCESS EXITED WITH STATUS \(status).")
        }
    }
}
