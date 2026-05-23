# 🎵 Apple Music JAM

**Let your guests control the music!**

Apple Music JAM is an iOS CarPlay app that lets your passengers and guests search Apple Music and control playback through their phones — no app install needed.

## How it Works

1. **Server** (your iPhone, connected to CarPlay): Runs the app, plays music, hosts a local web server
2. **Hosts** (guests' phones): Scan a QR code → opens a web interface in their browser → search songs, add to queue, control playback

## Architecture

```
┌─────────────────────────────────────┐
│  iPhone (Server) - CarPlay          │
│  ┌─────────────────────────────┐    │
│  │ Apple Music JAM App         │    │
│  │  ├── Web Server (port 8080) │    │
│  │  ├── MPMusicPlayerController│    │
│  │  ├── CarPlay Now Playing    │    │
│  │  └── Live Activity          │    │
│  └─────────────────────────────┘    │
└──────────────┬──────────────────────┘
               │ Local WiFi Network
    ┌──────────┼──────────┐
    │          │          │
┌───┴───┐ ┌───┴───┐ ┌───┴───┐
│Host 1 │ │Host 2 │ │Host N │
│Browser│ │Browser│ │Browser│
└───────┘ └───────┘ └───────┘
```

## Requirements

- iPhone with iOS 16.1+
- Active Apple Music subscription (on the server device)
- All devices on the same WiFi network
- Xcode 16+ (for development)

## Setup

### Prerequisites

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen):
   ```bash
   brew install xcodegen
   ```

2. Clone or download this project

### Generate Xcode Project

```bash
cd "Apple Music JAM"
xcodegen generate
open AppleMusicJAM.xcodeproj
```

### Configure Signing

1. Open the project in Xcode
2. Select the `AppleMusicJAM` target
3. Go to **Signing & Capabilities**
4. Select your Development Team
5. Repeat for the `AppleMusicJAMWidgetExtension` target

### CarPlay Entitlement

For **development/simulator testing**, the CarPlay entitlement works with the simulator.

For **production/App Store**, you must request the CarPlay Audio entitlement from Apple:
1. Go to [developer.apple.com/contact/carplay/](https://developer.apple.com/contact/carplay/)
2. Select "Audio" as your app category
3. Submit your request and wait for approval

### Run

1. Select your physical iPhone as the target device
2. Build and run (⌘R)
3. For CarPlay testing: In Simulator, go to **I/O → External Displays → CarPlay**

## Usage

1. Launch Apple Music JAM on your iPhone
2. The app displays a QR code
3. Guests scan the QR code with their phone camera
4. A web interface opens in their browser
5. They can search songs, play them, and control playback!

## Tech Stack

| Component | Technology |
|:---|:---|
| Search | iTunes Search API (REST, no auth) |
| Playback | MPMusicPlayerController (MediaPlayer framework) |
| Web Server | [Swifter](https://github.com/httpswift/swifter) |
| CarPlay | CarPlay Framework (CPNowPlayingTemplate) |
| Live Activities | ActivityKit + WidgetKit |
| QR Code | CoreImage (CIQRCodeGenerator) |
| UI | SwiftUI |

## Project Structure

```
├── project.yml                    # XcodeGen configuration
├── AppleMusicJAM/
│   ├── Info.plist                 # App configuration
│   ├── AppleMusicJAM.entitlements
│   ├── App/                       # App lifecycle
│   ├── CarPlay/                   # CarPlay integration
│   ├── Models/                    # Data models
│   ├── Services/                  # Business logic
│   ├── Views/                     # SwiftUI views
│   └── Web/                       # Web interface (served to hosts)
├── AppleMusicJAMWidget/           # Widget Extension (Live Activities)
└── Shared/                        # Shared types (App ↔ Widget)
```

## License

Private project. All rights reserved.
