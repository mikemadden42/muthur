# MU-TH-UR 6000 Development Roadmap

## Priority 1: Performance & Stability

- [x] **Fix Main Thread Blocking:** Refactor `runShell` to be asynchronous.
  Currently, `readDataToEndOfFile()` blocks the `@MainActor`, causing the UI to
  freeze during command execution.
- [x] **Fix `scrollTo` Crash Risk:** Add a safety check in the `onChange` scroll
  logic to ensure it doesn't attempt to scroll to index `-1` when the console
  log is cleared.
- [x] **Task Lifecycle Management:** Migrate `TypewriterText` to use the
  `.task` modifier for automatic task cancellation when views disappear.
- [x] **Command Sequentiality:** Implement an `isProcessing` state to prevent
  overlapping command execution and maintain the mainframe aesthetic.
- [x] **Real-time Pipe Streaming:** Refactor `runShell` to use `AsyncStream` and
  `readabilityHandler`. This ensures long-running commands (like `find /`)
  output data to the UI as it arrives rather than waiting for termination.
- [x] **Log Identity Stability:** Implement a `LogEntry` model with stable
  identifiers (UUIDs) to prevent animation re-triggers when the log is modified.
- [x] **High-Speed Streaming Catch-up:** Decouple shell reading from the
  typewriter animation. Implement "catch-up" logic to prevent the UI from
  falling too far behind high-volume shell output.
- [x] **Process Interrupt Support:** Add a way to terminate a long-running shell
  process (e.g., using the `Esc` key) and ensure `isProcessing` is tied strictly
  to the process lifecycle.
- [x] **Resource Cleanup (Ghost Processes):** Ensure the active shell process is
  terminated when the application is closed or the view is dismissed to prevent
  orphan background processes.
- [x] **Shell Environment Loading:** Update `runShell` to use a login shell
  environment (`-l`) and verify path loading for Homebrew/common dev tools.
- [x] **AppleScript Injection / Quoting:** In `runStreamingShell`, the raw
  command is interpolated directly into the `osascript` string
  (`do script "\(command)"`). Any command containing a double quote (e.g.
  `python3 -c "print(1)"`) breaks the script and the route silently misfires.
  Escape `\` and `"` (or pass the command via argument) before interpolation.
- [x] **Decouple Per-Line Sleep from Animation (root cause):** Shell output is
  currently typed twice — `appendLinesSequentially` sleeps `line.count * speed`
  *before* appending the next line, while `TypewriterText` *also* animates each
  entry char-by-char. This serializes large output (e.g. `find /`) and locks
  input for minutes. The ViewModel should append shell lines immediately and let
  the view own (or skip) animation. This is the underlying cause of both
  **High-Speed Streaming Catch-up** and **Throttled Auto-Scroll**.
- [x] **Surface Exit Status:** Non-zero exits blend silently into stderr output,
  and `try? task.run()` / `try? osascript.run()` swallow launch failures. Report
  the process exit code (and launch errors) to the console buffer.

## Priority 2: Modernization & API Updates

- [x] **Update `onChange` Syntax:** Migrate from the deprecated `.onChange(of:)`
  to the macOS 14+ `.onChange(of:) { oldValue, newValue in }` signature.
- [x] **Idiomatic Concurrency:** Replace the manual `Timer` in `TypewriterText`
  with `Task` and `ContinuousClock` for more modern, Swift 6-aligned animation
  logic.
- [x] **Multi-line Output Streaming:** Refactor shell output handling to split
  results by line, allowing for more natural scrolling and typing animations.
- [x] **Empty Line Preservation:** Update line splitting logic to preserve blank
  lines for correct command output formatting and readability.
- [x] **Throttled Auto-Scroll:** Implement a throttled or proximity-based scroll
  mechanism to prevent UI jitter and CPU spikes during high-frequency log
  updates. (LazyVStack + count-based, non-animated scroll + scrollback cap.)

## Priority 3: Refinement

- [x] **Grapheme Cluster Safety:** Refine `TypewriterText` indexing to ensure it
  handles multi-scalar characters safely if the character set expands beyond
  standard ASCII.
- [x] **State Management:** Consider moving terminal state (log and input) into
  an `@Observable` View Model as the application grows.
- [x] **AsyncStream Race Safety:** Ensure `runStreamingShell` performs a final
  drain of the pipe after process termination to prevent loss of final output
  chunks.
- [x] **Testing Infrastructure:** Establish an XCTest suite to verify
  `MuthurViewModel` logic and command interception.
- [x] **Deduplicate Typing Speed:** The `0.015` typing interval is defined both
  as `typingSpeed` and as a literal inside `TypewriterText`. Share a single
  source of truth so the two can't drift.
- [x] **Robust Lore Command Matching:** `commandKey = input.uppercased()` fails
  on extra whitespace (`CREW  STATUS`) or trailing arguments. Normalize
  whitespace before matching the interception table.
- [x] **Broaden Interactive Tool Detection:** `interactiveTools` only inspects
  the first token, so `sudo vim` / `env python3` slip through to the
  non-interactive path. At minimum document the limitation.

## Priority 4: Project Infrastructure

- [ ] **Continuous Integration:** Add a GitHub Actions workflow running
  `swift build` and `swift test` on push/PR to catch regressions.
- [ ] **Split Source Files:** `View.swift` holds the view model, three views,
  and the scanline overlay. Extract `MuthurViewModel` (and ideally the smaller
  views) into their own files as the app grows.
- [ ] **Commit Lint/Format Config:** Commit `.swiftlint.yml` / `.swiftformat` so
  the style rules referenced in past commits are reproducible.
