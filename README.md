# Leaf App

A lightweight **macOS menu bar productivity utility** that helps you automatically manage inactive applications.  

Built with **Swift**, **SwiftUI**, and **Xcode**, Leaf App improves focus and system performance by monitoring app activity in the background and closing unused apps based on user-defined preferences.

<p align="center">
  <img width="128" height="128" alt="leaf_256x256" src="https://github.com/user-attachments/assets/9bf73867-7be3-4b16-a5fd-ff204afb2fdf" />
  <br />
  <strong>Version: </strong>1.2
  <br />
  Requires macOS 14 or later.
  <br />
  <a href="https://github.com/Atswik/Leaf/releases/download/v1.2/Leaf_1.2.dmg"><strong>Download</strong></a>
  ·
  <a href="https://github.com/Atswik/Leaf/releases">Releases</a>
</p>

<div align="center">
  <img width="500" alt="leaf_notification" src="https://github.com/user-attachments/assets/b1f829a0-86b1-42f2-a828-597de061ab62" />
  <p>Notifies you to quit inactive apps using memory</p>
  <br />
  <img width="500" alt="leaf_settings" src="https://github.com/user-attachments/assets/6c138bb4-2094-49f1-a733-f45f9e09fdf2" />
  <p>Settings to help you customize</p>
</div>

## How it Works

Leaf watches which apps are running in the background and tracks when you last used them. 

When an app has been idle past your configured threshold and is consuming meaningful memory, Leaf sends a notification asking if you want to quit it. You can then decide to quit by pressing "Quit" button directly from the notification.

Leaf never quits anything automatically unless you enable that option in the Settings.

## Building from source

```bash
git clone https://github.com/Atswik/Leaf.git
cd Leaf
open Leaf.xcodeproj
```

Requires Xcode 16+. Dependencies are managed via Swift Package Manager and resolve automatically on first build.

## Tech Stack

- **Language:** Swift  
- **UI Framework:** SwiftUI  
- **IDE:** Xcode  
- **APIs:** NSWorkspace, NSRunningApplication  
- **Storage:** AppStorage
- **Updates:** Sparkle 2

## 📬 Contact

Built by [Satwik](https://satwiktungala.com). 

Have questions, feedback, or feature ideas? Reach out on [X](https://x.com/satwxyz) (Twitter) or open an issue right here on GitHub!

