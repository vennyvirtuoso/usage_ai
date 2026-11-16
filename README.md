# ⚡ Usage AI

**Usage AI** is a lightweight, native macOS menu bar and desktop widget app built with Swift and SwiftUI. It tracks real-time token consumption, caching efficiency, and estimated costs across **Claude (Anthropic)** and **Gemini (Antigravity)** sessions.

![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-blue?logo=apple)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)
![Architecture](https://img.shields.io/badge/Arch-Apple%20Silicon%20(ARM64)-purple)

---

## 🌟 Key Features

- **Hybrid Widget Design**:
  - **Menu Bar Extra**: Sits unobtrusively in your macOS status bar (`✨ 14.2k  🤖 28.5k` or `⚡ 42.7k`), showing live token stats at a glance.
  - **Floating Desktop Widget**: Can be detached with one click into a sleek, glassmorphic floating HUD widget on your desktop.
  - **Compact & Expanded Modes**: Switch between a minimal dual-gauge badge and a full statistical card.
  - **Pin to Desktop**: Option to pin behind normal windows like a native macOS desktop widget or float on top.

- **Dual Provider Intelligence**:
  - **Gemini / Antigravity**: Automatically scans local session transcripts (`~/.gemini/antigravity/brain/`) for prompt tokens, completion tokens, cached tokens, and active models.
  - **Claude (Anthropic)**: Automatically parses Claude Code sessions (`~/.claude/projects/`, `~/.claude/sessions/`) for input, output, cache-read, and cache-creation tokens.

- **Cost & Cache Optimization**:
  - Live cost estimations calculated per model (e.g. Gemini 3.8 Flash, 2.0 Flash, 1.5 Pro, Claude 3.5 Sonnet, Claude 3 Opus, Haiku).
  - Cache hit ratio metrics so you know how much context caching saves you.

- **Zero API Keys Required (With Optional Cloud Support)**:
  - Works out of the box by reading local CLI and IDE session logs.
  - Optional support for Anthropic and Google Gemini API keys in Preferences for live cloud monitoring.

---

## 🚀 Quick Start

### 1. Build and Run
Clone or navigate to the repository directory and run:

```bash
# Build and launch immediately
./run.sh
```

Or using `make`:

```bash
make run
```

### 2. Install to Applications
To install Usage AI into your macOS `/Applications` folder:

```bash
make install
```

---

## 🖥️ Usage

### Menu Bar Extra
- **Left-Click**: Opens the rich popup dashboard displaying:
  - Today's combined tokens and daily budget gauge.
  - Usage distribution comparison bar (Gemini vs Claude).
  - Gemini Antigravity card (Today tokens, all-time, cache ratio, estimated cost).
  - Claude card (Today tokens, all-time, cache ratio, estimated cost).
  - Model breakdown pills.
  - "Desktop Widget" button to toggle the floating widget.
  - Refresh and Settings buttons.
- **Right-Click**: Opens the quick context menu (Refresh, Toggle Widget, Preferences, Quit).

### Desktop Floating Widget
- Click **"Desktop Widget"** in the menu bar popover to detach it.
- **Drag**: Click and drag anywhere on the widget background to move it anywhere on your screens.
- **Compact Toggle (`⤢`)**: Toggle between compact dual-gauge and full card mode.
- **Pin Toggle (`📌`)**: Pin behind regular windows or float above all windows.
- **Close (`✕`)**: Closes the widget while keeping the menu bar status item active.

---

## ⚙️ Preferences & Customization

Open **Preferences** via the gear icon or right-clicking the menu bar item:

1. **General**:
   - Change Menu Bar display format:
     - `Both Tokens (✨ 12k | 🤖 45k)`
     - `Total Combined (⚡ 57k)`
     - `Total + Cost (⚡ 57k · $0.24)`
     - `Minimal Icon Only`
   - Refresh interval: `5s`, `15s`, `30s`, or `1m`.
   - Daily token budget (for circular progress gauge).
   - Widget opacity and desktop pinning.
2. **Local Logs**:
   - Configure custom directory paths for Antigravity or Claude logs.
   - Rescan cache.
3. **API Keys (Optional)**:
   - Enter Google Gemini API Key and Anthropic API Key to test connections.

---

## 🔒 macOS File Permissions Note

macOS has privacy protection on user directories like `~/.gemini` and `~/.claude`.
- When running outside a sandbox or as a regular macOS app, Usage AI reads files from your user directory directly.
- If prompted by macOS, grant **Full Disk Access** or folder access in **System Settings > Privacy & Security > Full Disk Access** to allow the app to read local CLI transcripts.
- Alternatively, use the **Browse...** button in **Preferences > Local Logs** to explicitly select your logs folder.

---

## 🧪 Running Tests

To verify scanners, parsers, and pricing calculations:

```bash
make test
```

All tests run against mock Antigravity and Claude transcript fixtures.
