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
- [ ] **Shell Environment Loading:** Update `runShell` to use a login shell
  environment to ensure user paths (like Homebrew) and aliases are available.

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

## Priority 3: Refinement

- [x] **Grapheme Cluster Safety:** Refine `TypewriterText` indexing to ensure it
  handles multi-scalar characters safely if the character set expands beyond
  standard ASCII.
- [x] **State Management:** Consider moving terminal state (log and input) into
  an `@Observable` View Model as the application grows.
- [ ] **Testing Infrastructure:** Establish an XCTest suite to verify
  `MuthurViewModel` logic and command interception.
