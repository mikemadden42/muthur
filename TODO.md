# MU-TH-UR 6000 Development Roadmap

## Priority 1: Performance & Stability

- [x] **Fix Main Thread Blocking:** Refactor `runShell` to be asynchronous.
  Currently, `readDataToEndOfFile()` blocks the `@MainActor`, causing the UI to
  freeze during command execution.
- [x] **Fix `scrollTo` Crash Risk:** Add a safety check in the `onChange` scroll
  logic to ensure it doesn't attempt to scroll to index `-1` when the console
  log is cleared.

## Priority 2: Modernization & API Updates

- [x] **Update `onChange` Syntax:** Migrate from the deprecated `.onChange(of:)`
  to the macOS 14+ `.onChange(of:) { oldValue, newValue in }` signature.
- [ ] **Idiomatic Concurrency:** Replace the manual `Timer` in `TypewriterText`
  with `Task` and `ContinuousClock` for more modern, Swift 6-aligned animation
  logic.

## Priority 3: Refinement

- [ ] **Grapheme Cluster Safety:** Refine `TypewriterText` indexing to ensure it
  handles multi-scalar characters safely if the character set expands beyond
  standard ASCII.
- [ ] **State Management:** Consider moving terminal state (log and input) into
  an `@Observable` View Model as the application grows.
