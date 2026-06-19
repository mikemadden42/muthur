# MU-TH-UR 6000 (muthur)

> **RESTRICTED ACCESS: WEYLAND-YUTANI CORP INTERNAL USE ONLY**
> **STATION:** NOSTROMO-2037
> **PRIORITY ONE:** INSURE RETURN OF ORGANISM. ALL OTHER PRIORITIES RESCINDED.

`muthur` is a macOS native terminal interface built with **Swift 6** and
**SwiftUI**. It provides a retro-futuristic TTY environment that bridges
standard shell commands with the high-clearance mainframe logic of the
MU-TH-UR 6000 system.

---

## Features

* **Native ZSH Integration:** Executes all standard Unix/macOS commands via a
  non-blocking background process.
* **Intelligent Routing:** Automatically detects interactive CLI tools (like
  `vim`, `nano`, or `python3`) and routes them to an external authenticated TTY.
* **Swift 6 Concurrency:** Built with strict actor isolation and thread-safe UI
  updates to ensure stability in high-throughput environments.
* **CRT Aesthetics:** Features a real-time typewriter rendering engine and a
  CRT scanline overlay.
* **Lore-Encoded:** Includes built-in interceptors for classified company
  directives and special orders.

---

## Architecture & Implementation

* **TTY Routing Bridge:** To maintain a responsive UI while supporting
  interactive terminal applications (like `vim` or `python3`), `muthur` uses an
  `osascript` bridge. This automatically detects TTY-dependent commands and
  routes them to a new, external macOS Terminal window.
* **Swift 6 Concurrency:** The engine is built with strict actor isolation. The
  UI is pinned to the `@MainActor`, while long-running shell processes and the
  typewriter animation logic utilize safe cross-actor boundaries to prevent data
  races.
* **Vector Scanlines:** Unlike static image overlays, the CRT effect is rendered
  in real-time using native SwiftUI `Path` primitives, ensuring high performance
  at any window scale.

---

## Classified Directives

Authorized personnel may query the mainframe for internal directives. Commands
are case-insensitive and tolerant of extra whitespace. Try entering:

* `HELP` - System diagnostics.
* `CREW STATUS` - Personnel manifest.
* `SPECIAL ORDER 937` (or `ORDER 937`) - [RESTRICTED]
* `CLEAR` - Purge the terminal buffer.
* `EXIT` / `QUIT` - Terminate the interface (or `Ctrl-D` on an empty line).

Any input that is not an intercepted directive is executed as a standard shell
command (see **Usage** below).

---

## Usage

Anything that isn't a classified directive is dispatched to a login `zsh`
shell, so your `PATH` (Homebrew, dev tools, etc.) is loaded as usual. The
interface is built for real workloads:

* **Live streaming:** Output is rendered with the typewriter engine as it
  arrives. High-volume commands (e.g. `find ~/src`) automatically switch to a
  "catch-up" mode that flushes the backlog instantly rather than locking the
  UI.
* **Scrollback cap:** The console retains the most recent 2,000 lines. The
  command still runs to completion — older lines simply scroll off. Redirect to
  a file (`find ~/src > /tmp/out.txt`) if you need the full record.
* **Interrupt:** Press `Esc` to terminate a running process. The mainframe logs
  `SIGNAL: PROCESS TERMINATED BY OPERATOR.`
* **Exit status:** A non-zero exit code is reported as
  `LOG: PROCESS EXITED WITH STATUS <n>.`
* **External TTY routing:** Interactive tools (`vim`, `vi`, `nano`, `python3`,
  `python`, `top`, `htop`, `bash`, `zsh`) are routed to a new macOS Terminal
  window via the `osascript` bridge — e.g. `python3 -c "print(1)"` opens an
  external session.
* **Resource cleanup:** Closing the window terminates any active process, so no
  orphaned shells are left behind.

---

## Installation

### Prerequisites

* **macOS 14.0 (Sonoma)** or later.
* **Swift 6.0+** (Included with Xcode 16+).

### Build from Source

Clone the repository and build using the Swift Package Manager in release mode:

```bash
git clone https://github.com/yourusername/muthur.git
cd muthur
swift build -c release
```
