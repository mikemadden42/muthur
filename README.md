# MU-TH-UR 6000 (muthur)

> **RESTRICTED ACCESS: WEYLAND-YUTANI CORP INTERNAL USE ONLY** > **STATION:** NOSTROMO-2037  
> **PRIORITY ONE:** INSURE RETURN OF ORGANISM. ALL OTHER PRIORITIES RESCINDED.

`muthur` is a macOS native terminal interface built with **Swift 6** and **SwiftUI**. It provides a retro-futuristic TTY environment that bridges standard shell commands with the high-clearance mainframe logic of the MU-TH-UR 6000 system.

---

## Features

* **Native ZSH Integration:** Executes all standard Unix/macOS commands via a non-blocking background process.
* **Intelligent Routing:** Automatically detects interactive CLI tools (like `vim`, `nano`, or `python3`) and routes them to an external authenticated TTY.
* **Swift 6 Concurrency:** Built with strict actor isolation and thread-safe UI updates to ensure stability in high-throughput environments.
* **CRT Aesthetics:** Features a real-time typewriter rendering engine and a CRT scanline overlay.
* **Lore-Encoded:** Includes built-in interceptors for classified company directives and special orders.

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
