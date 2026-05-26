# Leaf App

A lightweight **macOS menu bar productivity utility** that helps you automatically manage inactive applications.  

Built with **Swift**, **SwiftUI**, and **Xcode**, Leaf App improves focus and system performance by monitoring app activity in the background and closing unused apps based on user-defined preferences.

## 📌 Requirements

- macOS 14.0 or later  
- Xcode 15+ (for building from source)

## ↓ Download & Installation

You can grab the latest compiled release directly from [satwiktungala.com/apps/leaf](https://satwiktungala.com/apps) or download the `.dmg` from the **[Releases](https://github.com/Atswik/Leaf/releases)** tab.

## ⚡️ Features

- **Memory Pressure Monitoring** – Actively watches your system's memory state and identifies hidden background apps hoarding RAM.
- **Safe Quit** – Sends standard native termination requests (`Cmd + Q`) rather than force-killing processes, ensuring target apps still prompt you to save unsaved work.
- **Zero Data Collection** – 100% local processing with absolutely no telemetry or tracking.
- **Optimized Performance** – Background service designed to use minimal memory and CPU.
- **Optimized for Apple Silicon** – Lightweight background footprint designed specifically for modern Mac architectures.
- **Custom Inactivity Timer** – Configure how long apps can stay idle before being flagged to quit.  

## 🛠️ Tech Stack

- **Language:** Swift  
- **UI Framework:** SwiftUI  
- **IDE:** Xcode  
- **APIs:** NSWorkspace, NSRunningApplication  
- **Storage:** AppStorage
- **Updates:** Sparkle 2



## 📬 Contact

Built in public by [Satwik](https://satwiktungala.com). Have questions, feedback, or feature ideas? Reach out on X or open an issue right here on GitHub!

