# 🪔 Ghee-Khatam (घी खत्म)
### *“Bhagwaan! Ghee khatam ho gaya!” — Never let your AI oil run dry.*

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B%20(Sonoma%20%2F%20Sequoia)-000000?style=for-the-badge&logo=apple&logoColor=white" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Architecture-Universal%20(ARM64%20%2F%20x86__64)-blueviolet?style=for-the-badge" alt="Universal Binary">
  <img src="https://img.shields.io/badge/Swift-5.9%2B%20%2F%20SwiftUI%20%2B%20WidgetKit-FA7343?style=for-the-badge&logo=swift&logoColor=white" alt="SwiftUI + WidgetKit">
  <img src="https://img.shields.io/badge/RAM%20Usage-%3C%2015%20MB-success?style=for-the-badge" alt="Low RAM">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="MIT License">
</p>

---

## 🖥️ Live UI Preview

```text
   File  Edit  View  Window  Help                [ ✦ 97% · 100% ]   Tue 9:41 AM
                                                    └──────┬──────┘
                                                           ▼
╭─────────────────────────────────────────────────────────────────────────────╮
│  📈 Ghee-Khatam                  ● Synced to Cloud             ↻      ⚙     │
├─────────────────────────────────────────────────────────────────────────────┤
│  🪟 Desktop Widget Active        Pinned to desktop screen         [Hide]    │
├─────────────────────────────────────────────────────────────────────────────┤
│  ✨ Google Gemini / Antigravity                             ● Live API      │
│     Synced across all cloud servers & remote instances                      │
│     ACCOUNT: [ ● Work (user1@gmail.com) ]  [ Personal ]                     │
│                                                                             │
│     5-Hour Rolling Limit Remaining:               97%   (resets in 4h 39m)  │
│     [██████████████████████████████████████░]                               │
│                                                                             │
│     Weekly Plan Limit Remaining:                  79%   (resets in 4d 8h)   │
│     [███████████████████████████████░░░░░░░░]                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  🤖 Claude Code (Anthropic)                                 ● Live API      │
│     Direct macOS Keychain OAuth Session Sync                                │
│                                                                             │
│     5-Hour Rolling Limit Remaining:              100%   (Ready)             │
│     [████████████████████████████████████████]                              │
│                                                                             │
│     Weekly Limit Remaining:                       83%   (resets in 1d 15h)  │
│     [█████████████████████████████████░░░░░░]                               │
│     ↳ Active: Claude Code (99% utilization share)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│  ⏱️ Refreshes automatically every 20m                      [Quit Ghee-Khatam]│
╰─────────────────────────────────────────────────────────────────────────────╯
```

### 🧩 Native macOS Notification Center & Desktop Widgets

```text
╭─────────────────────────────────────────────────────────────────────────────╮
│  macOS Notification Center / Desktop Widget (Medium)                        │
│                                                                             │
│   ● AI Quotas                                                  Every 20m    │
│  ┌──────────────────────────────────┬──────────────────────────────────┐    │
│  │ ✨ Gemini       [Work] [Personal]│ 🤖 Claude Code          Pro Sync │    │
│  │                                  │                                  │    │
│  │ 5-Hour                       97% │ 5-Hour                      100% │    │
│  │ [████████████████████████░]      │ [██████████████████████████]     │    │
│  │ Resets in 4h 39m                 │ Ready to burn                    │    │
│  │                                  │                                  │    │
│  │ Weekly                       79% │ Weekly                       83% │    │
│  │ [███████████████████░░░░░]      │ [█████████████████████░░░░]      │    │
│  │ Resets in 4d 8h                  │ Resets in 1d 15h                 │    │
│  └──────────────────────────────────┴──────────────────────────────────┘    │
│                                                                             │
│  Small Widget (Radial Gauges):                                              │
│  ┌───────────────────────────────┐                                          │
│  │ [Work]          AI Quota      │                                          │
│  │                               │                                          │
│  │   ╭───╮          ╭───╮        │                                          │
│  │  │ 97% │        │100% │       │                                          │
│  │   ╰───╯          ╰───╯        │                                          │
│  │   Gemini        Claude        │                                          │
│  │  (4h 39m)       (Ready)       │                                          │
│  └───────────────────────────────┘                                          │
╰─────────────────────────────────────────────────────────────────────────────╯
```

---

## 💡 What is Ghee-Khatam?

**Ghee-Khatam** is an ultra-lightweight, 100% native macOS Menu Bar utility and **WidgetKit Notification Center Widget** that gives you instant, live visibility into your **Claude Code (Anthropic)** and **Google Gemini (Antigravity)** quotas across all local and remote sessions.

* **Pure Swift & SwiftUI**: Zero Electron bloat, zero webviews, zero Node dependencies.
* **Apple Silicon & Intel Ready**: Universal binary running natively on macOS Sonoma (14.0+) and Sequoia (15.0+).
* **0.0% Idle CPU**: Sleeps peacefully between refreshes and consumes less than 15 MB of RAM.

---

## 🌟 Key Highlights

```text
 ┌────────────────────────────────────────────────────────┐
 │  ✦ 92% · 100%                                          │  ← Menu Bar (Minimalist SF Symbol)
 └────────────────────────────────────────────────────────┘
                       │
       ┌───────────────┴───────────────┐
       ▼                               ▼
 ┌───────────────────────────┐   ┌───────────────────────────┐
 │ 🧩 Notification Center    │   │ 🪟 Floating Desktop HUD   │
 │   Widget (Small / Medium) │   │   Obsidian Glass Aesthetic│
 └───────────────────────────┘   └───────────────────────────┘
```

* **🤖 Official Claude Code Sync**: Reads your official session credentials securely from your macOS Keychain (`Claude Code-credentials`) and queries Anthropic's official usage endpoint—no manual API keys or brittle browser scraping.
* **👥 Multi-Account Gemini Switcher**: One-click toggle between accounts (e.g. `Work` ⇄ `Personal` or `account1` ⇄ `account2`) directly from the widget or menu bar with independent 5-hour rolling and weekly quotas.
* **🧩 Native macOS WidgetKit Support**: Built as a native `.appex` extension. Pin it right to your **Desktop** or inside **Notification Center** (`.systemSmall` and `.systemMedium`).
* **✦ Clean Single-Icon Menu Bar**: Replaces distracting clutter with a clean, single Apple SF Symbol (`✦`) followed by crisp quota typography (`✦ 92% · 100%`) or clean icon-only mode.
* **⏱️ Smart Polling with Local Timers**: 20-minute batched sync that respects provider rate limits while keeping smooth second-by-second countdown timers (`resets in 42m` or `Ready`).
* **🔒 100% Local & Private**: Read-only monitoring. Your tokens never leave your Mac and zero telemetry is collected.

---

## 🖼️ User Interface

### 1. Menu Bar Popover
A single click reveals an elegant glassmorphic dashboard:
- **Claude Quota Card**: 5-Hour rolling limit remaining, weekly account remaining, accurate reset countdowns, and active Claude Code percentage share.
- **Gemini Card**: Account selector tabs, 5-hour limits, weekly plan quota, and reset timers.
- **One-Click Refresh & Settings**: Instant cloud sync on demand.

### 2. Notification Center & Desktop Widget
- **Medium Widget**: Displays dual cards for Gemini and Claude side-by-side with an interactive account toggle button powered by **AppIntents**.
- **Small Widget**: High-contrast dual radial gauges with a quick-switch account badge.

---

## 🚀 1-Command Installation

Ghee-Khatam requires **macOS 14.0 (Sonoma)** or **macOS 15.0+ (Sequoia)**.

### Option A: Clone & Auto-Install (Recommended)

Open Terminal and run:

```bash
git clone https://github.com/your-username/ghee-khatam.git
cd ghee-khatam
./install.sh
```

The installer will:
1. Compile the native app and widget with `swiftc`.
2. Sign the bundle with your local Apple Development certificate (or ad-hoc signature).
3. Install to `/Applications/Ghee-Khatam.app`.
4. Register the WidgetKit extension with LaunchServices and launch Ghee-Khatam.

---

## 🧩 Adding Ghee-Khatam to Notification Center or Desktop

Once installed, adding the widget takes 10 seconds:

1. Click the **Date & Time** in the top-right corner of your screen to open macOS Notification Center.
2. Scroll to the bottom and click **"Edit Widgets"**.
3. In the left sidebar, select **Ghee-Khatam** (or search `Ghee`).
4. Choose **Small** or **Medium**, then click **`+`** or drag it anywhere onto your desktop or Notification Center!

---

## ⚙️ Configuration & Accounts

Open **Preferences** by clicking the menu bar icon and selecting the settings gear (or pressing `⌘,`):

| Setting | Options | Description |
| :--- | :--- | :--- |
| **Menu Bar Style** | `Minimal Icon (✦)`, `5-Hour Quotas (✦ 92% · 100%)`, `Weekly Quotas` | Configure how information appears in your menu bar. |
| **Gemini Accounts** | Custom emails (e.g. `work@company.com`, `personal@gmail.com`) | Enter your Google accounts; button labels dynamically adapt to your email username. |
| **Refresh Interval** | `5m`, `15m`, `20m (Default)`, `1h` | Controls background sync cadence. |
| **Desktop Widget** | Obsidian, Frosted, Opacity slider (0% - 100%), Pin behind windows | Customize the floating HUD widget. |

---

## 🛠️ Architecture & Under the Hood

```text
Ghee-Khatam.app
├── Contents/MacOS/GheeKhatam            ← Main AppKit / SwiftUI Menu Bar Application
├── Contents/Resources/Info.plist       ← Bundle ID: com.gheekhatam.mac
└── Contents/PlugIns/
    └── GheeKhatamWidget.appex          ← Native WidgetKit ExtensionKit PlugIn
        ├── MacOS/GheeKhatamWidget      ← Linked with _NSExtensionMain + WidgetBundle
        └── Info.plist                  ← com.apple.widgetkit-extension
```

1. **Keychain Access for Claude Code**:  
   Ghee-Khatam reads your authenticated Claude Code session token directly from macOS Keychain (`Claude Code-credentials`). It calls the official Anthropic `/api/oauth/usage` endpoint with `anthropic-beta: oauth-2025-04-20`, exactly mirroring Claude CLI's `/usage`.
2. **IPC Data Sharing via Containers**:  
   The main application serializes a lightweight `quota_snapshot.json` payload into both Application Support and the sandbox container directory (`Library/Containers/com.gheekhatam.mac.widget/`), enabling the WidgetKit extension to render snapshots with zero IPC latency.
3. **Interactive WidgetKit Buttons**:  
   Powered by Swift `AppIntents`, allowing direct account switching inside the Notification Center without opening the main window.

---

## 🔒 Privacy & Security

* **No Analytics / Telemetry**: Absolutely zero data collection.
* **100% Read-Only**: Ghee-Khatam monitors quotas only. It never modifies, resets, or triggers remote cloud usage.
* **Local Keychain Access**: All credential exchanges happen locally between your Mac and Anthropic / Google's official endpoints over HTTPS.

---

## 📄 License

Ghee-Khatam is open-source software licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <b>Made with 🪔 for developers who never want to run out of fuel mid-build.</b>
</p>
